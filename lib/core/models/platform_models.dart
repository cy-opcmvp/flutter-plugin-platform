import 'plugin_models.dart';

/// Events that can occur in the platform
abstract class PlatformEvent {
  final DateTime timestamp;

  const PlatformEvent({required this.timestamp});
}

/// Event fired when a plugin state changes
class PluginStateChangedEvent extends PlatformEvent {
  final String pluginId;
  final String oldState;
  final String newState;

  const PluginStateChangedEvent({
    required this.pluginId,
    required this.oldState,
    required this.newState,
    required super.timestamp,
  });
}

/// Event fired when network connectivity changes
class NetworkConnectivityEvent extends PlatformEvent {
  final bool isConnected;

  const NetworkConnectivityEvent({
    required this.isConnected,
    required super.timestamp,
  });
}

/// Event fired when operation mode changes
class OperationModeChangedEvent extends PlatformEvent {
  final OperationMode oldMode;
  final OperationMode newMode;

  const OperationModeChangedEvent({
    required this.oldMode,
    required this.newMode,
    required super.timestamp,
  });
}

/// User profile information
class UserProfile {
  final String userId;
  final String displayName;
  final Map<String, dynamic> preferences;
  final List<String> installedPlugins;
  final DateTime lastSyncTime;

  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.preferences,
    required this.installedPlugins,
    required this.lastSyncTime,
  });

  /// Validates the user profile for data integrity
  bool isValid() {
    // User ID must be non-empty
    if (userId.trim().isEmpty) {
      return false;
    }

    // Display name must be non-empty and reasonable length
    if (displayName.trim().isEmpty || displayName.length > 100) {
      return false;
    }

    // Installed plugins must have valid plugin IDs
    for (final pluginId in installedPlugins) {
      if (pluginId.isEmpty ||
          !RegExp(r'^[a-z0-9]+(\.[a-z0-9]+)*$').hasMatch(pluginId)) {
        return false;
      }
    }

    // Last sync time should not be in the future
    if (lastSyncTime.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return false;
    }

    return true;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      preferences: json['preferences'] as Map<String, dynamic>,
      installedPlugins: (json['installedPlugins'] as List<dynamic>)
          .cast<String>(),
      lastSyncTime: DateTime.parse(json['lastSyncTime'] as String),
    );

    if (!profile.isValid()) {
      throw ArgumentError('Invalid user profile data');
    }

    return profile;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'preferences': preferences,
      'installedPlugins': installedPlugins,
      'lastSyncTime': lastSyncTime.toIso8601String(),
    };
  }
}

/// Backend configuration
class BackendConfig {
  final String baseUrl;
  final String apiVersion;
  final Map<String, String> endpoints;
  final AuthenticationConfig auth;
  final int timeoutSeconds;

  const BackendConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.endpoints,
    required this.auth,
    required this.timeoutSeconds,
  });

  /// Validates the backend configuration for data integrity
  bool isValid() {
    // Base URL must be a valid URL
    try {
      final uri = Uri.parse(baseUrl);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
    } catch (e) {
      return false;
    }

    // API version must be non-empty
    if (apiVersion.trim().isEmpty) {
      return false;
    }

    // Timeout must be positive and reasonable (1-300 seconds)
    if (timeoutSeconds <= 0 || timeoutSeconds > 300) {
      return false;
    }

    // Endpoints must have valid URLs
    for (final endpoint in endpoints.values) {
      if (endpoint.trim().isEmpty) {
        return false;
      }
    }

    // Auth config must be valid
    if (!auth.isValid()) {
      return false;
    }

    return true;
  }

  factory BackendConfig.fromJson(Map<String, dynamic> json) {
    final config = BackendConfig(
      baseUrl: json['baseUrl'] as String,
      apiVersion: json['apiVersion'] as String,
      endpoints: Map<String, String>.from(json['endpoints'] as Map),
      auth: AuthenticationConfig.fromJson(json['auth'] as Map<String, dynamic>),
      timeoutSeconds: json['timeoutSeconds'] as int,
    );

    if (!config.isValid()) {
      throw ArgumentError('Invalid backend configuration data');
    }

    return config;
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiVersion': apiVersion,
      'endpoints': endpoints,
      'auth': auth.toJson(),
      'timeoutSeconds': timeoutSeconds,
    };
  }
}

