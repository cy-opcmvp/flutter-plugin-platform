/// Audio Service Implementation
///
/// Cross-platform audio playback service using just_audio
/// and fallback to SystemSound for Windows.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    as flutter_services; // For SystemSound on Windows
import 'package:just_audio/just_audio.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart'
    as platform;
import 'package:plugin_platform/core/services/disposable.dart';

/// Audio service implementation
class AudioServiceImpl extends platform.IAudioService implements Disposable {
  final Map<String, dynamic> _players =
      {}; // Use dynamic for platform-specific players
  final Map<platform.SystemSoundType, String> _systemSoundPaths = {
    platform.SystemSoundType.notification: 'assets/audio/notification.mp3',
    platform.SystemSoundType.alarm: 'assets/audio/alarm.mp3',
    platform.SystemSoundType.click: 'assets/audio/click.mp3',
    platform.SystemSoundType.success: 'assets/audio/success.mp3',
    platform.SystemSoundType.error: 'assets/audio/error.mp3',
    platform.SystemSoundType.warning: 'assets/audio/warning.mp3',
  };

  // Windows system sound mapping
  // Note: Flutter's SystemSoundType only has: click and alert
  // Since click often has no sound on Windows, we use alert for most sounds
  // but vary the pattern to make them distinguishable
  final Map<platform.SystemSoundType, List<flutter_services.SystemSoundType>>
  _windowsSystemSounds = {
    platform.SystemSoundType.notification: [
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.click,
    ],
    platform.SystemSoundType.click: [
      flutter_services.SystemSoundType.click,
      flutter_services.SystemSoundType.alert,
    ],
    platform.SystemSoundType.alarm: [
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.click,
    ],
    platform.SystemSoundType.success: [
      flutter_services.SystemSoundType.click,
      flutter_services.SystemSoundType.alert,
    ],
    platform.SystemSoundType.error: [
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.click,
    ],
    platform.SystemSoundType.warning: [
      flutter_services.SystemSoundType.alert,
      flutter_services.SystemSoundType.click,
      flutter_services.SystemSoundType.alert,
    ],
  };

  double _globalVolume = 1.0;
  bool _isInitialized = false;
  bool _useJustAudio = true; // Flag to determine which audio system to use

  @override
  bool get isInitialized => _isInitialized;

  /// Initialize the audio service
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Windows platform: just_audio not supported, use SystemSound instead
      if (defaultTargetPlatform == TargetPlatform.windows) {
        _useJustAudio = false;
        _isInitialized = true;

        if (kDebugMode) {
          debugPrint(
            'AudioService: Windows platform detected - using SystemSound',
          );
        }

        return true;
      }

      // Other platforms: Use just_audio
      try {
        // Pre-warm the audio system by creating one player
        final player = AudioPlayer();
        await player.setVolume(_globalVolume);
        _players['_warmup'] = player;

        _isInitialized = true;

        if (kDebugMode) {
          debugPrint(
            'AudioService: Initialized successfully (using just_audio)',
          );
        }

        return true;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: just_audio initialization failed: $e');
          debugPrint('AudioService: Falling back to SystemSound');
        }
        // Fallback to SystemSound
        _useJustAudio = false;
        _isInitialized = true;
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AudioService: Initialization failed: $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Play a short sound effect
  @override
  Future<void> playSound({
    required String soundPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    // Windows platform: Limited support - use SystemSound for notification-like sounds
    if (!_useJustAudio) {
      if (kDebugMode) {
        debugPrint(
          'AudioService: [Windows] Custom sound playback not supported, using SystemSound instead',
        );
      }
      // Fallback to system click sound
      flutter_services.SystemSound.play(flutter_services.SystemSoundType.click);
      return;
    }

    // Other platforms: Use just_audio
    try {
      final player = await _getPlayer();
      final adjustedVolume = (volume * _globalVolume).clamp(0.0, 1.0);

      // Determine if it's an asset or URL
      if (soundPath.startsWith('http')) {
        await player.setUrl(soundPath);
      } else {
        await player.setAsset(soundPath);
      }

      await player.setVolume(adjustedVolume);

      if (loop) {
        await player.setLoopMode(LoopMode.one);
      }

      await player.play();

      if (kDebugMode) {
        debugPrint('AudioService: Playing sound $soundPath (loop: $loop)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AudioService: Error playing sound: $e');
      }
      rethrow;
    }
  }

  /// Play a system sound
  @override
  Future<void> playSystemSound({
    required platform.SystemSoundType soundType,
    double volume = 1.0,
  }) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    // Windows platform: Use SystemSound.play() with patterned sequences
    if (!_useJustAudio) {
      try {
        final soundSequence = _windowsSystemSounds[soundType];
        if (soundSequence != null && soundSequence.isNotEmpty) {
          // Play the sequence with small delays to create distinctive patterns
          for (int i = 0; i < soundSequence.length; i++) {
            await Future.delayed(Duration(milliseconds: i * 100), () {
              flutter_services.SystemSound.play(soundSequence[i]);
            });
          }

          if (kDebugMode) {
            debugPrint(
              'AudioService: [Windows] Playing sound pattern for $soundType (${soundSequence.length} sounds)',
            );
          }
        } else {
          // Fallback
          flutter_services.SystemSound.play(
            flutter_services.SystemSoundType.alert,
          );
          if (kDebugMode) {
            debugPrint(
              'AudioService: [Windows] Playing fallback sound for $soundType',
            );
          }
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: [Windows] Error playing system sound: $e');
        }
        // Silently fail on Windows
        return;
      }
    }

    // Other platforms: Use just_audio
    final soundPath = _systemSoundPaths[soundType];
    if (soundPath == null) {
      if (kDebugMode) {
        debugPrint('AudioService: No sound path for $soundType');
      }
      return;
    }

    try {
      final player = await _getPlayer();
      final adjustedVolume = (volume * _globalVolume).clamp(0.0, 1.0);

      await player.setVolume(adjustedVolume);
      await player.setAsset(soundPath);
      await player.play();

      if (kDebugMode) {
        debugPrint('AudioService: Playing system sound $soundType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AudioService: Error playing system sound: $e');
      }
      rethrow;
    }
  }

