# AI 编码规则 - 单一配置模式规范

> 📋 **本文档定义了插件配置数据管理的单一配置模式，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-25
**适用范围**: 所有插件的数据持久化设计

---

## 🎯 核心原则

### 1. 单一配置键原则

**每个插件必须使用单一的配置键来存储所有持久化数据**

- ✅ **正确**: 使用单一键 `screenshot_config` 存储所有设置和数据
- ❌ **错误**: 使用多个键 `screenshot_settings`, `screenshot_history`, `screenshot_templates` 分散存储

### 2. 配置与临时状态分离

**配置（Configuration） vs 临时状态（Temporary State）**

| 类型 | 特点 | 示例 | 是否持久化 |
|------|------|------|----------|
| **配置** | 用户设置的参数，需要跨会话保存 | 保存路径、快捷键、主题 | ✅ 是 |
| **数据** | 插件管理的业务数据 | 时钟列表、历史记录、模板 | ✅ 是 |
| **临时状态** | 仅当前会话使用的运行时状态 | 当前输入、UI 展开状态 | ❌ 否 |

### 3. 配置键命名规范

**格式**: `{plugin_id}_config`

**示例**:
- `world_clock_config` - 世界时钟配置
- `calculator_config` - 计算器配置
- `screenshot_config` - 截图配置

---

## 📐 配置模型设计

### 基本结构

每个插件必须有一个继承自 `BasePluginSettings` 的配置模型：

```dart
library;

import '../../../core/models/base_plugin_settings.dart';

/// 插件设置模型
class PluginSettings extends BasePluginSettings {
  /// 配置版本（必需）
  @override
  final String version;

  /// 配置项1
  final String setting1;

  /// 配置项2
  final int setting2;

  /// 数据列表1（如：时钟列表）
  final List<DataItem> dataItems;

  /// 数据列表2（如：模板列表）
  final List<Map<String, dynamic>> templates;

  const PluginSettings({
    this.version = '1.0.0',
    required this.setting1,
    required this.setting2,
    this.dataItems = const [],
    this.templates = const [],
  });

  /// 默认设置
  factory PluginSettings.defaultSettings() {
    return const PluginSettings(
      version: '1.0.0',
      setting1: 'default_value',
      setting2: 100,
      dataItems: [],
      templates: [],
    );
  }

  /// 从 JSON 创建实例
  factory PluginSettings.fromJson(Map<String, dynamic> json) {
    return PluginSettings(
      version: json['version'] as String? ?? '1.0.0',
      setting1: json['setting1'] as String? ?? 'default_value',
      setting2: json['setting2'] as int? ?? 100,
      dataItems: (json['dataItems'] as List?)
              ?.map((e) => DataItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      templates: (json['templates'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'setting1': setting1,
      'setting2': setting2,
      'dataItems': dataItems.map((e) => e.toJson()).toList(),
      'templates': templates,
    };
  }

  /// 复制并修改部分设置
  @override
  PluginSettings copyWith({
    String? version,
    String? setting1,
    int? setting2,
    List<DataItem>? dataItems,
    List<Map<String, dynamic>>? templates,
  }) {
    return PluginSettings(
      version: version ?? this.version,
      setting1: setting1 ?? this.setting1,
      setting2: setting2 ?? this.setting2,
      dataItems: dataItems ?? this.dataItems,
      templates: templates ?? this.templates,
    );
  }

  /// 验证设置是否有效
  @override
  bool isValid() {
    return setting1.isNotEmpty && setting2 > 0;
  }
}
```

---

## 🔄 插件实现模式

### initialize() - 加载配置

```dart
@override
Future<void> initialize(PluginContext context) async {
  _context = context;

  // 从单一配置加载设置
  final savedConfig = await _context.dataStorage
      .retrieve<Map<String, dynamic>>('plugin_config');

  if (savedConfig != null) {
    _settings = PluginSettings.fromJson(savedConfig);

    // 如果配置中包含数据列表，同步到运行时状态
    _dataItems.clear();
    _dataItems.addAll(_settings.dataItems);
  } else {
    _settings = PluginSettings.defaultSettings();
  }

  // 初始化其他资源...
}
```

