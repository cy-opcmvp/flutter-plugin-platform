import 'dart:async';
import 'dart:convert';

import '../models/platform_models.dart';
import 'network_manager.dart';

/// Environment types for configuration
enum Environment { development, staging, production, testing }

/// Backend configuration manager with environment-specific settings
class BackendConfigManager {
  static const String _configPrefix = 'backend_config_';
  static const String _credentialsPrefix = 'credentials_';
  static const String _currentEnvKey = 'current_environment';

  final IStorage _storage;
  final StreamController<BackendConfig> _configController =
      StreamController<BackendConfig>.broadcast();

  Environment _currentEnvironment = Environment.development;
  BackendConfig? _currentConfig;
  final Map<Environment, BackendConfig> _environmentConfigs = {};

  BackendConfigManager({IStorage? storage})
    : _storage = storage ?? SharedPreferencesStorage();

  /// Get current environment
  Environment get currentEnvironment => _currentEnvironment;

  /// Get current configuration
  BackendConfig? get currentConfig => _currentConfig;

  /// Stream of configuration changes
  Stream<BackendConfig> get configStream => _configController.stream;

  /// Initialize the configuration manager
  Future<void> initialize() async {
    await _loadCurrentEnvironment();
    await _loadAllConfigurations();
    await _setEnvironment(_currentEnvironment);
  }

  /// Set configuration for a specific environment
  Future<void> setEnvironmentConfig(
    Environment environment,
    BackendConfig config,
  ) async {
    if (!config.isValid()) {
      throw ArgumentError('Invalid backend configuration provided');
    }

    _environmentConfigs[environment] = config;

    // Persist configuration
    final configKey = '$_configPrefix${environment.name}';
    await _storage.setString(configKey, jsonEncode(config.toJson()));

    // If this is the current environment, update current config
    if (environment == _currentEnvironment) {
      _currentConfig = config;
      _configController.add(config);
    }
  }

  /// Get configuration for a specific environment
  BackendConfig? getEnvironmentConfig(Environment environment) {
    return _environmentConfigs[environment];
  }

  /// Switch to a different environment
  Future<void> setEnvironment(Environment environment) async {
    await _setEnvironment(environment);

    // Persist current environment
    await _storage.setString(_currentEnvKey, environment.name);
  }

  /// Internal method to set environment
  Future<void> _setEnvironment(Environment environment) async {
    _currentEnvironment = environment;
    _currentConfig = _environmentConfigs[environment];

    if (_currentConfig != null) {
      _configController.add(_currentConfig!);
    }
  }

  /// Store secure credentials for authentication
  Future<void> storeCredentials(
    String key,
    Map<String, String> credentials,
  ) async {
    // Encrypt credentials before storing
    final encryptedCredentials = _encryptCredentials(credentials);
    final credentialsKey = '$_credentialsPrefix$key';
    await _storage.setString(credentialsKey, jsonEncode(encryptedCredentials));
  }

  /// Retrieve secure credentials
  Future<Map<String, String>?> getCredentials(String key) async {
    final credentialsKey = '$_credentialsPrefix$key';
    final credentialsJson = await _storage.getString(credentialsKey);

    if (credentialsJson == null) {
      return null;
    }

    try {
      final encryptedCredentials =
          jsonDecode(credentialsJson) as Map<String, dynamic>;
      return _decryptCredentials(encryptedCredentials.cast<String, String>());
    } catch (e) {
      return null;
    }
  }

  /// Remove stored credentials
  Future<void> removeCredentials(String key) async {
    final credentialsKey = '$_credentialsPrefix$key';
    await _storage.remove(credentialsKey);
  }

  /// Hot update configuration without restart
  Future<void> hotUpdateConfig(BackendConfig newConfig) async {
    if (!newConfig.isValid()) {
      throw ArgumentError('Invalid backend configuration provided');
    }

    // Update current environment configuration
    await setEnvironmentConfig(_currentEnvironment, newConfig);

    // The configuration change will be automatically propagated through the stream
  }

  /// Get all available environments
  List<Environment> getAvailableEnvironments() {
    return _environmentConfigs.keys.toList();
  }

  /// Check if environment has configuration
  bool hasEnvironmentConfig(Environment environment) {
    return _environmentConfigs.containsKey(environment);
  }

