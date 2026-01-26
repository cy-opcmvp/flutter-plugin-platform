library;

/// 全局配置 JSON Schema
///
/// 此 Schema 定义了全局配置文件的结构和验证规则
/// 用于配置文件的校验和文档生成
class GlobalConfigSchema {
  /// JSON Schema 定义
  static const String schemaJson = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "GlobalConfig",
  "description": "全局应用配置",
  "type": "object",
  "properties": {
    "app": {
      "type": "object",
      "description": "应用基本配置",
      "properties": {
        "name": {
          "type": "string",
          "description": "应用名称",
          "minLength": 1,
          "maxLength": 100
        },
        "version": {
          "type": "string",
          "description": "应用版本号",
          "pattern": "^\\d+\\.\\d+\\.\\d+$"
        },
        "language": {
          "type": "string",
          "description": "界面语言",
          "enum": ["zh_CN", "en_US"]
        },
        "theme": {
          "type": "string",
          "description": "主题模式",
          "enum": ["system", "light", "dark"]
        },
        "pluginViewMode": {
          "type": "string",
          "description": "插件视图模式",
          "enum": ["largeIcon", "mediumIcon", "smallIcon", "list"]
        },
        "autoStartPlugins": {
          "type": "array",
          "description": "自启动插件ID列表",
          "items": {
            "type": "string",
            "pattern": "^[a-z]+\\.[a-z]+\\.[a-z]+$"
          },
          "uniqueItems": true
        }
      },
      "required": ["name", "version", "language", "theme"]
    },
    "features": {
      "type": "object",
      "description": "功能开关配置",
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
              "description": "宠物透明度",
              "minimum": 0.3,
              "maximum": 1.0
            },
            "animations_enabled": {
              "type": "boolean",
              "description": "启用呼吸和眨眼动画"
            },
            "interactions_enabled": {
              "type": "boolean",
              "description": "启用点击和拖拽交互"
            }
          },
          "required": ["opacity", "animations_enabled", "interactions_enabled"]
        }
      },
      "required": ["autoStart", "minimizeToTray", "showDesktopPet", "enableNotifications", "desktopPet"]
    },
    "services": {
      "type": "object",
      "description": "平台服务配置",
      "properties": {
        "audio": {
          "type": "object",
          "description": "音频服务配置",
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
          "description": "通知服务配置",
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "启用通知服务"
            },
            "mode": {
              "type": "string",
              "description": "通知模式",
              "enum": ["app", "system"]
            }
          },
          "required": ["enabled", "mode"]
        },
        "taskScheduler": {
          "type": "object",
          "description": "任务调度服务配置",
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
      "description": "高级配置（开发者选项）",
      "properties": {
        "debugMode": {
          "type": "boolean",
          "description": "调试模式"
        },
        "logLevel": {
          "type": "string",
          "description": "日志级别",
          "enum": ["debug", "info", "warning", "error"]
        },
        "maxLogFileSize": {
          "type": "integer",
          "description": "单个日志文件最大大小（MB）",
          "minimum": 1,
          "maximum": 100
        }
      },
      "required": ["debugMode", "logLevel", "maxLogFileSize"]
    }
  },
  "required": ["app", "features", "services", "advanced"],
  "additionalProperties": false
}
''';

  /// Schema 版本
  static const String version = '1.0.0';

  /// Schema 创建日期
  static const String createdDate = '2026-01-26';

  /// 获取 Schema 描述
  static String getDescription() {
    return '''
# 全局配置 JSON Schema

## 版本信息
- Schema 版本: $version
- 创建日期: $createdDate
- 支持的应用版本: 0.4.4+

## 配置结构

全局配置包含以下主要部分:

### 1. app - 应用配置
应用的基本设置，包括名称、版本、语言、主题等。

### 2. features - 功能配置
控制各种功能模块的开关，如桌面宠物、通知、托盘等。

### 3. services - 服务配置
平台服务的配置，包括音频、通知、任务调度等。

### 4. advanced - 高级配置
开发者选项，包括调试模式、日志级别等。

## 验证规则

1. **必需字段**: 所有顶级配置项都是必需的
2. **枚举值**: 某些字段只能使用预定义的值
3. **数值范围**: 数值字段有最小值和最大值限制
4. **格式验证**: 版本号必须符合语义化版本规范
5. **唯一性**: autoStartPlugins 中的插件ID不能重复

## 使用说明

此 Schema 用于:
- 配置文件的验证
- 配置编辑器的自动补全
- 配置文档的生成
- 配置迁移的参考
''';
  }
}
