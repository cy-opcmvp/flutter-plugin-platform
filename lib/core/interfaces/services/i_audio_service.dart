/// Audio Service Interface
///
/// Provides cross-platform audio playback functionality.
library;

/// Audio service interface
abstract class IAudioService {
  /// Initialize the audio service
  Future<bool> initialize();

  /// Play a short sound effect
  ///
  /// Parameters:
  /// - [soundPath]: Path to the sound file (asset or file)
  /// - [volume]: Volume level (0.0 to 1.0)
  /// - [loop]: Whether to loop the sound
  Future<void> playSound({
    required String soundPath,
    double volume = 1.0,
    bool loop = false,
  });

  /// Play a system sound
  ///
  /// Parameters:
  /// - [soundType]: Type of system sound to play
  /// - [volume]: Volume level (0.0 to 1.0)
  Future<void> playSystemSound({
    required SystemSoundType soundType,
    double volume = 1.0,
  });

  /// Play background music
  ///
  /// Returns a player ID that can be used to control playback.
  ///
  /// Parameters:
  /// - [musicPath]: Path to the music file (asset or file)
  /// - [volume]: Volume level (0.0 to 1.0)
  /// - [loop]: Whether to loop the music
  Future<String> playMusic({
    required String musicPath,
    double volume = 1.0,
    bool loop = false,
  });

  /// Stop music playback
  ///
  /// Parameters:
  /// - [playerId]: ID of the player to stop
  Future<void> stopMusic(String playerId);

  /// Pause music playback
  ///
  /// Parameters:
  /// - [playerId]: ID of the player to pause
  Future<void> pauseMusic(String playerId);

  /// Resume music playback
  ///
  /// Parameters:
  /// - [playerId]: ID of the player to resume
  Future<void> resumeMusic(String playerId);

  /// Set global volume for all audio
  ///
  /// Parameters:
  /// - [volume]: Volume level (0.0 to 1.0)
  Future<void> setGlobalVolume(double volume);

  /// Stop all audio playback
  Future<void> stopAll();

  /// Dispose of resources
  Future<void> dispose();

  /// Whether the service has been initialized
  bool get isInitialized;
}

/// System sound types
enum SystemSoundType {
  /// Notification sound
  notification,

  /// Alarm sound
  alarm,

  /// Click/tap sound
  click,

  /// Success sound
  success,

  /// Error sound
  error,

  /// Warning sound
  warning,
}

/// Audio playback state
enum AudioPlaybackState {
  /// Currently playing
  playing,

  /// Paused
  paused,

  /// Stopped
  stopped,

  /// Completed
  completed,

  /// Error occurred
  error,
}