  /// Play background music
  @override
  Future<String> playMusic({
    required String musicPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    try {
      final playerId = DateTime.now().millisecondsSinceEpoch.toString();
      final player = AudioPlayer();

      if (musicPath.startsWith('http')) {
        await player.setUrl(musicPath);
      } else {
        await player.setAsset(musicPath);
      }

      await player.setVolume((volume * _globalVolume).clamp(0.0, 1.0));

      if (loop) {
        await player.setLoopMode(LoopMode.one);
      }

      await player.play();

      _players[playerId] = player;

      if (kDebugMode) {
        debugPrint('AudioService: Playing music $musicPath (loop: $loop)');
      }

      return playerId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AudioService: Error playing music: $e');
      }
      rethrow;
    }
  }

  /// Stop a specific sound
  Future<void> stopSound(String soundId) async {
    final player = _players[soundId];
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
        _players.remove(soundId);

        if (kDebugMode) {
          debugPrint('AudioService: Stopped sound $soundId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: Error stopping sound: $e');
        }
      }
    }
  }

  /// Stop background music
  @override
  Future<void> stopMusic(String musicId) async {
    await stopSound(musicId);
  }

  /// Pause music playback
  @override
  Future<void> pauseMusic(String playerId) async {
    final player = _players[playerId];
    if (player != null) {
      try {
        await player.pause();
        if (kDebugMode) {
          debugPrint('AudioService: Paused music $playerId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: Error pausing music: $e');
        }
      }
    }
  }

  /// Resume music playback
  @override
  Future<void> resumeMusic(String playerId) async {
    final player = _players[playerId];
    if (player != null) {
      try {
        await player.play();
        if (kDebugMode) {
          debugPrint('AudioService: Resumed music $playerId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: Error resuming music: $e');
        }
      }
    }
  }

  /// Set global volume
  @override
  Future<void> setGlobalVolume(double volume) async {
    _globalVolume = volume.clamp(0.0, 1.0);

    // Windows: SystemSound doesn't support volume control
    if (!_useJustAudio) {
      if (kDebugMode) {
        debugPrint(
          'AudioService: [Windows] Volume control not supported for SystemSound',
        );
      }
      return;
    }

    // Update volume for all active players
    for (final player in _players.values) {
      try {
        await player.setVolume(_globalVolume);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: Error setting volume: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('AudioService: Global volume set to $_globalVolume');
    }
  }

  /// Stop all audio playback
  @override
  Future<void> stopAll() async {
    // Windows: SystemSound plays once and doesn't need stopping
    if (!_useJustAudio) {
      if (kDebugMode) {
        debugPrint(
          'AudioService: [Windows] Stop all - no active players to stop',
        );
      }
      return;
    }

    final playerIds = _players.keys.toList();

    for (final playerId in playerIds) {
      if (playerId == '_warmup') continue;

      final player = _players[playerId];
      if (player != null) {
        try {
          await player.stop();
          await player.dispose();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('AudioService: Error stopping player $playerId: $e');
          }
        }
      }
    }

    _players.clear();

    // Recreate warmup player
    final warmupPlayer = AudioPlayer();
    await warmupPlayer.setVolume(_globalVolume);
    _players['_warmup'] = warmupPlayer;

    if (kDebugMode) {
      debugPrint('AudioService: Stopped all audio playback');
    }
  }

  /// Get or create a player
  Future<AudioPlayer> _getPlayer() async {
    // Try to find an available player
    for (final entry in _players.entries) {
      if (entry.key == '_warmup') continue;

      final player = entry.value;
      // Check if player is not playing
      try {
        if (player.playerState.playing == false) {
          return player;
        }
      } catch (e) {
        // Player might be disposed, continue
        continue;
      }
    }

    // Create a new player if none available
    final newPlayer = AudioPlayer();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _players[newId] = newPlayer;

    return newPlayer;
  }

  /// Dispose the audio service
  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService: Error disposing player: $e');
        }
      }
    }

    _players.clear();
    _isInitialized = false;

    if (kDebugMode) {
      debugPrint('AudioService: Disposed (using just_audio)');
    }
  }
}
