/// Task Scheduler Service Interface
///
/// Provides task scheduling and management functionality.
library;

/// Task callback function type
typedef TaskCallback = Future<void> Function(Map<String, dynamic>? data);

/// Task scheduler service interface
abstract class ITaskSchedulerService {
  /// Initialize the task scheduler service
  Future<bool> initialize();

  /// Schedule a one-shot task
  ///
  /// Returns the task ID.
  ///
  /// Parameters:
  /// - [taskId]: Unique identifier for the task
  /// - [scheduledTime]: When to execute the task
  /// - [callback]: Function to call when task executes
  /// - [data]: Optional data to pass to callback
  /// - [showNotification]: Whether to show notification when task completes
  /// - [notificationTitle]: Title for notification
  /// - [notificationBody]: Body for notification
  Future<String> scheduleOneShotTask({
    required String taskId,
    required DateTime scheduledTime,
    required TaskCallback callback,
    Map<String, dynamic>? data,
    bool showNotification = false,
    String? notificationTitle,
    String? notificationBody,
  });

  /// Schedule a periodic task
  ///
  /// Returns the task ID.
  ///
  /// Parameters:
  /// - [taskId]: Unique identifier for the task
  /// - [interval]: Interval between executions
  /// - [callback]: Function to call on each execution
  /// - [data]: Optional data to pass to callback
  Future<String> schedulePeriodicTask({
    required String taskId,
    required Duration interval,
    required TaskCallback callback,
    Map<String, dynamic>? data,
  });

  /// Cancel a specific task
  Future<void> cancelTask(String taskId);

  /// Cancel all tasks
  Future<void> cancelAllTasks();

  /// Get list of active tasks
  Future<List<ScheduledTask>> getActiveTasks();

  /// Pause a task
  Future<void> pauseTask(String taskId);

  /// Resume a paused task
  Future<void> resumeTask(String taskId);

  /// Stream of task completion events
  Stream<TaskEvent> get onTaskComplete;

  /// Stream of task failure events
  Stream<TaskEvent> get onTaskFailed;

  /// Whether the service has been initialized
  bool get isInitialized;
}

/// Represents a scheduled task
class ScheduledTask {
  /// Unique task ID
  final String id;

  /// Task type ('one_shot' or 'periodic')
  final String type;

  /// When the task is scheduled (null for periodic)
  final DateTime? scheduledTime;

  /// Interval for periodic tasks
  final Duration? interval;

  /// Data associated with the task
  final Map<String, dynamic>? data;

  /// Whether the task is currently active
  final bool isActive;

  /// Whether the task is paused
  final bool isPaused;

  const ScheduledTask({
    required this.id,
    required this.type,
    this.scheduledTime,
    this.interval,
    this.data,
    required this.isActive,
    required this.isPaused,
  });

  @override
  String toString() {
    return 'ScheduledTask(id: $id, type: $type, scheduledTime: $scheduledTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScheduledTask &&
        other.id == id &&
        other.type == type &&
        other.scheduledTime == scheduledTime &&
        other.interval == interval &&
        other.isActive == isActive &&
        other.isPaused == isPaused;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        scheduledTime.hashCode ^
        interval.hashCode ^
        isActive.hashCode ^
        isPaused.hashCode;
  }
}

/// Task event (completion or failure)
class TaskEvent {
  /// ID of the task
  final String taskId;

  /// Data associated with the task
  final Map<String, dynamic>? data;

  /// When the event occurred
  final DateTime timestamp;

  /// Error message (only for failure events)
  final String? error;

  const TaskEvent({
    required this.taskId,
    this.data,
    required this.timestamp,
    this.error,
  });

  @override
  String toString() {
    return 'TaskEvent(taskId: $taskId, timestamp: $timestamp, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskEvent &&
        other.taskId == taskId &&
        other.data == data &&
        other.timestamp == timestamp &&
        other.error == error;
  }

  @override
  int get hashCode {
    return taskId.hashCode ^
        data.hashCode ^
        timestamp.hashCode ^
        error.hashCode;
  }
}
