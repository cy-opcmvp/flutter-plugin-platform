import '../core/interfaces/i_plugin.dart';
import '../core/models/plugin_models.dart';
import 'calculator/calculator_plugin_factory.dart';

/// Registry for example plugins included with the platform
class ExamplePluginRegistry {
  static final Map<String, PluginFactory> _factories = {
    'com.example.calculator': PluginFactory(
      createPlugin: CalculatorPluginFactory.createPlugin,
      getDescriptor: CalculatorPluginFactory.getDescriptor,
    ),
  };

  /// Gets all available example plugin descriptors
  static List<PluginDescriptor> getAllDescriptors() {
    return _factories.values.map((factory) => factory.getDescriptor()).toList();
  }

  /// Gets a specific plugin descriptor by ID
  static PluginDescriptor? getDescriptor(String pluginId) {
    final factory = _factories[pluginId];
    return factory?.getDescriptor();
  }

  /// Creates a plugin instance by ID
  static IPlugin? createPlugin(String pluginId) {
    final factory = _factories[pluginId];
    return factory?.createPlugin();
  }

  /// Checks if a plugin ID is registered
  static bool isRegistered(String pluginId) {
    return _factories.containsKey(pluginId);
  }

  /// Gets all registered plugin IDs
  static List<String> getRegisteredPluginIds() {
    return _factories.keys.toList();
  }

  /// Registers a new plugin factory (for dynamic plugin loading)
  static void registerPlugin(String pluginId, PluginFactory factory) {
    _factories[pluginId] = factory;
  }

  /// Unregisters a plugin factory
  static void unregisterPlugin(String pluginId) {
    _factories.remove(pluginId);
  }
}

/// Factory interface for creating plugins
class PluginFactory {
  final IPlugin Function() createPlugin;
  final PluginDescriptor Function() getDescriptor;

  const PluginFactory({
    required this.createPlugin,
    required this.getDescriptor,
  });
}