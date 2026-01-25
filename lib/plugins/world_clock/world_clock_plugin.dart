import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_plugin.dart';
import '../../core/interfaces/services/i_notification_service.dart';
import '../../core/models/plugin_models.dart';
import '../../core/services/platform_service_manager.dart';
import '../../core/utils/platform_capability_helper.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'models/world_clock_models.dart';
import 'models/world_clock_settings.dart';
import 'widgets/world_clock_widget.dart';
import 'widgets/countdown_timer_widget.dart';
import 'widgets/settings_screen.dart';

/// 世界时钟插件 - 显示多个时区时间并支持倒计时提醒
///
/// 平台支持：
/// - 所有平台: 完整支持（纯 Dart 实现）
class WorldClockPlugin extends PlatformPluginBase {
  late PluginContext _context;

  // 插件状态变量
  bool _isInitialized = false;
  final List<WorldClockItem> _worldClocks = [];
  final List<CountdownTimer> _countdownTimers = [];
  Timer? _countdownUpdateTimer;

  // 平台服务
  INotificationService get _notificationService =>
      PlatformServiceManager.notification;

  // 插件设置
  WorldClockSettings _settings = WorldClockSettings.defaultSettings();

  /// 获取插件初始化状态
  bool get isInitialized => _isInitialized;

  /// 获取世界时钟列表（只读）
  List<WorldClockItem> get worldClocks => List.unmodifiable(_worldClocks);

  /// 获取倒计时列表（只读）
  List<CountdownTimer> get countdownTimers => List.unmodifiable(_countdownTimers);

  // 用于触发UI更新的回调
  VoidCallback? _onStateChanged;

  // App 内通知回调
  Function(String message)? _showInAppNotification;

  @override
  String get id => 'com.example.worldclock';

  @override
  String get name => '世界时钟';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

  @override
  PluginPlatformCapabilities get platformCapabilities =>
      _platformCapabilities ??= _createPlatformCapabilities();

  static PluginPlatformCapabilities? _platformCapabilities;

  /// 创建平台能力配置
  PluginPlatformCapabilities _createPlatformCapabilities() {
    return PlatformCapabilityHelper.fullySupported(
      pluginId: id,
      description: '支持多时区显示和倒计时提醒功能（纯 Dart 实现）',
      hideIfUnsupported: false,
    );
  }

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    try {
      // 加载保存的设置
      final savedSettings = await _context.dataStorage
          .retrieve<Map<String, dynamic>>('world_clock_settings');
      if (savedSettings != null) {
        _settings = WorldClockSettings.fromJson(savedSettings);
      }

      // 加载保存的状态
      await _loadSavedState();

      // 如果没有保存的时钟，添加默认时区的时钟
      if (_worldClocks.isEmpty) {
        final defaultTz = _settings.defaultTimeZone;
        // 从 TimeZoneInfo 查找中文城市名，如果没有找到则使用时区ID提取的名称
        final timeZoneInfo = TimeZoneInfo.findByTimeZoneId(defaultTz);
        final cityName = timeZoneInfo?.displayName ?? defaultTz.split('/').last.replaceAll('_', ' ');
        _worldClocks.add(
          WorldClockItem(
            id: 'default',
            cityName: cityName,
            timeZone: defaultTz,
            isDefault: true,
          ),
        );
      }

      // 启动倒计时更新定时器
      _startCountdownTimer();

      _isInitialized = true;

      // 注意：这里不显示通知，因为 initialize() 中的 context 不是 BuildContext
      // 无法访问 AppLocalizations。插件初始化成功后会通过其他方式通知用户。
    } catch (e) {
      // 注意：这里不显示通知，原因同上
      debugPrint('WorldClock plugin initialization failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      // 保存当前状态
      await _saveCurrentState();

      // 停止定时器
      _countdownUpdateTimer?.cancel();

      _isInitialized = false;
    } catch (e) {
      debugPrint('World Clock plugin disposal error: $e');
    }
  }

