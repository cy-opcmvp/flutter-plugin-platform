import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_logger.dart';

/// Platform-aware environment variable access service.
/// Provides unified API for environment access across web and native platforms.
/// On web, returns safe defaults; on native platforms, accesses actual environment variables.
class PlatformEnvironment {
  // Singleton instance
  static final PlatformEnvironment instance = PlatformEnvironment._();

  // Private constructor for singleton
  PlatformEnvironment._() {
    // Log platform detection on initialization
    _logger.logPlatformDetection(isWeb ? 'Web' : 'Native', {
      'supportsEnvironmentVariables': !isWeb,
      'supportsFileSystem': !isWeb,
    });
  }

  // Logger instance
  final PlatformLogger _logger = PlatformLogger.instance;

  // Cache for environment variable lookups
  final Map<String, String?> _cache = {};

  /// Check if running on web platform
  bool get isWeb => kIsWeb;

  /// Get environment variable with optional default value.
  /// On web platform, returns defaultValue or null.
  /// On native platforms, returns actual environment variable value or defaultValue.
  String? getVariable(String key, {String? defaultValue}) {
    // Check cache first
    if (_cache.containsKey(key)) {
      final cachedValue = _cache[key] ?? defaultValue;
      _logger.logEnvironmentAccess(key, _cache[key] != null, cachedValue);
      return cachedValue;
    }

    // On web, return default value without accessing Platform.environment
    if (isWeb) {
      _cache[key] = null;
      _logger.logEnvironmentAccess(key, false, defaultValue);
      if (defaultValue == null) {
        _logger.logFeatureDegradation(
          'Environment variable: $key',
          'Web platform does not support environment variables',
        );
      }
      return defaultValue;
    }

    // On native platforms, access actual environment variables
    try {
      final value = Platform.environment[key];
      _cache[key] = value;
      _logger.logEnvironmentAccess(key, value != null, value ?? defaultValue);
      return value ?? defaultValue;
    } catch (e) {
      // If access fails, cache null and return default
      _logger.logError('getVariable($key)', e);
      _cache[key] = null;
      return defaultValue;
    }
  }

  /// Get all environment variables.
  /// Returns empty map on web platform.
  /// Returns actual environment variables on native platforms.
  Map<String, String> getAllVariables() {
    if (isWeb) {
      _logger.logFeatureDegradation(
        'getAllVariables',
        'Web platform does not support environment variables',
      );
      return {};
    }

    try {
      final variables = Map<String, String>.from(Platform.environment);
      _logger.logDebug('Retrieved ${variables.length} environment variables');
      return variables;
    } catch (e) {
      _logger.logError('getAllVariables', e);
      return {};
    }
  }

  /// Check if environment variable exists.
  /// Always returns false on web platform.
  /// On native platforms, checks actual environment.
  bool containsKey(String key) {
    if (isWeb) {
      return false;
    }

    try {
      return Platform.environment.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Clear the cache (useful for testing)
  void clearCache() {
    _cache.clear();
  }

  /// Get home directory path.
  /// On web platform, returns '/home' as a browser-appropriate value.
  /// On native platforms, derives from HOME, USERPROFILE, or uses fallback.
  String getHomePath() {
    if (isWeb) {
      _logger.logFeatureDegradation(
        'getHomePath',
        'Web platform uses browser-appropriate default path',
      );
      return '/home';
    }

    try {
      // Try HOME first (Unix-like systems)
      final home = getVariable('HOME');
      if (home != null && home.isNotEmpty) {
        return home;
      }

      // Try USERPROFILE (Windows)
      final userProfile = getVariable('USERPROFILE');
      if (userProfile != null && userProfile.isNotEmpty) {
        return userProfile;
      }

      // Fallback based on platform
      String fallbackPath;
      if (Platform.isWindows) {
        fallbackPath = 'C:\\Users\\Default';
      } else if (Platform.isMacOS) {
        fallbackPath = '/Users/default';
      } else {
        fallbackPath = '/home/default';
      }

      _logger.logWarning('Using fallback home path: $fallbackPath');
      return fallbackPath;
    } catch (e) {
      // If all fails, return safe default
      _logger.logError('getHomePath', e);
      return '/home/default';
    }
  }

  /// Get documents directory path.
  /// On web platform, returns '/documents' as a browser-appropriate value.
  /// On native platforms, derives from home path with fallback.
  String getDocumentsPath() {
    if (isWeb) {
      _logger.logFeatureDegradation(
        'getDocumentsPath',
        'Web platform uses browser-appropriate default path',
      );
      return '/documents';
    }

    try {
      final home = getHomePath();

      if (Platform.isWindows) {
        return '$home\\Documents';
      } else {
        return '$home/Documents';
      }
    } catch (e) {
      _logger.logError('getDocumentsPath', e);
      return '/documents';
    }
  }

  /// Get temporary directory path.
  /// On web platform, returns '/tmp' as a browser-appropriate value.
  /// On native platforms, derives from TEMP, TMP, TMPDIR, or uses fallback.
  String getTempPath() {
    if (isWeb) {
      _logger.logFeatureDegradation(
        'getTempPath',
        'Web platform uses browser-appropriate default path',
      );
      return '/tmp';
    }

    try {
      // Try TEMP (Windows)
      final temp = getVariable('TEMP');
      if (temp != null && temp.isNotEmpty) {
        return temp;
      }

      // Try TMP (Windows alternative)
      final tmp = getVariable('TMP');
      if (tmp != null && tmp.isNotEmpty) {
        return tmp;
      }

      // Try TMPDIR (Unix-like systems)
      final tmpdir = getVariable('TMPDIR');
      if (tmpdir != null && tmpdir.isNotEmpty) {
        return tmpdir;
      }

      // Fallback based on platform
      String fallbackPath;
      if (Platform.isWindows) {
        fallbackPath = 'C:\\Windows\\Temp';
      } else if (Platform.isMacOS) {
        fallbackPath = '/tmp';
      } else {
        fallbackPath = '/tmp';
      }

      _logger.logWarning('Using fallback temp path: $fallbackPath');
      return fallbackPath;
    } catch (e) {
      _logger.logError('getTempPath', e);
      return '/tmp';
    }
  }

  /// Get application data directory path.
  /// On web platform, returns '/appdata' as a browser-appropriate value.
  /// On native platforms, derives from APPDATA, XDG_CONFIG_HOME, or uses fallback.
  String getAppDataPath() {
    if (isWeb) {
      _logger.logFeatureDegradation(
        'getAppDataPath',
        'Web platform uses browser-appropriate default path',
      );
      return '/appdata';
    }

    try {
      // Try APPDATA (Windows)
      final appData = getVariable('APPDATA');
      if (appData != null && appData.isNotEmpty) {
        return appData;
      }

      // Try XDG_CONFIG_HOME (Linux)
      final xdgConfig = getVariable('XDG_CONFIG_HOME');
      if (xdgConfig != null && xdgConfig.isNotEmpty) {
        return xdgConfig;
      }

      // Fallback based on platform
      final home = getHomePath();

      String fallbackPath;
      if (Platform.isWindows) {
        fallbackPath = '$home\\AppData\\Roaming';
      } else if (Platform.isMacOS) {
        fallbackPath = '$home/Library/Application Support';
      } else {
        fallbackPath = '$home/.config';
      }

      _logger.logWarning('Using fallback app data path: $fallbackPath');
      return fallbackPath;
    } catch (e) {
      _logger.logError('getAppDataPath', e);
      return '/appdata';
    }
  }
}
