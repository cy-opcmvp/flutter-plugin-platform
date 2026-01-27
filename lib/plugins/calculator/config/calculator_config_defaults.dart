library;

import 'dart:convert';
import '../models/calculator_settings.dart';

/// 计算器配置默认值和示例
class CalculatorConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "version": "1.0.0",
  "precision": 10,
  "angleMode": "deg",
  "historySize": 50,
  "memorySlots": 10,
  "showGroupingSeparator": true,
  "enableVibration": true,
  "buttonSoundVolume": 50
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "计算器插件配置文件",
  "_description": "修改此文件可以自定义计算器行为",

  "precision": 10,
  "_precision_help": "计算精度，小数点后的位数",
  "_precision_range": "取值范围: 0-15",
  "_precision_default": 10,

  "angleMode": "deg",
  "_angleMode_help": "角度模式",
  "_angleMode_options": [
    "deg - 角度制 (0-360°)",
    "rad - 弧度制 (0-2π)"
  ],
  "_angleMode_default": "deg",

  "historySize": 50,
  "_historySize_help": "历史记录保存的数量",
  "_historySize_range": "取值范围: 10-500",

  "memorySlots": 10,
  "_memorySlots_help": "内存槽位数量（M+, M-, MR, MC）",
  "_memorySize_range": "取值范围: 1-20",

  "showGroupingSeparator": true,
  "_showGroupingSeparator_help": "是否显示千分位分隔符（如 1,234.56）",

  "enableVibration": true,
  "_enableVibration_help": "按键时是否启用振动反馈",

  "buttonSoundVolume": 50,
  "_buttonSoundVolume_help": "按键音效音量",
  "_buttonSoundVolume_range": "取值范围: 0-100",
  "_buttonSoundVolume_note": "0 表示静音"
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
          entry.key.endsWith('_default') ||
          entry.key.endsWith('_range') ||
          entry.key.endsWith('_options') ||
          entry.key.endsWith('_note') ||
          entry.key.endsWith('_examples')) {
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
  "description": "计算器配置",
  "properties": {
    "version": {
      "type": "string",
      "description": "配置版本号"
    },
    "precision": {
      "type": "integer",
      "minimum": 0,
      "maximum": 15,
      "description": "计算精度，小数点后的位数"
    },
    "angleMode": {
      "type": "string",
      "enum": ["deg", "rad"],
      "description": "角度模式"
    },
    "historySize": {
      "type": "integer",
      "minimum": 10,
      "maximum": 500,
      "description": "历史记录保存的数量"
    },
    "memorySlots": {
      "type": "integer",
      "minimum": 1,
      "maximum": 20,
      "description": "内存槽位数量"
    },
    "showGroupingSeparator": {
      "type": "boolean",
      "description": "是否显示千分位分隔符"
    },
    "enableVibration": {
      "type": "boolean",
      "description": "按键时是否启用振动反馈"
    },
    "buttonSoundVolume": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100,
      "description": "按键音效音量"
    }
  },
  "required": ["version", "precision", "angleMode", "historySize", "memorySlots", "showGroupingSeparator", "enableVibration", "buttonSoundVolume"]
}''';

  /// 获取默认配置对象
  static CalculatorSettings get defaultSettings =>
      CalculatorSettings.defaultSettings();
}
