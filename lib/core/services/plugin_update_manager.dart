import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/external_plugin_models.dart';
import 'external_plugin_manager.dart';
import 'plugin_registry_service.dart';

/// Manager for automatic plugin updates and version management
class PluginUpdateManager {
  final ExternalPluginManager _pluginManager;
  final PluginRegistryService _registryService;

  Timer? _updateCheckTimer;
  bool _isInitialized = false;
  bool _autoUpdateEnabled = true;
  Duration _updateCheckInterval = const Duration(hours: 24);

  final Map<String, PluginUpdateInfo> _availableUpdates = {};
  final Map<String, UpdateProgress> _updateProgress = {};
  final StreamController<PluginUpdateEvent> _updateEventController =
      StreamController.broadcast();

  PluginUpdateManager({
    required ExternalPluginManager pluginManager,
    required PluginRegistryService registryService,
  }) : _pluginManager = pluginManager,
       _registryService = registryService;

  /// Stream of update events
  Stream<PluginUpdateEvent> get updateEvents => _updateEventController.stream;

  /// Whether automatic updates are enabled
  bool get autoUpdateEnabled => _autoUpdateEnabled;

  /// Current update check interval
  Duration get updateCheckInterval => _updateCheckInterval;

  /// Get all available updates
  Map<String, PluginUpdateInfo> get availableUpdates =>
      Map.unmodifiable(_availableUpdates);

  /// Get current update progress
  Map<String, UpdateProgress> get updateProgress =>
      Map.unmodifiable(_updateProgress);

  /// Initialize the update manager
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Initialize dependencies

    // Start periodic update checks if auto-update is enabled
    if (_autoUpdateEnabled) {
      _startPeriodicUpdateChecks();
    }

