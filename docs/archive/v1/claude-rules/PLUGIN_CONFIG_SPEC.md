# 插件配置规范

> 📋 **本文档定义了所有插件必须遵守的配置功能规范**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有内部插件

---

## 🎯 核心原则

### 1. 配置功能是强制的
**所有插件都必须提供配置功能**，除非插件：
- 没有任何可配置的参数（极少见）
- 只是演示性质的简单示例

### 2. 配置文件标准化
所有插件配置必须遵循统一的文件结构和命名规范。

### 3. 最小可用配置
每个插件至少提供 **3-5 个核心配置项**，确保用户可以自定义基本行为。

---

## 📁 强制的文件结构

每个插件必须包含以下配置相关文件：

```
lib/plugins/{plugin_name}/
├── config/
│   ├── {plugin_name}_config_defaults.dart   # 必需 - 默认配置和 Schema
│   └── {plugin_name}_config_docs.md         # 必需 - 配置说明文档
├── models/
│   └── {plugin_name}_settings.dart          # 必需 - 配置数据模型
└── widgets/
    └── settings_screen.dart                # 必需 - 配置界面
```

### 文件命名规则

- **配置文件**: `{plugin_name}_config_defaults.dart`
  - 示例: `calculator_config_defaults.dart`
  - 示例: `world_clock_config_defaults.dart`

- **配置模型**: `{plugin_name}_settings.dart`
  - 示例: `calculator_settings.dart`
  - 示例: `world_clock_settings.dart`

- **配置界面**: `settings_screen.dart`
  - 固定名称，不添加插件前缀
  - 示例: `settings_screen.dart` (在各自插件目录下)

- **配置文档**: `{plugin_name}_config_docs.md`
  - 示例: `calculator_config_docs.md`
  - 示例: `world_clock_config_docs.md`

---

## 📝 配置文件模板

### 1. 配置默认值文件模板

**文件**: `config/{plugin_name}_config_defaults.dart`

```dart
library;

import 'dart:convert';
import '../models/{plugin_name}_settings.dart';

/// {PluginName} 配置默认值和示例
class {PluginName}ConfigDefaults {
  /// 默认配置 JSON
  static const String defaultConfig = '''
{
  "key1": "value1",
  "key2": 123,
  "key3": true
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "{PluginName} 配置文件",
  "_description": "修改此文件可以自定义插件行为",

  "key1": "value1",
  "_key1_help": "配置说明...",
  "_key1_default": "value1",

  "key2": 123,
  "_key2_help": "配置说明...",
  "_key2_range": "取值范围: x-y",

  "key3": true,
  "_key3_help": "配置说明..."
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
          entry.key.endsWith('_default') ||
          entry.key.endsWith('_range') ||
          entry.key.endsWith('_examples')) {
        continue;
      }
      // 递归处理嵌套对象
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _removeHelpFields(entry.value as Map<String, dynamic>);
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
  "description": "{PluginName} 配置",
  "properties": {
    "key1": {
      "type": "string",
      "description": "配置说明"
    },
    "key2": {
      "type": "integer",
      "minimum": 0,
      "maximum": 1000,
      "description": "配置说明"
    },
    "key3": {
      "type": "boolean",
      "description": "配置说明"
    }
  },
  "required": ["key1", "key2", "key3"]
}''';

  /// 获取默认配置对象
  static {PluginName}Settings get defaultSettings =>
      {PluginName}Settings.defaultSettings();
}
```

### 2. 配置模型文件模板

**文件**: `models/{plugin_name}_settings.dart`

```dart
library;

/// {PluginName} 设置模型
class {PluginName}Settings {
  /// 配置项1
  final String key1;

  /// 配置项2
  final int key2;

  /// 配置项3
  final bool key3;

  const {PluginName}Settings({
    required this.key1,
    required this.key2,
    required this.key3,
  });

  /// 默认设置
  factory {PluginName}Settings.defaultSettings() {
    return const {PluginName}Settings(
      key1: 'default_value',
      key2: 100,
      key3: true,
    );
  }

  /// 从 JSON 创建实例
  factory {PluginName}Settings.fromJson(Map<String, dynamic> json) {
    return {PluginName}Settings(
      key1: json['key1'] as String? ?? 'default_value',
      key2: json['key2'] as int? ?? 100,
      key3: json['key3'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'key1': key1,
      'key2': key2,
      'key3': key3,
    };
  }

  /// 复制并修改部分设置
  {PluginName}Settings copyWith({
    String? key1,
    int? key2,
    bool? key3,
  }) {
    return {PluginName}Settings(
      key1: key1 ?? this.key1,
      key2: key2 ?? this.key2,
      key3: key3 ?? this.key3,
    );
  }

  /// 验证设置是否有效
  bool isValid() {
    return key1.isNotEmpty && key2 >= 0;
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
```

