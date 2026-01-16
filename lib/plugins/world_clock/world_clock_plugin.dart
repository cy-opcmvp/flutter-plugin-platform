import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../core/utils/platform_capability_helper.dart';
import 'models/world_clock_models.dart';
import 'widgets/world_clock_widget.dart';
import 'widgets/countdown_timer_widget.dart';

/// 世界时钟插件 - 显示多个时区时间并支持倒计时提醒
///
/// 平台支持：
/// - 所有平台: 完整支持（纯 Dart 实现）
class WorldClockPlugin implements IPlatformPlugin {
  late PluginContext _context;
  
  // 插件状态变量
  bool _isInitialized = false;
  final List<WorldClockItem> _worldClocks = [];
  final List<CountdownTimer> _countdownTimers = [];
  Timer? _clockUpdateTimer;
  Timer? _countdownUpdateTimer;
  
  // 设置选项
  bool _show24HourFormat = true;
  bool _showSeconds = true;
  bool _enableNotifications = true;
  bool _enableAnimations = true;
  
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
      // 加载保存的状态
      await _loadSavedState();
      
      // 如果没有保存的时钟，添加默认的北京时间
      if (_worldClocks.isEmpty) {
        _worldClocks.add(WorldClockItem(
          id: 'beijing',
          cityName: '北京',
          timeZone: 'Asia/Shanghai',
          isDefault: true,
        ));
      }
      
      // 启动时钟更新定时器
      _startClockTimer();
      
      // 启动倒计时更新定时器
      _startCountdownTimer();
      
      _isInitialized = true;
      
