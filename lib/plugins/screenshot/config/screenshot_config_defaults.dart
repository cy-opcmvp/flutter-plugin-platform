library;

import 'dart:convert';
import '../models/screenshot_settings.dart';

/// 截图配置默认值和示例
class ScreenshotConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "version": "1.0.0",
  "savePath": "{documents}/Screenshots",
  "filenameFormat": "screenshot_{timestamp}",
  "imageFormat": "png",
  "imageQuality": 95,
  "autoCopyToClipboard": true,
  "clipboardContentType": "image",
  "showPreview": true,
  "saveHistory": true,
  "maxHistoryCount": 100,
  "historyRetentionDays": 30,
  "shortcuts": {
    "regionCapture": "Ctrl+Shift+A",
    "fullScreenCapture": "Ctrl+Shift+F",
    "windowCapture": "Ctrl+Shift+W",
    "showHistory": "Ctrl+Shift+H",
    "showSettings": "Ctrl+Shift+S"
  },
  "pinSettings": {
    "alwaysOnTop": true,
    "defaultOpacity": 0.9,
    "enableDrag": true,
    "enableResize": false,
    "showCloseButton": true
  }
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "截图插件配置文件",
  "_description": "修改此文件可以自定义截图行为",

  "savePath": "{documents}/Screenshots",
  "_savePath_help": "支持占位符: {documents}, {desktop}, {pictures}, {downloads}",

  "filenameFormat": "screenshot_{timestamp}",
  "_filenameFormat_help": "支持占位符: {timestamp}, {date}, {time}, {datetime}, {index}",
  "_filenameFormat_examples": [
    "screenshot_{datetime} -> screenshot_2026-01-15_19-30-45",
    "Screenshot_{date}_{index} -> Screenshot_2026-01-15_1",
    "{timestamp} -> 1736952645000"
  ],

  "imageFormat": "png",
  "_imageFormat_help": "可选值: png (无损), jpeg (有损，文件小), webp (现代格式)",

  "imageQuality": 95,
  "_imageQuality_help": "图片质量 1-100，仅对 JPEG 和 WebP 有效",

  "autoCopyToClipboard": true,
  "_autoCopyToClipboard_help": "截图后自动复制到剪贴板",

  "clipboardContentType": "image",
  "_clipboardContentType_help": "剪贴板内容类型",
  "_clipboardContentType_options": [
    "image - 图片本身",
    "filename - 文件名（不含路径）",
    "fullPath - 完整路径",
    "directoryPath - 目录路径（不含文件名）"
  ],

  "showPreview": true,
  "_showPreview_help": "截图后显示预览窗口",

  "saveHistory": true,
  "_saveHistory_help": "保存截图历史记录",

  "maxHistoryCount": 100,
  "_maxHistoryCount_help": "最大历史记录数量，范围: 10-500",

  "historyRetentionDays": 30,
  "_historyRetentionDays_help": "历史记录保留天数",

  "shortcuts": {
    "_help": "快捷键设置",
    "regionCapture": "Ctrl+Shift+A",
    "fullScreenCapture": "Ctrl+Shift+F",
    "windowCapture": "Ctrl+Shift+W",
    "showHistory": "Ctrl+Shift+H",
    "showSettings": "Ctrl+Shift+S"
  },

  "pinSettings": {
    "_help": "钉图设置",
    "alwaysOnTop": true,
    "defaultOpacity": 0.9,
    "_defaultOpacity_help": "默认透明度，范围: 0.1-1.0",
    "enableDrag": true,
    "enableResize": false,
    "showCloseButton": true
  }
}''';

  /// 清理后的示例（移除注释）
  static String get cleanExample {
    // 移除所有 _comment、_description、_help 等字段
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
          entry.key.endsWith('_examples')) {
        continue;
      }
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _removeHelpFields(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is List) {
        // 跳过示例列表
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
  "description": "截图插件配置",
  "properties": {
    "version": {
      "type": "string",
      "description": "配置版本号"
    },
    "savePath": {
      "type": "string",
      "description": "保存路径，支持占位符"
    },
    "filenameFormat": {
      "type": "string",
      "description": "文件名格式"
    },
    "imageFormat": {
      "type": "string",
      "enum": ["png", "jpeg", "webp"],
      "description": "图片格式"
    },
    "imageQuality": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "description": "图片质量"
    },
    "autoCopyToClipboard": {
      "type": "boolean",
      "description": "自动复制到剪贴板"
    },
    "clipboardContentType": {
      "type": "string",
      "enum": ["image", "filename", "fullPath", "directoryPath"],
      "description": "剪贴板内容类型"
    },
    "showPreview": {
      "type": "boolean",
      "description": "显示预览"
    },
    "saveHistory": {
      "type": "boolean",
      "description": "保存历史"
    },
    "maxHistoryCount": {
      "type": "integer",
      "minimum": 10,
      "maximum": 500,
      "description": "最大历史数量"
    },
    "historyRetentionDays": {
      "type": "integer",
      "minimum": 1,
      "maximum": 365,
      "description": "历史保留天数"
    },
    "shortcuts": {
      "type": "object",
      "description": "快捷键设置",
      "properties": {
        "regionCapture": {"type": "string"},
        "fullScreenCapture": {"type": "string"},
        "windowCapture": {"type": "string"},
        "showHistory": {"type": "string"},
        "showSettings": {"type": "string"}
      }
    },
    "pinSettings": {
      "type": "object",
      "description": "钉图设置",
      "properties": {
        "alwaysOnTop": {"type": "boolean"},
        "defaultOpacity": {
          "type": "number",
          "minimum": 0.1,
          "maximum": 1.0
        },
        "enableDrag": {"type": "boolean"},
        "enableResize": {"type": "boolean"},
        "showCloseButton": {"type": "boolean"}
      }
    }
  }
}''';

  /// 获取默认配置对象
  static ScreenshotSettings get defaultSettings =>
      ScreenshotSettings.defaultSettings();

  /// 创建带说明的示例 JSON
  static String createAnnotatedExample() {
    return '''
# ============================================
# 截图插件配置文件
# ============================================
# 修改前请阅读以下说明：
#
# 1. 所有修改都会在保存前进行严格校验
# 2. 不符合规范的修改将被拒绝
# 3. 可以随时点击"重置"恢复默认值
# 4. 点击"示例"查看详细配置说明
#
# 支持的路径占位符：
#   {documents} - 文档目录
#   {desktop}   - 桌面目录
#   {pictures}  - 图片目录
#   {downloads} - 下载目录
#
# 支持的文件名占位符：
#   {timestamp} - Unix 时间戳
#   {date}      - 日期 (YYYY-MM-DD)
#   {time}      - 时间 (HH-MM-SS)
#   {datetime}  - 日期时间 (YYYY-MM-DD_HH-MM-SS)
#   {index}     - 自增序号
# ============================================

$exampleConfig
''';
  }
}
