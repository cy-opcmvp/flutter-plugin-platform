# Release Notes - v0.4.4

**发布日期**: 2026-01-25
**上一个版本**: v0.4.3
**类型**: Minor 版本（功能更新）

---

## 📦 版本概述

v0.4.4 版本主要实现了外部插件国际化支持系统，为外部插件提供完整的国际化能力。同时优化了桌面宠物和插件配置管理功能，修复了多个国际化相关的编译错误。

---

## ✨ 新增功能

### 🌍 外部插件国际化支持

为外部插件提供完整的国际化支持系统，使插件能够轻松实现多语言界面。

#### IPluginI18n 接口

定义了标准的外部插件国际化接口，提供以下功能：

- **翻译注册** - 插件可注册自己的翻译资源
- **翻译获取** - 支持通过键获取翻译文本
- **占位符替换** - 支持动态参数替换（`{key}` 格式）
- **语言回退** - 自动语言回退机制（zh_CN → zh → key）
- **翻译检查** - 检查翻译键是否存在
- **语言列表** - 获取所有支持的语言

#### PluginI18nHelper 实现

完整的国际化辅助实现类：

```dart
// 注册翻译
context.i18n.registerTranslations('com.example.plugin', {
  'zh': {'title': '我的插件'},
  'en': {'title': 'My Plugin'},
});

// 使用翻译
Text(i18n.translate('title'))

// 占位符替换
Text(i18n.translate('greeting', args: {'name': 'John'}))
// 输出：欢迎，John！
```

#### 系统集成

- 更新 `PluginContext`，添加 `i18n` 字段
- 更新 `PluginManager`，初始化 i18n 服务
- 更新 `EnhancedPluginContext`，支持 i18n 参数

### 📋 配置管理系统

新增配置管理文档和示例文件：

- **CONFIG_MANAGEMENT.md** - 配置管理完整指南
  - 配置文件格式和结构
  - 全局配置和插件配置管理
  - 配置验证和错误处理

- **global_config.example.json** - 配置示例文件
  - 完整的配置结构示例
  - 包含桌面宠物、插件配置等
  - 提供配置验证规则

---

## 🔧 改进

### 🐾 桌面宠物优化

- **设置界面改进**
  - 优化宠物设置界面布局
  - 改进配置管理的实时保存机制
  - 增强用户体验和响应性

- **配置管理优化**
  - 改进配置的加载和保存流程
  - 优化配置验证逻辑

### 🔧 插件配置优化

优化了多个插件的配置界面：

- **计算器插件** - 优化配置界面布局
- **世界时钟插件** - 改进配置界面
- **截图插件** - 修复配置相关问题

---

## 🐛 Bug 修复

### 国际化问题修复

修复了 7 个国际化相关的编译错误：

1. **screenshot_main_widget.dart** - 修复 `replaceAll` 错误
   - 问题：使用 `replaceAll` 处理函数返回值
   - 解决：直接调用国际化函数（`l10n.screenshot_minutes_ago(minutes)`）

2. **_ScreenshotListItem** - 修复 context 访问问题
   - 问题：在 build 方法外访问 context
   - 解决：将 l10n 作为参数传递给 `_formatDate` 方法

3. **翻译键缺失** - 添加 `common_add` 翻译
   - 添加到 `app_zh.arb`: "添加"
   - 添加到 `app_en.arb`: "Add"

4. **导入路径修复** - 修正 `PluginI18nHelper` 导入路径
5. **构造函数更新** - 更新 `EnhancedPluginContext` 支持 i18n 参数
6. **服务初始化** - 修复 `LocaleProvider` 初始化问题
7. **翻译文件生成** - 运行 `flutter gen-l10n` 生成最新翻译代码

---

## 📝 技术细节

### 新增文件（4个）

| 文件 | 行数 | 说明 |
|------|------|------|
| `lib/core/interfaces/i_plugin_i18n.dart` | 76 | 外部插件国际化接口定义 |
| `lib/core/services/plugin_i18n_helper.dart` | 129 | 国际化辅助实现类 |
| `assets/config/global_config.example.json` | - | 全局配置示例文件 |
| `docs/guides/CONFIG_MANAGEMENT.md` | - | 配置管理指南 |

### 修改文件（23个）

