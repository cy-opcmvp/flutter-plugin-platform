/// Service Test Screen
///
/// A comprehensive test UI for all platform services.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:plugin_platform/core/services/platform_service_manager.dart';
import 'package:plugin_platform/core/interfaces/services/i_notification_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_task_scheduler_service.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';

/// Service Test Screen
///
/// Provides a UI to test all platform services:
/// - Notifications
/// - Audio playback
/// - Task scheduling
class ServiceTestScreen extends StatefulWidget {
  const ServiceTestScreen({super.key});

  @override
  State<ServiceTestScreen> createState() => _ServiceTestScreenState();
}

class _ServiceTestScreenState extends State<ServiceTestScreen> {
  late final TextEditingController _notificationTitleController;
  late final TextEditingController _notificationBodyController;
  final TextEditingController _countdownSecondsController =
      TextEditingController(text: '10');
  final TextEditingController _taskIntervalController = TextEditingController(
    text: '5',
  );

  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  bool _notificationPermissionGranted = false;
  int? _activeCountdown;
  String? _activeTaskId;
  List<ScheduledTask> _activeTasks = [];

  // Stream subscriptions to cancel on dispose
  StreamSubscription<NotificationEvent>? _notificationClickSubscription;
  StreamSubscription<TaskEvent>? _taskCompleteSubscription;
  StreamSubscription<TaskEvent>? _taskFailedSubscription;