    _isInitialized = true;
  }

  /// Shutdown the update manager
  Future<void> shutdown() async {
    if (!_isInitialized) {
      return;
    }

    _stopPeriodicUpdateChecks();
    await _updateEventController.close();

    _availableUpdates.clear();
    _updateProgress.clear();
    _isInitialized = false;
  }

  /// Enable or disable automatic updates
  void setAutoUpdateEnabled(bool enabled) {
    _autoUpdateEnabled = enabled;

    if (_isInitialized) {
      if (enabled) {
        _startPeriodicUpdateChecks();
      } else {
        _stopPeriodicUpdateChecks();
      }
    }
  }

  /// Set the update check interval
  void setUpdateCheckInterval(Duration interval) {
    _updateCheckInterval = interval;

    if (_isInitialized && _autoUpdateEnabled) {
      _stopPeriodicUpdateChecks();
      _startPeriodicUpdateChecks();
    }
  }

  /// Check for updates for all installed plugins
  Future<List<PluginUpdateInfo>> checkForUpdates({
    List<String>? pluginIds,
    bool forceCheck = false,
  }) async {
    _ensureInitialized();

    final installedPlugins = pluginIds != null
        ? pluginIds
              .map(
                (id) => _pluginManager.getInstalledPlugins().firstWhere(
                  (pkg) => pkg.id == id,
                  orElse: () => throw ArgumentError('Plugin $id not found'),
                ),
              )
              .toList()
        : _pluginManager.getInstalledPlugins();

    final updates = <PluginUpdateInfo>[];

    for (final plugin in installedPlugins) {
      try {
        final updateInfo = await _checkPackageForUpdate(plugin, forceCheck);
        if (updateInfo != null) {
          _availableUpdates[plugin.id] = updateInfo;
          updates.add(updateInfo);

          _updateEventController.add(
            PluginUpdateEvent(
              type: UpdateEventType.updateAvailable,
              pluginId: plugin.id,
              updateInfo: updateInfo,
            ),
          );
        }
      } catch (e) {
        _updateEventController.add(
          PluginUpdateEvent(
            type: UpdateEventType.checkFailed,
            pluginId: plugin.id,
            error: e.toString(),
          ),
        );
      }
    }

    return updates;
  }

  /// Check for update for a specific plugin
  Future<PluginUpdateInfo?> checkPluginForUpdate(
    String pluginId, {
    bool forceCheck = false,
  }) async {
    _ensureInitialized();

    final plugin = _pluginManager.getInstalledPlugins().firstWhere(
      (pkg) => pkg.id == pluginId,
      orElse: () => throw ArgumentError('Plugin $pluginId not found'),
    );

    return await _checkPackageForUpdate(plugin, forceCheck);
  }

  /// Update a specific plugin to the latest version
  Future<void> updatePlugin(String pluginId, {String? targetVersion}) async {
    _ensureInitialized();

    final plugin = _pluginManager.getInstalledPlugins().firstWhere(
      (pkg) => pkg.id == pluginId,
      orElse: () => throw ArgumentError('Plugin $pluginId not found'),
    );

    final updateInfo = _availableUpdates[pluginId];
    if (updateInfo == null && targetVersion == null) {
      throw StateError('No update available for plugin $pluginId');
    }

    final newVersion = targetVersion ?? updateInfo!.latestVersion;

    try {
      // Start update process
      _updateProgress[pluginId] = UpdateProgress(
        pluginId: pluginId,
        currentVersion: plugin.version,
        targetVersion: newVersion,
        status: UpdateStatus.downloading,
        progress: 0.0,
        startTime: DateTime.now(),
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.updateStarted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );

      // Download new version
      await _downloadPluginUpdate(pluginId, newVersion);

      // Install new version
      await _installPluginUpdate(pluginId, newVersion);

      // Update completed successfully
      _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
        status: UpdateStatus.completed,
        progress: 1.0,
        endTime: DateTime.now(),
      );

      _availableUpdates.remove(pluginId);

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.updateCompleted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );
    } catch (e) {
      // Update failed
      _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
        status: UpdateStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.updateFailed,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  /// Update all plugins that have available updates
  Future<void> updateAllPlugins({bool confirmEach = false}) async {
    _ensureInitialized();

    final pluginsToUpdate = _availableUpdates.keys.toList();

    for (final pluginId in pluginsToUpdate) {
      try {
        if (confirmEach) {
          // In a real implementation, this would show a confirmation dialog
          // For now, we'll assume user confirms
        }

        await updatePlugin(pluginId);
      } catch (e) {
        // Continue with other plugins even if one fails
        debugPrint('Failed to update plugin $pluginId: $e');
      }
    }
  }

  /// Rollback a plugin to its previous version
  Future<void> rollbackPlugin(String pluginId) async {
    _ensureInitialized();

    final plugin = _pluginManager.getInstalledPlugins().firstWhere(
      (pkg) => pkg.id == pluginId,
      orElse: () => throw ArgumentError('Plugin $pluginId not found'),
    );

    // Get previous version from update history
    final previousVersion = await _getPreviousVersion(pluginId);
    if (previousVersion == null) {
      throw StateError('No previous version available for rollback');
    }

    try {
      // Start rollback process
      _updateProgress[pluginId] = UpdateProgress(
        pluginId: pluginId,
        currentVersion: plugin.version,
        targetVersion: previousVersion,
        status: UpdateStatus.rollingBack,
        progress: 0.0,
        startTime: DateTime.now(),
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.rollbackStarted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );

      // Download previous version
      await _downloadPluginUpdate(pluginId, previousVersion);

      // Install previous version
      await _installPluginUpdate(pluginId, previousVersion);

      // Rollback completed successfully
      _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
        status: UpdateStatus.completed,
        progress: 1.0,
        endTime: DateTime.now(),
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.rollbackCompleted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );
    } catch (e) {
      // Rollback failed
      _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
        status: UpdateStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.rollbackFailed,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  /// Get update history for a plugin
  Future<List<PluginUpdateRecord>> getUpdateHistory(String pluginId) async {
    _ensureInitialized();

    // In a real implementation, this would read from persistent storage
    // For now, return mock data
    return [
      PluginUpdateRecord(
        pluginId: pluginId,
        fromVersion: '1.0.0',
        toVersion: '1.1.0',
        updateTime: DateTime.now().subtract(const Duration(days: 7)),
        updateType: UpdateType.minor,
        success: true,
      ),
      PluginUpdateRecord(
        pluginId: pluginId,
        fromVersion: '1.1.0',
        toVersion: '1.2.0',
        updateTime: DateTime.now().subtract(const Duration(days: 3)),
        updateType: UpdateType.minor,
        success: true,
      ),
    ];
  }

  /// Get available versions for a plugin
  Future<List<String>> getAvailableVersions(String pluginId) async {
    _ensureInitialized();

    // In a real implementation, this would query distribution channels
    // For now, return mock versions
    return ['1.0.0', '1.1.0', '1.2.0', '2.0.0'];
  }

  /// Schedule an update for later
  Future<void> scheduleUpdate(
    String pluginId,
    DateTime scheduledTime, {
    String? targetVersion,
  }) async {
    _ensureInitialized();

    // In a real implementation, this would persist the schedule
    // For now, we'll use a simple timer
    final delay = scheduledTime.difference(DateTime.now());

    if (delay.isNegative) {
      throw ArgumentError('Scheduled time must be in the future');
    }

    Timer(delay, () async {
      try {
        await updatePlugin(pluginId, targetVersion: targetVersion);
      } catch (e) {
        _updateEventController.add(
          PluginUpdateEvent(
            type: UpdateEventType.scheduledUpdateFailed,
            pluginId: pluginId,
            error: e.toString(),
          ),
        );
      }
    });

    _updateEventController.add(
      PluginUpdateEvent(
        type: UpdateEventType.updateScheduled,
        pluginId: pluginId,
      ),
    );
  }

  /// Cancel a scheduled update
  Future<void> cancelScheduledUpdate(String pluginId) async {
    _ensureInitialized();

    // In a real implementation, this would cancel the persisted schedule
    // For now, we'll just emit an event
    _updateEventController.add(
      PluginUpdateEvent(
        type: UpdateEventType.scheduledUpdateCancelled,
        pluginId: pluginId,
      ),
    );
  }

  /// Get update settings for a plugin
  PluginUpdateSettings getPluginUpdateSettings(String pluginId) {
    return PluginUpdateSettings(
      pluginId: pluginId,
      autoUpdateEnabled: true,
      updateChannel: UpdateChannel.stable,
      allowPrerelease: false,
      updateNotifications: true,
    );
  }

  /// Update settings for a plugin
  void setPluginUpdateSettings(String pluginId, PluginUpdateSettings settings) {
    // In a real implementation, this would persist the settings
    _updateEventController.add(
      PluginUpdateEvent(
        type: UpdateEventType.settingsChanged,
        pluginId: pluginId,
      ),
    );
  }

  /// Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PluginUpdateManager not initialized. Call initialize() first.',
      );
    }
  }

  void _startPeriodicUpdateChecks() {
    _stopPeriodicUpdateChecks();

    _updateCheckTimer = Timer.periodic(_updateCheckInterval, (timer) async {
      try {
        await checkForUpdates();
      } catch (e) {
        debugPrint('Periodic update check failed: $e');
      }
    });
  }

  void _stopPeriodicUpdateChecks() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = null;
  }

  Future<PluginUpdateInfo?> _checkPackageForUpdate(
    PluginPackage plugin,
    bool forceCheck,
  ) async {
    try {
      // Get plugin info from registry
      final registryInfo = _registryService.getPluginInfo(plugin.id);
      if (registryInfo == null) {
        return null;
      }

      // Compare versions
      if (_isNewerVersion(registryInfo.version, plugin.version)) {
        return PluginUpdateInfo(
          pluginId: plugin.id,
          currentVersion: plugin.version,
          latestVersion: registryInfo.version,
          updateSize: 0, // Would be calculated from package info
          releaseNotes:
              'Bug fixes and improvements', // Would come from registry
          updateType: _determineUpdateType(
            plugin.version,
            registryInfo.version,
          ),
          isSecurityUpdate:
              registryInfo.securityStatus.securityWarnings.isEmpty,
          releaseDate: registryInfo.lastUpdated,
          downloadUrl: registryInfo.downloadUrl,
        );
      }

      return null;
    } catch (e) {
      throw Exception(
        'Failed to check for updates for plugin ${plugin.id}: $e',
      );
    }
  }

  Future<void> _downloadPluginUpdate(String pluginId, String version) async {
    // Update progress
    _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
      status: UpdateStatus.downloading,
      progress: 0.1,
    );

    _updateEventController.add(
      PluginUpdateEvent(
        type: UpdateEventType.downloadStarted,
        pluginId: pluginId,
        progress: _updateProgress[pluginId],
      ),
    );

    try {
      // Download plugin package
      // Simulate plugin download
      // In a real implementation, this would use a distribution manager

      // Simulate download progress
      for (double progress = 0.2; progress <= 0.8; progress += 0.1) {
        _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
          progress: progress,
        );
        _updateEventController.add(
          PluginUpdateEvent(
            type: UpdateEventType.downloadProgress,
            pluginId: pluginId,
            progress: _updateProgress[pluginId],
          ),
        );

        // Simulate download time
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
        status: UpdateStatus.installing,
        progress: 0.8,
      );

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.downloadCompleted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );
    } catch (e) {
      throw Exception('Failed to download plugin update: $e');
    }
  }

  Future<void> _installPluginUpdate(String pluginId, String version) async {
    _updateEventController.add(
      PluginUpdateEvent(
        type: UpdateEventType.installStarted,
        pluginId: pluginId,
        progress: _updateProgress[pluginId],
      ),
    );

    try {
      // Stop current plugin if running
      if (_pluginManager.isPluginActive(pluginId)) {
        await _pluginManager.terminateExternalPlugin(pluginId);
      }

      // Simulate installation progress
      for (double progress = 0.8; progress <= 0.95; progress += 0.05) {
        _updateProgress[pluginId] = _updateProgress[pluginId]!.copyWith(
          progress: progress,
        );
        _updateEventController.add(
          PluginUpdateEvent(
            type: UpdateEventType.installProgress,
            pluginId: pluginId,
            progress: _updateProgress[pluginId],
          ),
        );

        // Simulate installation time
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Update plugin version in manager
      // In a real implementation, this would update the plugin files and metadata

      _updateEventController.add(
        PluginUpdateEvent(
          type: UpdateEventType.installCompleted,
          pluginId: pluginId,
          progress: _updateProgress[pluginId],
        ),
      );
    } catch (e) {
      throw Exception('Failed to install plugin update: $e');
    }
  }

  Future<String?> _getPreviousVersion(String pluginId) async {
    final history = await getUpdateHistory(pluginId);
    if (history.isNotEmpty) {
      return history.last.fromVersion;
    }
    return null;
  }

  bool _isNewerVersion(String version1, String version2) {
    return _compareVersions(version1, version2) > 0;
  }

  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part != v2Part) {
        return v1Part.compareTo(v2Part);
      }
    }

    return 0;
  }

  UpdateType _determineUpdateType(String fromVersion, String toVersion) {
    final fromParts = fromVersion.split('.').map(int.parse).toList();
    final toParts = toVersion.split('.').map(int.parse).toList();

    if (fromParts.isNotEmpty &&
        toParts.isNotEmpty &&
        fromParts[0] != toParts[0]) {
      return UpdateType.major;
    } else if (fromParts.length > 1 &&
        toParts.length > 1 &&
        fromParts[1] != toParts[1]) {
      return UpdateType.minor;
    } else {
      return UpdateType.patch;
    }
  }
}

