import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/platform_environment.dart';

/// Configuration for different platform builds
class PlatformConfig {
  static const String _steamAppId = 'YOUR_STEAM_APP_ID';
  static const String _mobileAppId = 'com.example.plugin_platform';

  /// Get current platform type
  static PlatformType get currentPlatform {
    if (kIsWeb) {
      return PlatformType.web;
    } else if (Platform.isAndroid || Platform.isIOS) {
      return PlatformType.mobile;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Check if running through Steam
      if (_isSteamEnvironment()) {
        return PlatformType.steam;
      }
      return PlatformType.desktop;
    }
    return PlatformType.unknown;
  }

  /// Check if running in Steam environment
  static bool _isSteamEnvironment() {
    // On web platform, Steam is never available
    if (kIsWeb) {
      return false;
    }

    // On mobile platforms, Steam is not available
    if (Platform.isAndroid || Platform.isIOS) {
      return false;
    }

    // Only check for Steam on desktop platforms
    // Check for Steam environment variables or Steam API availability
    final platformEnv = PlatformEnvironment.instance;
    return platformEnv.containsKey('STEAM_COMPAT_DATA_PATH') ||
        platformEnv.containsKey('SteamAppId');
  }

  /// Get platform-specific configuration
  static Map<String, dynamic> getPlatformConfig() {
    switch (currentPlatform) {
      case PlatformType.steam:
        return {
          'appId': _steamAppId,
          'enableDesktopPet': true,
          'enableWorkshop': true,
          'enableAchievements': true,
          'windowConfig': {
            'resizable': true,
            'minimumSize': {'width': 800, 'height': 600},
            'maximumSize': {'width': 1920, 'height': 1080},
          },
        };
      case PlatformType.mobile:
        return {
          'appId': _mobileAppId,
          'enableTouchGestures': true,
          'enableOrientationChanges': true,
          'enableMobileNotifications': true,
        };
      case PlatformType.desktop:
        return {
          'enableDesktopFeatures': true,
          'windowConfig': {
            'resizable': true,
            'minimumSize': {'width': 600, 'height': 400},
          },
        };
      default:
        return {};
    }
  }

  /// Get supported features for current platform
  static Set<String> getSupportedFeatures() {
    switch (currentPlatform) {
      case PlatformType.steam:
        return {
          'desktop_pet',
          'steam_workshop',
          'steam_achievements',
          'always_on_top',
          'system_tray',
          'file_system_access',
          'network_access',
        };
      case PlatformType.mobile:
        return {
          'touch_gestures',
          'device_orientation',
          'mobile_notifications',
          'camera_access',
          'location_access',
          'network_access',
        };
      case PlatformType.desktop:
        return {
          'file_system_access',
          'network_access',
          'desktop_notifications',
        };
      default:
        return {'network_access'};
    }
  }
}

/// Platform types
enum PlatformType { mobile, desktop, steam, web, unknown }
