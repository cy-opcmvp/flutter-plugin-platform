library;

import '../../../core/models/base_plugin_settings.dart';
import 'world_clock_models.dart';

/// 通知类型
enum NotificationType {
  /// App 内通知（SnackBar）
  inApp,

  /// 系统通知
  system,
}

/// 世界时钟设置模型（包含所有插件数据）
class WorldClockSettings extends BasePluginSettings {
  /// 配置版本
  @override
  final String version;

  /// 默认时区
  final String defaultTimeZone;

  /// 时间格式 (12h/24h)
  final String timeFormat;

  /// 显示秒数
  final bool showSeconds;

  /// 启用倒计时通知
  final bool enableNotifications;

  /// 通知类型
  final NotificationType notificationType;

  /// 世界时钟列表
  final List<WorldClockItem> worldClocks;

  /// 倒计时列表
  final List<CountdownTimer> countdownTimers;

  /// 倒计时模板列表
  final List<Map<String, dynamic>> countdownTemplates;

  WorldClockSettings({
    this.version = '1.0.0',
    required this.defaultTimeZone,
    required this.timeFormat,
    required this.showSeconds,
    required this.enableNotifications,
    required this.notificationType,
    this.worldClocks = const [],
    this.countdownTimers = const [],
    this.countdownTemplates = const [],
  });

  /// 默认设置
  factory WorldClockSettings.defaultSettings() {
    return WorldClockSettings(
      version: '1.0.0',
      defaultTimeZone: 'Asia/Shanghai',
      timeFormat: '24h',
      showSeconds: false,
      enableNotifications: true,
      notificationType: NotificationType.system,
      worldClocks: [],
      countdownTimers: [],
      countdownTemplates: [
        {'name': '番茄时钟', 'hours': 0, 'minutes': 15, 'seconds': 0},
        {'name': '午休', 'hours': 1, 'minutes': 0, 'seconds': 0},
        {'name': '短休息', 'hours': 0, 'minutes': 5, 'seconds': 0},
        {'name': '长休息', 'hours': 0, 'minutes': 30, 'seconds': 0},
        {'name': '专注时段', 'hours': 2, 'minutes': 0, 'seconds': 0},
      ],
    );
  }

  /// 从 JSON 创建实例
  factory WorldClockSettings.fromJson(Map<String, dynamic> json) {
    // 解析世界时钟列表
    final worldClocksList = json['worldClocks'] as List?;
    final worldClocks =
        worldClocksList
            ?.map(
              (data) => WorldClockItem.fromJson(data as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // 解析倒计时列表
    final countdownTimersList = json['countdownTimers'] as List?;
    final countdownTimers =
        countdownTimersList
            ?.map(
              (data) => CountdownTimer.fromJson(data as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // 解析倒计时模板列表
    final templatesList = json['countdownTemplates'] as List?;
    final countdownTemplates =
        templatesList
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        [
          {'name': '番茄时钟', 'hours': 0, 'minutes': 15, 'seconds': 0},
          {'name': '午休', 'hours': 1, 'minutes': 0, 'seconds': 0},
          {'name': '短休息', 'hours': 0, 'minutes': 5, 'seconds': 0},
          {'name': '长休息', 'hours': 0, 'minutes': 30, 'seconds': 0},
          {'name': '专注时段', 'hours': 2, 'minutes': 0, 'seconds': 0},
        ];

    return WorldClockSettings(
      version: json['version'] as String? ?? '1.0.0',
      defaultTimeZone: json['defaultTimeZone'] as String? ?? 'Asia/Shanghai',
      timeFormat: json['timeFormat'] as String? ?? '24h',
      showSeconds: json['showSeconds'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      notificationType: json['notificationType'] == 'inApp'
          ? NotificationType.inApp
          : (json['notificationType'] == 'system'
                ? NotificationType.system
                : NotificationType.system),
      worldClocks: worldClocks,
      countdownTimers: countdownTimers,
      countdownTemplates: countdownTemplates,
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'defaultTimeZone': defaultTimeZone,
      'timeFormat': timeFormat,
      'showSeconds': showSeconds,
      'enableNotifications': enableNotifications,
      'notificationType': notificationType.name,
      'worldClocks': worldClocks.map((clock) => clock.toJson()).toList(),
      'countdownTimers': countdownTimers
          .map((timer) => timer.toJson())
          .toList(),
      'countdownTemplates': countdownTemplates,
    };
  }

  /// 复制并修改部分设置
  @override
  WorldClockSettings copyWith({
    String? version,
    String? defaultTimeZone,
    String? timeFormat,
    bool? showSeconds,
    bool? enableNotifications,
    NotificationType? notificationType,
    List<WorldClockItem>? worldClocks,
    List<CountdownTimer>? countdownTimers,
    List<Map<String, dynamic>>? countdownTemplates,
  }) {
    return WorldClockSettings(
      version: version ?? this.version,
      defaultTimeZone: defaultTimeZone ?? this.defaultTimeZone,
      timeFormat: timeFormat ?? this.timeFormat,
      showSeconds: showSeconds ?? this.showSeconds,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationType: notificationType ?? this.notificationType,
      worldClocks: worldClocks ?? this.worldClocks,
      countdownTimers: countdownTimers ?? this.countdownTimers,
      countdownTemplates: countdownTemplates ?? this.countdownTemplates,
    );
  }

  /// 验证设置是否有效
  @override
  bool isValid() {
    if (!['12h', '24h'].contains(timeFormat)) return false;
    return true;
  }
}
