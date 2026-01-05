import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import '../interfaces/i_plugin_manager.dart';
import '../interfaces/i_plugin.dart';
import '../interfaces/i_platform_services.dart';
import '../interfaces/i_hot_reload_manager.dart';
import '../models/plugin_models.dart';
import '../models/platform_models.dart';
import 'plugin_sandbox.dart';
import 'hot_reload_manager.dart';
import '../../plugins/plugin_registry.dart';

/// Exception thrown when plugin operations fail
class PluginException implements Exception {
  final String message;
  final String? pluginId;
  final Exception? cause;

  const PluginException(this.message, {this.pluginId, this.cause});

  @override
  String toString() => 'PluginException: $message${pluginId != null ? ' (Plugin: $pluginId)' : ''}';
}

/// Security validation result
class SecurityValidationResult {
  final bool isValid;
  final List<String> violations;
  final SecurityLevel level;

  const SecurityValidationResult({
    required this.isValid,
    required this.violations,
    required this.level,
  });
}

/// Security levels for plugins
enum SecurityLevel {
  low,
  medium,
  high,
  critical
}

/// Plugin registry entry
class PluginRegistryEntry {
  final PluginDescriptor descriptor;
  final bool isEnabled;
  final DateTime installedAt;
  final DateTime? lastUsed;
  final SecurityLevel securityLevel;

  const PluginRegistryEntry({
    required this.descriptor,
    required this.isEnabled,
    required this.installedAt,
    this.lastUsed,
    required this.securityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'descriptor': descriptor.toJson(),
      'isEnabled': isEnabled,
      'installedAt': installedAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'securityLevel': securityLevel.name,
    };
  }

  factory PluginRegistryEntry.fromJson(Map<String, dynamic> json) {
    return PluginRegistryEntry(
      descriptor: PluginDescriptor.fromJson(json['descriptor']),
      isEnabled: json['isEnabled'] as bool,
      installedAt: DateTime.parse(json['installedAt']),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      securityLevel: SecurityLevel.values.firstWhere((e) => e.name == json['securityLevel']),
    );
  }
}

/// Core plugin manager implementation
class PluginManager implements IPluginManager {
  final Map<String, IPlugin> _activePlugins = {};
  final Map<String, PluginRuntimeInfo> _pluginRuntimeInfo = {};
  final Map<String, PluginRegistryEntry> _pluginRegistry = {};
  final Map<String, PluginSandbox> _pluginSandboxes = {};
  final IPlatformServices _platformServices;
  final PermissionManager _permissionManager = PermissionManager();
  final StreamController<PluginEvent> _eventController = StreamController<PluginEvent>.broadcast();
  late final IHotReloadManager _hotReloadManager;
  
  bool _isInitialized = false;

  PluginManager(this._platformServices) {
    _hotReloadManager = HotReloadManager(this);
  }

