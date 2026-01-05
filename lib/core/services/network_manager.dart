import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interfaces/i_network_manager.dart';
import '../models/platform_models.dart';

/// Abstract storage interface for testing
abstract class IStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
}

/// Production storage implementation
class SharedPreferencesStorage implements IStorage {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// Mock storage for testing
class MockStorage implements IStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}

/// Abstract connectivity interface for testing
abstract class IConnectivity {
  Future<ConnectivityResult> checkConnectivity();
  Stream<ConnectivityResult> get onConnectivityChanged;
}

/// Production connectivity implementation
class ConnectivityWrapper implements IConnectivity {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<ConnectivityResult> checkConnectivity() => _connectivity.checkConnectivity();

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _connectivity.onConnectivityChanged;
}

/// Mock connectivity for testing
class MockConnectivity implements IConnectivity {
  ConnectivityResult _currentResult = ConnectivityResult.wifi;
  final StreamController<ConnectivityResult> _controller = StreamController<ConnectivityResult>.broadcast();

  @override
  Future<ConnectivityResult> checkConnectivity() async => _currentResult;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  void setConnectivity(ConnectivityResult result) {
    _currentResult = result;
    _controller.add(result);
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementation of network management and API communications
class NetworkManager implements INetworkManager {
  static const String _configKey = 'backend_config';
  static const String _userDataKey = 'user_data';
  static const String _pluginDataPrefix = 'plugin_data_';
  
  BackendConfig? _currentConfig;
  bool _isOnline = false;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  late final IConnectivity _connectivity;
  late final IStorage _storage;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Map<String, String> _monitoredRequests = {};
  
  NetworkManager({IConnectivity? connectivity, IStorage? storage}) {
    _connectivity = connectivity ?? ConnectivityWrapper();
    _storage = storage ?? SharedPreferencesStorage();
  }

  @override
  BackendConfig? get currentConfig => _currentConfig;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          // Handle connectivity stream errors gracefully
          _isOnline = false;
          if (!_connectivityController.isClosed) {
            _connectivityController.add(false);
          }
        },
      );
    } catch (e) {
      _isOnline = false;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(false);
      }
    }
  }

  /// Update connectivity status based on connectivity result
  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result == ConnectivityResult.wifi || 
                result == ConnectivityResult.mobile ||
                result == ConnectivityResult.ethernet;
    
    if (wasOnline != _isOnline && !_connectivityController.isClosed) {
      _connectivityController.add(_isOnline);
    }
  }

  @override
  Future<void> configureEndpoints(BackendConfig config) async {
    if (!config.isValid()) {
      throw ArgumentError('Invalid backend configuration provided');
    }
    
    _currentConfig = config;
    
    // Persist configuration
    await _storage.setString(_configKey, jsonEncode(config.toJson()));
    
    // Validate connectivity with new configuration
    await validateConnection();
  }

  @override
  Future<bool> validateConnection() async {
    if (_currentConfig == null) {
      return false;
    }
    
    if (!_isOnline) {
      return false;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_currentConfig!.baseUrl}/health'),
        headers: _buildAuthHeaders(),
      ).timeout(Duration(seconds: _currentConfig!.timeoutSeconds));
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> syncUserData() async {
    if (!_isOnline || _currentConfig == null) {
      throw Exception('Cannot sync user data: offline or not configured');
    }
    
    try {
      final localUserData = await _storage.getString(_userDataKey);
      
      if (localUserData != null) {
        // Upload local data to cloud
        await uploadData(_userDataKey, jsonDecode(localUserData));
      }
      
      // Download latest data from cloud
      final cloudData = await downloadData(_userDataKey);
      if (cloudData != null) {
        await _storage.setString(_userDataKey, jsonEncode(cloudData));
      }
    } catch (e) {
      throw Exception('Failed to sync user data: $e');
    }
  }

  @override
  Future<void> handleOfflineMode() async {
    // Clear any pending network operations
    _monitoredRequests.clear();
    
    // Ensure local data is available
    final hasLocalData = await _storage.containsKey(_userDataKey);
    
    if (!hasLocalData) {
      // Initialize with default local data
      final defaultUserData = {
        'userId': 'local_user',
        'displayName': 'Local User',
        'preferences': <String, dynamic>{},
        'installedPlugins': <String>[],
        'lastSyncTime': DateTime.now().toIso8601String(),
      };
      await _storage.setString(_userDataKey, jsonEncode(defaultUserData));
    }
  }

  @override
  Future<Map<String, dynamic>> apiRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (_currentConfig == null) {
      throw Exception('Network manager not configured');
    }
    
    if (!_isOnline) {
      throw Exception('No network connectivity');
    }
    
    final url = Uri.parse('${_currentConfig!.baseUrl}${_currentConfig!.endpoints[endpoint] ?? endpoint}');
    final requestId = '${method}_${url.toString()}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Monitor this request
    _monitoredRequests[requestId] = '${method} ${url}';
    
    try {
      final requestHeaders = {
        'Content-Type': 'application/json',
        ..._buildAuthHeaders(),
        ...?headers,
      };
      
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders)
              .timeout(Duration(seconds: _currentConfig!.timeoutSeconds));
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: _currentConfig!.timeoutSeconds));
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: _currentConfig!.timeoutSeconds));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders)
              .timeout(Duration(seconds: _currentConfig!.timeoutSeconds));
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw HttpException('API request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    } finally {
      _monitoredRequests.remove(requestId);
    }
  }

  @override
  Future<void> uploadData(String key, Map<String, dynamic> data) async {
    await apiRequest('/data/$key', method: 'PUT', body: data);
  }

  @override
  Future<Map<String, dynamic>?> downloadData(String key) async {
    try {
      return await apiRequest('/data/$key', method: 'GET');
    } catch (e) {
      // Return null if data doesn't exist
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> syncPluginData(String pluginId, Map<String, dynamic> data) async {
    if (!_isOnline || _currentConfig == null) {
      // Store locally for later sync
      await _storage.setString('$_pluginDataPrefix$pluginId', jsonEncode(data));
      return;
    }
    
    try {
      await uploadData('plugin_$pluginId', data);
      
      // Clear local cache after successful sync
      await _storage.remove('$_pluginDataPrefix$pluginId');
    } catch (e) {
      // Fall back to local storage
      await _storage.setString('$_pluginDataPrefix$pluginId', jsonEncode(data));
      throw Exception('Failed to sync plugin data, stored locally: $e');
    }
  }

  /// Build authentication headers based on current configuration
  Map<String, String> _buildAuthHeaders() {
    if (_currentConfig?.auth == null) {
      return {};
    }
    
    final auth = _currentConfig!.auth;
    switch (auth.type.toLowerCase()) {
      case 'bearer':
        return {'Authorization': 'Bearer ${auth.credentials['token']}'};
      case 'basic':
        final credentials = base64Encode(
          utf8.encode('${auth.credentials['username']}:${auth.credentials['password']}')
        );
        return {'Authorization': 'Basic $credentials'};
      case 'apikey':
        return {'X-API-Key': auth.credentials['key']!};
      case 'oauth2':
        // For OAuth2, assume token is stored in credentials
        return {'Authorization': 'Bearer ${auth.credentials['accessToken']}'};
      default:
        return {};
    }
  }

  /// Get list of currently monitored network requests
  Map<String, String> getMonitoredRequests() {
    return Map.from(_monitoredRequests);
  }

  /// Load configuration from persistent storage
  Future<void> loadConfiguration() async {
    final configJson = await _storage.getString(_configKey);
    
    if (configJson != null) {
      try {
        final configData = jsonDecode(configJson) as Map<String, dynamic>;
        _currentConfig = BackendConfig.fromJson(configData);
      } catch (e) {
        // Invalid stored configuration, ignore
        _currentConfig = null;
      }
    }
  }

  /// Initialize the network manager
  Future<void> initialize() async {
    // Only load configuration if not using mock storage
    if (_storage is! MockStorage) {
      await loadConfiguration();
    }
    await _initializeConnectivity();
  }

  /// Shutdown the network manager
  Future<void> shutdown() async {
    dispose();
  }

  /// Set offline mode
  Future<void> setOfflineMode(bool offline) async {
    _isOnline = !offline;
    if (offline) {
      await handleOfflineMode();
    }
    // Emit connectivity change event
    if (!_connectivityController.isClosed) {
      _connectivityController.add(_isOnline);
    }
  }

  /// Check if connected to network
  Future<bool> isConnected() async {
    return _isOnline;
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}