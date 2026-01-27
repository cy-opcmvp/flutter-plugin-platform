import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/interfaces/i_external_plugin.dart';
import '../core/models/plugin_models.dart';

/// Plugin SDK for external plugin developers
/// Provides communication helpers and event handling for external plugins
class PluginSDK {
  static PluginSDK? _instance;
  static PluginSDK get instance => _instance ??= PluginSDK._();

  PluginSDK._();

  String? _pluginId;
  String? _hostConnectionId;
  StreamController<IPCMessage>? _messageController;
  StreamController<HostEvent>? _eventController;
  final Map<String, MessageHandler> _messageHandlers = {};
  final Map<String, HostEventHandler> _eventHandlers = {};
  bool _isInitialized = false;
  bool _isConnected = false;

  /// Stream of incoming messages from host
  Stream<IPCMessage> get messageStream =>
      _messageController?.stream ?? const Stream.empty();

  /// Stream of host events
  Stream<HostEvent> get eventStream =>
      _eventController?.stream ?? const Stream.empty();

  /// Whether the SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Whether connected to host
  bool get isConnected => _isConnected;

  /// Current plugin ID
  String? get pluginId => _pluginId;

  /// Initialize the Plugin SDK
  /// Must be called before using any other SDK functionality
  static Future<void> initialize({
    required String pluginId,
    String? hostConnectionId,
    Map<String, dynamic>? config,
  }) async {
    final sdk = PluginSDK.instance;

    if (sdk._isInitialized) {
      throw StateError('PluginSDK is already initialized');
    }

    sdk._pluginId = pluginId;
    sdk._hostConnectionId = hostConnectionId ?? 'host';
    sdk._messageController = StreamController<IPCMessage>.broadcast();
    sdk._eventController = StreamController<HostEvent>.broadcast();

    // Set up message stream listener
    sdk.messageStream.listen(sdk._handleIncomingMessage);

    // Attempt to connect to host
    await sdk._connectToHost();

    // Register plugin capabilities with host
    await sdk._registerCapabilities(config ?? {});

    // Set up event handlers
    await sdk._setupEventHandlers();

    sdk._isInitialized = true;

    debugPrint('PluginSDK initialized for plugin: $pluginId');
  }

  /// Call a host API method
  /// Returns the result from the host API call
  static Future<T> callHostAPI<T>(
    String method,
    Map<String, dynamic> parameters,
  ) async {
    final sdk = PluginSDK.instance;

    if (!sdk._isInitialized) {
      throw StateError('PluginSDK not initialized. Call initialize() first.');
    }

    if (!sdk._isConnected) {
      throw StateError('Not connected to host. Cannot make API calls.');
    }

    final messageId = _generateMessageId();
    final message = IPCMessage(
      messageId: messageId,
      messageType: 'api_call',
      sourceId: sdk._pluginId!,
      targetId: sdk._hostConnectionId!,
      payload: {'method': method, 'parameters': parameters},
    );

    // Send message and wait for response
    final response = await sdk._sendMessageAndWaitForResponse(message);

    if (response.messageType == 'error') {
      final error = response.payload['error'] as Map<String, dynamic>;
      throw PluginAPIException(
        error['code'] as String,
        error['message'] as String,
        error['details'] as Map<String, dynamic>?,
      );
    }

    return response.payload['result'] as T;
  }

  /// Register a message handler for specific message types
  static void registerMessageHandler(
    String messageType,
    MessageHandler handler,
  ) {
    final sdk = PluginSDK.instance;
    sdk._messageHandlers[messageType] = handler;
  }

  /// Register an event handler for host events
  static void onHostEvent(String eventType, HostEventHandler handler) {
    final sdk = PluginSDK.instance;
    sdk._eventHandlers[eventType] = handler;
  }

  /// Send a message to the host
  static Future<void> sendMessage(IPCMessage message) async {
    final sdk = PluginSDK.instance;

    if (!sdk._isInitialized) {
      throw StateError('PluginSDK not initialized');
    }

    await sdk._sendMessage(message);
  }

  /// Send an event to the host
  static Future<void> sendEvent(
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    final message = IPCMessage(
      messageId: _generateMessageId(),
      messageType: 'event',
      sourceId: PluginSDK.instance._pluginId!,
      targetId: PluginSDK.instance._hostConnectionId!,
      payload: {'eventType': eventType, 'eventData': eventData},
    );

    await sendMessage(message);
  }

  /// Request a permission from the host
  static Future<bool> requestPermission(Permission permission) async {
    try {
      final result = await callHostAPI<bool>('requestPermission', {
        'permission': permission.name,
      });
      return result;
    } catch (e) {
      debugPrint('Failed to request permission $permission: $e');
      return false;
    }
  }

  /// Check if a permission is granted
  static Future<bool> hasPermission(Permission permission) async {
    try {
      final result = await callHostAPI<bool>('hasPermission', {
        'permission': permission.name,
      });
      return result;
    } catch (e) {
      debugPrint('Failed to check permission $permission: $e');
      return false;
    }
  }

  /// Get plugin configuration from host
  static Future<Map<String, dynamic>> getPluginConfig() async {
    try {
      final result = await callHostAPI<Map<String, dynamic>>(
        'getPluginConfig',
        {'pluginId': PluginSDK.instance._pluginId!},
      );
      return result;
    } catch (e) {
      debugPrint('Failed to get plugin config: $e');
      return {};
    }
  }