  /// Initialize the plugin manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadPluginRegistry();
    await _hotReloadManager.initialize();
    _isInitialized = true;
  }

  /// Shutdown the plugin manager
  Future<void> shutdown() async {
    if (!_isInitialized) return;
    
    // Shutdown hot-reload manager
    await _hotReloadManager.shutdown();
    
    // Unload all active plugins
    final activePluginIds = List<String>.from(_activePlugins.keys);
    for (final pluginId in activePluginIds) {
      await unloadPlugin(pluginId);
    }
    
    // Clear registry
    _pluginRegistry.clear();
    
    // Close event stream
    await _eventController.close();
    
    _isInitialized = false;
  }

  /// Stream of plugin events
  Stream<PluginEvent> get eventStream => _eventController.stream;

  @override
  Future<IPlugin> loadPlugin(PluginDescriptor descriptor) async {
    _ensureInitialized();
    
    if (_activePlugins.containsKey(descriptor.id)) {
      throw PluginException('Plugin ${descriptor.id} is already loaded');
    }

    // Validate plugin descriptor
    if (!descriptor.isValid()) {
      throw PluginException('Invalid plugin descriptor', pluginId: descriptor.id);
    }

    // Check if plugin is registered and enabled
    final registryEntry = _pluginRegistry[descriptor.id];
    if (registryEntry == null) {
      throw PluginException('Plugin ${descriptor.id} is not registered');
    }
    
    if (!registryEntry.isEnabled) {
      throw PluginException('Plugin ${descriptor.id} is disabled');
    }

    try {
      // Create runtime info and state manager
      final stateManager = PluginStateManager(
        pluginId: descriptor.id,
        initialState: PluginState.inactive,
      );
      
      final runtimeInfo = PluginRuntimeInfo(
        descriptor: descriptor,
        stateManager: stateManager,
      );

      _pluginRuntimeInfo[descriptor.id] = runtimeInfo;

      // Transition to loading state
      if (!stateManager.transitionTo(PluginState.loading)) {
        throw PluginException('Failed to transition plugin to loading state', pluginId: descriptor.id);
      }

      // Grant permissions to plugin
      _permissionManager.grantPermissions(descriptor.id, descriptor.requiredPermissions.toSet());

      // Create sandbox for plugin
      final resourceLimits = ResourceLimits.fromSecurityLevel(registryEntry.securityLevel);
      final sandbox = PluginSandbox(
        pluginId: descriptor.id,
        allowedPermissions: descriptor.requiredPermissions.toSet(),
        limits: resourceLimits,
      );
      
      _pluginSandboxes[descriptor.id] = sandbox;
      sandbox.start();

      // Create plugin instance (simplified - in real implementation would load from entry point)
      final plugin = _createPluginInstance(descriptor);
      
      // Create plugin context
      final context = PluginContext(
        platformServices: _platformServices,
        dataStorage: _createDataStorage(descriptor.id),
        networkAccess: _createNetworkAccess(descriptor.id),
        configuration: descriptor.metadata,
      );

      // Initialize plugin within sandbox
      await sandbox.executeInSandbox(
        () => plugin.initialize(context),
        operationDescription: 'Plugin initialization',
      );

      // Transition to active state
      if (!stateManager.transitionTo(PluginState.active)) {
        throw PluginException('Failed to transition plugin to active state', pluginId: descriptor.id);
      }

      _activePlugins[descriptor.id] = plugin;

      // Update last used time
      _updateLastUsedTime(descriptor.id);

      // Emit plugin loaded event
      _eventController.add(PluginEvent(
        type: PluginEventType.loaded,
        pluginId: descriptor.id,
        timestamp: DateTime.now(),
      ));

      return plugin;
    } catch (e) {
      // Transition to error state if something went wrong
      final runtimeInfo = _pluginRuntimeInfo[descriptor.id];
      runtimeInfo?.stateManager.transitionTo(PluginState.error);
      
      _eventController.add(PluginEvent(
        type: PluginEventType.error,
        pluginId: descriptor.id,
        timestamp: DateTime.now(),
        data: {'error': e.toString()},
      ));
      
      rethrow;
    }
  }

  @override
  Future<void> unloadPlugin(String pluginId) async {
    _ensureInitialized();
    
    final plugin = _activePlugins[pluginId];
    if (plugin == null) {
      throw PluginException('Plugin $pluginId is not loaded');
    }

    final runtimeInfo = _pluginRuntimeInfo[pluginId];
    if (runtimeInfo == null) {
      throw PluginException('Plugin runtime info not found', pluginId: pluginId);
    }

    try {
      // Get sandbox for cleanup
      final sandbox = _pluginSandboxes[pluginId];

      // Dispose plugin resources within sandbox if available
      if (sandbox != null) {
        await sandbox.executeInSandbox(
          () => plugin.dispose(),
          operationDescription: 'Plugin disposal',
        );
        sandbox.stop();
        await sandbox.dispose();
        _pluginSandboxes.remove(pluginId);
      } else {
        await plugin.dispose();
      }

      // Transition to inactive state
      runtimeInfo.stateManager.transitionTo(PluginState.inactive);

      // Remove from active plugins
      _activePlugins.remove(pluginId);
      _pluginRuntimeInfo.remove(pluginId);

      // Remove permissions
      _permissionManager.removePlugin(pluginId);

      // Emit plugin unloaded event
      _eventController.add(PluginEvent(
        type: PluginEventType.unloaded,
        pluginId: pluginId,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      // Transition to error state
      runtimeInfo.stateManager.transitionTo(PluginState.error);
      
      _eventController.add(PluginEvent(
        type: PluginEventType.error,
        pluginId: pluginId,
        timestamp: DateTime.now(),
        data: {'error': e.toString()},
      ));
      
      rethrow;
    }
  }

  @override
  Future<bool> validatePlugin(PluginPackage package) async {
    try {
      // Validate checksum
      final calculatedChecksum = _calculateChecksum(package.packageData);
      if (calculatedChecksum != package.checksum) {
        return false;
      }

      // Validate descriptor
      if (!package.descriptor.isValid()) {
        return false;
      }

      // Perform security validation
      final securityResult = await _performSecurityValidation(package);
      return securityResult.isValid;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PluginDescriptor>> getAvailablePlugins() async {
    _ensureInitialized();
    return _pluginRegistry.values.map((entry) => entry.descriptor).toList();
  }

  @override
  List<IPlugin> getActivePlugins() {
    _ensureInitialized();
    return _activePlugins.values.toList();
  }

  @override
  IPlugin? getPlugin(String pluginId) {
    _ensureInitialized();
    return _activePlugins[pluginId];
  }

  @override
  Future<void> registerPlugin(PluginDescriptor descriptor) async {
    _ensureInitialized();
    
    if (!descriptor.isValid()) {
      throw PluginException('Invalid plugin descriptor', pluginId: descriptor.id);
    }

    if (_pluginRegistry.containsKey(descriptor.id)) {
      throw PluginException('Plugin ${descriptor.id} is already registered');
    }

    final entry = PluginRegistryEntry(
      descriptor: descriptor,
      isEnabled: true,
      installedAt: DateTime.now(),
      securityLevel: SecurityLevel.medium, // Default security level
    );

    _pluginRegistry[descriptor.id] = entry;
    await _savePluginRegistry();

    _eventController.add(PluginEvent(
      type: PluginEventType.registered,
      pluginId: descriptor.id,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> unregisterPlugin(String pluginId) async {
    _ensureInitialized();
    
    // Unload plugin if it's currently loaded
    if (_activePlugins.containsKey(pluginId)) {
      await unloadPlugin(pluginId);
    }

    _pluginRegistry.remove(pluginId);
    await _savePluginRegistry();

    _eventController.add(PluginEvent(
      type: PluginEventType.unregistered,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> installPlugin(PluginPackage package) async {
    _ensureInitialized();
    
    // Validate plugin package
    if (!await validatePlugin(package)) {
      throw PluginException('Plugin validation failed', pluginId: package.descriptor.id);
    }

    // Register the plugin
    await registerPlugin(package.descriptor);

    _eventController.add(PluginEvent(
      type: PluginEventType.installed,
      pluginId: package.descriptor.id,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> uninstallPlugin(String pluginId) async {
    _ensureInitialized();
    
    // Unregister the plugin (this will also unload it if loaded)
    await unregisterPlugin(pluginId);

    _eventController.add(PluginEvent(
      type: PluginEventType.uninstalled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> enablePlugin(String pluginId) async {
    _ensureInitialized();
    
    final entry = _pluginRegistry[pluginId];
    if (entry == null) {
      throw PluginException('Plugin $pluginId is not registered');
    }

    if (entry.isEnabled) {
      return; // Already enabled
    }

    final updatedEntry = PluginRegistryEntry(
      descriptor: entry.descriptor,
      isEnabled: true,
      installedAt: entry.installedAt,
      lastUsed: entry.lastUsed,
      securityLevel: entry.securityLevel,
    );

    _pluginRegistry[pluginId] = updatedEntry;
    await _savePluginRegistry();

    _eventController.add(PluginEvent(
      type: PluginEventType.enabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> disablePlugin(String pluginId) async {
    _ensureInitialized();
    
    final entry = _pluginRegistry[pluginId];
    if (entry == null) {
      throw PluginException('Plugin $pluginId is not registered');
    }

    // Unload plugin if it's currently loaded
    if (_activePlugins.containsKey(pluginId)) {
      await unloadPlugin(pluginId);
    }

    if (!entry.isEnabled) {
      return; // Already disabled
    }

    final updatedEntry = PluginRegistryEntry(
      descriptor: entry.descriptor,
      isEnabled: false,
      installedAt: entry.installedAt,
      lastUsed: entry.lastUsed,
      securityLevel: entry.securityLevel,
    );

    _pluginRegistry[pluginId] = updatedEntry;
    await _savePluginRegistry();

    _eventController.add(PluginEvent(
      type: PluginEventType.disabled,
      pluginId: pluginId,
      timestamp: DateTime.now(),
    ));
  }

  @override
  bool isPluginEnabled(String pluginId) {
    _ensureInitialized();
    return _pluginRegistry[pluginId]?.isEnabled ?? false;
  }

  @override
  Future<PluginInfo?> getPluginInfo(String pluginId) async {
    _ensureInitialized();
    
    final entry = _pluginRegistry[pluginId];
    if (entry == null) return null;

    final runtimeInfo = _pluginRuntimeInfo[pluginId];
    final state = runtimeInfo?.currentState ?? PluginState.inactive;

    return PluginInfo(
      descriptor: entry.descriptor,
      state: state,
      isEnabled: entry.isEnabled,
      installedAt: entry.installedAt,
      lastUsed: entry.lastUsed,
    );
  }

  /// Get plugin runtime information
  PluginRuntimeInfo? getPluginRuntimeInfo(String pluginId) {
    return _pluginRuntimeInfo[pluginId];
  }

  /// Get plugin sandbox
  PluginSandbox? getPluginSandbox(String pluginId) {
    return _pluginSandboxes[pluginId];
  }

  /// Get permission manager
  PermissionManager get permissionManager => _permissionManager;

  /// Check if plugin has permission
  bool hasPluginPermission(String pluginId, Permission permission) {
    return _permissionManager.hasPermission(pluginId, permission);
  }

  /// Request permission for plugin
  Future<bool> requestPluginPermission(String pluginId, Permission permission) async {
    return await _permissionManager.requestPermission(pluginId, permission);
  }

  @override
  Future<void> hotReloadPlugin(String pluginId, PluginDescriptor newDescriptor) async {
    _ensureInitialized();
    
    if (!supportsHotReload(pluginId)) {
      throw PluginException('Plugin $pluginId does not support hot-reloading');
    }
    
    // Emit hot-reloading event
    _eventController.add(PluginEvent(
      type: PluginEventType.hotReloading,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'newVersion': newDescriptor.version,
      },
    ));
    
    try {
      await _hotReloadManager.hotReloadPlugin(pluginId, newDescriptor);
      
      // Emit hot-reloaded event
      _eventController.add(PluginEvent(
        type: PluginEventType.hotReloaded,
        pluginId: pluginId,
        timestamp: DateTime.now(),
        data: {
          'newVersion': newDescriptor.version,
        },
      ));
    } catch (e) {
      _eventController.add(PluginEvent(
        type: PluginEventType.error,
        pluginId: pluginId,
        timestamp: DateTime.now(),
        data: {'error': 'Hot-reload failed: ${e.toString()}'},
      ));
      rethrow;
    }
  }

  @override
  bool supportsHotReload(String pluginId) {
    _ensureInitialized();
    
    final plugin = _activePlugins[pluginId];
    if (plugin == null) return false;
    
    // Check if plugin supports hot-reloading based on metadata
    final registryEntry = _pluginRegistry[pluginId];
    if (registryEntry == null) return false;
    
    final metadata = registryEntry.descriptor.metadata;
    return metadata['supportsHotReload'] == true;
  }

  /// Get the hot-reload manager
  IHotReloadManager get hotReloadManager => _hotReloadManager;

  /// Dispose the plugin manager
  Future<void> dispose() async {
    // Dispose hot-reload manager
    await _hotReloadManager.dispose();
    
    // Unload all active plugins
    final activePluginIds = _activePlugins.keys.toList();
    for (final pluginId in activePluginIds) {
      try {
        await unloadPlugin(pluginId);
      } catch (e) {
        // Log error but continue cleanup
      }
    }

    // Dispose remaining sandboxes
    for (final sandbox in _pluginSandboxes.values) {
      try {
        await sandbox.dispose();
      } catch (e) {
        // Log error but continue cleanup
      }
    }
    _pluginSandboxes.clear();

    // Dispose permission manager
    await _permissionManager.dispose();

    await _eventController.close();
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('PluginManager not initialized. Call initialize() first.');
    }
  }

  Future<void> _loadPluginRegistry() async {
    // In a real implementation, this would load from persistent storage
    // For now, we'll load the example plugins
    _pluginRegistry.clear();
    
    // Load example plugins
    final exampleDescriptors = ExamplePluginRegistry.getAllDescriptors();
    for (final descriptor in exampleDescriptors) {
      final entry = PluginRegistryEntry(
        descriptor: descriptor,
        isEnabled: true,
        installedAt: DateTime.now(),
        securityLevel: SecurityLevel.low,
      );
      _pluginRegistry[descriptor.id] = entry;
    }
  }

  Future<void> _savePluginRegistry() async {
    // In a real implementation, this would save to persistent storage
    // For now, this is a no-op
  }

  IPlugin _createPluginInstance(PluginDescriptor descriptor) {
    // Try to create from example plugin registry first
    final examplePlugin = ExamplePluginRegistry.createPlugin(descriptor.id);
    if (examplePlugin != null) {
      return examplePlugin;
    }
    
    // In a real implementation, this would dynamically load the plugin
    // from the entry point. For now, we'll create a mock plugin.
    return _MockPlugin(descriptor);
  }

  IDataStorage _createDataStorage(String pluginId) {
    return _MockDataStorage(pluginId);
  }

  INetworkAccess _createNetworkAccess(String pluginId) {
    return _MockNetworkAccess(pluginId);
  }

  void _updateLastUsedTime(String pluginId) {
    final entry = _pluginRegistry[pluginId];
    if (entry != null) {
      final updatedEntry = PluginRegistryEntry(
        descriptor: entry.descriptor,
        isEnabled: entry.isEnabled,
        installedAt: entry.installedAt,
        lastUsed: DateTime.now(),
        securityLevel: entry.securityLevel,
      );
      _pluginRegistry[pluginId] = updatedEntry;
    }
  }

  String _calculateChecksum(List<int> data) {
    final bytes = Uint8List.fromList(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<SecurityValidationResult> _performSecurityValidation(PluginPackage package) async {
    final violations = <String>[];
    
    // Basic security checks
    if (package.descriptor.requiredPermissions.contains(Permission.fileAccess)) {
      // Check if file access is justified
      if (!package.descriptor.metadata.containsKey('fileAccessReason')) {
        violations.add('File access permission requires justification');
      }
    }

    if (package.descriptor.requiredPermissions.contains(Permission.networkAccess)) {
      // Check if network access is justified
      if (!package.descriptor.metadata.containsKey('networkAccessReason')) {
        violations.add('Network access permission requires justification');
      }
    }

    // Determine security level based on permissions
    SecurityLevel level = SecurityLevel.low;
    if (package.descriptor.requiredPermissions.isNotEmpty) {
      level = SecurityLevel.medium;
    }
    if (package.descriptor.requiredPermissions.length > 3) {
      level = SecurityLevel.high;
    }

    return SecurityValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
      level: level,
    );
  }
}

// Mock implementations for testing

class _MockPlugin implements IPlugin {
  final PluginDescriptor _descriptor;
  
  _MockPlugin(this._descriptor);

  @override
  String get id => _descriptor.id;

  @override
  String get name => _descriptor.name;

  @override
  String get version => _descriptor.version;

  @override
  PluginType get type => _descriptor.type;

  @override
  Future<void> initialize(PluginContext context) async {
    // Mock initialization
  }

  @override
  Future<void> dispose() async {
    // Mock disposal
  }

  @override
  Widget buildUI(BuildContext context) {
    // Mock UI - return a simple container
    return Container();
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    // Mock state change handling
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    // Mock state retrieval
    return <String, dynamic>{};
  }
}

class _MockDataStorage implements IDataStorage {
  final Map<String, dynamic> _storage = {};

  _MockDataStorage(String pluginId);

  @override
  Future<void> store(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    return _storage[key] as T?;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

class _MockNetworkAccess implements INetworkAccess {
  _MockNetworkAccess(String pluginId);

  @override
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    // Mock GET request
    return {'status': 'success', 'data': 'mock response'};
  }

  @override
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    // Mock POST request
    return {'status': 'success', 'data': 'mock response'};
  }

  @override
  Future<bool> isConnected() async {
    // Mock connectivity check
    return true;
  }
}