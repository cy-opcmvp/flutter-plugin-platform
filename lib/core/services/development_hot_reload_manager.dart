import 'dart:async';
import 'dart:io';

import 'hot_reload_manager.dart';

/// Exception thrown when development hot-reload operations fail
class DevelopmentHotReloadException implements Exception {
  final String message;
  final String? pluginId;
  final Exception? cause;

  const DevelopmentHotReloadException(this.message, {this.pluginId, this.cause});

  @override
  String toString() => 'DevelopmentHotReloadException: $message${pluginId != null ? ' (Plugin: $pluginId)' : ''}';
}

/// File watcher for monitoring plugin changes
class FileWatcher {
  final String pluginId;
  final List<String> watchedPaths;
  final StreamController<FileChangeEvent> _changeController = StreamController<FileChangeEvent>.broadcast();
  
  bool _isWatching = false;
  final Map<String, DateTime> _lastModified = {};
  Timer? _watchTimer;

  FileWatcher({
    required this.pluginId,
    required this.watchedPaths,
  });

  /// Stream of file change events
  Stream<FileChangeEvent> get changeStream => _changeController.stream;

  /// Start watching files
  Future<void> startWatching() async {
    if (_isWatching) return;
    
    _isWatching = true;
    
    // Initialize last modified times
    for (final path in watchedPaths) {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        _lastModified[path] = stat.modified;
      }
    }
    
    // Start periodic checking
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkForChanges());
  }

  /// Stop watching files
  Future<void> stopWatching() async {
    if (!_isWatching) return;
    
    _isWatching = false;
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  /// Check for file changes
  Future<void> _checkForChanges() async {
    for (final path in watchedPaths) {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        final lastModified = _lastModified[path];
        
        if (lastModified == null || stat.modified.isAfter(lastModified)) {
          _lastModified[path] = stat.modified;
          
          final event = FileChangeEvent(
            pluginId: pluginId,
            filePath: path,
            changeType: FileChangeType.modified,
            timestamp: stat.modified,
          );
          
          _changeController.add(event);
        }
      } else if (_lastModified.containsKey(path)) {
        // File was deleted
        _lastModified.remove(path);
        
        final event = FileChangeEvent(
          pluginId: pluginId,
          filePath: path,
          changeType: FileChangeType.deleted,
          timestamp: DateTime.now(),
        );
        
        _changeController.add(event);
      }
    }
  }

  /// Dispose the file watcher
  Future<void> dispose() async {
    await stopWatching();
    await _changeController.close();
  }
}

/// File change event
class FileChangeEvent {
  final String pluginId;
  final String filePath;
  final FileChangeType changeType;
  final DateTime timestamp;

