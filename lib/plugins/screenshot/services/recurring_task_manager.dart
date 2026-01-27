library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recurring_screenshot_task.dart';
import '../screenshot_plugin.dart';

/// 循环截图任务管理器
///
/// 负责管理所有循环截图任务的生命周期，包括：
/// - 任务的创建、启动、暂停、停止、删除
/// - 定时器的管理
/// - 任务状态的持久化
/// - 任务状态变化通知
class RecurringTaskManager {
  /// 所有任务列表
  final List<RecurringScreenshotTask> _tasks = [];

  /// 任务定时器映射（任务ID -> 定时器）
  final Map<String, Timer> _timers = {};

  /// 任务状态变化回调
  VoidCallback? _onTasksChanged;

  /// 插件引用（用于执行截图）
  final ScreenshotPlugin _plugin;

  /// 获取所有任务
  List<RecurringScreenshotTask> get tasks => List.unmodifiable(_tasks);

  /// 获取运行中的任务数量
  int get runningCount =>
      _tasks.where((t) => t.status == TaskStatus.running).length;

  /// 获取暂停的任务数量
  int get pausedCount =>
      _tasks.where((t) => t.status == TaskStatus.paused).length;

  /// 构造函数
  RecurringTaskManager({
    required ScreenshotPlugin plugin,
    VoidCallback? onTasksChanged,
  }) : _plugin = plugin,
       _onTasksChanged = onTasksChanged;

  /// 设置任务状态变化回调
  void setOnTasksChanged(VoidCallback? callback) {
    _onTasksChanged = callback;
  }

  /// 创建并启动任务
  ///
  /// 返回创建的任务
  RecurringScreenshotTask createTask({
    required String name,
    String? windowId,
    String? windowTitle,
    required int intervalSeconds,
    int? totalShots,
    String? saveDirectory,
  }) {
    final task = RecurringScreenshotTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      windowId: windowId,
      windowTitle: windowTitle,
      intervalSeconds: intervalSeconds,
      totalShots: totalShots,
      saveDirectory: saveDirectory,
      status: TaskStatus.running,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    _startTask(task);
    _notifyChanged();

    debugPrint('TaskManager: Created task ${task.id} (${task.name})');
    return task;
  }

  /// 启动任务
  void _startTask(RecurringScreenshotTask task) {
    // 如果已有定时器，先取消
    _timers[task.id]?.cancel();

    final timer = Timer.periodic(Duration(seconds: task.intervalSeconds), (
      timer,
    ) async {
      debugPrint('TaskManager: Executing task ${task.id} (${task.name})');

      // 获取最新的任务状态
      final currentTask = _getTask(task.id);
      if (currentTask == null) {
        debugPrint('TaskManager: Task ${task.id} not found, stopping');
        timer.cancel();
        return;
      }

      // 执行截图
      try {
        if (currentTask.windowId != null && currentTask.windowId!.isNotEmpty) {
          await _plugin.captureWindow(currentTask.windowId!);
        } else {
          await _plugin.captureFullScreen();
        }

        // 使用最新任务状态更新计数
        _updateTaskState(
          task.id,
          currentTask.copyWith(
            completedShots: currentTask.completedShots + 1,
            lastShotTime: DateTime.now(),
          ),
        );

        // 再次获取最新状态检查是否完成
        final updatedTask = _getTask(task.id);
        if (updatedTask != null && updatedTask.isCompleted) {
          debugPrint(
            'TaskManager: Task ${task.id} completed (${updatedTask.completedShots}/${updatedTask.totalShots})',
          );
          _stopTask(task.id);
          _updateTaskState(
            task.id,
            updatedTask.copyWith(status: TaskStatus.completed),
          );
        }
      } catch (e) {
        debugPrint('TaskManager: Error executing task ${task.id}: $e');
        // 出错时暂停任务
        pauseTask(task.id);
      }
    });

    _timers[task.id] = timer;
    debugPrint('TaskManager: Started task ${task.id}');
  }

  /// 暂停任务
  void pauseTask(String taskId) {
    final task = _getTask(taskId);
    if (task == null || task.status != TaskStatus.running) {
      debugPrint('TaskManager: Cannot pause task $taskId (not running)');
      return;
    }

    _stopTask(taskId);
    _updateTaskState(taskId, task.copyWith(status: TaskStatus.paused));
    debugPrint('TaskManager: Paused task $taskId');
  }

  /// 恢复任务
  void resumeTask(String taskId) {
    final task = _getTask(taskId);
    if (task == null || task.status != TaskStatus.paused) {
      debugPrint('TaskManager: Cannot resume task $taskId (not paused)');
      return;
    }

    _updateTaskState(taskId, task.copyWith(status: TaskStatus.running));
    _startTask(task);
    debugPrint('TaskManager: Resumed task $taskId');
  }

  /// 停止任务
  void _stopTask(String taskId) {
    _timers[taskId]?.cancel();
    _timers.remove(taskId);
    debugPrint('TaskManager: Stopped task $taskId');
  }

  /// 删除任务
  void deleteTask(String taskId) {
    _stopTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _notifyChanged();
    debugPrint('TaskManager: Deleted task $taskId');
  }

  /// 更新任务状态
  void _updateTaskState(String taskId, RecurringScreenshotTask newTask) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = newTask;
      _notifyChanged();
    }
  }

  /// 获取任务
  RecurringScreenshotTask? _getTask(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// 通知任务状态变化
  void _notifyChanged() {
    _onTasksChanged?.call();
  }

  /// 停止所有任务（插件销毁时调用）
  void stopAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    // 将所有运行中的任务改为暂停状态
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].status == TaskStatus.running) {
        _tasks[i] = _tasks[i].copyWith(status: TaskStatus.paused);
      }
    }

    debugPrint('TaskManager: Stopped all tasks');
  }

  /// 从 JSON 加载任务
  void loadTasksFromJson(List<dynamic> jsonList) {
    _tasks.clear();
    for (final json in jsonList) {
      if (json is Map<String, dynamic>) {
        try {
          final task = RecurringScreenshotTask.fromJson(json);
          _tasks.add(task);

          // 如果任务是运行中状态，改为暂停（因为刚启动）
          if (task.status == TaskStatus.running) {
            _tasks[_tasks.length - 1] = task.copyWith(
              status: TaskStatus.paused,
            );
          }
        } catch (e) {
          debugPrint('TaskManager: Failed to load task: $e');
        }
      }
    }

    debugPrint('TaskManager: Loaded ${_tasks.length} tasks from JSON');
    _notifyChanged();
  }

  /// 导出任务到 JSON
  List<Map<String, dynamic>> exportTasksToJson() {
    return _tasks.map((t) => t.toJson()).toList();
  }

  /// 释放资源
  void dispose() {
    stopAll();
    _tasks.clear();
    _onTasksChanged = null;
    debugPrint('TaskManager: Disposed');
  }
}