  @override
  void initState() {
    super.initState();
    // 初始化文本控制器（使用默认值，避免 late 初始化错误）
    _notificationTitleController = TextEditingController();
    _notificationBodyController = TextEditingController();

    // 在第一帧后设置国际化文本
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        _notificationTitleController.text =
            l10n.serviceTest_defaultNotificationTitle;
        _notificationBodyController.text =
            l10n.serviceTest_defaultNotificationBody;
        _addLog(l10n.serviceTest_serviceTestInitialized);
      }
    });

    _checkPermissions();
    _setupTaskListeners();
    _setupNotificationListener();
    // Delay task refresh to after init
    Future.microtask(() => _refreshActiveTasks());
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _notificationClickSubscription?.cancel();
    _taskCompleteSubscription?.cancel();
    _taskFailedSubscription?.cancel();

    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    _countdownSecondsController.dispose();
    _taskIntervalController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _checkPermissions() async {
    final granted = await PlatformServiceManager.notification
        .checkPermissions();
    setState(() {
      _notificationPermissionGranted = granted;
    });
  }

  void _setupTaskListeners() {
    _taskCompleteSubscription = PlatformServiceManager
        .taskScheduler
        .onTaskComplete
        .listen((event) {
          if (!mounted) return;

          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            _addLog('✅ ${l10n.serviceTest_taskCompleted}: ${event.taskId}');
          }
          _refreshActiveTasks();
        });

    _taskFailedSubscription = PlatformServiceManager.taskScheduler.onTaskFailed
        .listen((event) {
          if (!mounted) return;

          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            _addLog(
              '❌ ${l10n.serviceTest_taskFailed}: ${event.taskId} - ${event.error}',
            );
          }
          _refreshActiveTasks();
        });
  }

  void _setupNotificationListener() {
    _notificationClickSubscription = PlatformServiceManager
        .notification
        .onNotificationClick
        .listen((event) {
          // Check if widget is still mounted before using context
          if (!mounted) return;

          // On Windows, show notification as SnackBar
          if (Theme.of(context).platform == TargetPlatform.windows) {
            final payload = event.payload;
            if (payload != null && payload.contains('|')) {
              final parts = payload.split('|');
              if (parts.length >= 2) {
                final title = parts[0];
                final body = parts[1];
                _showNotificationSnackBar(title, body);
              }
            }
          }
        });
  }

  void _showNotificationSnackBar(String title, String body) {
    if (!mounted) return;

    // 获取 ScaffoldMessenger 和关闭按钮文本的引用
    final messenger = ScaffoldMessenger.of(context);
    final closeLabel = AppLocalizations.of(context)!.common_close;

    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: closeLabel,
          textColor: Colors.white,
          onPressed: () {
            // 使用捕获的 messenger 引用而不是 context
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _refreshActiveTasks() async {
    final tasks = await PlatformServiceManager.taskScheduler.getActiveTasks();
    setState(() {
      _activeTasks = tasks;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(
        '[${DateTime.now().toIso8601String().substring(11, 19)}] $message',
      );
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.serviceTest_title),
          bottom: TabBar(
            tabs: [
              Tab(
                text: l10n.serviceTest_notifications,
                icon: const Icon(Icons.notifications),
              ),
              Tab(
                text: l10n.serviceTest_audio,
                icon: const Icon(Icons.volume_up),
              ),
              Tab(
                text: l10n.serviceTest_tasks,
                icon: const Icon(Icons.schedule),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationTab(l10n),
                  _buildAudioTab(l10n),
                  _buildTaskTab(l10n),
                ],
              ),
            ),
            _buildLogPanel(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTab(AppLocalizations l10n) {
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _notificationPermissionGranted
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _notificationPermissionGranted
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _notificationPermissionGranted
                            ? l10n.serviceTest_permissionGranted
                            : l10n.serviceTest_permissionNotGranted,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_notificationPermissionGranted)
                    ElevatedButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon: const Icon(Icons.security),
                      label: Text(l10n.serviceTest_requestPermission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Windows platform notice
          if (isWindows)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.serviceTest_windowsPlatform,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.serviceTest_windowsNotice,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isWindows) const SizedBox(height: 16),
          TextField(
            controller: _notificationTitleController,
            decoration: InputDecoration(
              labelText: l10n.serviceTest_notificationTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notificationBodyController,
            decoration: InputDecoration(
              labelText: l10n.serviceTest_notificationBody,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _showImmediateNotification,
                icon: const Icon(Icons.send),
                label: Text(l10n.serviceTest_showNow),
              ),
              ElevatedButton.icon(
                onPressed: _showScheduledNotification,
                icon: const Icon(Icons.schedule),
                label: Text(l10n.serviceTest_schedule),
              ),
              ElevatedButton.icon(
                onPressed: _cancelAllNotifications,
                icon: const Icon(Icons.delete_sweep),
                label: Text(l10n.serviceTest_cancelAll),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 56), // 底部间距，留出空间给日志面板
        ],
      ),
    );
  }

  Widget _buildAudioTab(AppLocalizations l10n) {
    final audioServiceAvailable =
        PlatformServiceManager.isServiceAvailable<IAudioService>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.serviceTest_testAudioFeatures,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (!audioServiceAvailable)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.serviceTest_audioNotAvailable,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSoundButton(
            l10n.serviceTest_notificationSound,
            Icons.notifications,
            SystemSoundType.notification,
            Colors.blue,
            l10n,
          ),
          _buildSoundButton(
            l10n.serviceTest_successSound,
            Icons.check_circle,
            SystemSoundType.success,
            Colors.green,
            l10n,
          ),
          _buildSoundButton(
            l10n.serviceTest_errorSound,
            Icons.error,
            SystemSoundType.error,
            Colors.red,
            l10n,
          ),
          _buildSoundButton(
            l10n.serviceTest_warningSound,
            Icons.warning,
            SystemSoundType.warning,
            Colors.orange,
            l10n,
          ),
          _buildSoundButton(
            l10n.serviceTest_clickSound,
            Icons.touch_app,
            SystemSoundType.click,
            Colors.purple,
            l10n,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.volume_up),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.serviceTest_globalVolume),
                        Slider(
                          value: 0.8,
                          divisions: 10,
                          label: '80%',
                          onChanged:
                              PlatformServiceManager.isServiceAvailable<
                                IAudioService
                              >()
                              ? (value) {
                                  PlatformServiceManager.audio.setGlobalVolume(
                                    value,
                                  );
                                  _addLog(
                                    l10n.serviceTest_volumeSet(
                                      (value * 100).toInt(),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                PlatformServiceManager.isServiceAvailable<IAudioService>()
                ? () {
                    PlatformServiceManager.audio.stopAll();
                    _addLog(l10n.serviceTest_stoppedAllAudio);
                  }
                : null,
            icon: const Icon(Icons.stop),
            label: Text(l10n.serviceTest_stopAllAudio),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 56), // 底部间距，留出空间给日志面板
        ],
      ),
    );
  }

  Widget _buildSoundButton(
    String label,
    IconData icon,
    SystemSoundType soundType,
    Color color,
    AppLocalizations l10n,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: const Icon(Icons.play_arrow),
        onTap: PlatformServiceManager.isServiceAvailable<IAudioService>()
            ? () async {
                try {
                  await PlatformServiceManager.audio.playSystemSound(
                    soundType: soundType,
                  );
                  _addLog('✅ ${l10n.serviceTest_copied}: $label');
                } catch (e) {
                  _addLog('❌ ${l10n.serviceTest_errorPlayingSound}: $e');
                  _showErrorDialog(
                    '${l10n.serviceTest_errorPlayingSound}: $e',
                    l10n,
                  );
                }
              }
            : () {
                _addLog('⚠️ ${l10n.serviceTest_audioServiceUnavailable}');
                _showErrorDialog(
                  l10n.serviceTest_audioServiceNotAvailable,
                  l10n,
                );
              },
      ),
    );
  }

  Widget _buildTaskTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.serviceTest_countdownTimer,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_activeCountdown != null)
                        Chip(
                          label: Text(
                            '$_activeCountdown ${l10n.serviceTest_seconds}',
                          ),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _countdownSecondsController,
                    decoration: InputDecoration(
                      labelText: l10n.serviceTest_seconds,
                      border: const OutlineInputBorder(),
                      suffixText: l10n.serviceTest_seconds.substring(0, 1),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _activeCountdown == null
                            ? _startCountdown
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.serviceTest_start),
                      ),
                      ElevatedButton.icon(
                        onPressed: _activeCountdown != null
                            ? _cancelCountdown
                            : null,
                        icon: const Icon(Icons.cancel),
                        label: Text(l10n.serviceTest_cancel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.serviceTest_periodicTask,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskIntervalController,
                    decoration: InputDecoration(
                      labelText: l10n.serviceTest_interval,
                      border: const OutlineInputBorder(),
                      suffixText: l10n.serviceTest_seconds.substring(0, 1),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _activeTaskId == null
                            ? _startPeriodicTask
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.serviceTest_start),
                      ),
                      ElevatedButton.icon(
                        onPressed: _activeTaskId != null
                            ? _cancelPeriodicTask
                            : null,
                        icon: const Icon(Icons.cancel),
                        label: Text(l10n.serviceTest_cancel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 去掉 Card 的白色背景，使用 Container 替代
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent, // 透明背景
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.serviceTest_activeTasks,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${_activeTasks.length} ${l10n.serviceTest_tasks}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_activeTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l10n.serviceTest_noActiveTasks),
                    )
                  else
                    ..._activeTasks.map(
                      (task) => ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(task.id),
                        subtitle: Text(
                          task.type == 'one_shot'
                              ? '${l10n.serviceTest_at} ${task.scheduledTime}'
                              : '${l10n.serviceTest_every} ${task.interval}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () async {
                            await PlatformServiceManager.taskScheduler
                                .cancelTask(task.id);
                            _addLog(
                              '✅ ${l10n.serviceTest_taskCancelled}: ${task.id}',
                            );
                            await _refreshActiveTasks();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 56), // 底部间距，留出空间给日志面板
        ],
      ),
    );
  }

  Widget _buildLogPanel(AppLocalizations l10n) {
    return Container(
      height: 150, // 活动日志面板高度
      margin: const EdgeInsets.only(top: 16), // 往下移动，与上方内容拉开距离
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.serviceTest_activityLog,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                    size: 16,
                    color: Colors.white70,
                  ),
                  label: Text(
                    l10n.serviceTest_clear,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton.icon(
                  onPressed: _logs.isEmpty
                      ? null
                      : () {
                          final logText = _logs.join('\n');
                          flutter_services.Clipboard.setData(
                            flutter_services.ClipboardData(text: logText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.serviceTest_allLogsCopied),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: const Icon(
                    Icons.copy_all,
                    size: 16,
                    color: Colors.white70,
                  ),
                  label: Text(
                    l10n.serviceTest_copyAll,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    // Copy single log entry on tap
                    flutter_services.Clipboard.setData(
                      flutter_services.ClipboardData(text: _logs[index]),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.serviceTest_logCopied),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Copy single log entry on long press
                    flutter_services.Clipboard.setData(
                      flutter_services.ClipboardData(text: _logs[index]),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.serviceTest_logCopied),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectionArea(
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final l10n = AppLocalizations.of(context)!;
    final granted = await PlatformServiceManager.notification
        .requestPermissions();
    setState(() {
      _notificationPermissionGranted = granted;
    });
    _addLog(
      l10n.serviceTest_notificationPermission(
        granted ? l10n.serviceTest_granted : l10n.serviceTest_denied,
      ),
    );
  }

  Future<void> _showImmediateNotification() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await PlatformServiceManager.notification.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _notificationTitleController.text,
        body: _notificationBodyController.text,
        priority: NotificationPriority.high,
      );
      _addLog('✅ ${l10n.serviceTest_notificationShown}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorShowingNotification}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorShowingNotification}: $e',
        l10n,
      );
    }
  }

  Future<void> _showScheduledNotification() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
      await PlatformServiceManager.notification.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _notificationTitleController.text,
        body: _notificationBodyController.text,
        scheduledTime: scheduledTime,
        priority: NotificationPriority.high,
      );
      _addLog('✅ ${l10n.serviceTest_notificationScheduled}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorSchedulingNotification}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorSchedulingNotification}: $e',
        l10n,
      );
    }
  }

  Future<void> _cancelAllNotifications() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await PlatformServiceManager.notification.cancelAllNotifications();
      _addLog('✅ ${l10n.serviceTest_allNotificationsCancelled}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorCancellingNotifications}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorCancellingNotifications}: $e',
        l10n,
      );
    }
  }

  Future<void> _startCountdown() async {
    final l10n = AppLocalizations.of(context)!;
    final seconds = int.tryParse(_countdownSecondsController.text);
    if (seconds == null || seconds < 1) {
      _showErrorDialog(l10n.serviceTest_enterValidSeconds, l10n);
      return;
    }

    final taskId = 'countdown_${DateTime.now().millisecondsSinceEpoch}';
    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));

    try {
      await PlatformServiceManager.taskScheduler.scheduleOneShotTask(
        taskId: taskId,
        scheduledTime: scheduledTime,
        callback: (data) async {
          // Play notification sound (if available)
          if (PlatformServiceManager.isServiceAvailable<IAudioService>()) {
            try {
              await PlatformServiceManager.audio.playSystemSound(
                soundType: SystemSoundType.notification,
              );
            } catch (e) {
              _addLog('⚠️ ${l10n.serviceTest_couldNotPlaySound}: $e');
            }
          }

          // Show notification
          await PlatformServiceManager.notification.showNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: l10n.serviceTest_countdownComplete,
            body: l10n.serviceTest_countdownFinished,
            priority: NotificationPriority.high,
          );

          setState(() {
            _activeCountdown = null;
          });
        },
      );

      setState(() {
        _activeCountdown = seconds;
      });

      _addLog('✅ ${l10n.serviceTest_countdownStarted(seconds)}');

      // Update countdown display
      for (int i = seconds; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _activeCountdown != null) {
          setState(() {
            _activeCountdown = i - 1;
          });
        } else {
          break;
        }
      }
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorStartingCountdown}: $e');
      _showErrorDialog('${l10n.serviceTest_errorStartingCountdown}: $e', l10n);
    }
  }

  Future<void> _cancelCountdown() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Cancel all countdown tasks
      final tasks = await PlatformServiceManager.taskScheduler.getActiveTasks();
      for (final task in tasks) {
        if (task.id.startsWith('countdown_')) {
          await PlatformServiceManager.taskScheduler.cancelTask(task.id);
        }
      }

      setState(() {
        _activeCountdown = null;
      });

      _addLog('✅ ${l10n.serviceTest_countdownCancelled}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorCancellingCountdown}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorCancellingCountdown}: $e',
        l10n,
      );
    }
  }

  Future<void> _startPeriodicTask() async {
    final l10n = AppLocalizations.of(context)!;
    final interval = int.tryParse(_taskIntervalController.text);
    if (interval == null || interval < 1) {
      _showErrorDialog(l10n.serviceTest_enterValidInterval, l10n);
      return;
    }

    try {
      final taskId = await PlatformServiceManager.taskScheduler
          .schedulePeriodicTask(
            taskId: 'periodic_${DateTime.now().millisecondsSinceEpoch}',
            interval: Duration(seconds: interval),
            callback: (data) async {
              // Play a short sound (if available)
              if (PlatformServiceManager.isServiceAvailable<IAudioService>()) {
                try {
                  await PlatformServiceManager.audio.playSystemSound(
                    soundType: SystemSoundType.click,
                  );
                } catch (e) {
                  _addLog('⚠️ ${l10n.serviceTest_couldNotPlaySound}: $e');
                }
              }
              _addLog('🔄 ${l10n.serviceTest_periodicTaskExecuted}');
            },
          );

      setState(() {
        _activeTaskId = taskId;
      });

      await _refreshActiveTasks();
      _addLog('✅ ${l10n.serviceTest_periodicTaskStarted(interval)}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorStartingPeriodicTask}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorStartingPeriodicTask}: $e',
        l10n,
      );
    }
  }

  Future<void> _cancelPeriodicTask() async {
    final l10n = AppLocalizations.of(context)!;
    if (_activeTaskId == null) return;

    try {
      await PlatformServiceManager.taskScheduler.cancelTask(_activeTaskId!);

      setState(() {
        _activeTaskId = null;
      });

      await _refreshActiveTasks();
      _addLog('✅ ${l10n.serviceTest_periodicTaskCancelled}');
    } catch (e) {
      _addLog('❌ ${l10n.serviceTest_errorCancellingPeriodicTask}: $e');
      _showErrorDialog(
        '${l10n.serviceTest_errorCancellingPeriodicTask}: $e',
        l10n,
      );
    }
  }

  void _showErrorDialog(String message, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.serviceTest_error),
        content: SelectionArea(child: Text(message)),
        actions: [
          TextButton.icon(
            onPressed: () {
              flutter_services.Clipboard.setData(
                flutter_services.ClipboardData(text: message),
              );
              Navigator.of(context).pop();
              _addLog('✅ ${l10n.serviceTest_errorMessage}');
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.serviceTest_copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );
  }
}