  const FileChangeEvent({
    required this.pluginId,
    required this.filePath,
    required this.changeType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'filePath': filePath,
      'changeType': changeType.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Types of file changes
enum FileChangeType {
  created,
  modified,
  deleted,
  renamed
}

/// Live update configuration
class LiveUpdateConfig {
  final bool enableAutoReload;
  final bool enableLivePreview;
  final bool enableStatePreservation;
  final Duration debounceDelay;
  final List<String> excludePatterns;
  final Map<String, dynamic> customSettings;

  const LiveUpdateConfig({
    this.enableAutoReload = true,
    this.enableLivePreview = false,
    this.enableStatePreservation = true,
    this.debounceDelay = const Duration(milliseconds: 500),
    this.excludePatterns = const [],
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'enableAutoReload': enableAutoReload,
      'enableLivePreview': enableLivePreview,
      'enableStatePreservation': enableStatePreservation,
      'debounceDelay': debounceDelay.inMilliseconds,
      'excludePatterns': excludePatterns,
      'customSettings': customSettings,
    };
  }
}

/// Development hot-reload manager with enhanced features for development
class DevelopmentHotReloadManager extends HotReloadManager {
  final StreamController<FileChangeEvent> _fileChangeController = StreamController<FileChangeEvent>.broadcast();
  final StreamController<LiveUpdateEvent> _liveUpdateController = StreamController<LiveUpdateEvent>.broadcast();
  
  final Map<String, FileWatcher> _fileWatchers = {};
  final Map<String, LiveUpdateConfig> _liveUpdateConfigs = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, List<FileChangeEvent>> _pendingChanges = {};
  
  bool _isDevelopmentModeEnabled = false;

  DevelopmentHotReloadManager(super.pluginManager);

  /// Stream of file change events
  Stream<FileChangeEvent> get fileChangeStream => _fileChangeController.stream;

  /// Stream of live update events
  Stream<LiveUpdateEvent> get liveUpdateStream => _liveUpdateController.stream;

  /// Check if development mode is enabled
  bool get isDevelopmentModeEnabled => _isDevelopmentModeEnabled;

  @override
  Future<void> initialize() async {
    await super.initialize();
    _isDevelopmentModeEnabled = true;
  }

  @override
  Future<void> shutdown() async {
    await _stopAllFileWatchers();
    await _fileChangeController.close();
    await _liveUpdateController.close();
    
    _isDevelopmentModeEnabled = false;
    await super.shutdown();
  }

  /// Enable file watching for a plugin
  Future<void> enableFileWatching(String pluginId, List<String> watchedPaths) async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) {
      throw DevelopmentHotReloadException('Development mode is not enabled', pluginId: pluginId);
    }
    
    // Stop existing watcher if any
    await _stopFileWatcher(pluginId);
    
    // Create new file watcher
    final watcher = FileWatcher(
      pluginId: pluginId,
      watchedPaths: watchedPaths,
    );
    
    // Listen to file changes
    watcher.changeStream.listen((event) => _handleFileChange(event));
    
    // Start watching
    await watcher.startWatching();
    _fileWatchers[pluginId] = watcher;
    
    // Emit file watching enabled event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.fileWatchingEnabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'watchedPaths': watchedPaths,
      },
    ));
  }

  /// Disable file watching for a plugin
  Future<void> disableFileWatching(String pluginId) async {
    _ensureInitialized();
    
    await _stopFileWatcher(pluginId);
    
    // Emit file watching disabled event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.fileWatchingDisabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  /// Configure live updates for a plugin
  Future<void> configureLiveUpdates(String pluginId, LiveUpdateConfig config) async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) {
      throw DevelopmentHotReloadException('Development mode is not enabled', pluginId: pluginId);
    }
    
    _liveUpdateConfigs[pluginId] = config;
    
    // Emit live update configured event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.liveUpdateConfigured,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: config.toJson(),
    ));
  }

  /// Trigger manual hot-reload for a plugin
  Future<void> triggerHotReload(String pluginId) async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) {
      throw DevelopmentHotReloadException('Development mode is not enabled', pluginId: pluginId);
    }
    
    // Emit hot-reload triggered event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.hotReloadTriggered,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {'trigger': 'manual'},
    ));
    
    try {
      // Get current plugin info
      final pluginInfo = await pluginManager.getPluginInfo(pluginId);
      if (pluginInfo == null) {
        throw DevelopmentHotReloadException('Plugin not found: $pluginId', pluginId: pluginId);
      }
      
      // Perform hot-reload using base implementation
      await hotReloadPlugin(pluginId, pluginInfo.descriptor);
      
      // Emit hot-reload completed event
      _liveUpdateController.add(LiveUpdateEvent(
        type: LiveUpdateEventType.hotReloadCompleted,
        pluginId: pluginId,
        timestamp: DateTime.now(),
        data: {'trigger': 'manual'},
      ));
      
    } catch (e) {
      // Emit hot-reload failed event
      _liveUpdateController.add(LiveUpdateEvent(
        type: LiveUpdateEventType.hotReloadFailed,
        pluginId: pluginId,
        timestamp: DateTime.now(),
        data: {
          'trigger': 'manual',
          'error': e.toString(),
        },
      ));
      
      rethrow;
    }
  }

  /// Enable live preview for a plugin
  Future<void> enableLivePreview(String pluginId) async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) {
      throw DevelopmentHotReloadException('Development mode is not enabled', pluginId: pluginId);
    }
    
    final config = _liveUpdateConfigs[pluginId] ?? const LiveUpdateConfig();
    final updatedConfig = LiveUpdateConfig(
      enableAutoReload: config.enableAutoReload,
      enableLivePreview: true,
      enableStatePreservation: config.enableStatePreservation,
      debounceDelay: config.debounceDelay,
      excludePatterns: config.excludePatterns,
      customSettings: config.customSettings,
    );
    
    await configureLiveUpdates(pluginId, updatedConfig);
    
    // Emit live preview enabled event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.livePreviewEnabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  /// Disable live preview for a plugin
  Future<void> disableLivePreview(String pluginId) async {
    _ensureInitialized();
    
    final config = _liveUpdateConfigs[pluginId] ?? const LiveUpdateConfig();
    final updatedConfig = LiveUpdateConfig(
      enableAutoReload: config.enableAutoReload,
      enableLivePreview: false,
      enableStatePreservation: config.enableStatePreservation,
      debounceDelay: config.debounceDelay,
      excludePatterns: config.excludePatterns,
      customSettings: config.customSettings,
    );
    
    await configureLiveUpdates(pluginId, updatedConfig);
    
    // Emit live preview disabled event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.livePreviewDisabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  /// Get live update configuration for a plugin
  LiveUpdateConfig? getLiveUpdateConfig(String pluginId) {
    _ensureInitialized();
    return _liveUpdateConfigs[pluginId];
  }

  /// Get file watcher status for a plugin
  bool isFileWatchingEnabled(String pluginId) {
    _ensureInitialized();
    return _fileWatchers.containsKey(pluginId);
  }

  /// Get watched file paths for a plugin
  List<String> getWatchedPaths(String pluginId) {
    _ensureInitialized();
    final watcher = _fileWatchers[pluginId];
    return watcher?.watchedPaths ?? [];
  }

  /// Dispose the development hot-reload manager
  @override
  Future<void> dispose() async {
    await shutdown();
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError('DevelopmentHotReloadManager not initialized. Call initialize() first.');
    }
  }

  /// Handle file change events
  Future<void> _handleFileChange(FileChangeEvent event) async {
    // Emit file change event
    _fileChangeController.add(event);
    
    final config = _liveUpdateConfigs[event.pluginId] ?? const LiveUpdateConfig();
    
    // Check if file should be excluded
    if (_shouldExcludeFile(event.filePath, config.excludePatterns)) {
      return;
    }
    
    // Add to pending changes
    final pendingChanges = _pendingChanges[event.pluginId] ?? [];
    pendingChanges.add(event);
    _pendingChanges[event.pluginId] = pendingChanges;
    
    // Cancel existing debounce timer
    _debounceTimers[event.pluginId]?.cancel();
    
    // Set up new debounce timer
    _debounceTimers[event.pluginId] = Timer(config.debounceDelay, () {
      _processPendingChanges(event.pluginId);
    });
  }

  /// Process pending file changes for a plugin
  Future<void> _processPendingChanges(String pluginId) async {
    final pendingChanges = _pendingChanges[pluginId];
    if (pendingChanges == null || pendingChanges.isEmpty) return;
    
    final config = _liveUpdateConfigs[pluginId] ?? const LiveUpdateConfig();
    
    // Clear pending changes
    _pendingChanges[pluginId] = [];
    
    // Emit changes processed event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.changesProcessed,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'changeCount': pendingChanges.length,
        'changes': pendingChanges.map((c) => c.toJson()).toList(),
      },
    ));
    
    // Trigger hot-reload if auto-reload is enabled
    if (config.enableAutoReload) {
      try {
        await triggerHotReload(pluginId);
      } catch (e) {
        // Log error but don't fail the process
        print('Auto hot-reload failed for $pluginId: $e');
      }
    }
    
    // Trigger live preview if enabled
    if (config.enableLivePreview) {
      await _triggerLivePreview(pluginId, pendingChanges);
    }
  }

  /// Trigger live preview for a plugin
  Future<void> _triggerLivePreview(String pluginId, List<FileChangeEvent> changes) async {
    // Emit live preview triggered event
    _liveUpdateController.add(LiveUpdateEvent(
      type: LiveUpdateEventType.livePreviewTriggered,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'changeCount': changes.length,
        'changes': changes.map((c) => c.toJson()).toList(),
      },
    ));
    
    // In a real implementation, this would update the plugin's preview
    // without fully reloading it
  }

  /// Check if a file should be excluded from watching
  bool _shouldExcludeFile(String filePath, List<String> excludePatterns) {
    for (final pattern in excludePatterns) {
      if (filePath.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Stop file watcher for a plugin
  Future<void> _stopFileWatcher(String pluginId) async {
    final watcher = _fileWatchers[pluginId];
    if (watcher != null) {
      await watcher.dispose();
      _fileWatchers.remove(pluginId);
    }
    
    // Cancel debounce timer
    _debounceTimers[pluginId]?.cancel();
    _debounceTimers.remove(pluginId);
    
    // Clear pending changes
    _pendingChanges.remove(pluginId);
  }

  /// Stop all file watchers
  Future<void> _stopAllFileWatchers() async {
    final futures = <Future<void>>[];
    
    for (final pluginId in _fileWatchers.keys.toList()) {
      futures.add(_stopFileWatcher(pluginId));
    }
    
    await Future.wait(futures);
  }
}

/// Live update event types
enum LiveUpdateEventType {
  fileWatchingEnabled,
  fileWatchingDisabled,
  liveUpdateConfigured,
  hotReloadTriggered,
  hotReloadCompleted,
  hotReloadFailed,
  livePreviewEnabled,
  livePreviewDisabled,
  livePreviewTriggered,
  changesProcessed,
}

/// Live update events
class LiveUpdateEvent {
  final LiveUpdateEventType type;
  final String pluginId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const LiveUpdateEvent({
    required this.type,
    required this.pluginId,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'pluginId': pluginId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}