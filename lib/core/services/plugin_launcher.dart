import 'dart:async';
import 'package:flutter/foundation.dart';
import '../interfaces/i_plugin.dart';
import '../interfaces/i_plugin_manager.dart';
import '../models/plugin_models.dart';

/// Service responsible for plugin launching and switching
/// Implements requirements 1.2, 1.4 for plugin launching and state preservation
class PluginLauncher {
  final IPluginManager _pluginManager;

  // Currently active plugin
  IPlugin? _currentPlugin;

  // Plugin state storage for background plugins
  final Map<String, Map<String, dynamic>> _pluginStates = {};

  // Background plugins that are loaded but not currently active
  final Map<String, IPlugin> _backgroundPlugins = {};

  // Event stream for plugin switching events
  final StreamController<PluginLaunchEvent> _eventController =
      StreamController<PluginLaunchEvent>.broadcast();

  PluginLauncher(this._pluginManager);

  /// Current active plugin
  IPlugin? get currentPlugin => _currentPlugin;

  /// All background plugins
  Map<String, IPlugin> get backgroundPlugins =>
      Map.unmodifiable(_backgroundPlugins);

  /// Stream of plugin launch events
  Stream<PluginLaunchEvent> get eventStream => _eventController.stream;

  /// Launch a plugin within the application context
  /// Requirement 1.2: Create plugin launching system within application context
  Future<IPlugin> launchPlugin(PluginDescriptor descriptor) async {
    try {
      // Check if plugin is already loaded in background
      if (_backgroundPlugins.containsKey(descriptor.id)) {
        return await _switchToPlugin(descriptor.id);
      }

      // Save current plugin state if switching from another plugin
      if (_currentPlugin != null) {
        await _saveCurrentPluginState();
        await _moveCurrentToBackground();
      }

      // Load the new plugin
      final plugin = await _pluginManager.loadPlugin(descriptor);

      // Set as current plugin
      _currentPlugin = plugin;

      // Restore plugin state if it exists
      await _restorePluginState(plugin);

      // Emit launch event
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.launched,
          pluginId: plugin.id,
          timestamp: DateTime.now(),
        ),
      );