  /// Update plugin status
  static Future<void> updateStatus(
    PluginState status,
    Map<String, dynamic>? statusData,
  ) async {
    await callHostAPI<void>('updatePluginStatus', {
      'pluginId': PluginSDK.instance._pluginId!,
      'status': status.name,
      'statusData': statusData ?? {},
    });
  }

  /// Log a message to the host's logging system
  static Future<void> log(
    String level,
    String message,
    Map<String, dynamic>? context,
  ) async {
    await callHostAPI<void>('logMessage', {
      'pluginId': PluginSDK.instance._pluginId!,
      'level': level,
      'message': message,
      'context': context ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Convenience methods for logging
  static Future<void> logInfo(
    String message, [
    Map<String, dynamic>? context,
  ]) => log('info', message, context);

  static Future<void> logWarning(
    String message, [
    Map<String, dynamic>? context,
  ]) => log('warning', message, context);

  static Future<void> logError(
    String message, [
    Map<String, dynamic>? context,
  ]) => log('error', message, context);

  static Future<void> logDebug(
    String message, [
    Map<String, dynamic>? context,
  ]) => log('debug', message, context);

  /// Shutdown the SDK and cleanup resources
  static Future<void> shutdown() async {
    final sdk = PluginSDK.instance;

    if (!sdk._isInitialized) {
      return;
    }

    // Notify host of shutdown
    try {
      await sendEvent('plugin_shutdown', {
        'pluginId': sdk._pluginId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to notify host of shutdown: $e');
    }

    // Cleanup resources
    await sdk._messageController?.close();
    await sdk._eventController?.close();
    sdk._messageHandlers.clear();
    sdk._eventHandlers.clear();
    sdk._isInitialized = false;
    sdk._isConnected = false;
    sdk._pluginId = null;
    sdk._hostConnectionId = null;
    sdk._messageController = null;
    sdk._eventController = null;

    // Reset singleton instance for testing
    _instance = null;

    debugPrint('PluginSDK shutdown complete');
  }

  // Private methods

  Future<void> _connectToHost() async {
    // This would implement the actual IPC connection logic
    // For now, simulate a successful connection
    await Future.delayed(const Duration(milliseconds: 100));
    _isConnected = true;
    debugPrint('Connected to host: $_hostConnectionId');
  }

  Future<void> _registerCapabilities(Map<String, dynamic> config) async {
    final message = IPCMessage(
      messageId: _generateMessageId(),
      messageType: 'register_capabilities',
      sourceId: _pluginId!,
      targetId: _hostConnectionId!,
      payload: {
        'pluginId': _pluginId,
        'capabilities': config,
        'sdkVersion': '1.0.0',
      },
    );

    await _sendMessage(message);
  }

  Future<void> _setupEventHandlers() async {
    // Register default event handlers
    registerMessageHandler('host_event', (message) async {
      final eventType = message.payload['eventType'] as String;
      final eventData = message.payload['eventData'] as Map<String, dynamic>;

      final event = HostEvent(
        type: eventType,
        data: eventData,
        timestamp: DateTime.now(),
      );

      _eventController?.add(event);

      // Call registered event handler if exists
      final handler = _eventHandlers[eventType];
      if (handler != null) {
        await handler(event);
      }
    });
  }

  void _handleIncomingMessage(IPCMessage message) {
    final handler = _messageHandlers[message.messageType];
    if (handler != null) {
      handler(message).catchError((error) {
        debugPrint('Error handling message ${message.messageType}: $error');
      });
    }
  }

  Future<void> _sendMessage(IPCMessage message) async {
    // This would implement the actual message sending logic
    // For now, simulate sending
    debugPrint(
      'Sending message: ${message.messageType} to ${message.targetId}',
    );
  }

  Future<IPCMessage> _sendMessageAndWaitForResponse(IPCMessage message) async {
    final completer = Completer<IPCMessage>();
    final responseMessageId = '${message.messageId}_response';

    // Register temporary handler for response
    void responseHandler(IPCMessage response) {
      if (response.messageId == responseMessageId ||
          response.messageId == '${message.messageId}_error') {
        _messageHandlers.remove('response');
        _messageHandlers.remove('error');
        completer.complete(response);
      }
    }

    _messageHandlers['response'] = (msg) async => responseHandler(msg);
    _messageHandlers['error'] = (msg) async => responseHandler(msg);

    // Send the message
    await _sendMessage(message);

    // Wait for response with timeout
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _messageHandlers.remove('response');
        _messageHandlers.remove('error');
        throw TimeoutException('API call timeout', const Duration(seconds: 30));
      },
    );
  }

  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  static int _counter = 0;
}

/// Host event data structure
class HostEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const HostEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory HostEvent.fromJson(Map<String, dynamic> json) {
    return HostEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Exception thrown when plugin API calls fail
class PluginAPIException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const PluginAPIException(this.code, this.message, [this.details]);

  @override
  String toString() {
    return 'PluginAPIException($code): $message${details != null ? ' - $details' : ''}';
  }
}

/// Type definition for host event handlers
typedef HostEventHandler = Future<void> Function(HostEvent event);
