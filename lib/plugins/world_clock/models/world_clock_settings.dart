library;

import '../../../core/models/base_plugin_settings.dart';

/// 世界时钟设置模型
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

  /// 更新间隔（毫秒）
  final int updateInterval;

  WorldClockSettings({
    this.version = '1.0.0',
    required this.defaultTimeZone,
    required this.timeFormat,
    required this.showSeconds,
    required this.enableNotifications,
    required this.updateInterval,
  });

  /// 默认设置
  factory WorldClockSettings.defaultSettings() {
    return WorldClockSettings(
      version: '1.0.0',
      defaultTimeZone: 'Asia/Shanghai',
      timeFormat: '24h',
      showSeconds: false,
      enableNotifications: true,
      updateInterval: 1000,
    );
  }

  /// 从 JSON 创建实例
  factory WorldClockSettings.fromJson(Map<String, dynamic> json) {
    return WorldClockSettings(
      version: json['version'] as String? ?? '1.0.0',
      defaultTimeZone: json['defaultTimeZone'] as String? ?? 'Asia/Shanghai',
      timeFormat: json['timeFormat'] as String? ?? '24h',
      showSeconds: json['showSeconds'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      updateInterval: json['updateInterval'] as int? ?? 1000,
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
      'updateInterval': updateInterval,
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
    int? updateInterval,
  }) {
    return WorldClockSettings(
      version: version ?? this.version,
      defaultTimeZone: defaultTimeZone ?? this.defaultTimeZone,
      timeFormat: timeFormat ?? this.timeFormat,
      showSeconds: showSeconds ?? this.showSeconds,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      updateInterval: updateInterval ?? this.updateInterval,
    );
  }

  /// 验证设置是否有效
  @override
  bool isValid() {
    if (!['12h', '24h'].contains(timeFormat)) return false;
    if (updateInterval < 100 || updateInterval > 60000) return false;
    return true;
  }
}
