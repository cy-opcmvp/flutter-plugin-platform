import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'steam_integration.dart';

/// Concrete implementation of Steam integration
class SteamIntegrationImpl implements ISteamIntegration {
  static const MethodChannel _channel = MethodChannel('steam_integration');
  
  bool _isInitialized = false;
  bool _isDesktopPetMode = false;
  bool _isAlwaysOnTop = false;
  
  // Desktop pet preferences
  Map<String, dynamic> _petPreferences = {
    'position': {'x': 100.0, 'y': 100.0},
    'size': {'width': 200.0, 'height': 200.0},
    'opacity': 1.0,
    'animations_enabled': true,
    'interactions_enabled': true,
    'auto_hide': false,
  };

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Steam API if available
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;
      
      // Load user preferences for desktop pet
      await _loadPetPreferences();
    } catch (e) {
      // Fallback for non-Steam environments
      _isInitialized = true;
    }
  }

  @override
  Future<void> enableDesktopPetMode() async {
    if (!_isInitialized) await initialize();
    
    try {
      // Enable desktop pet mode
      await _channel.invokeMethod('enableDesktopPetMode', {
        'position': _petPreferences['position'],
        'size': _petPreferences['size'],
        'opacity': _petPreferences['opacity'],
      });
      
      _isDesktopPetMode = true;
      
      // Set always on top if enabled in preferences
      if (_petPreferences['always_on_top'] == true) {
        await setAlwaysOnTop(true);
      }
      
      // Start interactive behaviors if enabled
      if (_petPreferences['interactions_enabled'] == true) {
        await _startInteractiveBehaviors();
      }
      
    } catch (e) {
      // Fallback implementation for testing/development
      _isDesktopPetMode = true;
    }
  }

  @override
  Future<void> disableDesktopPetMode() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('disableDesktopPetMode');
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
      
      // Stop interactive behaviors
      await _stopInteractiveBehaviors();
      
    } catch (e) {
      // Fallback implementation
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
    }
  }

  @override
  bool get isDesktopPetMode => _isDesktopPetMode;

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('setAlwaysOnTop', {'alwaysOnTop': alwaysOnTop});
      _isAlwaysOnTop = alwaysOnTop;
      
      // Update preferences
      _petPreferences['always_on_top'] = alwaysOnTop;
      await _savePetPreferences();
      
    } catch (e) {
      // Fallback implementation
      _isAlwaysOnTop = alwaysOnTop;
    }
  }

  @override
  Future<SteamUserInfo?> getSteamUserInfo() async {
    if (!_isInitialized) return null;
    
    try {
      final result = await _channel.invokeMethod('getSteamUserInfo');
      if (result != null) {
        return SteamUserInfo(
          steamId: result['steamId'] ?? '',
          displayName: result['displayName'] ?? 'Unknown',
          avatarUrl: result['avatarUrl'] ?? '',
        );
      }
    } catch (e) {
      // Return null if Steam is not available
    }
    
    return null;
  }

  @override
  Future<void> openSteamWorkshop() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('openSteamWorkshop');
    } catch (e) {
      // Fallback: open Steam Workshop in browser
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await Process.run('open', ['https://steamcommunity.com/workshop/']);
      }
    }
  }

  @override
  Future<void> uploadToWorkshop(String pluginId) async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('uploadToWorkshop', {
        'pluginId': pluginId,
      });
    } catch (e) {
      throw Exception('Failed to upload plugin to Steam Workshop: $e');
    }
  }

  @override
  Future<void> downloadFromWorkshop(String workshopId) async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('downloadFromWorkshop', {
        'workshopId': workshopId,
      });
    } catch (e) {
      throw Exception('Failed to download plugin from Steam Workshop: $e');
    }
  }

  @override
  Future<List<SteamAchievement>> getAchievements() async {
    if (!_isInitialized) return [];
    
    try {
      final result = await _channel.invokeMethod('getAchievements');
      if (result is List) {
        return result.map((achievement) => SteamAchievement(
          id: achievement['id'] ?? '',
          name: achievement['name'] ?? '',
          description: achievement['description'] ?? '',
          isUnlocked: achievement['isUnlocked'] ?? false,
        )).toList();
      }
    } catch (e) {
      // Return empty list if Steam is not available
    }
    
    return [];
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('unlockAchievement', {
        'achievementId': achievementId,
      });
    } catch (e) {
      // Silently fail if Steam is not available
    }
  }

  // Desktop pet preference management
  Future<void> updatePetPreferences(Map<String, dynamic> preferences) async {
    _petPreferences.addAll(preferences);
    await _savePetPreferences();
    
    // Apply changes if in desktop pet mode
    if (_isDesktopPetMode) {
      await _applyPetPreferences();
    }
  }

  Map<String, dynamic> getPetPreferences() {
    return Map<String, dynamic>.from(_petPreferences);
  }

  Future<void> _loadPetPreferences() async {
    try {
      // In a real implementation, this would load from persistent storage
      // For now, we'll use default preferences
    } catch (e) {
      // Use default preferences if loading fails
    }
  }

  Future<void> _savePetPreferences() async {
    try {
      // In a real implementation, this would save to persistent storage
      // For now, we'll just keep them in memory
    } catch (e) {
      // Silently fail if saving fails
    }
  }

  Future<void> _applyPetPreferences() async {
    if (!_isDesktopPetMode) return;
    
    try {
      await _channel.invokeMethod('updatePetAppearance', {
        'position': _petPreferences['position'],
        'size': _petPreferences['size'],
        'opacity': _petPreferences['opacity'],
      });
      
      // Update always on top setting
      if (_petPreferences['always_on_top'] != _isAlwaysOnTop) {
        await setAlwaysOnTop(_petPreferences['always_on_top'] ?? false);
      }
      
    } catch (e) {
      // Silently fail if platform channel is not available
    }
  }

  Future<void> _startInteractiveBehaviors() async {
    if (!_petPreferences['interactions_enabled']) return;
    
    try {
      await _channel.invokeMethod('startInteractiveBehaviors', {
        'animations_enabled': _petPreferences['animations_enabled'],
      });
    } catch (e) {
      // Silently fail if platform channel is not available
    }
  }

  Future<void> _stopInteractiveBehaviors() async {
    try {
      await _channel.invokeMethod('stopInteractiveBehaviors');
    } catch (e) {
      // Silently fail if platform channel is not available
    }
  }

  // Smooth transition between modes
  Future<void> transitionToDesktopPet() async {
    if (_isDesktopPetMode) return;
    
    try {
      // Animate transition to desktop pet mode
      await _channel.invokeMethod('transitionToDesktopPet', {
        'duration': 500, // milliseconds
        'target_position': _petPreferences['position'],
        'target_size': _petPreferences['size'],
      });
      
      _isDesktopPetMode = true;
      
    } catch (e) {
      // Fallback to instant transition
      await enableDesktopPetMode();
    }
  }

  Future<void> transitionToFullApplication() async {
    if (!_isDesktopPetMode) return;
    
    try {
      // Animate transition to full application mode
      await _channel.invokeMethod('transitionToFullApplication', {
        'duration': 500, // milliseconds
      });
      
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
      
    } catch (e) {
      // Fallback to instant transition
      await disableDesktopPetMode();
    }
  }
}