  @override
  Widget buildUI(BuildContext context) {
    return _WorldClockPluginWidget(plugin: this);
  }

  /// 构建设置界面
  Widget buildSettingsScreen() {
    return WorldClockSettingsScreen(plugin: this);
  }

  /// 获取当前设置
  WorldClockSettings get settings => _settings;

  /// 更新设置
  void updateSettings(WorldClockSettings settings) {
    _settings = settings;
    _saveSettings();

    // 如果默认时区发生变化，更新默认时钟
    if (_worldClocks.isNotEmpty) {
      final defaultClock = _worldClocks.firstWhere(
        (clock) => clock.isDefault,
        orElse: () => _worldClocks.first,
      );

      // 如果默认时区改变，更新默认时钟的时区
      if (defaultClock.timeZone != settings.defaultTimeZone) {
        final timeZoneInfo = TimeZoneInfo.findByTimeZoneId(settings.defaultTimeZone);
        final cityName = timeZoneInfo?.displayName ?? settings.defaultTimeZone.split('/').last.replaceAll('_', ' ');

        // 更新默认时钟
        final index = _worldClocks.indexOf(defaultClock);
        _worldClocks[index] = WorldClockItem(
          id: defaultClock.id,
          cityName: cityName,
          timeZone: settings.defaultTimeZone,
          isDefault: true,
        );

        // 保存更新后的时钟列表
        _saveCurrentState();
      }
    }

    // 触发 UI 更新
    _onStateChanged?.call();
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    await _context.dataStorage.store(
      'world_clock_settings',
      _settings.toJson(),
    );
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        _startCountdownTimer();
        break;
      case PluginState.paused:
        await _saveCurrentState();
        break;
      case PluginState.inactive:
        _countdownUpdateTimer?.cancel();
        await _saveCurrentState();
        break;
      case PluginState.error:
        _countdownUpdateTimer?.cancel();
        break;
      case PluginState.loading:
        break;
    }
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return {
      'isInitialized': _isInitialized,
      'worldClocks': _worldClocks.map((clock) => clock.toJson()).toList(),
      'countdownTimers': _countdownTimers
          .map((timer) => timer.toJson())
          .toList(),
      'show24HourFormat': _settings.timeFormat == '24h',
      'showSeconds': _settings.showSeconds,
      'enableNotifications': _settings.enableNotifications,
      'enableAnimations': true, // 固定为true
      'lastUpdate': DateTime.now().toIso8601String(),
      'version': version,
    };
  }

  // 私有方法实现
  Future<void> _loadSavedState() async {
    try {
      // 加载世界时钟（从 JSON 字符串解析）
      final clocksJson = await _context.dataStorage.retrieve<String>('worldClocks');
      if (clocksJson != null && clocksJson.isNotEmpty) {
        final clocksData = jsonDecode(clocksJson) as List;
        _worldClocks.clear();
        _worldClocks.addAll(
          clocksData
              .map(
                (data) => WorldClockItem.fromJson(data as Map<String, dynamic>),
              )
              .toList(),
        );
      }

      // 加载倒计时（从 JSON 字符串解析）
      final timersJson = await _context.dataStorage.retrieve<String>('countdownTimers');
      if (timersJson != null && timersJson.isNotEmpty) {
        final timersData = jsonDecode(timersJson) as List;
        _countdownTimers.clear();
        _countdownTimers.addAll(
          timersData
              .map(
                (data) => CountdownTimer.fromJson(data as Map<String, dynamic>),
              )
              .toList(),
        );
      }

      // 加载设置
      // 设置已在 initialize() 中加载
    } catch (e) {
      debugPrint('Failed to load saved state: $e');
    }
  }

  Future<void> _saveCurrentState() async {
    try {
      // 将列表转为 JSON 字符串存储
      final clocksJson = jsonEncode(_worldClocks.map((clock) => clock.toJson()).toList());
      await _context.dataStorage.store('worldClocks', clocksJson);

      final timersJson = jsonEncode(_countdownTimers.map((timer) => timer.toJson()).toList());
      await _context.dataStorage.store('countdownTimers', timersJson);

      // 保存设置
      // 设置已通过 _saveSettings() 保存
    } catch (e) {
      debugPrint('Failed to save state: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownUpdateTimer?.cancel();
    _countdownUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdownTimers();
    });
  }

  void _updateCountdownTimers() {
    final now = DateTime.now();
    final completedTimers = <CountdownTimer>[];

    for (final timer in _countdownTimers) {
      if (timer.endTime.isBefore(now) && !timer.isCompleted) {
        timer.isCompleted = true;
        completedTimers.add(timer);
      }
    }

    // 处理完成的倒计时
    for (final timer in completedTimers) {
      onCountdownComplete(timer);
    }

    if (completedTimers.isNotEmpty) {
      _saveCurrentState();
      _onStateChanged?.call();
    }
  }

  void onCountdownComplete(CountdownTimer timer) async {
    if (_settings.enableNotifications) {
      if (_settings.notificationType == NotificationType.system) {
        // 使用系统通知
        await _context.platformServices.showNotification(
          '倒计时完成: ${timer.title}',
        );
      } else {
        // 使用 App 内通知（通过回调）
        _showInAppNotification?.call('倒计时完成: ${timer.title}');
      }
    }
  }

  void addClock(String timeZone) {
    // 获取当前时间戳（用于同步所有时钟）
    final now = DateTime.now();

    // 从 TimeZoneInfo 查找中文城市名
    final timeZoneInfo = TimeZoneInfo.findByTimeZoneId(timeZone);
    final cityName = timeZoneInfo?.displayName ?? timeZone.split('/').last.replaceAll('_', ' ');

    // 创建新时钟
    final newClock = WorldClockItem(
      id: now.millisecondsSinceEpoch.toString(),
      cityName: cityName,
      timeZone: timeZone,
      isDefault: false,
    );

    // 添加新时钟
    _worldClocks.add(newClock);

    // 刷新所有时钟（使用同一时间戳更新 ID，确保同步）
    for (int i = 0; i < _worldClocks.length - 1; i++) {
      final clock = _worldClocks[i];
      // 为保持同步，更新所有时钟的 ID 为同一时间戳
      _worldClocks[i] = WorldClockItem(
        id: now.millisecondsSinceEpoch.toString(),
        cityName: clock.cityName,
        timeZone: clock.timeZone,
        isDefault: clock.isDefault,
      );
    }

    _saveCurrentState();
    // 触发 UI 更新，确保所有时钟同时刷新显示
    _onStateChanged?.call();
  }

  void removeClock(String clockId) {
    _worldClocks.removeWhere((clock) => clock.id == clockId);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void addCountdownTimer(String title, Duration duration) async {
    final newTimer = CountdownTimer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      endTime: DateTime.now().add(duration),
      isCompleted: false,
    );

    // 如果启用了系统通知，安排倒计时结束通知
    if (_settings.enableNotifications &&
        _settings.notificationType == NotificationType.system) {
      try {
        // 请求通知权限
        final hasPermission =
            await _notificationService.checkPermissions();
        if (!hasPermission) {
          await _notificationService.requestPermissions();
        }

        // 安排在倒计时结束时显示通知
        await _notificationService.scheduleNotification(
          id: newTimer.id,
          title: title,
          body: _getCountdownCompleteMessage(title),
          scheduledTime: newTimer.endTime,
          priority: NotificationPriority.high,
        );
      } catch (e) {
        debugPrint('Failed to schedule notification: $e');
      }
    }

    _countdownTimers.add(newTimer);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void removeCountdownTimer(String timerId) async {
    // 取消已安排的系统通知
    if (_settings.enableNotifications &&
        _settings.notificationType == NotificationType.system) {
      try {
        await _notificationService.cancelNotification(timerId);
      } catch (e) {
        debugPrint('Failed to cancel notification: $e');
      }
    }

    _countdownTimers.removeWhere((timer) => timer.id == timerId);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  /// 生成倒计时完成消息
  String _getCountdownCompleteMessage(String title) {
    return '$title 已完成';
  }
}

// 插件UI Widget
class _WorldClockPluginWidget extends StatefulWidget {
  final WorldClockPlugin plugin;

  const _WorldClockPluginWidget({required this.plugin});

  @override
  State<_WorldClockPluginWidget> createState() =>
      _WorldClockPluginWidgetState();
}

class _WorldClockPluginWidgetState extends State<_WorldClockPluginWidget> {
  @override
  void initState() {
    super.initState();
    widget.plugin._onStateChanged = () {
      if (mounted) {
        setState(() {});
      }
    };

    // 设置 App 内通知回调
    widget.plugin._showInAppNotification = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.plugin.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plugin.name),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _showAddCountdownDialog(context),
            tooltip: l10n.worldclock_main_add_countdown,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClockDialog(context),
            tooltip: l10n.worldclock_main_add_clock,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      WorldClockSettingsScreen(plugin: widget.plugin),
                ),
              );
            },
            tooltip: l10n.worldclock_main_settings,
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 世界时钟区域
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.worldclock_main_world_clocks,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plugin.worldClocks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.worldclock_main_no_clocks,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.worldclock_main_add_clock_hint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...widget.plugin.worldClocks.map(
                          (clock) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: WorldClockWidget(
                              worldClock: clock,
                              showSeconds: widget.plugin.settings.showSeconds,
                              timeFormat: widget.plugin.settings.timeFormat,
                              onDelete: clock.isDefault
                                  ? null
                                  : () {
                                      widget.plugin.removeClock(clock.id);
                                    },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 倒计时区域
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.worldclock_main_countdown_timers,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plugin.countdownTimers.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.alarm_add,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.worldclock_main_no_countdowns,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.worldclock_main_add_countdown_hint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...widget.plugin.countdownTimers.map(
                          (timer) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CountdownTimerWidget(
                              countdownTimer: timer,
                              enableAnimations: true,
                              onDelete: () {
                                widget.plugin.removeCountdownTimer(timer.id);
                              },
                              onComplete: () {
                                widget.plugin.onCountdownComplete(timer);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 清理回调
    widget.plugin._showInAppNotification = null;
    super.dispose();
  }

  void _showAddClockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddClockDialog(
        onAdd: (timeZone) {
          widget.plugin.addClock(timeZone);
        },
      ),
    );
  }

  void _showAddCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddCountdownDialog(
        onAdd: (title, duration) {
          widget.plugin.addCountdownTimer(title, duration);
        },
      ),
    );
  }
}