      await _context.platformServices.showNotification('$name 插件已成功初始化');
      
    } catch (e) {
      await _context.platformServices.showNotification('$name 插件初始化失败: $e');
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
      print('World Clock plugin disposal error: $e');
    }
  }
  
  @override
  Widget buildUI(BuildContext context) {
    return _WorldClockPluginWidget(plugin: this);
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
      'countdownTimers': _countdownTimers.map((timer) => timer.toJson()).toList(),
      'show24HourFormat': _show24HourFormat,
      'showSeconds': _showSeconds,
      'enableNotifications': _enableNotifications,
      'enableAnimations': _enableAnimations,
      'lastUpdate': DateTime.now().toIso8601String(),
      'version': version,
    };
  }

  // 私有方法实现
  Future<void> _loadSavedState() async {
    try {
      final clocksData = await _context.dataStorage.retrieve<List<dynamic>>('worldClocks');
      if (clocksData != null) {
        _worldClocks.clear();
        _worldClocks.addAll(clocksData
            .map((data) => WorldClockItem.fromJson(data as Map<String, dynamic>))
            .toList());
      }
      
      final timersData = await _context.dataStorage.retrieve<List<dynamic>>('countdownTimers');
      if (timersData != null) {
        _countdownTimers.clear();
        _countdownTimers.addAll(timersData
            .map((data) => CountdownTimer.fromJson(data as Map<String, dynamic>))
            .toList());
      }
      
      // 加载设置
      _show24HourFormat = await _context.dataStorage.retrieve<bool>('show24HourFormat') ?? true;
      _showSeconds = await _context.dataStorage.retrieve<bool>('showSeconds') ?? true;
      _enableNotifications = await _context.dataStorage.retrieve<bool>('enableNotifications') ?? true;
      _enableAnimations = await _context.dataStorage.retrieve<bool>('enableAnimations') ?? true;
    } catch (e) {
      print('Failed to load saved state: $e');
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
      await _context.dataStorage.store('show24HourFormat', _show24HourFormat);
      await _context.dataStorage.store('showSeconds', _showSeconds);
      await _context.dataStorage.store('enableNotifications', _enableNotifications);
      await _context.dataStorage.store('enableAnimations', _enableAnimations);
    } catch (e) {
      print('Failed to save state: $e');
    }
  }

  void _startClockTimer() {
    _clockUpdateTimer?.cancel();
    _clockUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onStateChanged?.call();
    });
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
      _onCountdownComplete(timer);
    }
    
    if (completedTimers.isNotEmpty) {
      _saveCurrentState();
      _onStateChanged?.call();
    }
  }

  void _onCountdownComplete(CountdownTimer timer) async {
    if (_enableNotifications) {
      await _context.platformServices.showNotification(
        '倒计时提醒: ${timer.title} 时间到了！'
      );
    }
  }

  void _addClock(String cityName, String timeZone) {
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

  void _removeClock(String clockId) {
    _worldClocks.removeWhere((clock) => clock.id == clockId);
    _saveCurrentState();
    _onStateChanged?.call();
  }

  void _addCountdownTimer(String title, Duration duration) {
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

  void _removeCountdownTimer(String timerId) {
    _countdownTimers.removeWhere((timer) => timer.id == timerId);
    _saveCurrentState();
    _onStateChanged?.call();
  }
  
  void _updateSettings({
    bool? show24HourFormat,
    bool? showSeconds,
    bool? enableNotifications,
    bool? enableAnimations,
  }) {
    if (show24HourFormat != null) _show24HourFormat = show24HourFormat;
    if (showSeconds != null) _showSeconds = showSeconds;
    if (enableNotifications != null) _enableNotifications = enableNotifications;
    if (enableAnimations != null) _enableAnimations = enableAnimations;
    
    _saveCurrentState();
    _onStateChanged?.call();
  }
}


// 插件UI Widget
class _WorldClockPluginWidget extends StatefulWidget {
  final WorldClockPlugin plugin;

  const _WorldClockPluginWidget({required this.plugin});

  @override
  State<_WorldClockPluginWidget> createState() => _WorldClockPluginWidgetState();
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
    if (!widget.plugin._isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            tooltip: '添加倒计时',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClockDialog(context),
            tooltip: '添加时钟',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
            tooltip: '设置',
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
                            '世界时钟',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plugin._worldClocks.isEmpty)
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
                                  '暂无时钟',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击右上角 + 添加时钟',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...widget.plugin._worldClocks.map((clock) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: WorldClockWidget(
                            worldClock: clock,
                            showSeconds: widget.plugin._showSeconds,
                            onDelete: clock.isDefault ? null : () {
                              widget.plugin._removeClock(clock.id);
                            },
                          ),
                        )),
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
                            '倒计时提醒',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plugin._countdownTimers.isEmpty)
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
                                  '暂无倒计时',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击右上角闹钟图标添加倒计时',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...widget.plugin._countdownTimers.map((timer) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CountdownTimerWidget(
                            countdownTimer: timer,
                            enableAnimations: widget.plugin._enableAnimations,
                            onDelete: () {
                              widget.plugin._removeCountdownTimer(timer.id);
                            },
                            onComplete: () {
                              widget.plugin._onCountdownComplete(timer);
                            },
                          ),
                        )),
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
          widget.plugin._addClock(cityName, timeZone);
        },
      ),
    );
  }

  void _showAddCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddCountdownDialog(
        onAdd: (title, duration) {
          widget.plugin._addCountdownTimer(title, duration);
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        show24HourFormat: widget.plugin._show24HourFormat,
        showSeconds: widget.plugin._showSeconds,
        enableNotifications: widget.plugin._enableNotifications,
        enableAnimations: widget.plugin._enableAnimations,
        onSave: (settings) {
          widget.plugin._updateSettings(
            show24HourFormat: settings['show24HourFormat'],
            showSeconds: settings['showSeconds'],
            enableNotifications: settings['enableNotifications'],
            enableAnimations: settings['enableAnimations'],
          );
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
    return AlertDialog(
      title: const Text('添加时钟'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: '城市名称',
                hintText: '输入城市名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimeZone,
              decoration: const InputDecoration(
                labelText: '时区',
                border: OutlineInputBorder(),
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
                    final timeZone = _timeZones.firstWhere((tz) => tz['zone'] == value);
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _cityController.text.isEmpty ? null : () {
            widget.onAdd(_cityController.text, _selectedTimeZone);
            Navigator.of(context).pop();
          },
          child: const Text('添加'),
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
    final isValid = _titleController.text.isNotEmpty && 
                    (_hours > 0 || _minutes > 0 || _seconds > 0);
    
    return AlertDialog(
      title: const Text('添加倒计时'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '倒计时标题',
                hintText: '输入提醒内容',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),
            const Text('设置时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimePickerColumn(
                  label: '小时',
                  value: _hours,
                  maxValue: 23,
                  onChanged: (value) => setState(() => _hours = value),
                ),
                _TimePickerColumn(
                  label: '分钟',
                  value: _minutes,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _minutes = value),
                ),
                _TimePickerColumn(
                  label: '秒',
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: isValid ? () {
            final duration = Duration(
              hours: _hours,
              minutes: _minutes,
              seconds: _seconds,
            );
            widget.onAdd(_titleController.text, duration);
            Navigator.of(context).pop();
          } : null,
          child: const Text('添加'),
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

// 设置对话框
class _SettingsDialog extends StatefulWidget {
  final bool show24HourFormat;
  final bool showSeconds;
  final bool enableNotifications;
  final bool enableAnimations;
  final Function(Map<String, bool>) onSave;

  const _SettingsDialog({
    required this.show24HourFormat,
    required this.showSeconds,
    required this.enableNotifications,
    required this.enableAnimations,
    required this.onSave,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool _show24HourFormat;
  late bool _showSeconds;
  late bool _enableNotifications;
  late bool _enableAnimations;

  @override
  void initState() {
    super.initState();
    _show24HourFormat = widget.show24HourFormat;
    _showSeconds = widget.showSeconds;
    _enableNotifications = widget.enableNotifications;
    _enableAnimations = widget.enableAnimations;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '世界时钟设置',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '显示选项',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('24小时制'),
                        subtitle: const Text('使用24小时时间格式'),
                        value: _show24HourFormat,
                        onChanged: (value) => setState(() => _show24HourFormat = value),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      SwitchListTile(
                        title: const Text('显示秒数'),
                        subtitle: const Text('在时钟中显示秒数'),
                        value: _showSeconds,
                        onChanged: (value) => setState(() => _showSeconds = value),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        '功能选项',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('启用通知'),
                        subtitle: const Text('倒计时完成时显示通知'),
                        value: _enableNotifications,
                        onChanged: (value) => setState(() => _enableNotifications = value),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      SwitchListTile(
                        title: const Text('启用动画'),
                        subtitle: const Text('显示动画效果'),
                        value: _enableAnimations,
                        onChanged: (value) => setState(() => _enableAnimations = value),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.onSave({
                        'show24HourFormat': _show24HourFormat,
                        'showSeconds': _showSeconds,
                        'enableNotifications': _enableNotifications,
                        'enableAnimations': _enableAnimations,
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
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
