import '../models/platform_models.dart';
import '../models/plugin_models.dart';

/// Interface for platform services available to plugins
abstract class IPlatformServices {
  /// Initialize the platform services
  Future<void> initialize();

  /// Show a notification to the user
  Future<void> showNotification(String message);

  /// Request a specific permission from the user
  Future<void> requestPermission(Permission permission);

  /// Open an external URL
  Future<void> openExternalUrl(String url);

  /// Stream of platform events
  Stream<PlatformEvent> get eventStream;

  /// Get current platform information
  PlatformInfo get platformInfo;

  /// Check if a permission is granted
  Future<bool> hasPermission(Permission permission);
}

/// Information about the current platform
class PlatformInfo {
  final PlatformType type;
  final String version;
  final Map<String, dynamic> capabilities;

  const PlatformInfo({
    required this.type,
    required this.version,
    required this.capabilities,
  });
}

/// Types of platforms supported
enum PlatformType { mobile, desktop, steam }
