import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import 'models/world_clock_models.dart';
import 'widgets/world_clock_widget.dart';
import 'widgets/countdown_timer_widget.dart';

/// 世界时钟插件 - 显示多个时区时间并支持倒计时提醒
class WorldClockPlugin implements IPlugin {
  late PluginContext _context;
  
  // 插件状态变量
  bool _isInitialized = false;
  List<WorldClockItem> _worldClocks = [];
  List<CountdownTimer> _countdownTimers = [];
  Timer? _clockUpdateTimer;
  Timer? _countdownUpdateTimer;

  @override
  String get id => 'com.example.worldclock';

  @override
  String get name => '世界时钟';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

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
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).primaryColor,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 世界时钟区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '世界时钟',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_worldClocks.isEmpty)
                      const Center(
                        child: Text('暂无时钟，点击右上角添加'),
                      )
                    else
                      ...(_worldClocks.map((clock) => WorldClockWidget(
                        worldClock: clock,
                        onDelete: clock.isDefault ? null : () => _removeClock(clock.id),
                      ))),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 倒计时区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '倒计时提醒',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_countdownTimers.isEmpty)
                      const Center(
                        child: Text('暂无倒计时，点击右上角添加'),
                      )
                    else
                      ...(_countdownTimers.map((timer) => CountdownTimerWidget(
                        countdownTimer: timer,
                        onDelete: () => _removeCountdownTimer(timer.id),
                        onComplete: () => _onCountdownComplete(timer),
                      ))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      'countdownTimers': _countdownTimers.map((timer) => timer.toJson()).toList(),
      'lastUpdate': DateTime.now().toIso8601String(),
      'version': version,
    };
  }

  // 私有方法实现
  Future<void> _loadSavedState() async {
    try {
      final clocksData = await _context.dataStorage.retrieve<List<dynamic>>('worldClocks');
      if (clocksData != null) {
        _worldClocks = clocksData
            .map((data) => WorldClockItem.fromJson(data as Map<String, dynamic>))
            .toList();
      }
      
      final timersData = await _context.dataStorage.retrieve<List<dynamic>>('countdownTimers');
      if (timersData != null) {
        _countdownTimers = timersData
            .map((data) => CountdownTimer.fromJson(data as Map<String, dynamic>))
            .toList();
      }
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
    } catch (e) {
      print('Failed to save state: $e');
    }
  }

  void _startClockTimer() {
    _clockUpdateTimer?.cancel();
    _clockUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 触发UI更新 - 在实际应用中可能需要使用状态管理
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
    }
  }

  void _onCountdownComplete(CountdownTimer timer) async {
    await _context.platformServices.showNotification(
      '倒计时提醒: ${timer.title} 时间到了！'
    );
  }

  void _showAddClockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddClockDialog(
        onAdd: (cityName, timeZone) {
          _addClock(cityName, timeZone);
        },
      ),
    );
  }

  void _showAddCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCountdownDialog(
        onAdd: (title, duration) {
          _addCountdownTimer(title, duration);
        },
      ),
    );
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
  }

  void _removeClock(String clockId) {
    _worldClocks.removeWhere((clock) => clock.id == clockId);
    _saveCurrentState();
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
  }

  void _removeCountdownTimer(String timerId) {
    _countdownTimers.removeWhere((timer) => timer.id == timerId);
    _saveCurrentState();
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('世界时钟设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('设置选项将在后续版本中添加'),
            SizedBox(height: 16),
            Text('当前功能：'),
            Text('• 显示多个时区时间'),
            Text('• 倒计时提醒'),
            Text('• 默认北京时间'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

// 添加时钟对话框
class AddClockDialog extends StatefulWidget {
  final Function(String cityName, String timeZone) onAdd;

  const AddClockDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddClockDialog> createState() => _AddClockDialogState();
}

class _AddClockDialogState extends State<AddClockDialog> {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加时钟'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: '城市名称',
              hintText: '输入城市名称',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTimeZone,
            decoration: const InputDecoration(
              labelText: '时区',
            ),
            items: _timeZones.map((tz) {
              return DropdownMenuItem<String>(
                value: tz['zone'],
                child: Text(tz['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeZone = value!;
                // 自动填充城市名称
                final timeZone = _timeZones.firstWhere((tz) => tz['zone'] == value);
                if (_cityController.text.isEmpty) {
                  _cityController.text = timeZone['name']!;
                }
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_cityController.text.isNotEmpty) {
              widget.onAdd(_cityController.text, _selectedTimeZone);
              Navigator.of(context).pop();
            }
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
class AddCountdownDialog extends StatefulWidget {
  final Function(String title, Duration duration) onAdd;

  const AddCountdownDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddCountdownDialog> createState() => _AddCountdownDialogState();
}

class _AddCountdownDialogState extends State<AddCountdownDialog> {
  final _titleController = TextEditingController();
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加倒计时'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '倒计时标题',
              hintText: '输入提醒内容',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('小时'),
                    DropdownButton<int>(
                      value: _hours,
                      items: List.generate(24, (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i.toString()),
                      )),
                      onChanged: (value) => setState(() => _hours = value!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('分钟'),
                    DropdownButton<int>(
                      value: _minutes,
                      items: List.generate(60, (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i.toString()),
                      )),
                      onChanged: (value) => setState(() => _minutes = value!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('秒'),
                    DropdownButton<int>(
                      value: _seconds,
                      items: List.generate(60, (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i.toString()),
                      )),
                      onChanged: (value) => setState(() => _seconds = value!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && 
                (_hours > 0 || _minutes > 0 || _seconds > 0)) {
              final duration = Duration(
                hours: _hours,
                minutes: _minutes,
                seconds: _seconds,
              );
              widget.onAdd(_titleController.text, duration);
              Navigator.of(context).pop();
            }
          },
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