// 添加时钟对话框
class _AddClockDialog extends StatefulWidget {
  final Function(String timeZone) onAdd;

  const _AddClockDialog({required this.onAdd});

  @override
  State<_AddClockDialog> createState() => _AddClockDialogState();
}

class _AddClockDialogState extends State<_AddClockDialog> {
  String _selectedTimeZone = 'Asia/Shanghai';

  final List<Map<String, String>> _timeZones = [
    {'name': '北京', 'zone': 'Asia/Shanghai'},
    {'name': '东京', 'zone': 'Asia/Tokyo'},
    {'name': '首尔', 'zone': 'Asia/Seoul'},
    {'name': '新加坡', 'zone': 'Asia/Singapore'},
    {'name': '悉尼', 'zone': 'Australia/Sydney'},
    {'name': '伦敦', 'zone': 'Europe/London'},
    {'name': '巴黎', 'zone': 'Europe/Paris'},
    {'name': '纽约', 'zone': 'America/New_York'},
    {'name': '洛杉矶', 'zone': 'America/Los_Angeles'},
    {'name': '芝加哥', 'zone': 'America/Chicago'},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.worldClock_addClock),
      content: DropdownButtonFormField<String>(
        value: _selectedTimeZone,
        decoration: InputDecoration(
          labelText: l10n.world_clock_time_zone,
          border: const OutlineInputBorder(),
        ),
        items: _timeZones.map((tz) {
          return DropdownMenuItem<String>(
            value: tz['zone'],
            child: Text(tz['name']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeZone = value;
            });
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onAdd(_selectedTimeZone);
            Navigator.of(context).pop();
          },
          child: Text(l10n.common_add),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// 添加倒计时对话框
class _AddCountdownDialog extends StatefulWidget {
  final Function(String title, Duration duration) onAdd;

  const _AddCountdownDialog({required this.onAdd});

  @override
  State<_AddCountdownDialog> createState() => _AddCountdownDialogState();
}

class _AddCountdownDialogState extends State<_AddCountdownDialog> {
  final _titleController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '5');
  final _secondsController = TextEditingController(text: '0');

  // 默认模板（可动态添加自定义模板）
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _templates = [
    {'name': '番茄时钟', 'hours': 0, 'minutes': 15, 'seconds': 0},
    {'name': '午休', 'hours': 1, 'minutes': 0, 'seconds': 0},
    {'name': '短休息', 'hours': 0, 'minutes': 5, 'seconds': 0},
    {'name': '长休息', 'hours': 0, 'minutes': 30, 'seconds': 0},
    {'name': '专注时段', 'hours': 2, 'minutes': 0, 'seconds': 0},
  ];

  int get _hours => int.tryParse(_hoursController.text) ?? 0;
  int get _minutes => int.tryParse(_minutesController.text) ?? 0;
  int get _seconds => int.tryParse(_secondsController.text) ?? 0;

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    // 设置标题
    _titleController.text = template['name'];
    // 设置时间
    _hoursController.text = template['hours'].toString();
    _minutesController.text = template['minutes'].toString();
    _secondsController.text = template['seconds'].toString();
    setState(() {});
  }

  void _addCustomTemplate() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入倒计时标题'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 检查是否时间全为0
    if (_hours == 0 && _minutes == 0 && _seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请设置倒计时时间'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 检查是否已存在同名模板
    final exists = _templates.any((t) => t['name'] == title);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('模板"$title"已存在'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 添加新模板
    setState(() {
      _templates.add({
        'name': title,
        'hours': _hours,
        'minutes': _minutes,
        'seconds': _seconds,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加模板"$title"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 默认模板列表（用于判断哪些是不可删除的）
  static const List<String> _defaultTemplateNames = [
    '番茄时钟',
    '午休',
    '短休息',
    '长休息',
    '专注时段',
  ];

  /// 判断是否为默认模板
  bool _isDefaultTemplate(String name) {
    return _defaultTemplateNames.contains(name);
  }

  /// 删除自定义模板
  void _deleteTemplate(String name) {
    setState(() {
      _templates.removeWhere((t) => t['name'] == name);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除模板"$name"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isValid =
        _titleController.text.isNotEmpty &&
        (_hours > 0 || _minutes > 0 || _seconds > 0);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                l10n.worldClock_addCountdown,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 标题输入
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.worldClock_countdownTitle,
                  hintText: l10n.worldClock_countdownTitleHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // 快速模板
              Text(
                '快速模板',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _templates.map((template) {
                  final name = template['name'] as String;
                  final isDefault = _isDefaultTemplate(name);

                  return InputChip(
                    label: Text(name),
                    onDeleted: isDefault ? null : () => _deleteTemplate(name),
                    deleteIcon: isDefault ? null : const Icon(Icons.close, size: 18),
                    onPressed: () => _applyTemplate(template),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 时间设置
              Text(
                l10n.world_clock_set_time,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 数字输入
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '小时',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '分钟',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '秒',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: isValid ? _addCustomTemplate : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新增模板', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.common_cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isValid
                        ? () {
                            final duration = Duration(
                              hours: _hours,
                              minutes: _minutes,
                              seconds: _seconds,
                            );
                            widget.onAdd(_titleController.text, duration);
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: Text(l10n.common_add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
