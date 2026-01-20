import 'dart:async';
import 'package:flutter/foundation.dart';
import '../interfaces/i_platform_core.dart';
import '../interfaces/i_plugin_manager.dart';
import '../interfaces/i_network_manager.dart';
import '../interfaces/i_state_manager.dart';
import '../interfaces/i_platform_services.dart';
import '../interfaces/i_synchronization_engine.dart';
import '../models/platform_models.dart';
import 'plugin_manager.dart';
import 'network_manager.dart';
import 'state_manager.dart';
import 'platform_services.dart';
import 'cross_platform_core.dart';
import 'platform_environment.dart';

/// Core platform implementation that orchestrates all services
class PlatformCore implements IPlatformCore {
  late final IPluginManager _pluginManager;
  late final INetworkManager _networkManager;
  late final IStateManager _stateManager;
  late final IPlatformServices _platformServices;
  late final ISynchronizationEngine _syncEngine;

  // Optional dependencies for testing
  final IStateManager? _testStateManager;
  final INetworkManager? _testNetworkManager;
  final IPlatformServices? _testPlatformServices;
  final IPluginManager? _testPluginManager;
  final ISynchronizationEngine? _testSyncEngine;

  OperationMode _currentMode = OperationMode.local;
  bool _isInitialized = false;

  final StreamController<PlatformEvent> _eventController =
      StreamController<PlatformEvent>.broadcast();
  late final PlatformInfo _platformInfo;

  PlatformCore({
    IStateManager? stateManager,
    INetworkManager? networkManager,
    IPlatformServices? platformServices,
    IPluginManager? pluginManager,
    ISynchronizationEngine? syncEngine,
  }) : _testStateManager = stateManager,
       _testNetworkManager = networkManager,
       _testPlatformServices = platformServices,
       _testPluginManager = pluginManager,
       _testSyncEngine = syncEngine;

  /// Features available in each mode
  static const Map<OperationMode, Set<String>> _modeFeatures = {
    OperationMode.local: {
      'plugin_management',
      'local_storage',
      'offline_plugins',
      'local_preferences',
    },
    OperationMode.online: {
      'plugin_management',
      'local_storage',
      'offline_plugins',
      'local_preferences',
      'cloud_sync',
      'multiplayer',
      'online_plugins',
      'cloud_storage',
      'remote_config',
    },
  };

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Initialize platform info
    _platformInfo = _createPlatformInfo();

    // Initialize services (use test dependencies if provided)
    _stateManager = _testStateManager ?? StateManager();
    _networkManager = _testNetworkManager ?? NetworkManager();
    _platformServices = _testPlatformServices ?? PlatformServices();
    _pluginManager = _testPluginManager ?? PluginManager(_platformServices);
    _syncEngine =
        _testSyncEngine ??
        CrossPlatformCore(_networkManager, stateManager: _stateManager);

    // Initialize all services
    await _stateManager.initialize();
    await _networkManager.initialize();
    await _platformServices.initialize();
    await _pluginManager.initialize();
    await _syncEngine.initialize();

