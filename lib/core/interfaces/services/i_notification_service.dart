/// Notification Service Interface
///
/// Provides cross-platform local notification functionality.
library;

/// Notification service interface
abstract class INotificationService {
  /// Initialize the notification service
  ///
  /// Returns true if initialization was successful, false otherwise.
  /// Must be called before using any other methods.
  Future<bool> initialize();

  /// Check if notification permissions are granted
  Future<bool> checkPermissions();

  /// Request notification permissions from the user
  ///
  /// Returns true if permissions were granted, false otherwise.
  Future<bool> requestPermissions();

  /// Show an immediate notification
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this notification
  /// - [title]: Notification title
  /// - [body]: Notification body text
  /// - [payload]: Optional payload data
  /// - [priority]: Notification priority level
  /// - [sound]: Optional sound file path or identifier
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? sound,
  });

  /// Schedule a notification for a future time
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this notification
  /// - [title]: Notification title
  /// - [body]: Notification body text
  /// - [scheduledTime]: When to show the notification
  /// - [payload]: Optional payload data
  /// - [priority]: Notification priority level
  /// - [sound]: Optional sound file path or identifier
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? sound,
  });

  /// Cancel a specific notification
  ///
  /// If the notification hasn't been shown yet, it will be cancelled.
  /// If it's already visible, it will be dismissed.
  Future<void> cancelNotification(String id);

  /// Cancel all active notifications
  Future<void> cancelAllNotifications();

  /// Get list of active (scheduled or shown) notifications
  Future<List<ActiveNotification>> getActiveNotifications();

  /// Stream of notification click events
  ///
  /// Emits an event whenever a notification is clicked by the user.
  Stream<NotificationEvent> get onNotificationClick;

  /// Whether the service has been initialized
  bool get isInitialized;
}

/// Notification priority levels
enum NotificationPriority {
  /// Low priority - may be hidden or collapsed
  low,

  /// Normal priority - default behavior
  normal,

  /// High priority - shown prominently
  high,

  /// Urgent priority - shown at the top, may bypass DND
  urgent,
}

/// Represents an active notification
class ActiveNotification {
  /// Unique notification ID
  final String id;

  /// Notification title
  final String title;

  /// Notification body
  final String body;

  /// When the notification is scheduled (null for immediate)
  final DateTime? scheduledTime;

  /// Notification priority
  final NotificationPriority priority;

  const ActiveNotification({
    required this.id,
    required this.title,
    required this.body,
    this.scheduledTime,
    required this.priority,
  });

  @override
  String toString() {
    return 'ActiveNotification(id: $id, title: $title, scheduledTime: $scheduledTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActiveNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.scheduledTime == scheduledTime &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        scheduledTime.hashCode ^
        priority.hashCode;
  }
}

/// Notification click event
class NotificationEvent {
  /// ID of the clicked notification
  final String id;

  /// Payload data from the notification (if any)
  final String? payload;

  /// When the notification was clicked
  final DateTime timestamp;

  const NotificationEvent({
    required this.id,
    this.payload,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'NotificationEvent(id: $id, payload: $payload, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationEvent &&
        other.id == id &&
        other.payload == payload &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^ payload.hashCode ^ timestamp.hashCode;
  }
}
