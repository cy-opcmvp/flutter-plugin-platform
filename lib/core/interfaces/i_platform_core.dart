import '../models/platform_models.dart';
import 'i_plugin_manager.dart';
import 'i_network_manager.dart';
import 'i_state_manager.dart';
import 'i_platform_services.dart';

/// Core platform interface that orchestrates all services
abstract class IPlatformCore {
  /// Initialize the platform
  Future<void> initialize();

  /// Shutdown the platform
  Future<void> shutdown();

  /// Switch between operation modes
  Future<void> switchMode(OperationMode mode);

  /// Get current operation mode
  OperationMode get currentMode;

  /// Get plugin manager instance
  IPluginManager get pluginManager;

  /// Get network manager instance
  INetworkManager get networkManager;

  /// Get state manager instance
  IStateManager get stateManager;

  /// Get platform services instance
  IPlatformServices get platformServices;

  /// Check if platform is initialized
  bool get isInitialized;

  /// Stream of platform events
  Stream<PlatformEvent> get eventStream;

  /// Get platform information
  PlatformInfo get platformInfo;
}