  /// Create default configuration for an environment
  BackendConfig createDefaultConfig(Environment environment) {
    switch (environment) {
      case Environment.development:
        return BackendConfig(
          baseUrl: 'http://localhost:3000',
          apiVersion: 'v1',
          endpoints: {
            'auth': '/auth',
            'users': '/users',
            'plugins': '/plugins',
            'data': '/data',
            'sync': '/sync',
            'health': '/health',
          },
          auth: const AuthenticationConfig(type: 'none', credentials: {}),
          timeoutSeconds: 30,
        );
      case Environment.staging:
        return BackendConfig(
          baseUrl: 'https://staging-api.example.com',
          apiVersion: 'v1',
          endpoints: {
            'auth': '/auth',
            'users': '/users',
            'plugins': '/plugins',
            'data': '/data',
            'sync': '/sync',
            'health': '/health',
          },
          auth: const AuthenticationConfig(
            type: 'bearer',
            credentials: {'token': 'staging-token'},
          ),
          timeoutSeconds: 60,
        );
      case Environment.production:
        return BackendConfig(
          baseUrl: 'https://api.example.com',
          apiVersion: 'v1',
          endpoints: {
            'auth': '/auth',
            'users': '/users',
            'plugins': '/plugins',
            'data': '/data',
            'sync': '/sync',
            'health': '/health',
          },
          auth: const AuthenticationConfig(
            type: 'bearer',
            credentials: {'token': 'production-token'},
          ),
          timeoutSeconds: 30,
        );
      case Environment.testing:
        return BackendConfig(
          baseUrl: 'https://test-api.example.com',
          apiVersion: 'v1',
          endpoints: {
            'auth': '/auth',
            'users': '/users',
            'plugins': '/plugins',
            'data': '/data',
            'sync': '/sync',
            'health': '/health',
          },
          auth: const AuthenticationConfig(type: 'none', credentials: {}),
          timeoutSeconds: 10,
        );
    }
  }

  /// Load current environment from storage
  Future<void> _loadCurrentEnvironment() async {
    final envName = await _storage.getString(_currentEnvKey);
    if (envName != null) {
      try {
        _currentEnvironment = Environment.values.firstWhere(
          (env) => env.name == envName,
          orElse: () => Environment.development,
        );
      } catch (e) {
        _currentEnvironment = Environment.development;
      }
    }
  }

  /// Load all environment configurations from storage
  Future<void> _loadAllConfigurations() async {
    for (final environment in Environment.values) {
      final configKey = '$_configPrefix${environment.name}';
      final configJson = await _storage.getString(configKey);

      if (configJson != null) {
        try {
          final configData = jsonDecode(configJson) as Map<String, dynamic>;
          final config = BackendConfig.fromJson(configData);
          _environmentConfigs[environment] = config;
        } catch (e) {
          // Invalid stored configuration, create default
          _environmentConfigs[environment] = createDefaultConfig(environment);
        }
      } else {
        // No stored configuration, create default
        _environmentConfigs[environment] = createDefaultConfig(environment);
      }
    }
  }

  /// Simple encryption for credentials (in production, use proper encryption)
  Map<String, String> _encryptCredentials(Map<String, String> credentials) {
    final encrypted = <String, String>{};

    for (final entry in credentials.entries) {
      // Simple base64 encoding (in production, use proper encryption like AES)
      final bytes = utf8.encode(entry.value);
      encrypted[entry.key] = base64Encode(bytes);
    }

    return encrypted;
  }

  /// Simple decryption for credentials
  Map<String, String> _decryptCredentials(
    Map<String, String> encryptedCredentials,
  ) {
    final decrypted = <String, String>{};

    for (final entry in encryptedCredentials.entries) {
      try {
        // Simple base64 decoding
        final bytes = base64Decode(entry.value);
        decrypted[entry.key] = utf8.decode(bytes);
      } catch (e) {
        // If decryption fails, skip this credential
        continue;
      }
    }

    return decrypted;
  }

  /// Validate configuration interface
  bool validateConfigInterface(BackendConfig config) {
    // Check if configuration provides all required interfaces
    final requiredEndpoints = [
      'auth',
      'users',
      'plugins',
      'data',
      'sync',
      'health',
    ];

    for (final endpoint in requiredEndpoints) {
      if (!config.endpoints.containsKey(endpoint)) {
        return false;
      }
    }

    return config.isValid();
  }

  /// Export configuration for backup
  Future<Map<String, dynamic>> exportConfiguration() async {
    final export = <String, dynamic>{
      'currentEnvironment': _currentEnvironment.name,
      'configurations': <String, dynamic>{},
    };

    for (final entry in _environmentConfigs.entries) {
      export['configurations'][entry.key.name] = entry.value.toJson();
    }

    return export;
  }

  /// Import configuration from backup
  Future<void> importConfiguration(Map<String, dynamic> configData) async {
    try {
      // Import environment configurations
      final configurations =
          configData['configurations'] as Map<String, dynamic>;

      for (final entry in configurations.entries) {
        final environment = Environment.values.firstWhere(
          (env) => env.name == entry.key,
          orElse: () => Environment.development,
        );

        final config = BackendConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
        await setEnvironmentConfig(environment, config);
      }

      // Set current environment
      final currentEnvName = configData['currentEnvironment'] as String?;
      if (currentEnvName != null) {
        final environment = Environment.values.firstWhere(
          (env) => env.name == currentEnvName,
          orElse: () => Environment.development,
        );
        await setEnvironment(environment);
      }
    } catch (e) {
      throw Exception('Failed to import configuration: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _configController.close();
  }
}
