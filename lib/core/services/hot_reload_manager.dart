import 'dart:async';

import '../interfaces/i_hot_reload_manager.dart';
import '../interfaces/i_plugin_manager.dart';
import '../interfaces/i_plugin.dart';
import '../models/plugin_models.dart';

/// Exception thrown when hot-reload operations fail
class HotReloadException implements Exception {
  final String message;
  final String? pluginId;
  final Exception? cause;

  const HotReloadException(this.message, {this.pluginId, this.cause});

  @override
  String toString() =>
      'HotReloadException: $message${pluginId != null ? ' (Plugin: $pluginId)' : ''}';
}

/// Implementation of hot-reload manager
class HotReloadManager implements IHotReloadManager {
  final IPluginManager _pluginManager;
  final Map<String, List<PluginVersionInfo>> _versionHistory = {};
  final Map<String, Timer> _updateCheckTimers = {};
  final StreamController<HotReloadEvent> _eventController =
      StreamController<HotReloadEvent>.broadcast();

  bool _isInitialized = false;
  bool _autoUpdateDetectionEnabled = false;
  Duration _updateCheckInterval = const Duration(minutes: 5);

  HotReloadManager(this._pluginManager);

  /// Get the plugin manager instance
  IPluginManager get pluginManager => _pluginManager;