**核心系统**：
- `lib/core/interfaces/i_plugin.dart` - 添加 i18n 字段
- `lib/core/services/plugin_manager.dart` - 初始化 i18n 服务
- `lib/core/services/platform_services.dart` - 更新构造函数

**UI 界面**：
- `lib/ui/screens/settings_screen.dart`
- `lib/ui/screens/desktop_pet_settings_screen.dart`
- `lib/ui/screens/app_info_screen.dart`

**插件配置**：
- `lib/plugins/calculator/widgets/settings_screen.dart`
- `lib/plugins/world_clock/widgets/settings_screen.dart`
- `lib/plugins/screenshot/widgets/settings_screen.dart`
- `lib/plugins/screenshot/widgets/screenshot_main_widget.dart`

**国际化**：
- `lib/l10n/app_zh.arb` - 添加 common_add 翻译
- `lib/l10n/app_en.arb` - 添加 common_add 翻译
- `lib/l10n/generated/*` - 自动生成的翻译代码

**文档**：
- `.claude/CLAUDE.md` - 添加外部插件国际化支持章节
- `docs/guides/developer/external-plugin-development.md` - 添加完整国际化指南（380+ 行）

### 代码统计

- **文件变更**: 27 个文件
- **新增行数**: +2781
- **删除行数**: -469
- **净增长**: +2312 行

---

## 🚀 升级指南

### 对于开发者

#### 外部插件国际化

如果您正在开发外部插件，现在可以使用新的国际化系统：

1. **准备翻译文件** - 在插件中创建翻译资源
2. **注册翻译** - 在 `initialize()` 方法中注册
3. **使用翻译** - 通过 `context.i18n.translate()` 使用

详细文档请参考：`docs/guides/developer/external-plugin-development.md`

#### 配置管理

新的配置管理系统提供更强大的配置能力：

- 使用 `global_config.example.json` 作为参考
- 遵循 `CONFIG_MANAGEMENT.md` 中的配置规范
- 配置文件支持 JSON Schema 验证

### 对于用户

- **语言切换** - 外部插件现在会自动响应系统语言切换
- **配置管理** - 更友好的配置界面和实时保存
- **稳定性** - 修复了多个编译错误，提高稳定性

---

## 📋 已知问题

### 🐾 宠物窗口背景闪烁

**描述**: 当宠物窗口缩小时，会有背景闪烁现象

**影响**: 用户体验

**计划**: 在下版本（v0.4.5）中修复

**临时方案**: 避免频繁调整宠物窗口大小

---

## 🎯 下版本计划（v0.4.5）

### 主要任务

1. **验证和修复各插件的配置功能**
   - 测试所有插件的配置保存和加载
   - 修复配置验证和错误处理问题
   - 优化配置界面的用户体验

2. **优化部分插件功能**
   - 性能优化
   - 功能增强
   - 用户界面改进

3. **修复宠物窗口缩小时背景闪烁**
   - 调查闪烁原因
   - 实现修复方案
   - 测试验证

---

## 📊 完整提交历史

| 提交 ID | 描述 | 作者 |
|---------|------|------|
| 44afdf0 | feat: 宠物和设置功能优化，外部插件国际化支持 | Claude Code |
| a9bbf64 | docs: 更新 CHANGELOG.md，记录 v0.4.4 版本变更 | Claude Code |

**提交范围**: 1e12358..a9bbf64

---

## 🔗 相关资源

- **项目仓库**: [GitHub](https://github.com/your-org/flutter-plugin-platform)
- **文档中心**: [docs/MASTER_INDEX.md](../MASTER_INDEX.md)
- **更新日志**: [../../CHANGELOG.md](../../CHANGELOG.md)
- **版本历史**: [../../.claude/rules/VERSION_CONTROL_HISTORY.md](../../.claude/rules/VERSION_CONTROL_HISTORY.md)

---

## 💬 反馈与支持

如有问题或建议，请通过以下方式联系：

- **GitHub Issues**: [提交问题](https://github.com/your-org/flutter-plugin-platform/issues)
- **文档**: [查看完整文档](../MASTER_INDEX.md)

---

**发布时间**: 2026-01-25
**版本**: v0.4.4
**状态**: ✅ 已发布