      return plugin;
    } catch (e) {
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.launchFailed,
          pluginId: descriptor.id,
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Switch to an already loaded plugin
  /// Requirement 1.4: Plugin switching with state preservation
  Future<IPlugin> switchToPlugin(String pluginId) async {
    return await _switchToPlugin(pluginId);
  }

  /// Internal method to switch to a plugin
  Future<IPlugin> _switchToPlugin(String pluginId) async {
    try {
      // Check if plugin exists in background
      final backgroundPlugin = _backgroundPlugins[pluginId];
      if (backgroundPlugin == null) {
        throw StateError('Plugin $pluginId is not loaded in background');
      }

      // Save current plugin state and move to background
      if (_currentPlugin != null) {
        await _saveCurrentPluginState();
        await _moveCurrentToBackground();
      }

      // Move background plugin to foreground
      _currentPlugin = backgroundPlugin;
      _backgroundPlugins.remove(pluginId);

      // Restore plugin state
      await _restorePluginState(_currentPlugin!);

      // Emit switch event
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.switched,
          pluginId: pluginId,
          timestamp: DateTime.now(),
        ),
      );

      return _currentPlugin!;
    } catch (e) {
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.switchFailed,
          pluginId: pluginId,
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Close the current plugin and optionally switch to another
  /// Requirement 1.2: Background plugin management
  Future<void> closeCurrentPlugin({String? switchToPluginId}) async {
    if (_currentPlugin == null) {
      return;
    }

    try {
      final closingPluginId = _currentPlugin!.id;

      // Save current plugin state
      await _saveCurrentPluginState();

      // Unload the current plugin
      await _pluginManager.unloadPlugin(_currentPlugin!.id);

      // Remove from background plugins if it exists there
      _backgroundPlugins.remove(closingPluginId);

      // Clear current plugin
      _currentPlugin = null;

      // Switch to another plugin if requested
      if (switchToPluginId != null &&
          _backgroundPlugins.containsKey(switchToPluginId)) {
        await _switchToPlugin(switchToPluginId);
      }

      // Emit close event
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.closed,
          pluginId: closingPluginId,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.closeFailed,
          pluginId: _currentPlugin?.id ?? 'unknown',
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Pause the current plugin (move to background without unloading)
  /// Requirement 1.4: State preservation for background plugins
  Future<void> pauseCurrentPlugin() async {
    if (_currentPlugin == null) {
      return;
    }

    try {
      // Save current plugin state
      await _saveCurrentPluginState();

      // Move to background
      await _moveCurrentToBackground();

      // Emit pause event
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.paused,
          pluginId: _currentPlugin!.id,
          timestamp: DateTime.now(),
        ),
      );

      _currentPlugin = null;
    } catch (e) {
      _eventController.add(
        PluginLaunchEvent(
          type: PluginLaunchEventType.pauseFailed,
          pluginId: _currentPlugin?.id ?? 'unknown',
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Get list of all loaded plugins (current + background)
  List<IPlugin> getAllLoadedPlugins() {
    final plugins = <IPlugin>[];
    if (_currentPlugin != null) {
      plugins.add(_currentPlugin!);
    }
    plugins.addAll(_backgroundPlugins.values);
    return plugins;
  }

  /// Check if a plugin is currently loaded (active or background)
  bool isPluginLoaded(String pluginId) {
    return (_currentPlugin?.id == pluginId) ||
        _backgroundPlugins.containsKey(pluginId);
  }

  /// Get plugin state for a specific plugin
  Map<String, dynamic>? getPluginState(String pluginId) {
    return _pluginStates[pluginId];
  }

  /// Save current plugin state
  /// Requirement 1.4: State preservation when switching between plugins
  Future<void> _saveCurrentPluginState() async {
    if (_currentPlugin == null) {
      return;
    }

    try {
      final state = await _currentPlugin!.getState();
      _pluginStates[_currentPlugin!.id] = state;

      // Also notify plugin of state change
      await _currentPlugin!.onStateChanged(PluginState.paused);
    } catch (e) {
      // Log error but don't fail the operation
      debugPrint('Failed to save plugin state for ${_currentPlugin!.id}: $e');
    }
  }

  /// Restore plugin state
  Future<void> _restorePluginState(IPlugin plugin) async {
    try {
      final savedState = _pluginStates[plugin.id];
      if (savedState != null) {
        // Plugin should handle state restoration internally
        // We just notify it that it's becoming active
        await plugin.onStateChanged(PluginState.active);
      }
    } catch (e) {
      // Log error but don't fail the operation
      debugPrint('Failed to restore plugin state for ${plugin.id}: $e');
    }
  }

  /// Move current plugin to background
  Future<void> _moveCurrentToBackground() async {
    if (_currentPlugin == null) {
      return;
    }

    try {
      // Notify plugin it's being paused
      await _currentPlugin!.onStateChanged(PluginState.paused);

      // Move to background
      _backgroundPlugins[_currentPlugin!.id] = _currentPlugin!;
    } catch (e) {
      // Log error but continue
      debugPrint(
        'Failed to move plugin ${_currentPlugin!.id} to background: $e',
      );
    }
  }

  /// Clean up all plugins and resources
  Future<void> dispose() async {
    // Save all plugin states
    if (_currentPlugin != null) {
      await _saveCurrentPluginState();
    }

    for (final plugin in _backgroundPlugins.values) {
      try {
        final state = await plugin.getState();
        _pluginStates[plugin.id] = state;
      } catch (e) {
        debugPrint(
          'Failed to save state for background plugin ${plugin.id}: $e',
        );
      }
    }

    // Clear all references
    _currentPlugin = null;
    _backgroundPlugins.clear();

    // Close event stream
    await _eventController.close();
  }
}

/// Events related to plugin launching and switching
class PluginLaunchEvent {
  final PluginLaunchEventType type;
  final String pluginId;
  final DateTime timestamp;
  final String? error;

  const PluginLaunchEvent({
    required this.type,
    required this.pluginId,
    required this.timestamp,
    this.error,
  });
}

/// Types of plugin launch events
enum PluginLaunchEventType {
  launched,
  launchFailed,
  switched,
  switchFailed,
  closed,
  closeFailed,
  paused,
  pauseFailed,
}