/// Authentication configuration
class AuthenticationConfig {
  final String type;
  final Map<String, String> credentials;

  const AuthenticationConfig({required this.type, required this.credentials});

  /// Validates the authentication configuration for data integrity
  bool isValid() {
    // Type must be non-empty and one of supported types
    const supportedTypes = ['bearer', 'basic', 'apikey', 'oauth2', 'none'];
    if (type.trim().isEmpty || !supportedTypes.contains(type.toLowerCase())) {
      return false;
    }

    // Credentials validation based on type
    switch (type.toLowerCase()) {
      case 'bearer':
        return credentials.containsKey('token') &&
            credentials['token']!.isNotEmpty;
      case 'basic':
        return credentials.containsKey('username') &&
            credentials.containsKey('password') &&
            credentials['username']!.isNotEmpty;
      case 'apikey':
        return credentials.containsKey('key') && credentials['key']!.isNotEmpty;
      case 'oauth2':
        return credentials.containsKey('clientId') &&
            credentials['clientId']!.isNotEmpty;
      case 'none':
        return true;
      default:
        return false;
    }
  }

  factory AuthenticationConfig.fromJson(Map<String, dynamic> json) {
    final config = AuthenticationConfig(
      type: json['type'] as String,
      credentials: Map<String, String>.from(json['credentials'] as Map),
    );

    if (!config.isValid()) {
      throw ArgumentError('Invalid authentication configuration data');
    }

    return config;
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'credentials': credentials};
  }
}

/// Operation modes
enum OperationMode { local, online }

/// Plugin-specific events
class PluginEvent extends PlatformEvent {
  final PluginEventType type;
  final String pluginId;
  final Map<String, dynamic>? data;

  const PluginEvent({
    required this.type,
    required this.pluginId,
    required super.timestamp,
    this.data,
  });
}

/// Types of plugin events
enum PluginEventType {
  loaded,
  unloaded,
  registered,
  unregistered,
  installed,
  uninstalled,
  enabled,
  disabled,
  error,
  stateChanged,
  updateDetected,
  hotReloading,
  hotReloaded,
  rollback,
}

/// Event fired when a notification is shown
class NotificationEvent extends PlatformEvent {
  final String message;

  const NotificationEvent({required this.message, required super.timestamp});
}

/// Event fired when a permission is requested
class PermissionEvent extends PlatformEvent {
  final Permission permission;
  final bool granted;

  const PermissionEvent({
    required this.permission,
    required this.granted,
    required super.timestamp,
  });
}

/// Event fired when an external URL is opened
class UrlOpenedEvent extends PlatformEvent {
  final String url;

  const UrlOpenedEvent({required this.url, required super.timestamp});
}

/// Represents an environment variable with its value and availability status
class EnvironmentVariable {
  final String key;
  final String? value;
  final String defaultValue;
  final bool isAvailable;

  EnvironmentVariable({
    required this.key,
    this.value,
    required this.defaultValue,
  }) : isAvailable = value != null;

  /// Gets the effective value (actual value or default)
  String get effectiveValue => value ?? defaultValue;

  /// Serialization for debugging purposes
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'defaultValue': defaultValue,
      'isAvailable': isAvailable,
    };
  }

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      key: json['key'] as String,
      value: json['value'] as String?,
      defaultValue: json['defaultValue'] as String,
    );
  }

  @override
  String toString() {
    return 'EnvironmentVariable(key: $key, value: ${value ?? 'null'}, defaultValue: $defaultValue, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentVariable &&
        other.key == key &&
        other.value == value &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode => Object.hash(key, value, defaultValue);
}

