import '../models/platform_models.dart';

/// Interface for network management and API communications
abstract class INetworkManager {
  /// Initialize the network manager
  Future<void> initialize();

  /// Shutdown the network manager
  Future<void> shutdown();

  /// Configure API endpoints
  Future<void> configureEndpoints(BackendConfig config);

  /// Synchronize user data across devices
  Future<void> syncUserData();

  /// Validate network connectivity
  Future<bool> validateConnection();

  /// Handle offline mode operations
  Future<void> handleOfflineMode();

  /// Set offline mode
  Future<void> setOfflineMode(bool offline);

  /// Check if connected to network
  Future<bool> isConnected();

  /// Get current backend configuration
  BackendConfig? get currentConfig;

  /// Check if currently online
  bool get isOnline;

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream;

  /// Make authenticated API request
  Future<Map<String, dynamic>> apiRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });

  /// Upload data to cloud storage
  Future<void> uploadData(String key, Map<String, dynamic> data);

  /// Download data from cloud storage
  Future<Map<String, dynamic>?> downloadData(String key);

  /// Sync plugin data
  Future<void> syncPluginData(String pluginId, Map<String, dynamic> data);
}