/// Information about an available plugin update
class PluginUpdateInfo {
  final String pluginId;
  final String currentVersion;
  final String latestVersion;
  final int updateSize;
  final String releaseNotes;
  final UpdateType updateType;
  final bool isSecurityUpdate;
  final DateTime releaseDate;
  final String downloadUrl;

  const PluginUpdateInfo({
    required this.pluginId,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateSize,
    required this.releaseNotes,
    required this.updateType,
    required this.isSecurityUpdate,
    required this.releaseDate,
    required this.downloadUrl,
  });

  factory PluginUpdateInfo.fromJson(Map<String, dynamic> json) {
    return PluginUpdateInfo(
      pluginId: json['pluginId'] as String,
      currentVersion: json['currentVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      updateSize: json['updateSize'] as int,
      releaseNotes: json['releaseNotes'] as String,
      updateType: UpdateType.values.firstWhere(
        (type) => type.name == json['updateType'],
        orElse: () => UpdateType.patch,
      ),
      isSecurityUpdate: json['isSecurityUpdate'] as bool,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      downloadUrl: json['downloadUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'updateSize': updateSize,
      'releaseNotes': releaseNotes,
      'updateType': updateType.name,
      'isSecurityUpdate': isSecurityUpdate,
      'releaseDate': releaseDate.toIso8601String(),
      'downloadUrl': downloadUrl,
    };
  }
}

/// Progress information for an ongoing update
class UpdateProgress {
  final String pluginId;
  final String currentVersion;
  final String targetVersion;
  final UpdateStatus status;
  final double progress;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;

  const UpdateProgress({
    required this.pluginId,
    required this.currentVersion,
    required this.targetVersion,
    required this.status,
    required this.progress,
    required this.startTime,
    this.endTime,
    this.error,
  });

  UpdateProgress copyWith({
    String? pluginId,
    String? currentVersion,
    String? targetVersion,
    UpdateStatus? status,
    double? progress,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
  }) {
    return UpdateProgress(
      pluginId: pluginId ?? this.pluginId,
      currentVersion: currentVersion ?? this.currentVersion,
      targetVersion: targetVersion ?? this.targetVersion,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  factory UpdateProgress.fromJson(Map<String, dynamic> json) {
    return UpdateProgress(
      pluginId: json['pluginId'] as String,
      currentVersion: json['currentVersion'] as String,
      targetVersion: json['targetVersion'] as String,
      status: UpdateStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => UpdateStatus.pending,
      ),
      progress: (json['progress'] as num).toDouble(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'currentVersion': currentVersion,
      'targetVersion': targetVersion,
      'status': status.name,
      'progress': progress,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'error': error,
    };
  }
}

/// Update event for notifications
class PluginUpdateEvent {
  final UpdateEventType type;
  final String pluginId;
  final PluginUpdateInfo? updateInfo;
  final UpdateProgress? progress;
  final String? error;
  final DateTime timestamp;

  PluginUpdateEvent({
    required this.type,
    required this.pluginId,
    this.updateInfo,
    this.progress,
    this.error,
  }) : timestamp = DateTime.now();

  factory PluginUpdateEvent.fromJson(Map<String, dynamic> json) {
    return PluginUpdateEvent(
      type: UpdateEventType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => UpdateEventType.updateAvailable,
      ),
      pluginId: json['pluginId'] as String,
      updateInfo: json['updateInfo'] != null
          ? PluginUpdateInfo.fromJson(
              json['updateInfo'] as Map<String, dynamic>,
            )
          : null,
      progress: json['progress'] != null
          ? UpdateProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'pluginId': pluginId,
      'updateInfo': updateInfo?.toJson(),
      'progress': progress?.toJson(),
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Record of a plugin update
class PluginUpdateRecord {
  final String pluginId;
  final String fromVersion;
  final String toVersion;
  final DateTime updateTime;
  final UpdateType updateType;
  final bool success;
  final String? error;

  const PluginUpdateRecord({
    required this.pluginId,
    required this.fromVersion,
    required this.toVersion,
    required this.updateTime,
    required this.updateType,
    required this.success,
    this.error,
  });

  factory PluginUpdateRecord.fromJson(Map<String, dynamic> json) {
    return PluginUpdateRecord(
      pluginId: json['pluginId'] as String,
      fromVersion: json['fromVersion'] as String,
      toVersion: json['toVersion'] as String,
      updateTime: DateTime.parse(json['updateTime'] as String),
      updateType: UpdateType.values.firstWhere(
        (type) => type.name == json['updateType'],
        orElse: () => UpdateType.patch,
      ),
      success: json['success'] as bool,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'updateTime': updateTime.toIso8601String(),
      'updateType': updateType.name,
      'success': success,
      'error': error,
    };
  }
}

/// Plugin update settings
class PluginUpdateSettings {
  final String pluginId;
  final bool autoUpdateEnabled;
  final UpdateChannel updateChannel;
  final bool allowPrerelease;
  final bool updateNotifications;

  const PluginUpdateSettings({
    required this.pluginId,
    required this.autoUpdateEnabled,
    required this.updateChannel,
    required this.allowPrerelease,
    required this.updateNotifications,
  });

  factory PluginUpdateSettings.fromJson(Map<String, dynamic> json) {
    return PluginUpdateSettings(
      pluginId: json['pluginId'] as String,
      autoUpdateEnabled: json['autoUpdateEnabled'] as bool,
      updateChannel: UpdateChannel.values.firstWhere(
        (channel) => channel.name == json['updateChannel'],
        orElse: () => UpdateChannel.stable,
      ),
      allowPrerelease: json['allowPrerelease'] as bool,
      updateNotifications: json['updateNotifications'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'autoUpdateEnabled': autoUpdateEnabled,
      'updateChannel': updateChannel.name,
      'allowPrerelease': allowPrerelease,
      'updateNotifications': updateNotifications,
    };
  }
}

/// Types of updates
enum UpdateType { major, minor, patch, hotfix }

/// Update status
enum UpdateStatus {
  pending,
  downloading,
  installing,
  completed,
  failed,
  rollingBack,
  cancelled,
}

/// Update event types
enum UpdateEventType {
  updateAvailable,
  updateStarted,
  downloadStarted,
  downloadProgress,
  downloadCompleted,
  installStarted,
  installProgress,
  installCompleted,
  updateCompleted,
  updateFailed,
  rollbackStarted,
  rollbackCompleted,
  rollbackFailed,
  updateScheduled,
  scheduledUpdateFailed,
  scheduledUpdateCancelled,
  checkFailed,
  settingsChanged,
}

/// Update channels
enum UpdateChannel { stable, beta, alpha, nightly }