/// Represents platform-specific capabilities
class PlatformCapabilities {
  final bool supportsEnvironmentVariables;
  final bool supportsFileSystem;
  final bool supportsSteamIntegration;
  final bool supportsNativeProcesses;
  final bool supportsDesktopPet;
  final bool supportsAlwaysOnTop;
  final bool supportsSystemTray;

  const PlatformCapabilities({
    required this.supportsEnvironmentVariables,
    required this.supportsFileSystem,
    required this.supportsSteamIntegration,
    required this.supportsNativeProcesses,
    required this.supportsDesktopPet,
    required this.supportsAlwaysOnTop,
    required this.supportsSystemTray,
  });

  /// Factory for web platform capabilities
  factory PlatformCapabilities.forWeb() {
    return const PlatformCapabilities(
      supportsEnvironmentVariables: false,
      supportsFileSystem: false,
      supportsSteamIntegration: false,
      supportsNativeProcesses: false,
      supportsDesktopPet: false,
      supportsAlwaysOnTop: false,
      supportsSystemTray: false,
    );
  }

  /// Factory for native platform capabilities
  factory PlatformCapabilities.forNative() {
    return const PlatformCapabilities(
      supportsEnvironmentVariables: true,
      supportsFileSystem: true,
      supportsSteamIntegration: true,
      supportsNativeProcesses: true,
      supportsDesktopPet: true,
      supportsAlwaysOnTop: true,
      supportsSystemTray: true,
    );
  }

  /// Serialization for debugging purposes
  Map<String, dynamic> toJson() {
    return {
      'supportsEnvironmentVariables': supportsEnvironmentVariables,
      'supportsFileSystem': supportsFileSystem,
      'supportsSteamIntegration': supportsSteamIntegration,
      'supportsNativeProcesses': supportsNativeProcesses,
      'supportsDesktopPet': supportsDesktopPet,
      'supportsAlwaysOnTop': supportsAlwaysOnTop,
      'supportsSystemTray': supportsSystemTray,
    };
  }

  factory PlatformCapabilities.fromJson(Map<String, dynamic> json) {
    return PlatformCapabilities(
      supportsEnvironmentVariables:
          json['supportsEnvironmentVariables'] as bool,
      supportsFileSystem: json['supportsFileSystem'] as bool,
      supportsSteamIntegration: json['supportsSteamIntegration'] as bool,
      supportsNativeProcesses: json['supportsNativeProcesses'] as bool,
      supportsDesktopPet: json['supportsDesktopPet'] as bool,
      supportsAlwaysOnTop: json['supportsAlwaysOnTop'] as bool,
      supportsSystemTray: json['supportsSystemTray'] as bool,
    );
  }

  @override
  String toString() {
    return 'PlatformCapabilities(envVars: $supportsEnvironmentVariables, fileSystem: $supportsFileSystem, steam: $supportsSteamIntegration, processes: $supportsNativeProcesses, desktopPet: $supportsDesktopPet, alwaysOnTop: $supportsAlwaysOnTop, systemTray: $supportsSystemTray)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformCapabilities &&
        other.supportsEnvironmentVariables == supportsEnvironmentVariables &&
        other.supportsFileSystem == supportsFileSystem &&
        other.supportsSteamIntegration == supportsSteamIntegration &&
        other.supportsNativeProcesses == supportsNativeProcesses &&
        other.supportsDesktopPet == supportsDesktopPet &&
        other.supportsAlwaysOnTop == supportsAlwaysOnTop &&
        other.supportsSystemTray == supportsSystemTray;
  }

  @override
  int get hashCode => Object.hash(
    supportsEnvironmentVariables,
    supportsFileSystem,
    supportsSteamIntegration,
    supportsNativeProcesses,
    supportsDesktopPet,
    supportsAlwaysOnTop,
    supportsSystemTray,
  );
}
