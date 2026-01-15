/// Audio Service Implementation
///
/// Cross-platform audio playback service using audioplayers.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
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
        print('AudioService: Initialized successfully');
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

      await player.setVolume(adjustedVolume);
      await player.play(
        AssetSource(soundPath),
        mode: PlayerMode.lowLatency,
      );

      if (kDebugMode) {
        print('AudioService: Playing sound $soundPath');
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
      throw ArgumentError('Unknown system sound type: $soundType');
    }

    await playSound(soundPath: soundPath, volume: volume);

    if (kDebugMode) {
      print('AudioService: Playing system sound $soundType');
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
      final playerId = 'music_${DateTime.now().millisecondsSinceEpoch}';
      final player = await _getPlayer(playerId);

      final adjustedVolume = (volume * _globalVolume).clamp(0.0, 1.0);
      await player.setVolume(adjustedVolume);
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);

      await player.play(
        AssetSource(musicPath),
        mode: PlayerMode.mediaPlayer,
      );

      if (kDebugMode) {
        print('AudioService: Playing music $musicPath (player: $playerId)');
      }

      return playerId;
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error playing music: $e');
      }
      rethrow;
    }
  }

  /// Stop music playback
  @override
  Future<void> stopMusic(String playerId) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    final player = _players[playerId];
    if (player != null) {
      await player.stop();
      await _releasePlayer(playerId);

      if (kDebugMode) {
        print('AudioService: Stopped music player $playerId');
      }
    }
  }

  /// Pause music playback
  @override
  Future<void> pauseMusic(String playerId) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    final player = _players[playerId];
    if (player != null) {
      await player.pause();

      if (kDebugMode) {
        print('AudioService: Paused music player $playerId');
      }
    }
  }

  /// Resume music playback
  @override
  Future<void> resumeMusic(String playerId) async {
    if (!_isInitialized) {
      throw StateError('AudioService not initialized');
    }

    final player = _players[playerId];
    if (player != null) {
      await player.resume();

      if (kDebugMode) {
        print('AudioService: Resumed music player $playerId');
      }
    }
  }

  /// Set global volume for all audio
  @override
  Future<void> setGlobalVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    _globalVolume = clampedVolume;

    // Update volume for all active players
    for (final player in _players.values) {
      await player.setVolume(_globalVolume);
    }

    if (kDebugMode) {
      print('AudioService: Set global volume to $_globalVolume');
    }
  }

  /// Stop all audio playback
  @override
  Future<void> stopAll() async {
    if (!_isInitialized) {
      return;
    }

    final players = List<String>.from(_players.keys);

    for (final playerId in players) {
      if (playerId != '_warmup') {
        await stopMusic(playerId);
      }
    }

    if (kDebugMode) {
      print('AudioService: Stopped all audio');
    }
  }

  /// Get or create a player
  Future<AudioPlayer> _getPlayer([String? playerId]) async {
    final id = playerId ?? 'sound_${DateTime.now().millisecondsSinceEpoch}';

    if (!_players.containsKey(id)) {
      final player = AudioPlayer();
      _players[id] = player;

      // Listen for completion to auto-release
      player.onPlayerComplete.listen((_) {
        if (id.startsWith('sound_')) {
          _releasePlayer(id);
        }
      });
    }

    return _players[id]!;
  }

  /// Release a player
  Future<void> _releasePlayer(String playerId) async {
    final player = _players.remove(playerId);
    if (player != null) {
      await player.dispose();
    }
  }

  /// Dispose of resources
  @override
  Future<void> dispose() async {
    await stopAll();

    // Dispose all players
    final players = List<AudioPlayer>.from(_players.values);
    for (final player in players) {
      await player.dispose();
    }

    _players.clear();
    _isInitialized = false;

    if (kDebugMode) {
      print('AudioService: Disposed');
    }
  }
}
