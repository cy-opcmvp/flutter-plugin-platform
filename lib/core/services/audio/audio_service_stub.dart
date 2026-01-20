/// Stub Audio Service Implementation for platforms without audio support
///
/// This is a fallback implementation that provides the same interface
/// but doesn't actually play audio. Used when audioplayers is not available.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';
import 'package:plugin_platform/core/services/disposable.dart';

/// Stub audio service implementation
class AudioServiceImpl extends IAudioService implements Disposable {
  double _globalVolume = 1.0;
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint(
        'AudioService: Initialized (stub mode - no actual audio playback)',
      );
    }
    return true;
  }

  @override
  Future<void> playSound({
    required String soundPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'AudioService: playSound($soundPath) - stub mode, no audio played',
      );
    }
  }

  @override
  Future<String> playMusic({
    required String musicPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'AudioService: playMusic($musicPath) - stub mode, no audio played',
      );
    }
    return 'stub_music_id';
  }

  @override
  Future<void> playSystemSound({
    required SystemSoundType soundType,
    double volume = 1.0,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'AudioService: playSystemSound($soundType) - stub mode, no audio played',
      );
    }
  }

  Future<void> stopSound(String soundId) async {
    if (kDebugMode) {
      debugPrint('AudioService: stopSound($soundId) - stub mode');
    }
  }

  @override
  Future<void> stopMusic(String musicId) async {
    if (kDebugMode) {
      debugPrint('AudioService: stopMusic($musicId) - stub mode');
    }
  }

  @override
  Future<void> pauseMusic(String playerId) async {
    if (kDebugMode) {
      debugPrint('AudioService: pauseMusic($playerId) - stub mode');
    }
  }

  @override
  Future<void> resumeMusic(String playerId) async {
    if (kDebugMode) {
      debugPrint('AudioService: resumeMusic($playerId) - stub mode');
    }
  }

  @override
  Future<void> setGlobalVolume(double volume) async {
    _globalVolume = volume.clamp(0.0, 1.0);
    if (kDebugMode) {
      debugPrint('AudioService: setGlobalVolume($_globalVolume) - stub mode');
    }
  }

  @override
  Future<void> stopAll() async {
    if (kDebugMode) {
      debugPrint('AudioService: stopAll() - stub mode');
    }
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    if (kDebugMode) {
      debugPrint('AudioService: Disposed (stub mode)');
    }
  }
}
