import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_plugin.dart';
import '../../core/models/plugin_models.dart';
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
  Timer? _clockUpdateTimer;
  Timer? _countdownUpdateTimer;

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

      // 启动时钟更新定时器
      _startClockTimer();

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
      _clockUpdateTimer?.cancel();
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

    // 重启定时器以应用新的更新间隔
    _clockUpdateTimer?.cancel();
    _startClockTimer();
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
        _startClockTimer();
        _startCountdownTimer();
        break;
      case PluginState.paused:
        await _saveCurrentState();
        break;
      case PluginState.inactive:
        _clockUpdateTimer?.cancel();
        _countdownUpdateTimer?.cancel();
        await _saveCurrentState();
        break;
      case PluginState.error:
        _clockUpdateTimer?.cancel();
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
      final clocksData = await _context.dataStorage.retrieve<List<dynamic>>(
        'worldClocks',
      );
      if (clocksData != null) {
        _worldClocks.clear();
        _worldClocks.addAll(
          clocksData
              .map(
                (data) => WorldClockItem.fromJson(data as Map<String, dynamic>),
              )
              .toList(),
        );
      }

      final timersData = await _context.dataStorage.retrieve<List<dynamic>>(
        'countdownTimers',
      );
      if (timersData != null) {
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
      await _context.dataStorage.store(
        'worldClocks',
        _worldClocks.map((clock) => clock.toJson()).toList(),
      );
      await _context.dataStorage.store(
        'countdownTimers',
        _countdownTimers.map((timer) => timer.toJson()).toList(),
      );

      // 保存设置
      // 设置已通过 _saveSettings() 保存
    } catch (e) {
      debugPrint('Failed to save state: $e');
    }
  }

  void _startClockTimer() {
    _clockUpdateTimer?.cancel();
    _clockUpdateTimer = Timer.periodic(
      Duration(milliseconds: _settings.updateInterval),
      (timer) => _onStateChanged?.call(),
    );
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
      // 使用硬编码的文本，因为 _context 不是 BuildContext
      await _context.platformServices.showNotification(
        '倒计时完成: ${timer.title}',
      );
    }
  }

  void addClock(String cityName, String timeZone) {
    final newClock = WorldClockItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cityName: cityName,
      timeZone: timeZone,
      isDefault: false,
    );

    _worldClocks.add(newClock);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void removeClock(String clockId) {
    _worldClocks.removeWhere((clock) => clock.id == clockId);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void addCountdownTimer(String title, Duration duration) {
    final newTimer = CountdownTimer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      endTime: DateTime.now().add(duration),
      isCompleted: false,
    );

    _countdownTimers.add(newTimer);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void removeCountdownTimer(String timerId) {
    _countdownTimers.removeWhere((timer) => timer.id == timerId);
    _saveCurrentState();
    _onStateChanged?.call();
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

  void _showAddClockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddClockDialog(
        onAdd: (cityName, timeZone) {
          widget.plugin.addClock(cityName, timeZone);
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
  final Function(String cityName, String timeZone) onAdd;

  const _AddClockDialog({required this.onAdd});

  @override
  State<_AddClockDialog> createState() => _AddClockDialogState();
}

class _AddClockDialogState extends State<_AddClockDialog> {
  final _cityController = TextEditingController();
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
  void initState() {
    super.initState();
    // 默认填充北京
    _cityController.text = '北京';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.worldClock_addCountdown),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: l10n.world_clock_city_name,
                hintText: l10n.world_clock_city_name_hint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
                    // 自动填充城市名称
                    final timeZone = _timeZones.firstWhere(
                      (tz) => tz['zone'] == value,
                    );
                    _cityController.text = timeZone['name']!;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _cityController.text.isEmpty
              ? null
              : () {
                  widget.onAdd(_cityController.text, _selectedTimeZone);
                  Navigator.of(context).pop();
                },
          child: Text(l10n.common_add),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
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
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isValid =
        _titleController.text.isNotEmpty &&
        (_hours > 0 || _minutes > 0 || _seconds > 0);

    return AlertDialog(
      title: Text(l10n.worldClock_addCountdown),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.worldClock_countdownTitle,
                hintText: l10n.worldClock_countdownTitleHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.world_clock_set_time,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimePickerColumn(
                  label: l10n.world_clock_hours,
                  value: _hours,
                  maxValue: 23,
                  onChanged: (value) => setState(() => _hours = value),
                ),
                _TimePickerColumn(
                  label: l10n.world_clock_minutes,
                  value: _minutes,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _minutes = value),
                ),
                _TimePickerColumn(
                  label: l10n.world_clock_seconds,
                  value: _seconds,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _seconds = value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

// 时间选择器列
class _TimePickerColumn extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const _TimePickerColumn({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_drop_up),
                onPressed: () {
                  if (value < maxValue) {
                    onChanged(value + 1);
                  }
                },
                iconSize: 20,
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () {
                  if (value > 0) {
                    onChanged(value - 1);
                  }
                },
                iconSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
