/// Task Scheduler Service Implementation
///
/// Provides task scheduling and management functionality.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform/core/interfaces/services/i_task_scheduler_service.dart';
import 'package:plugin_platform/core/services/disposable.dart';

/// Internal task representation
class _ScheduledTaskInternal {
  final String id;
  final String type; // 'one_shot' or 'periodic'
  final DateTime? scheduledTime;
  final Duration? interval;
  final Map<String, dynamic>? data;
  final TaskCallback callback;
  bool isActive;
  bool isPaused;
  Timer? timer;

  _ScheduledTaskInternal({
    required this.id,
    required this.type,
    this.scheduledTime,
    this.interval,
    this.data,
    required this.callback,
    this.isActive = true,
    this.isPaused = false,
  });
}

/// Task scheduler service implementation
class TaskSchedulerServiceImpl extends ITaskSchedulerService
    implements Disposable {
  final Map<String, _ScheduledTaskInternal> _tasks = {};
  final StreamController<TaskEvent> _completeController =
      StreamController<TaskEvent>.broadcast();
  final StreamController<TaskEvent> _failedController =
      StreamController<TaskEvent>.broadcast();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<TaskEvent> get onTaskComplete => _completeController.stream;

  @override
  Stream<TaskEvent> get onTaskFailed => _failedController.stream;

  /// Initialize the task scheduler service
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      _prefs = await SharedPreferences.getInstance();

      // Restore persisted tasks
      await _restoreTasks();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint(
          'TaskSchedulerService: Initialized with ${_tasks.length} tasks',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Initialization failed: $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Schedule a one-shot task
  @override
  Future<String> scheduleOneShotTask({
    required String taskId,
    required DateTime scheduledTime,
    required TaskCallback callback,
    Map<String, dynamic>? data,
    bool showNotification = false,
    String? notificationTitle,
    String? notificationBody,
  }) async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      throw ArgumentError('scheduledTime must be in the future');
    }

    final task = _ScheduledTaskInternal(
      id: taskId,
      type: 'one_shot',
      scheduledTime: scheduledTime,
      data: data,
      callback: callback,
    );

    _tasks[taskId] = task;
    await _persistTask(task);

    // Calculate delay and schedule
    final delay = scheduledTime.difference(DateTime.now());
    task.timer = Timer(delay, () => _executeTask(task));

    if (kDebugMode) {
      debugPrint(
        'TaskSchedulerService: Scheduled one-shot task $taskId for $scheduledTime',
      );
    }

    return taskId;
  }

  /// Schedule a periodic task
  @override
  Future<String> schedulePeriodicTask({
    required String taskId,
    required Duration interval,
    required TaskCallback callback,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    if (interval.inSeconds < 1) {
      throw ArgumentError('interval must be at least 1 second');
    }

    final task = _ScheduledTaskInternal(
      id: taskId,
      type: 'periodic',
      interval: interval,
      data: data,
      callback: callback,
    );

    _tasks[taskId] = task;
    await _persistTask(task);

    // Start periodic timer
    task.timer = Timer.periodic(interval, (_) => _executeTask(task));

    if (kDebugMode) {
      debugPrint(
        'TaskSchedulerService: Scheduled periodic task $taskId every $interval',
      );
    }

    return taskId;
  }

  /// Cancel a specific task
  @override
  Future<void> cancelTask(String taskId) async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    final task = _tasks.remove(taskId);
    if (task != null) {
      task.timer?.cancel();
      await _removePersistedTask(taskId);

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Cancelled task $taskId');
      }
    }
  }

  /// Cancel all tasks
  @override
  Future<void> cancelAllTasks() async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    final taskIds = List<String>.from(_tasks.keys);

    for (final taskId in taskIds) {
      await cancelTask(taskId);
    }

    if (kDebugMode) {
      debugPrint('TaskSchedulerService: Cancelled all tasks');
    }
  }

  /// Get list of active tasks
  @override
  Future<List<ScheduledTask>> getActiveTasks() async {
    if (!_isInitialized) {
      return [];
    }

    return _tasks.values
        .map(
          (task) => ScheduledTask(
            id: task.id,
            type: task.type,
            scheduledTime: task.scheduledTime,
            interval: task.interval,
            data: task.data,
            isActive: task.isActive,
            isPaused: task.isPaused,
          ),
        )
        .toList();
  }

  /// Pause a task
  @override
  Future<void> pauseTask(String taskId) async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    final task = _tasks[taskId];
    if (task != null && !task.isPaused) {
      task.isPaused = true;
      task.timer?.cancel();

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Paused task $taskId');
      }
    }
  }

  /// Resume a paused task
  @override
  Future<void> resumeTask(String taskId) async {
    if (!_isInitialized) {
      throw StateError('TaskSchedulerService not initialized');
    }

    final task = _tasks[taskId];
    if (task != null && task.isPaused) {
      task.isPaused = false;

      // Reschedule
      if (task.type == 'one_shot' && task.scheduledTime != null) {
        final delay = task.scheduledTime!.difference(DateTime.now());
        if (delay > Duration.zero) {
          task.timer = Timer(delay, () => _executeTask(task));
        }
      } else if (task.type == 'periodic' && task.interval != null) {
        task.timer = Timer.periodic(task.interval!, (_) => _executeTask(task));
      }

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Resumed task $taskId');
      }
    }
  }

  /// Execute a task
  Future<void> _executeTask(_ScheduledTaskInternal task) async {
    if (!task.isActive || task.isPaused) {
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Executing task ${task.id}');
      }

      await task.callback(task.data);

      // Emit completion event
      _completeController.add(
        TaskEvent(taskId: task.id, data: task.data, timestamp: DateTime.now()),
      );

      // For one-shot tasks, remove after execution
      if (task.type == 'one_shot') {
        task.isActive = false;
        task.timer?.cancel();
        _tasks.remove(task.id);
        await _removePersistedTask(task.id);

        if (kDebugMode) {
          debugPrint(
            'TaskSchedulerService: Completed one-shot task ${task.id}',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Error executing task ${task.id}: $e');
        debugPrint('$stackTrace');
      }

      // Emit failure event
      _failedController.add(
        TaskEvent(
          taskId: task.id,
          data: task.data,
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
    }
  }

  /// Persist a task to storage
  Future<void> _persistTask(_ScheduledTaskInternal task) async {
    if (_prefs == null) return;

    try {
      final taskJson = jsonEncode({
        'id': task.id,
        'type': task.type,
        'scheduledTime': task.scheduledTime?.toIso8601String(),
        'intervalSeconds': task.interval?.inSeconds,
        'data': task.data,
      });

      await _prefs!.setString('task_${task.id}', taskJson);

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Persisted task ${task.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TaskSchedulerService: Error persisting task ${task.id}: $e',
        );
      }
    }
  }

  /// Remove a persisted task
  Future<void> _removePersistedTask(String taskId) async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove('task_$taskId');

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Removed persisted task $taskId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TaskSchedulerService: Error removing persisted task $taskId: $e',
        );
      }
    }
  }

  /// Restore tasks from storage
  Future<void> _restoreTasks() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('task_'));

      for (final key in keys) {
        final taskJson = _prefs!.getString(key);
        if (taskJson != null) {
          final taskData = jsonDecode(taskJson) as Map<String, dynamic>;

          final scheduledTime = taskData['scheduledTime'] != null
              ? DateTime.parse(taskData['scheduledTime'] as String)
              : null;

          // Only restore if scheduled time is in the future
          if (scheduledTime != null && scheduledTime.isBefore(DateTime.now())) {
            await _removePersistedTask(taskData['id'] as String);
            continue;
          }

          // Note: We can't restore callbacks, so these tasks will be in limbo
          // In a real implementation, you'd need a way to register callbacks
          // For now, we just log them
          if (kDebugMode) {
            debugPrint(
              'TaskSchedulerService: Found persisted task ${taskData['id']} without callback',
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Restored tasks from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TaskSchedulerService: Error restoring tasks: $e');
      }
    }
  }

  /// Dispose of resources
  @override
  Future<void> dispose() async {
    await cancelAllTasks();

    await _completeController.close();
    await _failedController.close();

    _isInitialized = false;

    if (kDebugMode) {
      debugPrint('TaskSchedulerService: Disposed');
    }
  }
}
