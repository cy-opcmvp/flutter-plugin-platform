# AI 编码规则 - 插件配置页面开发规范

> 📋 **本文档定义了插件配置页面的开发标准和最佳实践，所有 AI 助手必须遵守**

## 🎯 核心原则

### 1. 统一的架构模式

所有插件配置页面必须遵循相同的架构模式，确保用户体验一致。

### 2. 实时保存

配置修改后必须**立即保存**，不允许使用"保存设置"按钮。

### 3. 完整的国际化

所有用户可见文本必须使用国际化（l10n），禁止硬编码。

### 4. 双模式编辑

同时支持可视化 UI 控件和 JSON 编辑器两种配置方式。

## 📐 架构模式

### 基本结构

```dart
library;

import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../core/services/json_validator.dart';
import '../config/{plugin_name}_config_defaults.dart';
import '../models/{plugin_name}_settings.dart';
import '../{plugin_name}_plugin.dart';

/// {PluginName} 插件配置界面
class {PluginName}SettingsScreen extends StatefulWidget {
  final {PluginName}Plugin plugin;

  const {PluginName}SettingsScreen({
    super.key,
    required this.plugin,
  });

  @override
  State<{PluginName}SettingsScreen> createState() =>
      _{PluginName}SettingsScreenState();
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 配置分组
          _buildSectionHeader(l10n.{plugin_name}_settings_section1),
          const SizedBox(height: 8),
          _buildConfigTile1(l10n),

          const SizedBox(height: 24),

          _buildSectionHeader(l10n.{plugin_name}_settings_section2),
          const SizedBox(height: 8),
          _buildConfigTile2(l10n),

          const SizedBox(height: 24),

          // JSON 编辑器入口
          _buildJsonEditorSection(context, l10n),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 配置项 1
  Widget _buildConfigTile1(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.{plugin_name}_setting_name),
      subtitle: Text(l10n.{plugin_name}_setting_description),
      value: _settings.configField,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(configField: value);
        await widget.plugin.updateSettings(newSettings);
        if (mounted) {
          setState(() {
            _settings = newSettings;
          });
          _showSuccessMessage();
        }
      },
    );
  }

  /// JSON 编辑器入口
  Widget _buildJsonEditorSection(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: Text(
            l10n.json_editor_edit_json,
            style: TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: _openJsonEditor,
        ),
      ],
    );
  }

  /// 打开 JSON 编辑器
  void _openJsonEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final initialJson = widget.plugin.settings.toJsonString();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.{plugin_name}_config_name,
          configDescription: l10n.{plugin_name}_config_description,
          currentJson: initialJson,
          schema: null, // 或提供 schema
          defaultJson: {PluginName}ConfigDefaults.defaultConfig,
          exampleJson: {PluginName}ConfigDefaults.cleanExample,
          onSave: _saveJsonConfig,
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
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 保存 JSON 配置
  Future<bool> _saveJsonConfig(String jsonString) async {
    try {
      // 1. 校验 JSON
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      // 2. 解析 JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = {PluginName}Settings.fromJson(data);

      // 3. 验证配置
      if (!settings.isValid()) {
        throw Exception('配置验证失败：请检查所有配置项是否符合要求');
      }

      // 4. 保存配置
      await widget.plugin.updateSettings(settings);

      return true;
    } catch (e) {
      debugPrint('保存配置失败: $e');
      return false;
    }
  }

  /// 显示成功消息
  void _showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.{plugin_name}_settings_saved),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
```

## 🎨 UI 组件使用规范

### 1. SwitchListTile - 开关配置

用于布尔值配置项（启用/禁用）。

```dart
SwitchListTile(
  title: Text(l10n.setting_name),
  subtitle: Text(l10n.setting_description),
  value: _settings.booleanField,
  onChanged: (value) async {
    final newSettings = _settings.copyWith(booleanField: value);
    await widget.plugin.updateSettings(newSettings);
    if (mounted) {
      setState(() {
        _settings = newSettings;
      });
      _showSuccessMessage();
    }
  },
)
```

**使用场景**：
- 启用/禁用功能
- 开启/关闭选项

### 2. SegmentedButton - 枚举配置

用于少量固定选项（2-4个）。

```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment(
      value: 'option1',
      label: Text(l10n.option1),
    ),
    ButtonSegment(
      value: 'option2',
      label: Text(l10n.option2),
    ),
  ],
  selected: {_settings.enumField},
  onSelectionChanged: (Set<String> selection) async {
    final newValue = selection.first;
    final newSettings = _settings.copyWith(enumField: newValue);
    await widget.plugin.updateSettings(newSettings);
    if (mounted) {
      setState(() {
        _settings = newSettings;
      });
      _showSuccessMessage();
    }
  },
)
```

**使用场景**：
- 时间格式（12h/24h）
- 角度模式（deg/rad）
- 图片格式（PNG/JPEG/WebP）

### 3. ListTile + showDialog - 复杂配置

用于需要详细配置或验证的选项。

```dart
ListTile(
  leading: const Icon(Icons.folder),
  title: Text(l10n.setting_name),
  subtitle: Text(_settings.complexField),
  trailing: const Icon(Icons.chevron_right),
  onTap: _selectComplexField,
)

void _selectComplexField() {
  showDialog(
    context: context,
    builder: (context) => _ComplexFieldDialog(
      currentValue: _settings.complexField,
      onSave: (value) async {
        final newSettings = _settings.copyWith(complexField: value);
        await widget.plugin.updateSettings(newSettings);
        if (mounted) {
          setState(() {
            _settings = newSettings;
          });
          _showSuccessMessage();
        }
      },
    ),
  );
}
```