### 3. 配置界面文件模板

**文件**: `widgets/settings_screen.dart`

```dart
library;

import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../config/{plugin_name}_config_defaults.dart';
import '../models/{plugin_name}_settings.dart';
import '../{plugin_name}_plugin.dart';

/// {PluginName} 插件设置界面
class {PluginName}SettingsScreen extends StatefulWidget {
  final {PluginName}Plugin plugin;

  const {PluginName}SettingsScreen({
    super.key,
    required this.plugin,
  });

  @override
  State<{PluginName}SettingsScreen> createState() => _{PluginName}SettingsScreenState();
}

class _{PluginName}SettingsScreenState extends State<{PluginName}SettingsScreen> {
  late {PluginName}Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.plugin.settings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.{plugin_name}_settings_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 配置项
          ListTile(
            title: Text(l10n.{plugin_name}_setting_key1),
            subtitle: Text(_settings.key1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editKey1(),
          ),

          // JSON 编辑器入口
          const SizedBox(height: 24),
          _buildJsonEditorSection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildJsonEditorSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.json_editor_title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.{plugin_name}_config_description),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openJsonEditor(context),
              icon: const Icon(Icons.edit),
              label: Text(l10n.json_editor_edit_json),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJsonEditor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.{plugin_name}_config_name,
          configDescription: l10n.{plugin_name}_config_description,
          currentJson: _settings.toJsonString(),
          schema: {PluginName}ConfigDefaults.schemaJson,
          defaultJson: {PluginName}ConfigDefaults.defaultConfig,
          exampleJson: {PluginName}ConfigDefaults.cleanExample,
          onSave: _saveConfig,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _settings = widget.plugin.settings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.{plugin_name}_settings_saved),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<bool> _saveConfig(String json) async {
    // 保存配置逻辑
    return true;
  }

  void _editKey1() {
    // 编辑配置项逻辑
  }
}
```

---

## ✅ 配置功能检查清单

### 文件完整性检查

- [ ] `config/{plugin_name}_config_defaults.dart`
  - [ ] 包含 `defaultConfig` 常量
  - [ ] 包含 `exampleConfig` 常量
  - [ ] 包含 `schemaJson` 常量
  - [ ] 包含 `cleanExample` getter
  - [ ] 包含 `_removeHelpFields()` 方法
  - [ ] 包含 `defaultSettings` getter

- [ ] `models/{plugin_name}_settings.dart`
  - [ ] 包含所有配置字段的定义
  - [ ] 包含 `defaultSettings()` 工厂方法
  - [ ] 包含 `fromJson()` 工厂方法
  - [ ] 包含 `toJson()` 方法
  - [ ] 包含 `copyWith()` 方法
  - [ ] 包含 `isValid()` 验证方法

- [ ] `widgets/settings_screen.dart`
  - [ ] 继承 `StatefulWidget`
  - [ ] 包含可视化配置界面
  - [ ] 包含 JSON 编辑器入口
  - [ ] 包含配置保存逻辑
  - [ ] 包含错误处理

- [ ] `config/{plugin_name}_config_docs.md`
  - [ ] 包含配置概述
  - [ ] 包含所有配置项说明
  - [ ] 包含配置示例
  - [ ] 包含常见问题

### 功能完整性检查

- [ ] **配置持久化**
  - [ ] 配置可以保存到文件
  - [ ] 配置可以从文件加载
  - [ ] 配置在应用重启后保持

- [ ] **配置验证**
  - [ ] JSON 语法校验
  - [ ] Schema 校验
  - [ ] 业务逻辑验证

- [ ] **用户体验**
  - [ ] 可视化配置界面友好
  - [ ] JSON 编辑器功能完整
  - [ ] 错误提示清晰
  - [ ] 支持重置到默认值
  - [ ] 支持查看示例配置

