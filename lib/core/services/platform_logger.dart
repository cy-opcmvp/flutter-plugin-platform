import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'config_manager.dart';

/// Log levels for platform logging
enum LogLevel { debug, info, warning, error }

/// Logger for platform-specific operations and feature degradation.
/// Provides different logging strategies for debug vs production mode.
class PlatformLogger {
  // Singleton instance
  static final PlatformLogger instance = PlatformLogger._();

  // Private constructor for singleton
  PlatformLogger._();

  /// Parse log level from string configuration
  LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info; // 默认级别
    }
  }

  /// Check if a message should be logged based on configured level
  bool _shouldLog(LogLevel messageLevel) {
    // 在 Release 模式下，只输出 warning 和 error
    if (!kDebugMode) {
      return messageLevel == LogLevel.warning || messageLevel == LogLevel.error;
    }

    // 在 Debug 模式下，读取配置的日志级别
    try {
      final config = ConfigManager.instance.globalConfig;
      final configLevelStr = config.advanced.logLevel;
      final configLevel = _parseLogLevel(configLevelStr);

      // 只有当消息级别 >= 配置级别时才输出
      // LogLevel.debug (0) < LogLevel.info (1) < LogLevel.warning (2) < LogLevel.error (3)
      return messageLevel.index >= configLevel.index;
    } catch (e) {
      // 如果读取配置失败，默认输出所有日志（开发模式）
      return true;
    }
  }

  /// Log environment variable access.
  /// In debug mode, logs detailed information about the access.
  /// In production mode, logs minimal information.
  void logEnvironmentAccess(String key, bool found, String? value) {
    if (kDebugMode) {
      // Detailed logging in debug mode
      if (found && value != null) {
        if (_shouldLog(LogLevel.debug)) {
          _log(LogLevel.debug, 'Environment variable accessed: $key = $value');
        }
      } else if (found && value == null) {
        if (_shouldLog(LogLevel.debug)) {
          _log(LogLevel.debug, 'Environment variable accessed: $key = null');
        }
      } else {
        if (_shouldLog(LogLevel.debug)) {
          _log(LogLevel.debug, 'Environment variable not found: $key');
        }
      }
    } else {
      // Minimal logging in production mode
      if (!found && _shouldLog(LogLevel.info)) {
        _log(LogLevel.info, 'Environment variable not available: $key');
      }
    }
  }

  /// Log feature degradation when platform-specific features are unavailable.
  /// Always logs feature unavailability regardless of mode.
  void logFeatureDegradation(String feature, String reason) {
    if (kDebugMode) {
      // Detailed logging in debug mode
      if (_shouldLog(LogLevel.warning)) {
        _log(LogLevel.warning, 'Feature degraded: $feature - Reason: $reason');
      }
    } else {
      // Minimal logging in production mode
      if (_shouldLog(LogLevel.warning)) {
        _log(LogLevel.warning, 'Feature unavailable: $feature');
      }
    }
  }

  /// Log platform detection information.
  /// Useful for debugging platform-specific behavior.
  void logPlatformDetection(
    String platform,
    Map<String, dynamic> capabilities,
  ) {
    if (_shouldLog(LogLevel.info)) {
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
  /// Always logs errors regardless of mode (unless level is set higher than error).
  void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.error)) {
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
  }

  /// Log warning message.
  void logWarning(String message) {
    if (_shouldLog(LogLevel.warning)) {
      _log(LogLevel.warning, message);
    }
  }

  /// Log info message.
  /// Respects the configured log level.
  void logInfo(String message) {
    if (_shouldLog(LogLevel.info)) {
      _log(LogLevel.info, message);
    }
  }

  /// Log debug message.
  /// Respects the configured log level.
  void logDebug(String message) {
    if (_shouldLog(LogLevel.debug)) {
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
