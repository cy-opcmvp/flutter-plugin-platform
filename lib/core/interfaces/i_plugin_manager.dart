import '../models/plugin_models.dart';
import '../models/platform_models.dart';
import 'i_plugin.dart';

/// Interface for managing plugin lifecycle
abstract class IPluginManager {
  /// Initialize the plugin manager
  Future<void> initialize();

  /// Shutdown the plugin manager
  Future<void> shutdown();

  /// Load a plugin from its descriptor
  Future<IPlugin> loadPlugin(PluginDescriptor descriptor);

  /// Unload a plugin by its ID
  Future<void> unloadPlugin(String pluginId);

  /// Validate a plugin package for security and compatibility
  Future<bool> validatePlugin(PluginPackage package);

  /// Get list of all available plugins
  Future<List<PluginDescriptor>> getAvailablePlugins();

  /// Get list of currently active plugins
  List<IPlugin> getActivePlugins();

  /// Get a specific plugin by ID
  IPlugin? getPlugin(String pluginId);

  /// Register a plugin in the registry
  Future<void> registerPlugin(PluginDescriptor descriptor);

  /// Unregister a plugin from the registry
  Future<void> unregisterPlugin(String pluginId);

  /// Install a plugin from a package
  Future<void> installPlugin(PluginPackage package);

  /// Uninstall a plugin completely
  Future<void> uninstallPlugin(String pluginId);

  /// Get plugin information
  Future<PluginInfo?> getPluginInfo(String pluginId);

  /// Hot-reload a plugin with a new version
  Future<void> hotReloadPlugin(String pluginId, PluginDescriptor newDescriptor);

  /// Check if hot-reloading is supported for a plugin
  bool supportsHotReload(String pluginId);

  /// Stream of plugin events
  Stream<PluginEvent> get eventStream;
}

/// Plugin package for installation
class PluginPackage {
  final PluginDescriptor descriptor;
  final List<int> packageData;
  final String checksum;

  const PluginPackage({
    required this.descriptor,
    required this.packageData,
    required this.checksum,
  });
}

/// Extended plugin information
class PluginInfo {
  final PluginDescriptor descriptor;
  final PluginState state;
  final DateTime installedAt;
  final DateTime? lastUsed;

  const PluginInfo({
    required this.descriptor,
    required this.state,
    required this.installedAt,
    this.lastUsed,
  });
}