### _saveConfig() - 保存配置

```dart
/// 保存配置
Future<void> _saveConfig() async {
  try {
    // 创建新的配置对象，包含当前运行时状态
    final config = _settings.copyWith(
      dataItems: List.from(_dataItems), // 同步运行时状态到配置
    );

    // 保存到单一配置键
    await _context.dataStorage.store(
      'plugin_config',
      config.toJson(),
    );
  } catch (e) {
    debugPrint('Failed to save config: $e');
  }
}
```

### updateSettings() - 更新配置

```dart
/// 更新设置
Future<void> updateSettings(PluginSettings newSettings) async {
  _settings = newSettings;
  await _saveConfig();
  _onStateChanged?.call();
}
```

### dispose() - 清理时保存

```dart
@override
Future<void> dispose() async {
  try {
    // 释放资源
    await _cleanup();

    // 保存配置
    await _saveConfig();
  } catch (e) {
    debugPrint('Disposal error: $e');
  }
}
```

---

## 📋 配置默认值文件

### 文件位置

`lib/plugins/{plugin_name}/config/{plugin_name}_config_defaults.dart`

### 文件内容

```dart
library;

import 'dart:convert';
import '../models/{plugin_name}_settings.dart';

/// 插件配置默认值和示例
class PluginConfigDefaults {
  /// 默认配置 JSON（必须包含 version 字段）
  static const String defaultConfig = '''
{
  "version": "1.0.0",
  "setting1": "default_value",
  "setting2": 100,
  "dataItems": [],
  "templates": []
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "插件配置文件",
  "_description": "修改此文件可以自定义插件行为",

  "version": "1.0.0",
  "_version_help": "配置版本号，用于迁移和兼容性检查",

  "setting1": "default_value",
  "_setting1_help": "配置说明...",

  "setting2": 100,
  "_setting2_help": "配置说明...",
  "_setting2_range": "取值范围: 0-200"
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
          entry.key == '_description' ||
          entry.key.endsWith('_help') ||
          entry.key.endsWith('_examples') ||
          entry.key.endsWith('_range')) {
        continue;
      }
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _removeHelpFields(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is List) {
        continue; // 跳过示例列表
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
  "description": "插件配置",
  "properties": {
    "version": {
      "type": "string",
      "description": "配置版本号"
    },
    "setting1": {
      "type": "string",
      "description": "配置说明"
    },
    "setting2": {
      "type": "integer",
      "minimum": 0,
      "maximum": 200,
      "description": "配置说明"
    }
  },
  "required": ["version", "setting1", "setting2"]
}''';

  /// 获取默认配置对象
  static PluginSettings get defaultSettings =>
      PluginSettings.defaultSettings();
}
```

---

## ⚠️ 常见错误

### 错误 1: 使用多个存储键

```dart
// ❌ 错误：使用多个键分散存储
await _context.dataStorage.store('settings', settings.toJson());
await _context.dataStorage.store('history', history.toJson());
await _context.dataStorage.store('templates', templates.toJson());

// ✅ 正确：所有数据在一个配置中
final config = PluginSettings(
  settings: settings,
  history: history,
  templates: templates,
);
await _context.dataStorage.store('plugin_config', config.toJson());
```

### 错误 2: 持久化临时状态

```dart
// ❌ 错误：保存 UI 临时状态
final config = _settings.copyWith(
  isDialogOpen: _isDialogOpen, // UI 状态，不应持久化
  currentInput: _inputController.text, // 临时输入，不应持久化
);

// ✅ 正确：只保存配置和数据
final config = _settings.copyWith(
  dataItems: List.from(_dataItems), // 持久化数据
  templates: List.from(_templates), // 持久化数据
);
```

### 错误 3: 配置键命名不规范

```dart
// ❌ 错误：配置键命名不规范
await _context.dataStorage.store('myPluginConfig', ...);
await _context.dataStorage.store('settings_v2', ...);

// ✅ 正确：使用 {plugin_id}_config 格式
await _context.dataStorage.store('screenshot_config', ...);
await _context.dataStorage.store('calculator_config', ...);
await _context.dataStorage.store('world_clock_config', ...);
```

