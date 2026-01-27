import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../interfaces/i_external_plugin.dart';

/// IPC Bridge for communication between host and external plugins
class IPCBridge {
  final Map<String, MessageHandler> _messageHandlers = {};
  final Map<String, IPCConnection> _connections = {};
  final Map<String, Completer<IPCMessage>> _pendingRequests = {};
  final Duration _defaultTimeout = const Duration(seconds: 30);
  final Map<String, RetryConfig> _retryConfigs = {};
  final Map<String, int> _connectionAttempts = {};

  /// Send a message to an external plugin
  Future<void> sendMessage(String pluginId, IPCMessage message) async {
    // Validate message before sending
    if (!_validateMessage(message)) {
      throw ArgumentError('Invalid message format');
    }

    final connection = _connections[pluginId];
    if (connection == null) {
      throw StateError('No connection to plugin $pluginId');
    }

    if (!connection.isConnected) {
      // Try to reconnect if configured
      final retryConfig = _retryConfigs[pluginId];
      if (retryConfig != null && retryConfig.autoReconnect) {
        await _attemptReconnection(pluginId);
      } else {
        throw StateError('Connection to plugin $pluginId is not active');
      }
    }

    await _sendMessageWithRetry(pluginId, message);
  }

  /// Send message with retry logic
  Future<void> _sendMessageWithRetry(
    String pluginId,
    IPCMessage message,
  ) async {
    final retryConfig = _retryConfigs[pluginId] ?? RetryConfig.defaultConfig();
    Exception? lastException;

    for (int attempt = 0; attempt < retryConfig.maxAttempts; attempt++) {
      try {
        final connection = _connections[pluginId];
        if (connection == null || !connection.isConnected) {
          throw StateError('Connection lost during message send');
        }

        await connection.sendMessage(message);
        return; // Success
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // If this is the last attempt, throw the exception
        if (attempt == retryConfig.maxAttempts - 1) {
          throw lastException;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateBackoffDelay(attempt, retryConfig);
        debugPrint(
          'Message send attempt ${attempt + 1} failed for $pluginId: $e. Retrying in ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);
      }
    }

    throw lastException ??
        Exception(
          'Failed to send message after ${retryConfig.maxAttempts} attempts',
        );
  }

  /// Send a message and wait for response
  Future<IPCMessage> sendMessageWithResponse(
    String pluginId,
    IPCMessage message, {
    Duration? timeout,
  }) async {
    // Validate message before sending
    if (!_validateMessage(message)) {
      throw ArgumentError('Invalid message format');
    }

    final connection = _connections[pluginId];
    if (connection == null) {
      throw StateError('No connection to plugin $pluginId');
    }

    if (!connection.isConnected) {
      throw StateError('Connection to plugin $pluginId is not active');
    }

    // Set up response waiting
    final completer = Completer<IPCMessage>();
    _pendingRequests[message.messageId] = completer;

    // Set up timeout
    final timeoutDuration = timeout ?? _defaultTimeout;
    Timer(timeoutDuration, () {
      if (!completer.isCompleted) {
        _pendingRequests.remove(message.messageId);
        completer.completeError(
          TimeoutException(
            'Message ${message.messageId} timed out after ${timeoutDuration.inSeconds}s',
            timeoutDuration,
          ),
        );
      }
    });

    try {
      await connection.sendMessage(message);
      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(message.messageId);
      rethrow;
    }
  }

  /// Register a message handler for a specific message type
  void registerMessageHandler(String messageType, MessageHandler handler) {
    if (messageType.isEmpty) {
      throw ArgumentError('Message type cannot be empty');
    }
    _messageHandlers[messageType] = handler;
  }

  /// Unregister a message handler
  void unregisterMessageHandler(String messageType) {
    _messageHandlers.remove(messageType);
  }

  /// Get all registered message types
  List<String> getRegisteredMessageTypes() {
    return _messageHandlers.keys.toList();
  }

  /// Broadcast an event to all connected plugins
  Future<void> broadcastEvent(PlatformEvent event) async {
    final message = IPCMessage(
      messageId: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
      messageType: 'platform_event',
      sourceId: 'host',
      targetId: 'broadcast',
      payload: event.toJson(),
    );

    final futures = <Future<void>>[];
    for (final entry in _connections.entries) {
      if (entry.value.isConnected) {
        futures.add(
          entry.value.sendMessage(message).catchError((error) {
            // Log error but don't fail the broadcast
            debugPrint('Failed to broadcast to ${entry.key}: $error');
          }),
        );
      }
    }

    await Future.wait(futures);
  }

  /// Establish IPC connection with an external plugin
  Future<void> establishConnection(
    String pluginId,
    ConnectionConfig config, {
    RetryConfig? retryConfig,
  }) async {
    if (pluginId.isEmpty) {
      throw ArgumentError('Plugin ID cannot be empty');
    }

    if (_connections.containsKey(pluginId)) {
      throw StateError('Connection to plugin $pluginId already exists');
    }

    // Set up retry configuration
    final retry = retryConfig ?? RetryConfig.defaultConfig();
    _retryConfigs[pluginId] = retry;
    _connectionAttempts[pluginId] = 0;

    await _establishConnectionWithRetry(pluginId, config, retry);
  }

  /// Establish connection with retry logic
  Future<void> _establishConnectionWithRetry(
    String pluginId,
    ConnectionConfig config,
    RetryConfig retryConfig,
  ) async {
    Exception? lastException;

    for (int attempt = 0; attempt < retryConfig.maxAttempts; attempt++) {
      try {
        _connectionAttempts[pluginId] = attempt + 1;

        final connection = await _createConnection(config);
        _connections[pluginId] = connection;

        // Set up message handling for this connection
        connection.onMessage = (message) => _handleMessage(pluginId, message);
        connection.onDisconnect = () => _handleDisconnection(pluginId);
        connection.onError = (error) => _handleConnectionError(pluginId, error);

        // Connection successful
        _connectionAttempts.remove(pluginId);
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // If this is the last attempt, throw the exception
        if (attempt == retryConfig.maxAttempts - 1) {
          _connectionAttempts.remove(pluginId);
          _retryConfigs.remove(pluginId);
          throw lastException;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateBackoffDelay(attempt, retryConfig);
        debugPrint(
          'Connection attempt ${attempt + 1} failed for $pluginId: $e. Retrying in ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    _connectionAttempts.remove(pluginId);
    _retryConfigs.remove(pluginId);
    throw lastException ??
        Exception(
          'Failed to establish connection after ${retryConfig.maxAttempts} attempts',
        );
  }

  /// Close IPC connection with an external plugin
  Future<void> closeConnection(String pluginId) async {
    final connection = _connections[pluginId];
    if (connection != null) {
      await connection.close();
      _connections.remove(pluginId);

      // Cancel any pending requests for this plugin
      _pendingRequests.removeWhere((messageId, completer) {
        if (messageId.startsWith(pluginId)) {
          if (!completer.isCompleted) {
            completer.completeError(StateError('Connection closed'));
          }
          return true;
        }
        return false;
      });
    }
  }

  /// Get connection status for a plugin
  bool isConnected(String pluginId) {
    final connection = _connections[pluginId];
    return connection?.isConnected ?? false;
  }

  /// Get all connected plugin IDs
  List<String> getConnectedPlugins() {
    return _connections.entries
        .where((entry) => entry.value.isConnected)
        .map((entry) => entry.key)
        .toList();
  }

  /// Handle incoming message from external plugin
  Future<void> _handleMessage(String pluginId, IPCMessage message) async {
    try {
      // Validate incoming message
      if (!_validateMessage(message)) {
        final errorResponse = message.createErrorResponse(
          errorCode: 'INVALID_MESSAGE_FORMAT',
          errorMessage: 'Message validation failed',
        );
        await sendMessage(pluginId, errorResponse);
        return;
      }

      // Check if this is a response to a pending request
      if (message.messageType == 'response' || message.messageType == 'error') {
        final originalMessageId = message.messageId
            .replaceAll('_response', '')
            .replaceAll('_error', '');
        final completer = _pendingRequests.remove(originalMessageId);
        if (completer != null && !completer.isCompleted) {
          if (message.messageType == 'error') {
            final error = message.payload['error'] as Map<String, dynamic>?;
            completer.completeError(
              IPCException(
                error?['code'] as String? ?? 'UNKNOWN_ERROR',
                error?['message'] as String? ?? 'Unknown error occurred',
                error?['details'] as Map<String, dynamic>?,
              ),
            );
          } else {
            completer.complete(message);
          }
          return;
        }
      }

      // Route to registered handler
      final handler = _messageHandlers[message.messageType];
      if (handler != null) {
        await handler(message);
      } else {
        // Send error response for unhandled message types
        final errorResponse = message.createErrorResponse(
          errorCode: 'UNHANDLED_MESSAGE_TYPE',
          errorMessage:
              'No handler registered for message type: ${message.messageType}',
        );
        await sendMessage(pluginId, errorResponse);
      }
    } catch (e) {
      // Send error response for any processing errors
      try {
        final errorResponse = message.createErrorResponse(
          errorCode: 'MESSAGE_PROCESSING_ERROR',
          errorMessage: 'Error processing message: $e',
        );
        await sendMessage(pluginId, errorResponse);
      } catch (sendError) {
        // Log error if we can't even send error response
        debugPrint('Failed to send error response to $pluginId: $sendError');
      }
    }
  }

  /// Handle connection disconnection
  void _handleDisconnection(String pluginId) {
    debugPrint('Plugin $pluginId disconnected');

    // Check if auto-reconnect is enabled
    final retryConfig = _retryConfigs[pluginId];
    if (retryConfig?.autoReconnect == true) {
      debugPrint('Attempting to reconnect to plugin $pluginId');
      _scheduleReconnection(pluginId);
    } else {
      _connections.remove(pluginId);
      _retryConfigs.remove(pluginId);
      _connectionAttempts.remove(pluginId);
    }

    // Cancel any pending requests for this plugin
    _pendingRequests.removeWhere((messageId, completer) {
      if (messageId.startsWith(pluginId)) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Plugin disconnected'));
        }
        return true;
      }
      return false;
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnection(String pluginId) {
    final retryConfig = _retryConfigs[pluginId];
    if (retryConfig == null) return;

    final delay = _calculateBackoffDelay(0, retryConfig);
    Timer(delay, () async {
      try {
        await _attemptReconnection(pluginId);
      } catch (e) {
        debugPrint('Reconnection failed for plugin $pluginId: $e');
        // Remove the connection if reconnection fails
        _connections.remove(pluginId);
        _retryConfigs.remove(pluginId);
        _connectionAttempts.remove(pluginId);
      }
    });
  }

  /// Attempt to reconnect to a plugin
  Future<void> _attemptReconnection(String pluginId) async {
    final connection = _connections[pluginId];
    if (connection == null) {
      throw StateError(
        'No connection configuration found for plugin $pluginId',
      );
    }

    // Close existing connection
    await connection.close();
    _connections.remove(pluginId);

    // Create new connection with same configuration
    // Note: In a real implementation, we'd need to store the original ConnectionConfig
    // For now, we'll simulate reconnection
    debugPrint('Reconnecting to plugin $pluginId...');

    // Simulate reconnection delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, this would recreate the connection:
    // await _establishConnectionWithRetry(pluginId, originalConfig, retryConfig);

    debugPrint('Reconnected to plugin $pluginId');
  }

  /// Handle connection errors
  void _handleConnectionError(String pluginId, dynamic error) {
    debugPrint('Connection error for plugin $pluginId: $error');

    // Check if this is a recoverable error
    if (_isRecoverableError(error)) {
      final retryConfig = _retryConfigs[pluginId];
      if (retryConfig?.autoReconnect == true) {
        debugPrint('Attempting recovery for plugin $pluginId');
        _scheduleReconnection(pluginId);
      }
    } else {
      debugPrint(
        'Non-recoverable error for plugin $pluginId, closing connection',
      );
      closeConnection(pluginId);
    }
  }

  /// Check if an error is recoverable
  bool _isRecoverableError(dynamic error) {
    if (error is TimeoutException) return true;
    if (error is StateError && error.message.contains('connection')) {
      return true;
    }
    if (error is IPCException && error.code == 'CONNECTION_LOST') return true;

    // Add more recoverable error conditions as needed
    return false;
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int attempt, RetryConfig config) {
    final baseDelay = config.baseDelay.inMilliseconds;
    final maxDelay = config.maxDelay.inMilliseconds;

    // Exponential backoff: baseDelay * (2^attempt) with jitter
    final exponentialDelay = baseDelay * (1 << attempt);
    final delayWithJitter =
        exponentialDelay +
        (exponentialDelay *
            config.jitterFactor *
            (DateTime.now().millisecond / 1000.0));

    // Cap at maximum delay
    final finalDelay = delayWithJitter.clamp(
      baseDelay.toDouble(),
      maxDelay.toDouble(),
    );

    return Duration(milliseconds: finalDelay.round());
  }

  /// Validate message format and content
  bool _validateMessage(IPCMessage message) {
    // Check required fields
    if (message.messageId.isEmpty ||
        message.messageType.isEmpty ||
        message.sourceId.isEmpty ||
        message.targetId.isEmpty) {
      return false;
    }

    // Validate message ID format (should be unique)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(message.messageId)) {
      return false;
    }

    // Validate message type format
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(message.messageType)) {
      return false;
    }

    // Validate timestamp (should not be too far in the future)
    final now = DateTime.now();
    if (message.timestamp.isAfter(now.add(const Duration(minutes: 5)))) {
      return false;
    }

    // Validate payload can be serialized to JSON
    try {
      jsonEncode(message.payload);
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Create connection based on configuration
  Future<IPCConnection> _createConnection(ConnectionConfig config) async {
    switch (config.type) {
      case ConnectionType.namedPipe:
        return NamedPipeConnection(config);
      case ConnectionType.webSocket:
        return WebSocketConnection(config);
      case ConnectionType.http:
        return HTTPConnection(config);
      default:
        throw ArgumentError('Unsupported connection type: ${config.type}');
    }
  }

  /// Dispose of all connections and resources
  Future<void> dispose() async {
    final futures = <Future<void>>[];

    // Create a copy of connections to avoid concurrent modification
    final connectionEntries = _connections.entries.toList();
    for (final entry in connectionEntries) {
      futures.add(entry.value.close());
    }
    await Future.wait(futures);

    _connections.clear();
    _messageHandlers.clear();

    // Complete any remaining pending requests with error
    final pendingRequestValues = _pendingRequests.values.toList();
    for (final completer in pendingRequestValues) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('IPCBridge disposed'));
      }
    }
    _pendingRequests.clear();
  }
}

/// Exception thrown during IPC communication
class IPCException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const IPCException(this.code, this.message, [this.details]);

  @override
  String toString() {
    return 'IPCException($code): $message${details != null ? ' - $details' : ''}';
  }
}

/// Configuration for IPC connections
class ConnectionConfig {
  final ConnectionType type;
  final String address;
  final int? port;
  final Map<String, dynamic> options;

  const ConnectionConfig({
    required this.type,
    required this.address,
    this.port,
    this.options = const {},
  });
}

/// Types of IPC connections
enum ConnectionType { namedPipe, webSocket, http, sharedMemory }

/// Abstract IPC connection
abstract class IPCConnection {
  /// Callback for incoming messages
  void Function(IPCMessage message)? onMessage;

  /// Callback for connection disconnection
  void Function()? onDisconnect;

  /// Callback for connection errors
  void Function(dynamic error)? onError;

  /// Send a message through this connection
  Future<void> sendMessage(IPCMessage message);

  /// Close the connection
  Future<void> close();

  /// Check if connection is active
  bool get isConnected;

  /// Get connection statistics
  ConnectionStats get stats;
}

/// Connection statistics
class ConnectionStats {
  final int messagesSent;
  final int messagesReceived;
  final int errorsCount;
  final DateTime connectedAt;
  final DateTime? lastActivity;

  const ConnectionStats({
    required this.messagesSent,
    required this.messagesReceived,
    required this.errorsCount,
    required this.connectedAt,
    this.lastActivity,
  });
}

/// Named pipe connection implementation
class NamedPipeConnection extends IPCConnection {
  final ConnectionConfig config;
  bool _isConnected = false;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _errorsCount = 0;
  late final DateTime _connectedAt;
  DateTime? _lastActivity;

  // Platform-specific pipe handles
  // ignore: unused_field
  dynamic _pipeHandle;
  StreamSubscription? _readSubscription;

  NamedPipeConnection(this.config) {
    _connectedAt = DateTime.now();
    _initializeConnection();
  }

  /// Initialize the named pipe connection
  Future<void> _initializeConnection() async {
    try {
      // Platform-specific named pipe implementation
      if (config.options['platform'] == 'windows') {
        await _initializeWindowsPipe();
      } else {
        await _initializeUnixPipe();
      }
      _isConnected = true;
      _lastActivity = DateTime.now();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Initialize Windows named pipe
  Future<void> _initializeWindowsPipe() async {
    // Windows named pipe format: \\.\pipe\pipename
    final pipeName = config.address.startsWith(r'\\.\pipe\')
        ? config.address
        : r'\\.\pipe\' + config.address;

    // For now, simulate the connection
    // In a real implementation, this would use FFI to call Windows APIs
    _pipeHandle = 'windows_pipe_$pipeName';

    // Simulate message listening
    _startMessageListener();
  }

  /// Initialize Unix domain socket (FIFO)
  Future<void> _initializeUnixPipe() async {
    // Unix named pipe format: /tmp/pipename or custom path
    final pipePath = config.address.startsWith('/')
        ? config.address
        : '/tmp/${config.address}';

    // For now, simulate the connection
    // In a real implementation, this would use dart:io Socket.connect
    _pipeHandle = 'unix_pipe_$pipePath';

    // Simulate message listening
    _startMessageListener();
  }

  /// Start listening for incoming messages
  void _startMessageListener() {
    // Simulate message reception
    // In a real implementation, this would read from the actual pipe
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Simulate receiving messages occasionally
      if (DateTime.now().millisecond % 100 == 0) {
        _simulateIncomingMessage();
      }
    });
  }

  /// Simulate incoming message for testing
  void _simulateIncomingMessage() {
    final message = IPCMessage(
      messageId: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      messageType: 'ping',
      sourceId: 'external_plugin',
      targetId: 'host',
      payload: {'timestamp': DateTime.now().toIso8601String()},
    );

    _messagesReceived++;
    _lastActivity = DateTime.now();
    onMessage?.call(message);
  }

  @override
  Future<void> sendMessage(IPCMessage message) async {
    if (!_isConnected) {
      throw StateError('Named pipe connection is not active');
    }

    try {
      // Serialize message to JSON
      final messageJson = jsonEncode(message.toJson());

      // Platform-specific sending
      if (config.options['platform'] == 'windows') {
        await _sendWindowsPipeMessage(messageJson);
      } else {
        await _sendUnixPipeMessage(messageJson);
      }

      _messagesSent++;
      _lastActivity = DateTime.now();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Send message through Windows named pipe
  Future<void> _sendWindowsPipeMessage(String messageJson) async {
    // Simulate Windows pipe write
    // In a real implementation, this would use FFI to call WriteFile
    await Future.delayed(const Duration(milliseconds: 10));
    debugPrint('Windows pipe send: $messageJson');
  }

  /// Send message through Unix named pipe
  Future<void> _sendUnixPipeMessage(String messageJson) async {
    // Simulate Unix pipe write
    // In a real implementation, this would write to the socket
    await Future.delayed(const Duration(milliseconds: 10));
    debugPrint('Unix pipe send: $messageJson');
  }

  @override
  Future<void> close() async {
    if (_isConnected) {
      _isConnected = false;
      _readSubscription?.cancel();

      // Platform-specific cleanup
      if (config.options['platform'] == 'windows') {
        await _closeWindowsPipe();
      } else {
        await _closeUnixPipe();
      }

      onDisconnect?.call();
    }
  }

  /// Close Windows named pipe
  Future<void> _closeWindowsPipe() async {
    // Simulate Windows pipe close
    // In a real implementation, this would use FFI to call CloseHandle
    _pipeHandle = null;
  }

  /// Close Unix named pipe
  Future<void> _closeUnixPipe() async {
    // Simulate Unix pipe close
    // In a real implementation, this would close the socket
    _pipeHandle = null;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  ConnectionStats get stats => ConnectionStats(
    messagesSent: _messagesSent,
    messagesReceived: _messagesReceived,
    errorsCount: _errorsCount,
    connectedAt: _connectedAt,
    lastActivity: _lastActivity,
  );
}

/// WebSocket connection implementation
class WebSocketConnection extends IPCConnection {
  final ConnectionConfig config;
  bool _isConnected = false;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _errorsCount = 0;
  late final DateTime _connectedAt;
  DateTime? _lastActivity;

  // WebSocket connection
  // ignore: unused_field
  dynamic _webSocket; // Would be WebSocket in real implementation
  StreamSubscription? _messageSubscription;

  WebSocketConnection(this.config) {
    _connectedAt = DateTime.now();
    _initializeConnection();
  }

  /// Initialize WebSocket connection
  Future<void> _initializeConnection() async {
    try {
      final uri = _buildWebSocketUri();

      // Simulate WebSocket connection
      // In a real implementation: _webSocket = await WebSocket.connect(uri.toString());
      _webSocket = 'websocket_${uri.toString()}';

      _isConnected = true;
      _lastActivity = DateTime.now();

      // Set up message listening
      _setupMessageListener();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Build WebSocket URI from config
  Uri _buildWebSocketUri() {
    final scheme = config.options['secure'] == true ? 'wss' : 'ws';
    final port = config.port ?? (config.options['secure'] == true ? 443 : 80);
    final path = config.options['path'] as String? ?? '/';

    return Uri(scheme: scheme, host: config.address, port: port, path: path);
  }

  /// Set up WebSocket message listener
  void _setupMessageListener() {
    // Simulate WebSocket message listening
    // In a real implementation: _messageSubscription = _webSocket.listen(...)
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Simulate receiving messages occasionally
      if (DateTime.now().second % 5 == 0) {
        _simulateIncomingMessage();
      }
    });
  }

  /// Simulate incoming WebSocket message
  void _simulateIncomingMessage() {
    final message = IPCMessage(
      messageId: 'ws_${DateTime.now().millisecondsSinceEpoch}',
      messageType: 'heartbeat',
      sourceId: 'web_plugin',
      targetId: 'host',
      payload: {
        'status': 'alive',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    _messagesReceived++;
    _lastActivity = DateTime.now();
    onMessage?.call(message);
  }

  @override
  Future<void> sendMessage(IPCMessage message) async {
    if (!_isConnected) {
      throw StateError('WebSocket connection is not active');
    }

    try {
      // Serialize message to JSON
      final messageJson = jsonEncode(message.toJson());

      // Send through WebSocket
      // In a real implementation: _webSocket.add(messageJson);
      await _simulateWebSocketSend(messageJson);

      _messagesSent++;
      _lastActivity = DateTime.now();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Simulate WebSocket message sending
  Future<void> _simulateWebSocketSend(String messageJson) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('WebSocket send: $messageJson');
  }

  @override
  Future<void> close() async {
    if (_isConnected) {
      _isConnected = false;
      _messageSubscription?.cancel();

      // Close WebSocket connection
      // In a real implementation: await _webSocket.close();
      _webSocket = null;

      onDisconnect?.call();
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  ConnectionStats get stats => ConnectionStats(
    messagesSent: _messagesSent,
    messagesReceived: _messagesReceived,
    errorsCount: _errorsCount,
    connectedAt: _connectedAt,
    lastActivity: _lastActivity,
  );
}

/// HTTP connection implementation
class HTTPConnection extends IPCConnection {
  final ConnectionConfig config;
  bool _isConnected = false;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _errorsCount = 0;
  late final DateTime _connectedAt;
  DateTime? _lastActivity;

  // HTTP client and polling
  // ignore: unused_field
  dynamic _httpClient; // Would be HttpClient in real implementation
  Timer? _pollingTimer;
  final Duration _pollingInterval = const Duration(seconds: 1);

  HTTPConnection(this.config) {
    _connectedAt = DateTime.now();
    _initializeConnection();
  }

  /// Initialize HTTP connection
  Future<void> _initializeConnection() async {
    try {
      // Simulate HTTP client initialization
      // In a real implementation: _httpClient = HttpClient();
      _httpClient = 'http_client_${config.address}:${config.port}';

      // Test connection with a ping
      await _testConnection();

      _isConnected = true;
      _lastActivity = DateTime.now();

      // Start polling for messages
      _startPolling();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Test HTTP connection
  Future<void> _testConnection() async {
    final uri = _buildUri('/ping');

    // Simulate HTTP GET request
    // In a real implementation:
    // final request = await _httpClient.getUrl(uri);
    // final response = await request.close();
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('HTTP ping to: $uri');
  }

  /// Build URI for HTTP requests
  Uri _buildUri(String path) {
    final scheme = config.options['secure'] == true ? 'https' : 'http';
    final port = config.port ?? (config.options['secure'] == true ? 443 : 80);

    return Uri(scheme: scheme, host: config.address, port: port, path: path);
  }

  /// Start polling for incoming messages
  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      try {
        await _pollForMessages();
      } catch (e) {
        _errorsCount++;
        onError?.call(e);
      }
    });
  }

  /// Poll for incoming messages via HTTP
  Future<void> _pollForMessages() async {
    // Simulate HTTP GET request for messages
    // In a real implementation:
    // final request = await _httpClient.getUrl(uri);
    // final response = await request.close();
    // final messages = await _parseMessages(response);

    // Simulate occasional message reception
    if (DateTime.now().second % 10 == 0) {
      _simulateIncomingMessage();
    }
  }

  /// Simulate incoming HTTP message
  void _simulateIncomingMessage() {
    final message = IPCMessage(
      messageId: 'http_${DateTime.now().millisecondsSinceEpoch}',
      messageType: 'status_update',
      sourceId: 'container_plugin',
      targetId: 'host',
      payload: {
        'status': 'running',
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': {'cpu': 25.5, 'memory': 128},
      },
    );

    _messagesReceived++;
    _lastActivity = DateTime.now();
    onMessage?.call(message);
  }

  @override
  Future<void> sendMessage(IPCMessage message) async {
    if (!_isConnected) {
      throw StateError('HTTP connection is not active');
    }

    try {
      final uri = _buildUri('/messages');
      final messageJson = jsonEncode(message.toJson());

      // Send HTTP POST request
      // In a real implementation:
      // final request = await _httpClient.postUrl(uri);
      // request.headers.contentType = ContentType.json;
      // request.write(messageJson);
      // final response = await request.close();

      await _simulateHttpPost(uri, messageJson);

      _messagesSent++;
      _lastActivity = DateTime.now();
    } catch (e) {
      _errorsCount++;
      onError?.call(e);
      rethrow;
    }
  }

  /// Simulate HTTP POST request
  Future<void> _simulateHttpPost(Uri uri, String messageJson) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('HTTP POST to $uri: $messageJson');
  }

  @override
  Future<void> close() async {
    if (_isConnected) {
      _isConnected = false;
      _pollingTimer?.cancel();

      // Close HTTP client
      // In a real implementation: _httpClient.close();
      _httpClient = null;

      onDisconnect?.call();
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  ConnectionStats get stats => ConnectionStats(
    messagesSent: _messagesSent,
    messagesReceived: _messagesReceived,
    errorsCount: _errorsCount,
    connectedAt: _connectedAt,
    lastActivity: _lastActivity,
  );
}

/// Platform event for broadcasting to plugins
class PlatformEvent {
  final String eventType;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PlatformEvent({
    required this.eventType,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Configuration for retry and error handling
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterFactor;
  final bool autoReconnect;
  final Duration reconnectDelay;

  const RetryConfig({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.jitterFactor,
    required this.autoReconnect,
    required this.reconnectDelay,
  });

  /// Default retry configuration
  factory RetryConfig.defaultConfig() {
    return const RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(milliseconds: 1000),
      maxDelay: Duration(seconds: 30),
      jitterFactor: 0.1,
      autoReconnect: true,
      reconnectDelay: Duration(seconds: 5),
    );
  }

  /// Conservative retry configuration for production
  factory RetryConfig.conservative() {
    return const RetryConfig(
      maxAttempts: 2,
      baseDelay: Duration(milliseconds: 2000),
      maxDelay: Duration(seconds: 60),
      jitterFactor: 0.2,
      autoReconnect: false,
      reconnectDelay: Duration(seconds: 10),
    );
  }

  /// Aggressive retry configuration for development
  factory RetryConfig.aggressive() {
    return const RetryConfig(
      maxAttempts: 5,
      baseDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 15),
      jitterFactor: 0.05,
      autoReconnect: true,
      reconnectDelay: Duration(seconds: 2),
    );
  }
}
