import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart';

/// Log levels for platform logging
enum LogLevel { debug, info, warning, error }

/// Logger for platform-specific operations and feature degradation.
/// Provides different logging strategies for debug vs production mode.
class PlatformLogger {
  // Singleton instance
  static final PlatformLogger instance = PlatformLogger._();

  // Private constructor for singleton
  PlatformLogger._();

  /// Log environment variable access.
  /// In debug mode, logs detailed information about the access.
  /// In production mode, logs minimal information.
  void logEnvironmentAccess(String key, bool found, String? value) {
    if (kDebugMode) {
      // Detailed logging in debug mode
      if (found && value != null) {
        _log(LogLevel.debug, 'Environment variable accessed: $key = $value');
      } else if (found && value == null) {
        _log(LogLevel.debug, 'Environment variable accessed: $key = null');
      } else {
        _log(LogLevel.debug, 'Environment variable not found: $key');
      }
    } else {
      // Minimal logging in production mode
      if (!found) {
        _log(LogLevel.info, 'Environment variable not available: $key');
      }
    }
  }

  /// Log feature degradation when platform-specific features are unavailable.
  /// Always logs feature unavailability regardless of mode.
  void logFeatureDegradation(String feature, String reason) {
    if (kDebugMode) {
      // Detailed logging in debug mode
      _log(LogLevel.warning, 'Feature degraded: $feature - Reason: $reason');
    } else {
      // Minimal logging in production mode
      _log(LogLevel.warning, 'Feature unavailable: $feature');
    }
  }

  /// Log platform detection information.
  /// Useful for debugging platform-specific behavior.
  void logPlatformDetection(
    String platform,
    Map<String, dynamic> capabilities,
  ) {
    if (kDebugMode) {
      final capabilitiesStr = capabilities.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      _log(
        LogLevel.info,
        'Platform detected: $platform - Capabilities: {$capabilitiesStr}',
      );
    }
  }

  /// Log error with context.
  /// Always logs errors regardless of mode.
  void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      // Detailed error logging in debug mode
      _log(
        LogLevel.error,
        'Error in $context: $error${stackTrace != null ? '\nStack trace: $stackTrace' : ''}',
      );
    } else {
      // Minimal error logging in production mode
      _log(LogLevel.error, 'Error in $context: ${error.toString()}');
    }
  }

  /// Log warning message.
  void logWarning(String message) {
    _log(LogLevel.warning, message);
  }

  /// Log info message (only in debug mode).
  void logInfo(String message) {
    if (kDebugMode) {
      _log(LogLevel.info, message);
    }
  }

  /// Log debug message (only in debug mode).
  void logDebug(String message) {
    if (kDebugMode) {
      _log(LogLevel.debug, message);
    }
  }

  /// Internal logging method that outputs to console.
  /// Can be extended to support different logging backends.
  void _log(LogLevel level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] [$levelStr] $message';

    // Output to console based on level
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        break;
    }
  }
}
