/// Notification Service Implementation
///
/// Cross-platform notification service using flutter_local_notifications.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:plugin_platform/core/interfaces/services/i_notification_service.dart'
    as platform;
import 'package:plugin_platform/core/services/disposable.dart' as platform_core;

/// Notification service implementation
class NotificationServiceImpl extends platform.INotificationService
    implements platform_core.Disposable {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<platform.NotificationEvent>
  _notificationClickController =
      StreamController<platform.NotificationEvent>.broadcast();

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<platform.NotificationEvent> get onNotificationClick =>
      _notificationClickController.stream;

  /// Initialize the notification service
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Windows platform: flutter_local_notifications 17.x doesn't properly support Windows
      // Skip initialization and mark as successful to prevent crashes
      if (defaultTargetPlatform == TargetPlatform.windows) {
        if (kDebugMode) {
          debugPrint(
            'NotificationService: Windows platform detected - using UI notifications',
          );
        }
        _isInitialized = true;
        return true;
      }

      // Initialize timezone database for other platforms
      tz_data.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Linux initialization settings
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      // Initialization settings
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      // Initialize the plugin
      final result = await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationClick(response);
        },
      );

      _isInitialized = result ?? false;

      if (_isInitialized && kDebugMode) {
        debugPrint('NotificationService: Initialized successfully');
      }

      return _isInitialized;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('NotificationService: Initialization failed: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Check if notification permissions are granted
  @override
  Future<bool> checkPermissions() async {
    if (!_isInitialized) {
      return false;
    }

    // Check platform-specific permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;

      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin == null) return false;

      final granted = await iosPlugin.checkPermissions();
      return granted == true;
    }

    // Other platforms (desktop) usually don't require explicit permission checks
    return true;
  }

  /// Request notification permissions
  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;

      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin == null) return false;

      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Show an immediate notification
  @override
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
    platform.NotificationPriority priority =
        platform.NotificationPriority.normal,
    String? sound,
  }) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    // Windows platform: Emit notification event for UI to handle
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: [Windows] Emitting notification event: $title - $body',
        );
      }

      // Emit event so UI can display SnackBar or similar
      _notificationClickController.add(
        platform.NotificationEvent(
          id: id,
          payload: '$title|$body', // Encode title and body in payload
          timestamp: DateTime.now(),
        ),
      );

      return;
    }

    try {
      final notificationDetails = _buildNotificationDetails(priority, sound);

      await _plugin.show(
        int.tryParse(id) ?? 0,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('NotificationService: Showed notification $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error showing notification: $e');
      }
      rethrow;
    }
  }

  /// Schedule a notification for a future time
  @override
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    platform.NotificationPriority priority =
        platform.NotificationPriority.normal,
    String? sound,
  }) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      throw ArgumentError('scheduledTime must be in the future');
    }

    // Windows doesn't support scheduled notifications in flutter_local_notifications 17.x
    // Use task scheduler instead
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Scheduled notifications not supported on Windows, showing immediately',
        );
      }
      // Fall back to immediate notification
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        priority: priority,
        sound: sound,
      );
      return;
    }

    final notificationDetails = _buildNotificationDetails(priority, sound);

    // For mobile platforms, use zonedSchedule with timezone support
    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      int.tryParse(id) ?? 0,
      title,
      body,
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint(
        'NotificationService: Scheduled notification $id for $scheduledTime',
      );
    }
  }

  /// Cancel a specific notification
  @override
  Future<void> cancelNotification(String id) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    // Windows platform: No-op since notifications aren't supported
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: [Windows] Cancel notification $id (no-op)',
        );
      }
      return;
    }

    try {
      await _plugin.cancel(int.tryParse(id) ?? 0);

      if (kDebugMode) {
        debugPrint('NotificationService: Cancelled notification $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error cancelling notification: $e');
      }
      rethrow;
    }
  }

  /// Cancel all active notifications
  @override
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    // Windows platform: No-op since notifications aren't supported
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: [Windows] Cancel all notifications (no-op)',
        );
      }
      return;
    }

    try {
      await _plugin.cancelAll();

      if (kDebugMode) {
        debugPrint('NotificationService: Cancelled all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Error cancelling all notifications: $e',
        );
      }
      rethrow;
    }
  }

  /// Get active notifications
  @override
  Future<List<platform.ActiveNotification>> getActiveNotifications() async {
    if (!_isInitialized) {
      return [];
    }

    // Note: flutter_local_notifications doesn't provide a direct way
    // to get active notifications. This is a placeholder that would
    // require platform-specific implementation to actually work.
    // For now, return empty list.

    if (kDebugMode) {
      debugPrint(
        'NotificationService: getActiveNotifications not fully implemented',
      );
    }

    return [];
  }

  /// Build notification details for the current platform
  NotificationDetails _buildNotificationDetails(
    platform.NotificationPriority priority,
    String? sound,
  ) {
    // Android details
    final androidDetails = AndroidNotificationDetails(
      'plugin_platform_channel',
      'Plugin Platform Notifications',
      channelDescription: 'Notifications from Plugin Platform',
      importance: _convertPriorityToImportance(priority),
      priority: _convertPriorityToAndroidPriority(priority),
      playSound: sound != null,
    );

    // iOS details
    final iosDetails = DarwinNotificationDetails(
      presentSound: sound != null,
      presentBadge: true,
      presentAlert: true,
    );

    // Linux details
    final linuxDetails = LinuxNotificationDetails();

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );
  }

  /// Convert platform.NotificationPriority to Android importance
  Importance _convertPriorityToImportance(
    platform.NotificationPriority priority,
  ) {
    switch (priority) {
      case platform.NotificationPriority.low:
        return Importance.low;
      case platform.NotificationPriority.normal:
        return Importance.defaultImportance;
      case platform.NotificationPriority.high:
        return Importance.high;
      case platform.NotificationPriority.urgent:
        return Importance.max;
    }
  }

  /// Convert platform.NotificationPriority to Android priority
  Priority _convertPriorityToAndroidPriority(
    platform.NotificationPriority priority,
  ) {
    switch (priority) {
      case platform.NotificationPriority.low:
        return Priority.low;
      case platform.NotificationPriority.normal:
        return Priority.defaultPriority;
      case platform.NotificationPriority.high:
        return Priority.high;
      case platform.NotificationPriority.urgent:
        return Priority.max;
    }
  }

  /// Handle notification click event
  void _handleNotificationClick(NotificationResponse response) {
    final event = platform.NotificationEvent(
      id: response.id.toString(),
      payload: response.payload,
      timestamp: DateTime.now(),
    );

    _notificationClickController.add(event);

    if (kDebugMode) {
      debugPrint('NotificationService: Notification clicked: $event');
    }
  }

  /// Dispose of resources
  @override
  Future<void> dispose() async {
    await _notificationClickController.close();
    _isInitialized = false;

    if (kDebugMode) {
      debugPrint('NotificationService: Disposed');
    }
  }
}
