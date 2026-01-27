library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../screenshot_plugin.dart';
import '../models/screenshot_models.dart';
import '../models/recurring_screenshot_task.dart';

/// 窗口截图和循环任务管理界面
class WindowCaptureScreen extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const WindowCaptureScreen({super.key, required this.plugin});

  @override
  State<WindowCaptureScreen> createState() => _WindowCaptureScreenState();
}

class _WindowCaptureScreenState extends State<WindowCaptureScreen> {
  /// 可用窗口列表
  List<WindowInfo> _windows = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 定时刷新任务状态的Timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWindows();
    // 每秒刷新一次任务状态，实时显示进度
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 开始定期刷新任务状态
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 触发UI重建，显示最新的任务进度
        });
      }
    });
  }

  /// 加载窗口列表
  Future<void> _loadWindows() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final windows = await widget.plugin.getAvailableWindows();
      if (mounted) {
        setState(() {
          _windows = windows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载窗口列表失败: $e')));
      }
    }
  }

  /// 截取全屏
  Future<void> _captureFullScreen() async {
    try {
      final l10n = AppLocalizations.of(context)!;

      // 隐藏当前窗口
      Navigator.of(context).pop();

      // 等待窗口关闭
      await Future.delayed(const Duration(milliseconds: 300));

      // 执行全屏截图
      await widget.plugin.captureFullScreen();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_capturing),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to capture full screen: $e');
    }
  }

  /// 截取指定窗口
  Future<void> _captureWindow(String windowId) async {
    try {
      await widget.plugin.captureWindow(windowId);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_capturing),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to capture window: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('截图失败: $e')));
      }
    }
  }

  /// 创建循环任务
  Future<void> _createRecurringTask(
    String? windowId,
    String? windowTitle,
  ) async {
    final result = await Navigator.of(context).push<RecurringScreenshotTask>(
      MaterialPageRoute(
        builder: (context) =>
            _CreateTaskDialog(windowId: windowId, windowTitle: windowTitle),
      ),
    );

    if (result != null && mounted) {
      // 使用插件层创建任务
      widget.plugin.createRecurringTask(
        name: result.name,
        windowId: result.windowId,
        windowTitle: result.windowTitle,
        intervalSeconds: result.intervalSeconds,
        totalShots: result.totalShots,
        saveDirectory: result.saveDirectory,
      );

      // 手动刷新 UI
      setState(() {});
    }
  }

  /// 暂停/恢复任务
  void _toggleTask(RecurringScreenshotTask task) {
    if (task.status == TaskStatus.running) {
      widget.plugin.pauseRecurringTask(task.id);
    } else {
      widget.plugin.resumeRecurringTask(task.id);
    }
    // 手动刷新 UI
    setState(() {});
  }

  /// 删除任务
  void _deleteTask(String taskId) {
    widget.plugin.deleteRecurringTask(taskId);
    // 手动刷新 UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshot_window_capture_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Row(
        children: [
          // 左侧：窗口列表
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 标题和刷新按钮
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.screenshot_available_windows,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadWindows,
                          tooltip: l10n.screenshot_refresh,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 全屏截图按钮（置顶）
                  ListTile(
                    leading: const Icon(Icons.fullscreen, size: 32),
                    title: Text(l10n.screenshot_fullscreen_capture),
                    subtitle: Text(l10n.screenshot_fullscreen_hint),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_camera),
                          tooltip: l10n.screenshot_capture,
                          onPressed: _captureFullScreen,
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer),
                          tooltip: l10n.screenshot_create_recurring_task,
                          onPressed: () => _createRecurringTask(null, null),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 窗口列表
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _windows.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.window,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.screenshot_no_windows,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _windows.length,
                            itemBuilder: (context, index) {
                              final window = _windows[index];
                              return ListTile(
                                leading: _buildWindowIcon(window),
                                title: Text(
                                  window.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: window.appName != null
                                    ? Text(
                                        window.appName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : null,
                                trailing: SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.photo_camera),
                                        tooltip: l10n.screenshot_capture,
                                        onPressed: () =>
                                            _captureWindow(window.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.timer),
                                        tooltip: l10n
                                            .screenshot_create_recurring_task,
                                        onPressed: () => _createRecurringTask(
                                          window.id,
                                          window.title,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // 右侧：循环任务列表
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 标题
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.screenshot_recurring_tasks,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  // 任务列表
                  Expanded(
                    child: widget.plugin.recurringTasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.screenshot_no_tasks,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.screenshot_create_task_hint,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.plugin.recurringTasks.length,
                            itemBuilder: (context, index) {
                              final task = widget.plugin.recurringTasks[index];
                              return _TaskListTile(
                                task: task,
                                onToggle: () => _toggleTask(task),
                                onDelete: () => _deleteTask(task.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建窗口图标
  Widget _buildWindowIcon(WindowInfo window) {
    if (window.icon != null && window.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          window.icon!,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.window, size: 32);
          },
        ),
      );
    }
    return const Icon(Icons.window, size: 32);
  }
}

/// 任务列表项
class _TaskListTile extends StatelessWidget {
  final RecurringScreenshotTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskListTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.formattedWindowInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 播放/暂停按钮
                    IconButton(
                      icon: Icon(
                        task.status == TaskStatus.running
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: onToggle,
                      tooltip: task.status == TaskStatus.running
                          ? l10n.screenshot_pause_task
                          : l10n.screenshot_resume_task,
                    ),
                    // 删除按钮
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                      tooltip: l10n.screenshot_delete_task,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 进度和统计信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${l10n.screenshot_interval}: ${task.formattedInterval}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${l10n.screenshot_completed}: ${task.completedShots}${task.isInfinite ? '' : '/${task.totalShots}'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (!task.isInfinite)
                        LinearProgressIndicator(
                          value: task.progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 创建任务对话框
class _CreateTaskDialog extends StatefulWidget {
  final String? windowId;
  final String? windowTitle;

  const _CreateTaskDialog({this.windowId, this.windowTitle});

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _secondsController = TextEditingController(text: '10');
  final _totalShotsController = TextEditingController(text: '10');
  final _directoryController = TextEditingController();

  bool _isInfinite = false;
  bool _useDefaultDirectory = true;

  @override
  void initState() {
    super.initState();
    if (widget.windowTitle != null) {
      _nameController.text = '${widget.windowTitle} 循环截图';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _totalShotsController.dispose();
    _directoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.screenshot_create_recurring_task),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 任务名称
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.screenshot_task_name,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.screenshot_task_name_required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 截图间隔（时分秒）
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '小时',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入小时';
                        }
                        final hours = int.tryParse(value);
                        if (hours == null || hours < 0) {
                          return '小时必须≥0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '分钟',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入分钟';
                        }
                        final minutes = int.tryParse(value);
                        if (minutes == null || minutes < 0 || minutes > 59) {
                          return '分钟0-59';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '秒',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入秒';
                        }
                        final seconds = int.tryParse(value);
                        if (seconds == null || seconds < 0 || seconds > 59) {
                          return '秒0-59';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 总截图次数
              Row(
                children: [
                  Checkbox(
                    value: _isInfinite,
                    onChanged: (value) {
                      setState(() {
                        _isInfinite = value!;
                      });
                    },
                  ),
                  Text(l10n.screenshot_infinite_execution),
                ],
              ),
              const SizedBox(height: 8),
              if (!_isInfinite)
                TextFormField(
                  controller: _totalShotsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.screenshot_total_shots,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.screenshot_total_shots_required;
                    }
                    final shots = int.tryParse(value);
                    if (shots == null || shots < 1) {
                      return l10n.screenshot_total_shots_invalid;
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              // 存放目录
              Row(
                children: [
                  Checkbox(
                    value: _useDefaultDirectory,
                    onChanged: (value) {
                      setState(() {
                        _useDefaultDirectory = value!;
                      });
                    },
                  ),
                  Text(l10n.screenshot_use_default_directory),
                ],
              ),
              const SizedBox(height: 8),
              if (!_useDefaultDirectory)
                TextFormField(
                  controller: _directoryController,
                  decoration: InputDecoration(
                    labelText: l10n.screenshot_save_directory,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.folder_open),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _createTask,
          child: Text(l10n.screenshot_create),
        ),
      ],
    );
  }

  void _createTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 计算间隔秒数（时+分+秒）
    final hours = int.parse(_hoursController.text);
    final minutes = int.parse(_minutesController.text);
    final seconds = int.parse(_secondsController.text);
    final intervalSeconds = hours * 3600 + minutes * 60 + seconds;

    // 验证间隔范围（1秒到24小时）
    if (intervalSeconds < 1 || intervalSeconds > 86400) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('间隔必须在1秒到24小时之间')));
      return;
    }

    final task = RecurringScreenshotTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      windowId: widget.windowId,
      windowTitle: widget.windowTitle,
      intervalSeconds: intervalSeconds,
      totalShots: _isInfinite ? null : int.parse(_totalShotsController.text),
      saveDirectory: _useDefaultDirectory ? null : _directoryController.text,
      status: TaskStatus.running,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(task);
  }
}
