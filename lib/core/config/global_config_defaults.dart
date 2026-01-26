library;

import 'dart:convert';
import '../models/global_config.dart';

/// 全局配置默认值和示例
class GlobalConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "app": {
    "name": "Flutter Plugin Platform",
    "version": "0.4.4",
    "language": "zh_CN",
    "theme": "system",
    "pluginViewMode": "mediumIcon",
    "autoStartPlugins": []
  },
  "features": {
    "autoStart": false,
    "minimizeToTray": true,
    "showDesktopPet": true,
    "enableNotifications": true,
    "desktopPet": {
      "opacity": 1.0,
      "animations_enabled": true,
      "interactions_enabled": true
    }
  },
  "services": {
    "audio": {
      "enabled": true
    },
    "notification": {
      "enabled": true,
      "mode": "system"
    },
    "taskScheduler": {
      "enabled": true
    }
  },
  "advanced": {
    "debugMode": false,
    "logLevel": "info",
    "maxLogFileSize": 10
  }
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "全局应用配置文件",

  "app": {
    "_help": "应用基本配置",
    "name": "Flutter Plugin Platform",
    "_name_help": "应用名称",

    "version": "0.4.4",
    "_version_help": "应用版本号",

    "language": "zh_CN",
    "_language_help": "界面语言 (zh_CN, en_US)",
    "_language_options": ["zh_CN", "en_US"],

    "theme": "system",
    "_theme_help": "主题模式 (system, light, dark)",

    "pluginViewMode": "mediumIcon",
    "_pluginViewMode_help": "插件视图模式",
    "_pluginViewMode_options": [
      "largeIcon - 大图标",
      "mediumIcon - 中图标（默认）",
      "smallIcon - 小图标",
      "list - 列表"
    ],

    "autoStartPlugins": [],
    "_autoStartPlugins_help": "自启动插件ID列表"
  },

  "features": {
    "_help": "功能开关配置",

    "autoStart": false,
    "_autoStart_help": "开机自启动",

    "minimizeToTray": true,
    "_minimizeToTray_help": "最小化到系统托盘",

    "showDesktopPet": true,
    "_showDesktopPet_help": "显示桌面宠物",

    "enableNotifications": true,
    "_enableNotifications_help": "启用通知功能",

    "desktopPet": {
      "_help": "桌面宠物配置",

      "opacity": 1.0,
      "_opacity_help": "宠物透明度（0.3-1.0）",

      "animations_enabled": true,
      "_animations_enabled_help": "启用呼吸和眨眼动画",

      "interactions_enabled": true,
      "_interactions_enabled_help": "启用点击和拖拽交互"
    }
  },

  "services": {
    "_help": "平台服务配置",

    "audio": {
      "_help": "音频服务配置",
      "enabled": true,
      "_enabled_help": "启用音频服务"
    },

    "notification": {
      "_help": "通知服务配置",
      "enabled": true,
      "_enabled_help": "启用通知服务",

      "mode": "system",
      "_mode_help": "通知模式",
      "_mode_options": [
        "app - App 内部通知",
        "system - 系统级通知"
      ]
    },

    "taskScheduler": {
      "_help": "任务调度服务配置",
      "enabled": true,
      "_enabled_help": "启用任务调度服务"
    }
  },

  "advanced": {
    "_help": "高级配置（开发者选项）",

    "debugMode": false,
    "_debugMode_help": "调试模式",

    "logLevel": "info",
    "_logLevel_help": "日志级别",
    "_logLevel_options": ["debug", "info", "warning", "error"],

    "maxLogFileSize": 10,
    "_maxLogFileSize_help": "单个日志文件最大大小（MB）"
  }
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
      // 跳过注释和帮助字段
      if (entry.key.startsWith('_') ||
          entry.key == '_comment' ||
          entry.key == '_help' ||
          entry.key.endsWith('_help') ||
          entry.key.endsWith('_options')) {
        continue;
      }
      // 递归处理嵌套对象
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
  "description": "全局应用配置",
  "properties": {
    "app": {
      "type": "object",
      "description": "应用配置",
      "properties": {
        "name": {
          "type": "string",
          "description": "应用名称"
        },
        "version": {
          "type": "string",
          "description": "应用版本号"
        },
        "language": {
          "type": "string",
          "enum": ["zh_CN", "en_US"],
          "description": "界面语言"
        },
        "theme": {
          "type": "string",
          "description": "主题模式"
        },
        "pluginViewMode": {
          "type": "string",
          "enum": ["largeIcon", "mediumIcon", "smallIcon", "list"],
          "description": "插件视图模式"
        },
        "autoStartPlugins": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "自启动插件ID列表"
        }
      },
      "required": ["name", "version", "language", "theme"]
    },
    "features": {
      "type": "object",
      "description": "功能配置",
      "properties": {
        "autoStart": {
          "type": "boolean",
          "description": "开机自启动"
        },
        "minimizeToTray": {
          "type": "boolean",
          "description": "最小化到系统托盘"
        },
        "showDesktopPet": {
          "type": "boolean",
          "description": "显示桌面宠物"
        },
        "enableNotifications": {
          "type": "boolean",
          "description": "启用通知功能"
        },
        "desktopPet": {
          "type": "object",
          "description": "桌面宠物配置",
          "properties": {
            "opacity": {
              "type": "number",
              "minimum": 0.3,
              "maximum": 1.0,
              "description": "宠物透明度"
            },
            "animations_enabled": {
              "type": "boolean",
              "description": "启用动画"
            },
            "interactions_enabled": {
              "type": "boolean",
              "description": "启用交互"
            }
          },
          "required": ["opacity", "animations_enabled", "interactions_enabled"]
        }
      },
      "required": ["autoStart", "minimizeToTray", "showDesktopPet", "enableNotifications", "desktopPet"]
    },
    "services": {
      "type": "object",
      "description": "服务配置",
      "properties": {
        "audio": {
          "type": "object",
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "启用音频服务"
            }
          },
          "required": ["enabled"]
        },
        "notification": {
          "type": "object",
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "启用通知服务"
            },
            "mode": {
              "type": "string",
              "enum": ["app", "system"],
              "description": "通知模式"
            }
          },
          "required": ["enabled", "mode"]
        },
        "taskScheduler": {
          "type": "object",
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "启用任务调度服务"
            }
          },
          "required": ["enabled"]
        }
      },
      "required": ["audio", "notification", "taskScheduler"]
    },
    "advanced": {
      "type": "object",
      "description": "高级配置",
      "properties": {
        "debugMode": {
          "type": "boolean",
          "description": "调试模式"
        },
        "logLevel": {
          "type": "string",
          "enum": ["debug", "info", "warning", "error"],
          "description": "日志级别"
        },
        "maxLogFileSize": {
          "type": "integer",
          "minimum": 1,
          "maximum": 100,
          "description": "单个日志文件最大大小（MB）"
        }
      },
      "required": ["debugMode", "logLevel", "maxLogFileSize"]
    }
  },
  "required": ["app", "features", "services", "advanced"]
}''';

  /// 获取默认配置对象
  static GlobalConfig get defaultSettings => GlobalConfig.defaultConfig;
}