- [ ] **国际化**
  - [ ] 所有文本使用国际化
  - [ ] 中英文翻译完整

---

## 📋 最小配置要求

每个插件必须提供至少 **3 个配置项**：

### 推荐的配置类型

1. **显示/行为配置** (至少 1 个)
   - 示例: `showSeconds`, `enableNotifications`, `showPreview`

2. **数值/范围配置** (至少 1 个)
   - 示例: `precision`, `maxHistoryCount`, `updateInterval`

3. **格式/选项配置** (至少 1 个)
   - 示例: `timeFormat`, `imageFormat`, `angleMode`

### 可选的高级配置

- 快捷键配置
- 主题配置
- 声音配置
- 网络配置
- 权限配置

---

## 🎨 UI 规范

### 配置界面布局

```dart
Scaffold
├── AppBar
│   └── title: "{PluginName} 设置"
└── ListView
    ├── Section 1: 基础设置
    │   ├── ListTile (配置项1)
    │   ├── ListTile (配置项2)
    │   └── ListTile (配置项3)
    ├── Section 2: 高级设置
    │   ├── SwitchListTile (布尔配置)
    │   └── SliderListTile (数值配置)
    └── Section 3: JSON 编辑器
        └── Card
            ├── Icon + Title
            ├── Description
            └── FilledButton (编辑 JSON)
```

### 配置项控件选择

| 数据类型 | 推荐控件 | 示例 |
|---------|---------|------|
| String | TextField / ListTile | 文件路径、名称 |
| Int | Slider / Spinner | 精度、数量 |
| Double | Slider | 透明度、质量 |
| Bool | SwitchListTile | 启用/禁用 |
| Enum | DropdownButton | 格式、模式 |
| List | ListView / Chips | 快捷键列表 |

---

## 🔧 实现流程

### 1. 创建配置文件

```bash
# 使用模板工具自动生成
dart tools/plugin_config_cli.dart create \
  --plugin calculator \
  --settings precision,angleMode,historySize
```

### 2. 实现配置模型

```dart
// 复制模板并修改
// 1. 定义字段
// 2. 实现方法
// 3. 添加验证
```

### 3. 实现配置界面

```dart
// 复制模板并修改
// 1. 添加配置项控件
// 2. 实现 JSON 编辑器集成
// 3. 添加保存逻辑
```

### 4. 添加国际化

```dart
// lib/l10n/app_zh.arb
"calculator_settings_title": "计算器设置",
"calculator_setting_precision": "计算精度",
...

// lib/l10n/app_en.arb
"calculator_settings_title": "Calculator Settings",
"calculator_setting_precision": "Precision",
...
```

### 5. 集成到插件

```dart
class CalculatorPlugin extends IPlugin {
  CalculatorSettings _settings = CalculatorSettings.defaultSettings();

  @override
  Widget buildUI(BuildContext context) {
    return CalculatorSettingsScreen(plugin: this);
  }
}
```

---

## 📚 参考资料

### 参考实现

- **Screenshot 插件** - 完整的配置实现参考
  - 文件: `lib/plugins/screenshot/`

### 相关文档

- `.claude/rules/JSON_CONFIG_RULES.md` - JSON 配置管理规范
- `.claude/rules/FILE_ORGANIZATION_RULES.md` - 文件组织规范
- `docs/reports/CONFIG_FEATURE_AUDIT.md` - 配置功能审计报告

---

## 🚀 快速开始

### 方式 1: 手动创建（3-5个配置项）

1. 复制本文档的模板文件
2. 替换 `{plugin_name}` 和 `{PluginName}` 占位符
3. 定义配置项
4. 实现配置界面

### 方式 2: 使用自动化工具（推荐）

```bash
# 即将推出的配置生成工具
dart tools/plugin_config_generator.dart \
  --plugin calculator \
  --interactive
```

---

## ✅ 验收标准

插件配置功能被认为完整实现，当且仅当：

- [x] 包含所有必需的配置文件
- [x] 配置模型完整实现
- [x] 配置界面可访问且功能正常
- [x] JSON 编辑器集成且功能完整
- [x] 配置可以保存和加载
- [x] 配置验证正常工作
- [x] 国际化完整
- [x] 有配置说明文档

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Claude Code
