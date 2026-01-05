import 'package:flutter/widgets.dart';
import '../models/plugin_models.dart';
import 'i_platform_services.dart';

/// Base interface that all plugins must implement
abstract class IPlugin {
  /// Unique identifier for the plugin
  String get id;
  
  /// Display name of the plugin
  String get name;
  
  /// Version of the plugin
  String get version;
  
  /// Type of plugin (TOOL or GAME)
  PluginType get type;
  
  /// Initialize the plugin with the provided context
  Future<void> initialize(PluginContext context);
  
  /// Clean up resources when plugin is disposed
  Future<void> dispose();
  
  /// Build the UI for this plugin
  Widget buildUI(BuildContext context);
  
  /// Handle state changes for the plugin
  Future<void> onStateChanged(PluginState state);
  
  /// Get the current state data of the plugin
  Future<Map<String, dynamic>> getState();
}

/// Context provided to plugins during initialization
class PluginContext {
  final IPlatformServices platformServices;
  final IDataStorage dataStorage;
  final INetworkAccess networkAccess;
  final Map<String, dynamic> configuration;

  const PluginContext({
    required this.platformServices,
    required this.dataStorage,
    required this.networkAccess,
    required this.configuration,
  });
}

/// Interface for plugin data storage
abstract class IDataStorage {
  Future<void> store(String key, dynamic value);
  Future<T?> retrieve<T>(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

/// Interface for plugin network access
abstract class INetworkAccess {
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers});
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers});
  Future<bool> isConnected();
}