    // Load saved operation mode
    final savedMode = await _stateManager.loadState<String>('operation_mode');
    if (savedMode != null) {
      _currentMode = OperationMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => OperationMode.local,
      );
    }

    // Configure services based on current mode
    await _configureForMode(_currentMode);

    _isInitialized = true;

    // Emit initialization event
    _eventController.add(
      OperationModeChangedEvent(
        oldMode: OperationMode.local,
        newMode: _currentMode,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> shutdown() async {
    if (!_isInitialized) {
      return;
    }

    // Shutdown all services
    await _pluginManager.shutdown();
    await _networkManager.shutdown();
    await _syncEngine.shutdown();

    // Dispose state manager
    if (_stateManager is StateManager) {
      _stateManager.dispose();
    }

    _eventController.close();
    _isInitialized = false;
  }

  @override
  Future<void> switchMode(OperationMode mode) async {
    if (!_isInitialized) {
      throw StateError('Platform not initialized');
    }

    if (_currentMode == mode) {
      return; // Already in the requested mode
    }

    final oldMode = _currentMode;

    // Preserve current state before switching
    await _preserveStateForModeSwitch(oldMode, mode);

    // Update current mode
    _currentMode = mode;

    // Save the new mode
    await _stateManager.saveState('operation_mode', mode.name);

    // Configure services for new mode
    await _configureForMode(mode);

    // Restore state for new mode
    await _restoreStateForMode(mode);

    // Emit mode change event
    _eventController.add(
      OperationModeChangedEvent(
        oldMode: oldMode,
        newMode: mode,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  OperationMode get currentMode => _currentMode;

  @override
  IPluginManager get pluginManager => _pluginManager;

  @override
  INetworkManager get networkManager => _networkManager;

  @override
  IStateManager get stateManager => _stateManager;

  @override
  IPlatformServices get platformServices => _platformServices;

  /// Get synchronization engine instance
  ISynchronizationEngine get syncEngine => _syncEngine;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<PlatformEvent> get eventStream => _eventController.stream;

  @override
  PlatformInfo get platformInfo => _platformInfo;

  /// Check if a feature is available in the current mode
  bool isFeatureAvailable(String feature) {
    return _modeFeatures[_currentMode]?.contains(feature) ?? false;
  }

  /// Get all available features for the current mode
  Set<String> getAvailableFeatures() {
    return _modeFeatures[_currentMode] ?? <String>{};
  }

  /// Configure services for the specified operation mode
  Future<void> _configureForMode(OperationMode mode) async {
    switch (mode) {
      case OperationMode.local:
        // Configure for offline operation
        await _networkManager.setOfflineMode(true);
        break;
      case OperationMode.online:
        // Configure for online operation
        await _networkManager.setOfflineMode(false);
        // Initialize cloud sync if available
        if (await _networkManager.isConnected()) {
          await _stateManager.syncState();
          await _syncEngine.synchronizeData();
        }
        break;
    }
  }

  /// Preserve state before mode switching
  Future<void> _preserveStateForModeSwitch(
    OperationMode fromMode,
    OperationMode toMode,
  ) async {
    // Save current plugin states
    final pluginStates = await _stateManager.getAllPluginStates();
    await _stateManager.saveState('mode_switch_plugin_states', pluginStates);

    // Save current user preferences
    final preferences = await _stateManager.loadState('user_preferences');
    await _stateManager.saveState('mode_switch_preferences', preferences);

    // Save current platform state
    final platformState = {
      'from_mode': fromMode.name,
      'to_mode': toMode.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _stateManager.saveState('mode_switch_state', platformState);
  }

  /// Restore state after mode switching
  Future<void> _restoreStateForMode(OperationMode mode) async {
    // Restore plugin states
    final pluginStates = await _stateManager.loadState<Map<String, dynamic>>(
      'mode_switch_plugin_states',
    );
    if (pluginStates != null) {
      for (final entry in pluginStates.entries) {
        await _stateManager.savePluginState(
          entry.key,
          Map<String, dynamic>.from(entry.value),
        );
      }
    }

    // Restore user preferences
    final preferences = await _stateManager.loadState(
      'mode_switch_preferences',
    );
    if (preferences != null) {
      await _stateManager.saveState('user_preferences', preferences);
    }

    // Clean up temporary mode switch data
    await _stateManager.saveState('mode_switch_plugin_states', null);
    await _stateManager.saveState('mode_switch_preferences', null);
    await _stateManager.saveState('mode_switch_state', null);
  }

  /// Create platform information based on current environment
  PlatformInfo _createPlatformInfo() {
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    // Check if running on Steam (only on desktop platforms, disabled on web)
    // Use PlatformEnvironment to safely check for Steam environment variables
    final platformEnv = PlatformEnvironment.instance;
    final supportsSteam =
        isDesktop &&
        !platformEnv.isWeb &&
        platformEnv.containsKey('STEAM_COMPAT_DATA_PATH');

    PlatformType type;
    if (supportsSteam) {
      type = PlatformType.steam;
    } else if (isMobile) {
      type = PlatformType.mobile;
    } else {
      type = PlatformType.desktop;
    }

    final capabilities = <String, dynamic>{
      'touch_input': isMobile,
      'keyboard_input': isDesktop,
      'mouse_input': isDesktop,
      'desktop_pet': isDesktop, // 所有桌面平台都支持Desktop Pet
      'always_on_top': isDesktop,
      'system_tray': isDesktop,
      'steam_integration': supportsSteam, // Steam特有功能单独标识
      'notifications': true,
      'file_system': true,
      'network': true,
    };

    return PlatformInfo(
      type: type,
      version:
          '1.0.0', // This would come from package info in real implementation
      capabilities: capabilities,
    );
  }
}
