library;

import 'dart:convert';
import '../models/world_clock_settings.dart';

/// 世界时钟配置默认值和示例
class WorldClockConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "defaultTimeZone": "Asia/Shanghai",
  "timeFormat": "24h",
  "showSeconds": false,
  "enableNotifications": true,
  "updateInterval": 1000
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "世界时钟配置文件",
  "_description": "修改此文件可以自定义世界时钟行为",

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

  "updateInterval": 1000,
  "_updateInterval_help": "时钟更新间隔（毫秒）",
  "_updateInterval_range": "取值范围: 100-60000",
  "_updateInterval_note": "1000 = 1秒，建议保持默认值"
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
        result[entry.key] = _removeHelpFields(entry.value as Map<String, dynamic>);
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
    "updateInterval": {
      "type": "integer",
      "minimum": 100,
      "maximum": 60000,
      "description": "时钟更新间隔（毫秒）"
    }
  },
  "required": ["defaultTimeZone", "timeFormat", "showSeconds", "enableNotifications", "updateInterval"]
}''';

  /// 获取默认配置对象
  static WorldClockSettings get defaultSettings =>
      WorldClockSettings.defaultSettings();
}
