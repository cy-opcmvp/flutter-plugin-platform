# AI 编码规则 - JSON 配置文件管理规范

> 📋 **本文档定义了项目中 JSON 配置文件的管理规范，所有 AI 助手（Claude Code 等）必须遵守**

## 🎯 核心原则

### 1. 每个配置文件必须包含的元素

**每个 JSON 配置文件都必须提供**：

1. **默认配置 (Default Config)** - 干净、可用的默认值
2. **示例配置 (Example Config)** - 带详细注释和说明的示例
3. **JSON Schema** - 用于严格校验配置文件
4. **配置说明文档** - 人类可读的详细说明

### 2. 配置文件必须支持的功能

**每个配置文件的编辑界面都必须提供**：

1. ✅ **JSON 语法校验** - 实时校验 JSON 格式
2. ✅ **Schema 校验** - 根据规则校验数据类型和取值范围
3. ✅ **格式化功能** - 美化 JSON 输出，提高可读性
4. ✅ **压缩功能** - 移除不必要的空格和换行
5. ✅ **重置功能** - 一键恢复默认配置
6. ✅ **示例加载** - 显示带注释的示例配置
7. ✅ **详细说明** - 每个配置项的用途和可选值

### 3. 保存前的强制校验

**在保存任何 JSON 配置前**：

- 必须先通过 JSON 语法校验
- 必须通过 Schema 校验（如果有 Schema）
- 不符合规范的配置必须被拒绝保存
- 必须向用户显示清晰的错误信息（包括错误行号和位置）

## 📁 文件组织规范

### 配置文件目录结构

```
lib/plugins/{plugin_name}/config/
├── {plugin_name}_config_defaults.dart  # 默认配置和示例
├── {plugin_name}_config_schema.dart     # JSON Schema 定义
└── {plugin_name}_config_docs.md        # 配置说明文档
```

### 配置模型目录

```
lib/plugins/{plugin_name}/models/
└── {plugin_name}_settings.dart         # 设置模型定义
```

## 📝 配置文件模板