**使用场景**：
- 路径选择
- 文件名格式
- 快捷键配置

### 4. Slider - 数值范围配置

用于连续数值配置。

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.setting_name),
        Text('${_settings.numericField} ${l10n.unit}'),
        const SizedBox(height: 16),
        Slider(
          value: _settings.numericField.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '${_settings.numericField}',
          onChanged: (value) async {
            final newSettings = _settings.copyWith(numericField: value.toInt());
            await widget.plugin.updateSettings(newSettings);
            if (mounted) {
              setState(() {
                _settings = newSettings;
              });
            }
          },
        ),
      ],
    ),
  ),
)
```

**使用场景**：
- 图片质量（0-100）
- 更新间隔（100-10000ms）
- 历史记录数量

## ⚠️ 禁止事项

### ❌ 绝对禁止

1. **禁止使用"保存设置"按钮**
   ```dart
   // ❌ 错误：手动保存按钮
   FilledButton(
     onPressed: _saveSettings,
     child: Text('保存设置'),
   )

   // ✅ 正确：实时保存
   onChanged: (value) async {
     await widget.plugin.updateSettings(newSettings);
     setState(() {
       _settings = newSettings;
     });
   }
   ```

2. **禁止硬编码文本**
   ```dart
   // ❌ 错误：硬编码文本
   Text('保存路径')
   title: '设置'

   // ✅ 正确：使用国际化
   Text(l10n.screenshot_savePath)
   title: l10n.settings_title
   ```

3. **禁止先缓存后批量保存**
   ```dart
   // ❌ 错误：缓存到本地变量
   void _onChanged(bool value) {
     setState(() {
       _tempSettings = _settings.copyWith(field: value);
     });
   }

   // ✅ 正确：立即保存
   void _onChanged(bool value) async {
     final newSettings = _settings.copyWith(field: value);
     await widget.plugin.updateSettings(newSettings);
     setState(() {
       _settings = newSettings;
     });
   }
   ```

4. **禁止缺少错误处理**
   ```dart
   // ❌ 错误：没有错误处理
   onChanged: (value) {
     widget.plugin.updateSettings(newSettings);
   }

   // ✅ 正确：完整的错误处理
   onChanged: (value) async {
     try {
       final newSettings = _settings.copyWith(field: value);
       await widget.plugin.updateSettings(newSettings);
       if (mounted) {
         setState(() {
           _settings = newSettings;
         });
         _showSuccessMessage();
       }
     } catch (e) {
       _showErrorMessage();
     }
   }
   ```

## 📋 配置页面检查清单

在创建或修改配置页面时，必须确认：

### 结构检查
- [ ] 继承 `StatefulWidget`
- [ ] 包含 `final {PluginName}Plugin plugin` 参数
- [ ] 在 `initState` 中初始化 `_settings = widget.plugin.settings`
- [ ] 使用 `ListView` 作为根布局
- [ ] 使用 `Scaffold` + `AppBar` 结构

### 功能检查
- [ ] 所有配置修改后立即保存
- [ ] 显示保存成功/失败提示
- [ ] 使用 `mounted` 检查防止内存泄漏
- [ ] 使用 `copyWith` 创建新配置对象
- [ ] 提供 JSON 编辑器入口

### 国际化检查
- [ ] 所有用户可见文本都使用 `l10n.xxx`
- [ ] 没有硬编码的中文字符串
- [ ] 没有硬编码的英文字符串
- [ ] 在 `app_zh.arb` 和 `app_en.arb` 中添加了翻译

### UI 检查
- [ ] 使用章节标题分组（`_buildSectionHeader`）
- [ ] 章节之间有适当的间距（24px）
- [ ] 配置项之间有适当间距（8px）
- [ ] 使用适当的图标（`leading` 或 `secondary`）
- [ ] 使用 `overflow: TextOverflow.ellipsis` 防止溢出

### JSON 编辑器检查
- [ ] 提供 JSON 编辑器入口按钮
- [ ] 实现 `_saveJsonConfig` 方法
- [ ] 包含 JSON 语法校验
- [ ] 包含配置验证（`isValid()`）
- [ ] 保存成功后刷新界面

## 🔗 参考实现

### 完整的参考实现

1. **世界时钟配置页面** - `lib/plugins/world_clock/widgets/settings_screen.dart`
   - SwitchListTile 示例
   - SegmentedButton 示例
   - Slider 示例

2. **计算器配置页面** - `lib/plugins/calculator/widgets/settings_screen.dart`
   - ListTile + Dialog 示例
   - 数值输入示例

3. **截图配置页面** - `lib/plugins/screenshot/widgets/settings_screen.dart`
   - 复杂配置示例
   - 嵌套对象配置示例

## 📚 相关文档

- [JSON 配置文件管理规范](./JSON_CONFIG_RULES.md)
- [文件组织规范](./FILE_ORGANIZATION_RULES.md)
- [项目主文档](../CLAUDE.md)

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**适用范围**: 所有插件配置页面开发
