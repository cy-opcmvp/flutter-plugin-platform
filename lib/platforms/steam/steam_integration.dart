import 'steam_integration_impl.dart';

/// Steam-specific integration interface
abstract class ISteamIntegration {
  /// Initialize Steam integration
  Future<void> initialize();
  
  /// Enable desktop pet mode
  Future<void> enableDesktopPetMode();
  
  /// Disable desktop pet mode
  Future<void> disableDesktopPetMode();
  
  /// Check if in desktop pet mode
  bool get isDesktopPetMode;
  
  /// Set window to always on top
  Future<void> setAlwaysOnTop(bool alwaysOnTop);
  
  /// Get Steam user information
  Future<SteamUserInfo?> getSteamUserInfo();
  
  /// Access Steam Workshop
  Future<void> openSteamWorkshop();
  
  /// Upload plugin to Steam Workshop
  Future<void> uploadToWorkshop(String pluginId);
  
  /// Download plugin from Steam Workshop
  Future<void> downloadFromWorkshop(String workshopId);
  
  /// Get Steam achievements
  Future<List<SteamAchievement>> getAchievements();
  
  /// Unlock achievement
  Future<void> unlockAchievement(String achievementId);
}

/// Steam user information
class SteamUserInfo {
  final String steamId;
  final String displayName;
  final String avatarUrl;

  const SteamUserInfo({
    required this.steamId,
    required this.displayName,
    required this.avatarUrl,
  });
}

/// Steam achievement
class SteamAchievement {
  final String id;
  final String name;
  final String description;
  final bool isUnlocked;

  const SteamAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.isUnlocked,
  });
}

/// Factory for creating Steam integration instances
class SteamIntegrationFactory {
  static ISteamIntegration create() {
    return SteamIntegrationImpl();
  }
}