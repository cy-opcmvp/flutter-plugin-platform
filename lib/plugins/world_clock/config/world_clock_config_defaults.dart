library;

import 'dart:convert';
import '../models/world_clock_settings.dart';

/// 世界时钟配置默认值和示例
class WorldClockConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "version": "1.0.0",
  "defaultTimeZone": "Asia/Shanghai",
  "timeFormat": "24h",
  "showSeconds": false,
  "enableNotifications": true,
  "notificationType": "system",
  "worldClocks": [],
  "countdownTimers": [],
  "countdownTemplates": [
    {"name": "番茄时钟", "hours": 0, "minutes": 15, "seconds": 0},
    {"name": "午休", "hours": 1, "minutes": 0, "seconds": 0},
    {"name": "短休息", "hours": 0, "minutes": 5, "seconds": 0},
    {"name": "长休息", "hours": 0, "minutes": 30, "seconds": 0},
    {"name": "专注时段", "hours": 2, "minutes": 0, "seconds": 0}
  ]
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "世界时钟配置文件",
  "_description": "修改此文件可以自定义世界时钟行为，包括设置、时钟、倒计时和模板",

  "version": "1.0.0",
  "_version_help": "配置版本号，用于未来的迁移和兼容性检查",

  "defaultTimeZone": "Asia/Shanghai",
  "_defaultTimeZone_help": "默认显示的时区",
  "_defaultTimeZone_examples": [
    "Asia/Shanghai - 北京时间",
    "America/New_York - 纽约时间",
    "Europe/London - 伦敦时间",
    "Asia/Tokyo - 东京时间"
  ],

  "timeFormat": "24h",
  "_timeFormat_help": "时间格式",
  "_timeFormat_options": [
    "12h - 12小时制 (上午/下午)",
    "24h - 24小时制 (0-23)"
  ],

  "showSeconds": false,
  "_showSeconds_help": "是否显示秒数",

  "enableNotifications": true,
  "_enableNotifications_help": "倒计时完成时是否显示通知",

  "notificationType": "system",
  "_notificationType_help": "通知类型",
  "_notificationType_options": [
    "system - 系统通知（需要在通知栏中显示）",
    "inApp - App 内通知（SnackBar 显示）"
  ],

  "worldClocks": [
    {
      "id": "1706185200000",
      "cityName": "北京",
      "timeZone": "Asia/Shanghai",
      "isDefault": true
    },
    {
      "id": "1706185200001",
      "cityName": "伦敦",
      "timeZone": "Europe/London",
      "isDefault": false
    }
  ],
  "_worldClocks_help": "已添加的世界时钟列表",

  "countdownTimers": [
    {
      "id": "1706185200002",
      "title": "专注时段",
      "endTime": "2026-01-25T15:30:00.000Z",
      "isCompleted": false
    }
  ],
  "_countdownTimers_help": "已创建的倒计时列表",

  "countdownTemplates": [
    {"name": "番茄时钟", "hours": 0, "minutes": 15, "seconds": 0},
    {"name": "午休", "hours": 1, "minutes": 0, "seconds": 0},
    {"name": "短休息", "hours": 0, "minutes": 5, "seconds": 0},
    {"name": "长休息", "hours": 0, "minutes": 30, "seconds": 0},
    {"name": "专注时段", "hours": 2, "minutes": 0, "seconds": 0}
  ],
  "_countdownTemplates_help": "倒计时快速模板列表，可在设置中添加自定义模板"
}''';

  /// 清理后的示例（移除注释）
  static String get cleanExample {
    final json = jsonDecode(exampleConfig) as Map<String, dynamic>;
    final cleaned = _removeHelpFields(json);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(cleaned);
  }

  /// 递归移除帮助字段
  static Map<String, dynamic> _removeHelpFields(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.key.startsWith('_') ||
          entry.key == '_comment' ||
          entry.key == '_description' ||
          entry.key.endsWith('_help') ||
          entry.key.endsWith('_options') ||
          entry.key.endsWith('_examples') ||
          entry.key.endsWith('_range') ||
          entry.key.endsWith('_note')) {
        continue;
      }
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _removeHelpFields(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is List) {
        continue;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// JSON Schema
  static const String schemaJson = '''
{
  "type": "object",
  "description": "世界时钟配置",
  "properties": {
    "version": {
      "type": "string",
      "description": "配置版本号"
    },
    "defaultTimeZone": {
      "type": "string",
      "description": "默认显示的时区（IANA 时区标识符）"
    },
    "timeFormat": {
      "type": "string",
      "enum": ["12h", "24h"],
      "description": "时间格式"
    },
    "showSeconds": {
      "type": "boolean",
      "description": "是否显示秒数"
    },
    "enableNotifications": {
      "type": "boolean",
      "description": "倒计时完成时是否显示通知"
    },
    "notificationType": {
      "type": "string",
      "enum": ["system", "inApp"],
      "description": "通知类型"
    },
    "worldClocks": {
      "type": "array",
      "description": "已添加的世界时钟列表",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "cityName": {"type": "string"},
          "timeZone": {"type": "string"},
          "isDefault": {"type": "boolean"}
        },
        "required": ["id", "cityName", "timeZone", "isDefault"]
      }
    },
    "countdownTimers": {
      "type": "array",
      "description": "已创建的倒计时列表",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "title": {"type": "string"},
          "endTime": {"type": "string", "format": "date-time"},
          "isCompleted": {"type": "boolean"}
        },
        "required": ["id", "title", "endTime", "isCompleted"]
      }
    },
    "countdownTemplates": {
      "type": "array",
      "description": "倒计时快速模板列表",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "hours": {"type": "integer"},
          "minutes": {"type": "integer"},
          "seconds": {"type": "integer"}
        },
        "required": ["name", "hours", "minutes", "seconds"]
      }
    }
  },
  "required": ["version", "defaultTimeZone", "timeFormat", "showSeconds", "enableNotifications", "notificationType"]
}''';

  /// 获取默认配置对象
  static WorldClockSettings get defaultSettings =>
      WorldClockSettings.defaultSettings();
}
