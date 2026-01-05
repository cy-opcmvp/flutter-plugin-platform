import '../models/plugin_models.dart';

/// Interface for managing plugin hot-reloading
abstract class IHotReloadManager {
  /// Initialize the hot-reload manager
  Future<void> initialize();
  
  /// Shutdown the hot-reload manager
  Future<void> shutdown();
  
  /// Check for plugin updates
  Future<List<PluginUpdateInfo>> checkForUpdates();
  
  /// Hot-reload a plugin with a new version
  Future<void> hotReloadPlugin(String pluginId, PluginDescriptor newDescriptor);
  
  /// Rollback a plugin to its previous version
  Future<void> rollbackPlugin(String pluginId);
  
  /// Get available rollback versions for a plugin
  List<String> getAvailableVersions(String pluginId);
  
  /// Enable/disable automatic update detection
  void setAutoUpdateDetection(bool enabled);
  
  /// Get current auto-update detection status
  bool get isAutoUpdateDetectionEnabled;
  
  /// Stream of hot-reload events
  Stream<HotReloadEvent> get eventStream;
  
  /// Dispose the hot-reload manager
  Future<void> dispose();
}

/// Information about a plugin update
class PluginUpdateInfo {
  final String pluginId;
  final String currentVersion;
  final String newVersion;
  final PluginDescriptor newDescriptor;
  final DateTime detectedAt;
  final bool isCompatible;
  final List<String> changeLog;

  const PluginUpdateInfo({
    required this.pluginId,
    required this.currentVersion,
    required this.newVersion,
    required this.newDescriptor,
    required this.detectedAt,
    required this.isCompatible,
    required this.changeLog,
  });
}

/// Hot-reload specific events
class HotReloadEvent {
  final HotReloadEventType type;
  final String pluginId;
  final String? version;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const HotReloadEvent({
    required this.type,
    required this.pluginId,
    this.version,
    required this.timestamp,
    this.data,
  });
}

/// Types of hot-reload events
enum HotReloadEventType {
  updateDetected,
  reloadStarted,
  reloadCompleted,
  reloadFailed,
  rollbackStarted,
  rollbackCompleted,
  rollbackFailed,
}

/// Version management for plugins
class PluginVersionInfo {
  final String version;
  final PluginDescriptor descriptor;
  final DateTime installedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const PluginVersionInfo({
    required this.version,
    required this.descriptor,
    required this.installedAt,
    required this.isActive,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'descriptor': descriptor.toJson(),
      'installedAt': installedAt.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory PluginVersionInfo.fromJson(Map<String, dynamic> json) {
    return PluginVersionInfo(
      version: json['version'] as String,
      descriptor: PluginDescriptor.fromJson(json['descriptor'] as Map<String, dynamic>),
      installedAt: DateTime.parse(json['installedAt'] as String),
      isActive: json['isActive'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}