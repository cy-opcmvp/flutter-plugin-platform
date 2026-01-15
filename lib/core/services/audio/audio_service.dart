/// Audio Service Implementation
///
/// Cross-platform audio playback service using just_audio.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';
import 'package:plugin_platform/core/services/disposable.dart';

/// Audio service implementation
class AudioServiceImpl extends IAudioService implements Disposable {
  final Map<String, AudioPlayer> _players = {};
  final Map<SystemSoundType, String> _systemSoundPaths = {
    SystemSoundType.notification: 'assets/audio/notification.mp3',
    SystemSoundType.alarm: 'assets/audio/alarm.mp3',
    SystemSoundType.click: 'assets/audio/click.mp3',
    SystemSoundType.success: 'assets/audio/success.mp3',
    SystemSoundType.error: 'assets/audio/error.mp3',
    SystemSoundType.warning: 'assets/audio/warning.mp3',
  };

  double _globalVolume = 1.0;
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  /// Initialize the audio service
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Pre-warm the audio system by creating one player
      final player = AudioPlayer();
      await player.setVolume(_globalVolume);
      _players['_warmup'] = player;

      _isInitialized = true;

      if (kDebugMode) {
        print('AudioService: Initialized successfully (using just_audio)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Initialization failed: $e');
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
        print('AudioService: Playing sound $soundPath (loop: $loop)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error playing sound: $e');
      }
      rethrow;
    }
  }

  /// Play a system sound
  @override
  Future<void> playSystemSound({
    required SystemSoundType soundType,
    double volume = 1.0,
  }) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    final soundPath = _systemSoundPaths[soundType];
    if (soundPath == null) {
      if (kDebugMode) {
        print('AudioService: No sound path for $soundType');
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
        print('AudioService: Playing system sound $soundType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error playing system sound: $e');
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
        print('AudioService: Playing music $musicPath (loop: $loop)');
      }

      return playerId;
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error playing music: $e');
      }
      rethrow;
    }
  }

  /// Stop a specific sound
  @override
  Future<void> stopSound(String soundId) async {
    final player = _players[soundId];
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
        _players.remove(soundId);

        if (kDebugMode) {
          print('AudioService: Stopped sound $soundId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error stopping sound: $e');
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
          print('AudioService: Paused music $playerId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error pausing music: $e');
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
          print('AudioService: Resumed music $playerId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error resuming music: $e');
        }
      }
    }
  }

  /// Set global volume
  @override
  Future<void> setGlobalVolume(double volume) async {
    _globalVolume = volume.clamp(0.0, 1.0);

    // Update volume for all active players
    for (final player in _players.values) {
      try {
        await player.setVolume(_globalVolume);
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error setting volume: $e');
        }
      }
    }

    if (kDebugMode) {
      print('AudioService: Global volume set to $_globalVolume');
    }
  }

  /// Stop all audio playback
  @override
  Future<void> stopAll() async {
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
            print('AudioService: Error stopping player $playerId: $e');
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
      print('AudioService: Stopped all audio playback');
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
          print('AudioService: Error disposing player: $e');
        }
      }
    }

    _players.clear();
    _isInitialized = false;

    if (kDebugMode) {
      print('AudioService: Disposed (using just_audio)');
    }
  }
}
