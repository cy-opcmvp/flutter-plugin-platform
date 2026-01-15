/// Service Test Screen
///
/// A comprehensive test UI for all platform services.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:plugin_platform/core/services/platform_service_manager.dart';
import 'package:plugin_platform/core/interfaces/services/i_notification_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_task_scheduler_service.dart';

/// Service Test Screen
///
/// Provides a UI to test all platform services:
/// - Notifications
/// - Audio playback
/// - Task scheduling
class ServiceTestScreen extends StatefulWidget {
  const ServiceTestScreen({Key? key}) : super(key: key);

  @override
  State<ServiceTestScreen> createState() => _ServiceTestScreenState();
}

class _ServiceTestScreenState extends State<ServiceTestScreen> {
  final TextEditingController _notificationTitleController =
      TextEditingController(text: 'Test Notification');
  final TextEditingController _notificationBodyController =
      TextEditingController(text: 'This is a test notification from the platform services!');
  final TextEditingController _countdownSecondsController =
      TextEditingController(text: '10');
  final TextEditingController _taskIntervalController =
      TextEditingController(text: '5');

  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  bool _notificationPermissionGranted = false;
  int? _activeCountdown;
  String? _activeTaskId;
  List<ScheduledTask> _activeTasks = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupTaskListeners();
    _addLog('Service Test Screen initialized');
    // Delay task refresh to after init
    Future.microtask(() => _refreshActiveTasks());
  }

  @override
  void dispose() {
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    _countdownSecondsController.dispose();
    _taskIntervalController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _checkPermissions() async {
    final granted = await PlatformServiceManager.notification.checkPermissions();
    setState(() {
      _notificationPermissionGranted = granted;
    });
  }

  void _setupTaskListeners() {
    PlatformServiceManager.taskScheduler.onTaskComplete.listen((event) {
      _addLog('✅ Task completed: ${event.taskId}');
      _refreshActiveTasks();
    });

    PlatformServiceManager.taskScheduler.onTaskFailed.listen((event) {
      _addLog('❌ Task failed: ${event.taskId} - ${event.error}');
      _refreshActiveTasks();
    });
  }

  Future<void> _refreshActiveTasks() async {
    final tasks = await PlatformServiceManager.taskScheduler.getActiveTasks();
    setState(() {
      _activeTasks = tasks;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Platform Services Test'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
              Tab(text: 'Audio', icon: Icon(Icons.volume_up)),
              Tab(text: 'Tasks', icon: Icon(Icons.schedule)),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationTab(),
                  _buildAudioTab(),
                  _buildTaskTab(),
                ],
              ),
            ),
            _buildLogPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTab() {
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
                            ? 'Notification Permission Granted'
                            : 'Notification Permission Not Granted',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_notificationPermissionGranted)
                    ElevatedButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon: const Icon(Icons.security),
                      label: const Text('Request Permission'),
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
          TextField(
            controller: _notificationTitleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notificationBodyController,
            decoration: const InputDecoration(
              labelText: 'Notification Body',
              border: OutlineInputBorder(),
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
                label: const Text('Show Now'),
              ),
              ElevatedButton.icon(
                onPressed: _showScheduledNotification,
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule (5s)'),
              ),
              ElevatedButton.icon(
                onPressed: _cancelAllNotifications,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Cancel All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTab() {
    final audioServiceAvailable = PlatformServiceManager.isServiceAvailable<IAudioService>();

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
                  const Text(
                    'Test various audio playback features',
                    style: TextStyle(fontSize: 16),
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
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Audio service is not available on this platform. '
                              'Some features may be disabled.',
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
            'Notification Sound',
            Icons.notifications,
            SystemSoundType.notification,
            Colors.blue,
          ),
          _buildSoundButton(
            'Success Sound',
            Icons.check_circle,
            SystemSoundType.success,
            Colors.green,
          ),
          _buildSoundButton(
            'Error Sound',
            Icons.error,
            SystemSoundType.error,
            Colors.red,
          ),
          _buildSoundButton(
            'Warning Sound',
            Icons.warning,
            SystemSoundType.warning,
            Colors.orange,
          ),
          _buildSoundButton(
            'Click Sound',
            Icons.touch_app,
            SystemSoundType.click,
            Colors.purple,
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
                        const Text('Global Volume'),
                        Slider(
                          value: 0.8,
                          divisions: 10,
                          label: '80%',
                          onChanged: PlatformServiceManager.isServiceAvailable<IAudioService>()
                              ? (value) {
                                  PlatformServiceManager.audio.setGlobalVolume(value);
                                  _addLog('Volume set to ${(value * 100).toInt()}%');
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
            onPressed: PlatformServiceManager.isServiceAvailable<IAudioService>()
                ? () {
                    PlatformServiceManager.audio.stopAll();
                    _addLog('Stopped all audio playback');
                  }
                : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop All Audio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundButton(
    String label,
    IconData icon,
    SystemSoundType soundType,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: const Icon(Icons.play_arrow),
        onTap: PlatformServiceManager.isServiceAvailable<IAudioService>()
            ? () async {
                try {
                  await PlatformServiceManager.audio.playSystemSound(soundType: soundType);
                  _addLog('Played $label');
                } catch (e) {
                  _addLog('Error playing $label: $e');
                  _showErrorDialog('Error playing sound: $e');
                }
              }
            : () {
                _addLog('⚠️ Audio service is not available');
                _showErrorDialog('Audio service is not available on this platform');
              },
      ),
    );
  }

  Widget _buildTaskTab() {
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
                          'Countdown Timer',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_activeCountdown != null)
                        Chip(
                          label: Text('$_activeCountdown s'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _countdownSecondsController,
                    decoration: const InputDecoration(
                      labelText: 'Seconds',
                      border: OutlineInputBorder(),
                      suffixText: 's',
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
                        label: const Text('Start'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _activeCountdown != null
                            ? _cancelCountdown
                            : null,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
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
                          'Periodic Task',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskIntervalController,
                    decoration: const InputDecoration(
                      labelText: 'Interval',
                      border: OutlineInputBorder(),
                      suffixText: 's',
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
                        label: const Text('Start'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _activeTaskId != null
                            ? _cancelPeriodicTask
                            : null,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Stop'),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Tasks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${_activeTasks.length} tasks'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_activeTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No active tasks'),
                    )
                  else
                    ..._activeTasks.map((task) => ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(task.id),
                          subtitle: Text(
                              task.type == 'one_shot'
                                  ? 'At ${task.scheduledTime}'
                                  : 'Every ${task.interval}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () async {
                              await PlatformServiceManager.taskScheduler
                                  .cancelTask(task.id);
                              _addLog('Cancelled task: ${task.id}');
                              await _refreshActiveTasks();
                            },
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Log',
                  style: TextStyle(
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
                  icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                  label: const Text('Clear',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton.icon(
                  onPressed: _logs.isEmpty
                      ? null
                      : () {
                          final logText = _logs.join('\n');
                          flutter_services.Clipboard.setData(flutter_services.ClipboardData(text: logText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All logs copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_all, size: 16, color: Colors.white70),
                  label: const Text('Copy All',
                      style: TextStyle(color: Colors.white70)),
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
                    flutter_services.Clipboard.setData(flutter_services.ClipboardData(text: _logs[index]));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Log entry copied'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Copy single log entry on long press
                    flutter_services.Clipboard.setData(flutter_services.ClipboardData(text: _logs[index]));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log entry copied'),
                        duration: Duration(seconds: 1),
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
    final granted = await PlatformServiceManager.notification
        .requestPermissions();
    setState(() {
      _notificationPermissionGranted = granted;
    });
    _addLog('Notification permission ${granted ? "granted" : "denied"}');
  }

  Future<void> _showImmediateNotification() async {
    try {
      await PlatformServiceManager.notification.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _notificationTitleController.text,
        body: _notificationBodyController.text,
        priority: NotificationPriority.high,
      );
      _addLog('✅ Notification shown');
    } catch (e) {
      _addLog('❌ Error showing notification: $e');
      _showErrorDialog('Error showing notification: $e');
    }
  }

  Future<void> _showScheduledNotification() async {
    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
      await PlatformServiceManager.notification.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _notificationTitleController.text,
        body: _notificationBodyController.text,
        scheduledTime: scheduledTime,
        priority: NotificationPriority.high,
      );
      _addLog('✅ Notification scheduled for 5 seconds from now');
    } catch (e) {
      _addLog('❌ Error scheduling notification: $e');
      _showErrorDialog('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await PlatformServiceManager.notification.cancelAllNotifications();
      _addLog('✅ All notifications cancelled');
    } catch (e) {
      _addLog('❌ Error cancelling notifications: $e');
      _showErrorDialog('Error cancelling notifications: $e');
    }
  }

  Future<void> _startCountdown() async {
    final seconds = int.tryParse(_countdownSecondsController.text);
    if (seconds == null || seconds < 1) {
      _showErrorDialog('Please enter a valid number of seconds');
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
              await PlatformServiceManager.audio
                  .playSystemSound(soundType: SystemSoundType.notification);
            } catch (e) {
              _addLog('⚠️ Could not play sound: $e');
            }
          }

          // Show notification
          await PlatformServiceManager.notification.showNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Countdown Complete!',
            body: 'Your countdown has finished.',
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

      _addLog('✅ Countdown started: $seconds seconds');

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
      _addLog('❌ Error starting countdown: $e');
      _showErrorDialog('Error starting countdown: $e');
    }
  }

  Future<void> _cancelCountdown() async {
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

      _addLog('✅ Countdown cancelled');
    } catch (e) {
      _addLog('❌ Error cancelling countdown: $e');
      _showErrorDialog('Error cancelling countdown: $e');
    }
  }

  Future<void> _startPeriodicTask() async {
    final interval = int.tryParse(_taskIntervalController.text);
    if (interval == null || interval < 1) {
      _showErrorDialog('Please enter a valid interval');
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
              await PlatformServiceManager.audio
                  .playSystemSound(soundType: SystemSoundType.click);
            } catch (e) {
              _addLog('⚠️ Could not play sound: $e');
            }
          }
          _addLog('🔄 Periodic task executed');
        },
      );

      setState(() {
        _activeTaskId = taskId;
      });

      await _refreshActiveTasks();
      _addLog('✅ Periodic task started: every $interval seconds');
    } catch (e) {
      _addLog('❌ Error starting periodic task: $e');
      _showErrorDialog('Error starting periodic task: $e');
    }
  }

  Future<void> _cancelPeriodicTask() async {
    if (_activeTaskId == null) return;

    try {
      await PlatformServiceManager.taskScheduler.cancelTask(_activeTaskId!);

      setState(() {
        _activeTaskId = null;
      });

      await _refreshActiveTasks();
      _addLog('✅ Periodic task cancelled');
    } catch (e) {
      _addLog('❌ Error cancelling periodic task: $e');
      _showErrorDialog('Error cancelling periodic task: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SelectionArea(
          child: Text(message),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              flutter_services.Clipboard.setData(flutter_services.ClipboardData(text: message));
              Navigator.of(context).pop();
              _addLog('✅ Error message copied to clipboard');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