  /// Check if the manager is initialized
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadVersionHistory();
    _isInitialized = true;
  }

  @override
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    // Stop all update check timers
    for (final timer in _updateCheckTimers.values) {
      timer.cancel();
    }
    _updateCheckTimers.clear();

    // Close event stream
    await _eventController.close();

    _isInitialized = false;
  }

  @override
  Stream<HotReloadEvent> get eventStream => _eventController.stream;

  @override
  Future<List<PluginUpdateInfo>> checkForUpdates() async {
    _ensureInitialized();

    final updates = <PluginUpdateInfo>[];
    final availablePlugins = await _pluginManager.getAvailablePlugins();

    for (final plugin in availablePlugins) {
      final updateInfo = await _checkPluginForUpdate(plugin);
      if (updateInfo != null) {
        updates.add(updateInfo);

        // Emit update detected event
        _eventController.add(
          HotReloadEvent(
            type: HotReloadEventType.updateDetected,
            pluginId: plugin.id,
            version: updateInfo.newVersion,
            timestamp: DateTime.now(),
            data: {
              'currentVersion': updateInfo.currentVersion,
              'newVersion': updateInfo.newVersion,
              'isCompatible': updateInfo.isCompatible,
            },
          ),
        );
      }
    }

    return updates;
  }

  @override
  Future<void> hotReloadPlugin(
    String pluginId,
    PluginDescriptor newDescriptor,
  ) async {
    _ensureInitialized();

    // Emit reload started event
    _eventController.add(
      HotReloadEvent(
        type: HotReloadEventType.reloadStarted,
        pluginId: pluginId,
        version: newDescriptor.version,
        timestamp: DateTime.now(),
      ),
    );

    try {
      // Get current plugin info
      final currentPluginInfo = await _pluginManager.getPluginInfo(pluginId);
      if (currentPluginInfo == null) {
        throw HotReloadException(
          'Plugin $pluginId not found',
          pluginId: pluginId,
        );
      }

      // Validate new descriptor
      if (!newDescriptor.isValid()) {
        throw HotReloadException(
          'Invalid new plugin descriptor',
          pluginId: pluginId,
        );
      }

      // Check version compatibility
      if (!_isVersionCompatible(
        currentPluginInfo.descriptor.version,
        newDescriptor.version,
      )) {
        throw HotReloadException(
          'Version ${newDescriptor.version} is not compatible with current version ${currentPluginInfo.descriptor.version}',
          pluginId: pluginId,
        );
      }

      // Store current version in history before updating
      await _storeVersionInHistory(pluginId, currentPluginInfo.descriptor);

      // Get current plugin state to preserve it
      final currentPlugin = _pluginManager.getPlugin(pluginId);
      final preservedState = currentPlugin != null
          ? await _extractPluginState(currentPlugin)
          : null;

      // Unload current plugin
      if (currentPlugin != null) {
        await _pluginManager.unloadPlugin(pluginId);
      }

      // Update plugin descriptor in registry
      await _pluginManager.unregisterPlugin(pluginId);
      await _pluginManager.registerPlugin(newDescriptor);

      // Load new plugin version
      final newPlugin = await _pluginManager.loadPlugin(newDescriptor);

      // Restore preserved state if available
      if (preservedState != null) {
        await _restorePluginState(newPlugin, preservedState);
      }

      // Update version history
      await _updateVersionHistory(pluginId, newDescriptor);

      // Emit reload completed event
      _eventController.add(
        HotReloadEvent(
          type: HotReloadEventType.reloadCompleted,
          pluginId: pluginId,
          version: newDescriptor.version,
          timestamp: DateTime.now(),
          data: {
            'previousVersion': currentPluginInfo.descriptor.version,
            'newVersion': newDescriptor.version,
            'statePreserved': preservedState != null,
          },
        ),
      );
    } catch (e) {
      // Emit reload failed event
      _eventController.add(
        HotReloadEvent(
          type: HotReloadEventType.reloadFailed,
          pluginId: pluginId,
          version: newDescriptor.version,
          timestamp: DateTime.now(),
          data: {'error': e.toString()},
        ),
      );

      rethrow;
    }
  }

  @override
  Future<void> rollbackPlugin(String pluginId) async {
    _ensureInitialized();

    // Emit rollback started event
    _eventController.add(
      HotReloadEvent(
        type: HotReloadEventType.rollbackStarted,
        pluginId: pluginId,
        timestamp: DateTime.now(),
      ),
    );

    try {
      // Get version history for the plugin
      final versions = _versionHistory[pluginId];
      if (versions == null || versions.isEmpty) {
        throw HotReloadException(
          'No previous versions available for rollback',
          pluginId: pluginId,
        );
      }

      // Find the most recent non-active version
      final previousVersion = versions
          .where((v) => !v.isActive)
          .reduce((a, b) => a.installedAt.isAfter(b.installedAt) ? a : b);

      // Get current plugin state to preserve it
      final currentPlugin = _pluginManager.getPlugin(pluginId);
      final preservedState = currentPlugin != null
          ? await _extractPluginState(currentPlugin)
          : null;

      // Unload current plugin
      if (currentPlugin != null) {
        await _pluginManager.unloadPlugin(pluginId);
      }

      // Update plugin descriptor in registry
      await _pluginManager.unregisterPlugin(pluginId);
      await _pluginManager.registerPlugin(previousVersion.descriptor);

      // Load previous plugin version
      final rolledBackPlugin = await _pluginManager.loadPlugin(
        previousVersion.descriptor,
      );

      // Restore preserved state if available
      if (preservedState != null) {
        await _restorePluginState(rolledBackPlugin, preservedState);
      }

      // Update version history - mark previous version as active
      await _markVersionAsActive(pluginId, previousVersion.version);

      // Emit rollback completed event
      _eventController.add(
        HotReloadEvent(
          type: HotReloadEventType.rollbackCompleted,
          pluginId: pluginId,
          version: previousVersion.version,
          timestamp: DateTime.now(),
          data: {
            'rolledBackToVersion': previousVersion.version,
            'statePreserved': preservedState != null,
          },
        ),
      );
    } catch (e) {
      // Emit rollback failed event
      _eventController.add(
        HotReloadEvent(
          type: HotReloadEventType.rollbackFailed,
          pluginId: pluginId,
          timestamp: DateTime.now(),
          data: {'error': e.toString()},
        ),
      );

      rethrow;
    }
  }

  @override
  List<String> getAvailableVersions(String pluginId) {
    _ensureInitialized();

    final versions = _versionHistory[pluginId];
    if (versions == null) return [];

    return versions.map((v) => v.version).toList()..sort();
  }

  @override
  void setAutoUpdateDetection(bool enabled) {
    _autoUpdateDetectionEnabled = enabled;

    if (enabled) {
      _startAutoUpdateDetection();
    } else {
      _stopAutoUpdateDetection();
    }
  }

  @override
  bool get isAutoUpdateDetectionEnabled => _autoUpdateDetectionEnabled;

  /// Set the interval for automatic update checks
  void setUpdateCheckInterval(Duration interval) {
    _updateCheckInterval = interval;

    if (_autoUpdateDetectionEnabled) {
      _stopAutoUpdateDetection();
      _startAutoUpdateDetection();
    }
  }

  /// Get the current update check interval
  Duration get updateCheckInterval => _updateCheckInterval;

  /// Dispose the hot-reload manager
  Future<void> dispose() async {
    await shutdown();
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HotReloadManager not initialized. Call initialize() first.',
      );
    }
  }

  Future<void> _loadVersionHistory() async {
    // In a real implementation, this would load from persistent storage
    // For now, we'll start with an empty history
    _versionHistory.clear();
  }

  Future<void> _saveVersionHistory() async {
    // In a real implementation, this would save to persistent storage
    // For now, this is a no-op
  }

  Future<PluginUpdateInfo?> _checkPluginForUpdate(
    PluginDescriptor currentPlugin,
  ) async {
    // In a real implementation, this would check external sources for updates
    // For now, we'll simulate by checking if there's a newer version in our mock system

    // Mock update detection - randomly decide if there's an update
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    if (random < 2) {
      // 20% chance of having an update
      final newVersion = _generateNextVersion(currentPlugin.version);
      final newDescriptor = PluginDescriptor(
        id: currentPlugin.id,
        name: currentPlugin.name,
        version: newVersion,
        type: currentPlugin.type,
        requiredPermissions: currentPlugin.requiredPermissions,
        metadata: {...currentPlugin.metadata, 'updated': true},
        entryPoint: currentPlugin.entryPoint,
      );

      return PluginUpdateInfo(
        pluginId: currentPlugin.id,
        currentVersion: currentPlugin.version,
        newVersion: newVersion,
        newDescriptor: newDescriptor,
        detectedAt: DateTime.now(),
        isCompatible: true,
        changeLog: ['Bug fixes', 'Performance improvements'],
      );
    }

    return null;
  }

  String _generateNextVersion(String currentVersion) {
    // Simple version increment for testing
    final parts = currentVersion.split('.');
    if (parts.length >= 3) {
      final patch = int.tryParse(parts[2]) ?? 0;
      return '${parts[0]}.${parts[1]}.${patch + 1}';
    }
    return '$currentVersion.1';
  }

  bool _isVersionCompatible(String currentVersion, String newVersion) {
    // Simple compatibility check - major version must be the same
    final currentParts = currentVersion.split('.');
    final newParts = newVersion.split('.');

    if (currentParts.isEmpty || newParts.isEmpty) return false;

    // Major version must be the same for compatibility
    return currentParts[0] == newParts[0];
  }

  Future<void> _storeVersionInHistory(
    String pluginId,
    PluginDescriptor descriptor,
  ) async {
    final versions = _versionHistory[pluginId] ?? [];

    // Mark all existing versions as inactive
    for (final version in versions) {
      final updatedVersion = PluginVersionInfo(
        version: version.version,
        descriptor: version.descriptor,
        installedAt: version.installedAt,
        isActive: false,
        metadata: version.metadata,
      );
      versions[versions.indexOf(version)] = updatedVersion;
    }

    // Add current version to history
    final versionInfo = PluginVersionInfo(
      version: descriptor.version,
      descriptor: descriptor,
      installedAt: DateTime.now(),
      isActive: false,
      metadata: {'storedForRollback': true},
    );

    versions.add(versionInfo);
    _versionHistory[pluginId] = versions;

    await _saveVersionHistory();
  }

  Future<void> _updateVersionHistory(
    String pluginId,
    PluginDescriptor newDescriptor,
  ) async {
    final versions = _versionHistory[pluginId] ?? [];

    // Mark all existing versions as inactive
    for (int i = 0; i < versions.length; i++) {
      final version = versions[i];
      versions[i] = PluginVersionInfo(
        version: version.version,
        descriptor: version.descriptor,
        installedAt: version.installedAt,
        isActive: false,
        metadata: version.metadata,
      );
    }

    // Add new version as active
    final newVersionInfo = PluginVersionInfo(
      version: newDescriptor.version,
      descriptor: newDescriptor,
      installedAt: DateTime.now(),
      isActive: true,
      metadata: {'hotReloaded': true},
    );

    versions.add(newVersionInfo);
    _versionHistory[pluginId] = versions;

    await _saveVersionHistory();
  }

  Future<void> _markVersionAsActive(String pluginId, String version) async {
    final versions = _versionHistory[pluginId];
    if (versions == null) return;

    for (int i = 0; i < versions.length; i++) {
      final versionInfo = versions[i];
      versions[i] = PluginVersionInfo(
        version: versionInfo.version,
        descriptor: versionInfo.descriptor,
        installedAt: versionInfo.installedAt,
        isActive: versionInfo.version == version,
        metadata: versionInfo.metadata,
      );
    }

    await _saveVersionHistory();
  }

  Future<Map<String, dynamic>?> _extractPluginState(IPlugin plugin) async {
    // In a real implementation, this would extract the plugin's current state
    // For now, we'll return a mock state
    return {
      'pluginId': plugin.id,
      'extractedAt': DateTime.now().toIso8601String(),
      'mockState': 'preserved',
    };
  }

  Future<void> _restorePluginState(
    IPlugin plugin,
    Map<String, dynamic> state,
  ) async {
    // In a real implementation, this would restore the plugin's state
    // For now, we'll just simulate the restoration
    await plugin.onStateChanged(PluginState.active);
  }

  void _startAutoUpdateDetection() {
    _stopAutoUpdateDetection(); // Stop any existing timers

    // Start update check timer for each plugin
    _pluginManager.getAvailablePlugins().then((plugins) {
      for (final plugin in plugins) {
        final timer = Timer.periodic(_updateCheckInterval, (timer) async {
          try {
            final updateInfo = await _checkPluginForUpdate(plugin);
            if (updateInfo != null) {
              // Emit update detected event
              _eventController.add(
                HotReloadEvent(
                  type: HotReloadEventType.updateDetected,
                  pluginId: plugin.id,
                  version: updateInfo.newVersion,
                  timestamp: DateTime.now(),
                  data: {
                    'currentVersion': updateInfo.currentVersion,
                    'newVersion': updateInfo.newVersion,
                    'isCompatible': updateInfo.isCompatible,
                    'autoDetected': true,
                  },
                ),
              );
            }
          } catch (e) {
            // Log error but continue checking
          }
        });

        _updateCheckTimers[plugin.id] = timer;
      }
    });
  }

  void _stopAutoUpdateDetection() {
    for (final timer in _updateCheckTimers.values) {
      timer.cancel();
    }
    _updateCheckTimers.clear();
  }
}