### 错误 4: 缺少 version 字段

```dart
// ❌ 错误：配置中没有 version 字段
static const String defaultConfig = '''
{
  "setting1": "value",
  "setting2": 100
}''';

// ✅ 正确：配置必须包含 version 字段
static const String defaultConfig = '''
{
  "version": "1.0.0",
  "setting1": "value",
  "setting2": 100
}''';
```

---

## ✅ 检查清单

### 配置模型检查
- [ ] 继承自 `BasePluginSettings`
- [ ] 包含 `version` 字段（String 类型）
- [ ] 实现 `fromJson()` 方法
- [ ] 实现 `toJson()` 方法
- [ ] 实现 `copyWith()` 方法
- [ ] 实现 `isValid()` 方法
- [ ] 实现 `defaultSettings()` 工厂方法
- [ ] 所有持久化数据都包含在模型中

### 插件实现检查
- [ ] 使用单一配置键 `{plugin_id}_config`
- [ ] `initialize()` 中从配置加载
- [ ] `_saveConfig()` 保存到配置键
- [ ] `dispose()` 中保存配置
- [ ] `updateSettings()` 更新配置
- [ ] 临时状态不持久化

### 配置默认值文件检查
- [ ] `defaultConfig` 包含 `version` 字段
- [ ] `exampleConfig` 有详细注释
- [ ] `schemaJson` 定义了 `version` 字段
- [ ] 实现 `cleanExample` getter
- [ ] 实现 `_removeHelpFields()` 方法

---

## 📚 参考实现

### 完整示例：世界时钟插件

**配置模型**: `lib/plugins/world_clock/models/world_clock_settings.dart`
- 包含所有设置、时钟列表、倒计时列表、模板列表
- 单一的 `fromJson()` / `toJson()` 方法
- 完整的 `copyWith()` 方法

**插件实现**: `lib/plugins/world_clock/world_clock_plugin.dart`
- 使用 `world_clock_config` 单一配置键
- `initialize()` 加载配置并同步到运行时状态
- `_saveCurrentState()` 保存配置
- 模板修改通过 `updateSettings()` 持久化

**配置默认值**: `lib/plugins/world_clock/config/world_clock_config_defaults.dart`
- 完整的 `defaultConfig`（含 version）
- 详细的 `exampleConfig`（含注释）
- 完整的 `schemaJson`

### 其他参考实现

- **计算器插件**: `lib/plugins/calculator/` - 简单配置，无数据列表
- **截图插件**: `lib/plugins/screenshot/` - 复杂配置，分离历史元数据

---

## 🎯 快速参考

| 场景 | 规范 | 示例 |
|------|------|------|
| **配置键命名** | `{plugin_id}_config` | `screenshot_config` |
| **配置模型** | 继承 `BasePluginSettings` | `class Settings extends BasePluginSettings` |
| **version 字段** | 必需，String 类型 | `"version": "1.0.0"` |
| **数据持久化** | 所有数据在配置模型中 | `dataItems: [...]` |
| **临时状态** | 不持久化 | `_isDialogOpen` 不保存 |
| **加载配置** | `initialize()` 中加载 | `PluginSettings.fromJson(data)` |
| **保存配置** | `_saveConfig()` 方法 | `dataStorage.store(key, json)` |

---

## 📖 相关文档

- [插件配置规范](./PLUGIN_CONFIG_SPEC.md) - 插件配置功能强制规范
- [插件配置页面开发规范](./PLUGIN_SETTINGS_SCREEN_RULES.md) - 配置界面开发
- [JSON 配置文件管理规范](./JSON_CONFIG_RULES.md) - JSON 配置管理
- [配置响应式管理规范](./REACTIVE_CONFIG_RULES.md) - 配置实时生效

---

**版本**: v1.0.0
**最后更新**: 2026-01-25
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 单一配置模式让插件数据管理更简单、更一致、更易维护！
