import '../models/plugin_models.dart';
import '../models/external_plugin_models.dart';
import 'i_plugin.dart';

/// Interface for external plugins that run outside the main application process
abstract class IExternalPlugin extends IPlugin {
  /// Runtime type of the external plugin
  PluginRuntimeType get pluginRuntimeType;
  
  /// Plugin package information
  PluginPackage get package;
  
  /// Plugin manifest with external plugin specific metadata
  PluginManifest get manifest;
  
  /// Launch the external plugin process
  Future<void> launch();
  
  /// Terminate the external plugin process
  Future<void> terminate();
  
  /// Check if the external plugin process is running
  bool get isRunning;
  
  /// Get the process ID of the external plugin (if applicable)
  int? get processId;
  
  /// Send a message to the external plugin via IPC
  Future<void> sendMessage(IPCMessage message);
  
  /// Register a message handler for IPC communication
  void registerMessageHandler(String messageType, MessageHandler handler);
  
  /// Get the IPC connection status
  bool get isConnected;
  
  /// Establish IPC connection with the external plugin
  Future<void> establishConnection();
  
  /// Close IPC connection with the external plugin
  Future<void> closeConnection();
  
  /// Get security level for this external plugin
  SecurityLevel get securityLevel;
  
  /// Get resource limits for this external plugin
  ResourceLimits get resourceLimits;
  
  /// Get required permissions for this external plugin
  List<Permission> get requiredPermissions;
  
  /// Validate plugin requirements against system capabilities
  Future<bool> validateRequirements();
  
  /// Get platform-specific configuration
  Map<String, dynamic> getPlatformConfig(String platform);
}

/// Message handler function type for IPC communication
typedef MessageHandler = Future<void> Function(IPCMessage message);

/// IPC Message for communication between host and external plugins
class IPCMessage {
  final String messageId;
  final String messageType;
  final String sourceId;
  final String targetId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final MessagePriority priority;

  IPCMessage({
    required this.messageId,
    required this.messageType,
    required this.sourceId,
    required this.targetId,
    required this.payload,
    DateTime? timestamp,
    this.priority = MessagePriority.normal,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a response message to this message
  IPCMessage createResponse({
    required Map<String, dynamic> responsePayload,
    MessagePriority? responsePriority,
  }) {
    return IPCMessage(
      messageId: '${messageId}_response',
      messageType: 'response',
      sourceId: targetId,
      targetId: sourceId,
      payload: responsePayload,
      priority: responsePriority ?? priority,
    );
  }

  /// Create an error response message
  IPCMessage createErrorResponse({
    required String errorCode,
    required String errorMessage,
    Map<String, dynamic>? errorDetails,
  }) {
    return IPCMessage(
      messageId: '${messageId}_error',
      messageType: 'error',
      sourceId: targetId,
      targetId: sourceId,
      payload: {
        'error': {
          'code': errorCode,
          'message': errorMessage,
          'details': errorDetails ?? {},
        }
      },
      priority: MessagePriority.high,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'messageType': messageType,
      'sourceId': sourceId,
      'targetId': targetId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.name,
    };
  }

  /// Create from JSON
  factory IPCMessage.fromJson(Map<String, dynamic> json) {
    return IPCMessage(
      messageId: json['messageId'] as String,
      messageType: json['messageType'] as String,
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => MessagePriority.normal,
      ),
    );
  }
}

/// Message priority levels for IPC communication
enum MessagePriority {
  low,
  normal,
  high,
  critical
}