### Dart 配置类模板

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
  "key2": 123
}''';

  /// 示例配置 JSON（带详细注释的版本）
  static const String exampleConfig = '''
{
  "_comment": "{PluginName} 配置文件",
  "_description": "修改此文件可以自定义...",

  "key1": "value1",
  "_key1_help": "配置说明...",

  "key2": 123,
  "_key2_help": "配置说明...",
  "_key2_range": "取值范围: x-y",
  "_key2_examples": [
    "示例1",
    "示例2"
  ]
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
          entry.key.endsWith('_examples') ||
          entry.key.endsWith('_range')) {
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
    }
  }
}''';

  /// 获取默认配置对象
  static {PluginName}Settings get defaultSettings =>
      {PluginName}Settings.defaultSettings();
}
```

### 配置模型模板

```dart
library;

/// {PluginName} 设置模型
class {PluginName}Settings {
  /// 配置项1
  final String key1;

  /// 配置项2
  final int key2;

  const {PluginName}Settings({
    required this.key1,
    required this.key2,
  });

  /// 默认设置
  factory {PluginName}Settings.defaultSettings() {
    return const {PluginName}Settings(
      key1: 'default_value',
      key2: 100,
    );
  }

  /// 从 JSON 创建实例
  factory {PluginName}Settings.fromJson(Map<String, dynamic> json) {
    return {PluginName}Settings(
      key1: json['key1'] as String? ?? 'default_value',
      key2: json['key2'] as int? ?? 100,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'key1': key1,
      'key2': key2,
    };
  }

  /// 复制并修改部分设置
  {PluginName}Settings copyWith({
    String? key1,
    int? key2,
  }) {
    return {PluginName}Settings(
      key1: key1 ?? this.key1,
      key2: key2 ?? this.key2,
    );
  }

  /// 验证设置是否有效
  bool isValid() {
    return key1.isNotEmpty && key2 >= 0;
  }
}
```

### JSON Schema 模板

```json
{
  "type": "object",
  "description": "配置文件描述",
  "properties": {
    "key1": {
      "type": "string",
      "description": "配置项说明"
    },
    "key2": {
      "type": "integer",
      "minimum": 0,
      "maximum": 1000,
      "description": "配置项说明"
    }
  },
  "required": ["key1", "key2"]
}
```

## 🔧 使用 JSON 编辑器

### 在设置页面添加 JSON 编辑入口

```dart
// 在设置页面添加按钮
ListTile(
  leading: const Icon(Icons.code),
  title: Text(l10n.json_editor_edit_json),
  trailing: const Icon(Icons.chevron_right),
  onTap: _openJsonEditor,
);

/// 打开 JSON 编辑器
void _openJsonEditor() async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => JsonEditorScreen(
        configName: l10n.{plugin_name}_config_name,
        configDescription: l10n.{plugin_name}_config_description,
        currentJson: currentConfigJson,
        schema: configSchema,
        defaultJson: {PluginName}ConfigDefaults.defaultConfig,
        exampleJson: {PluginName}ConfigDefaults.cleanExample,
        onSave: _saveConfig,
      ),
    ),
  );

  if (result == true) {
    // 配置已保存，刷新界面
    setState(() {});
  }
}

/// 保存配置
Future<bool> _saveConfig(String json) async {
  try {
    // 1. 校验 JSON
    final validationResult = JsonValidator.validateJsonString(json);
    if (!validationResult.isValid) {
      throw Exception(validationResult.errorMessage);
    }

    // 2. 解析 JSON
    final data = jsonDecode(json) as Map<String, dynamic>;

    // 3. Schema 校验
    if (configSchema != null) {
      final schemaResult = JsonValidator.validateSchema(
        data,
        configSchema!,
      );
      if (!schemaResult.isValid) {
        throw Exception(schemaResult.errorMessage);
      }
    }

    // 4. 创建配置对象
    final settings = {PluginName}Settings.fromJson(data);

    // 5. 验证配置
    if (!settings.isValid()) {
      throw Exception('Invalid configuration');
    }

    // 6. 保存配置
    await widget.plugin.updateSettings(settings);

    return true;
  } catch (e) {
    debugPrint('Failed to save config: $e');
    return false;
  }
}
```

## ✅ 检查清单

### 创建新配置文件时

- [ ] 创建配置模型类（`{plugin}_settings.dart`）
- [ ] 创建配置默认值类（`config/{plugin}_config_defaults.dart`）
- [ ] 定义 JSON Schema
- [ ] 创建默认配置 JSON
- [ ] 创建带注释的示例配置
- [ ] 在设置页面添加"编辑 JSON"按钮
- [ ] 实现保存逻辑（包含校验）
- [ ] 添加国际化文本
- [ ] 创建配置说明文档

### 更新现有配置时

- [ ] 更新配置模型类（添加新字段）
- [ ] 更新默认配置
- [ ] 更新示例配置（添加注释）
- [ ] 更新 JSON Schema
- [ ] 更新配置说明文档
- [ ] 提供迁移指南（如果有破坏性变更）
- [ ] 测试配置加载和保存
- [ ] 测试配置校验功能

## 🚫 禁止事项

### ❌ 绝对禁止

1. **禁止跳过 JSON 校验** - 所有配置保存前必须校验
2. **禁止硬编码配置** - 所有配置必须可编辑
3. **禁止缺少默认值** - 每个字段都必须有默认值
4. **禁止缺少示例** - 必须提供示例配置
5. **禁止缺少说明** - 每个配置项都必须有说明
6. **禁止破坏性静默升级** - 配置格式变更必须明确通知用户

### ⚠️ 需要谨慎评估

1. **删除配置项** - 需要提供迁移指南和降级方案
2. **重命名字段** - 需要保持向后兼容
3. **修改类型** - 需要提供类型转换逻辑
4. **修改默认值** - 需要评估对现有用户的影响

## 📚 参考文档

- [JSON Schema 规范](https://json-schema.org/)
- [Dart JSON 解码](https://api.dart.dev/stable/dart-convert/JsonDecoder-class.html)
- [配置管理最佳实践](../docs/guides/CONFIG_MANAGEMENT.md)

---

**版本**: v1.0.0
**最后更新**: 2026-01-19
**适用范围**: 所有 AI 编码助手和开发者

## 🔗 相关文档

- [文件组织规范](./FILE_ORGANIZATION_RULES.md)
- [版本控制规则](./VERSION_CONTROL_RULES.md)
- [国际化开发规范](../CLAUDE.md#国际化开发规范)
