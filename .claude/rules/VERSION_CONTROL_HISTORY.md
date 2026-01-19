# 版本控制历史

本文档记录所有 tag 创建、push 操作和重要对话的详细历史，用于追溯项目演进过程。

## 版本索引

- [v0.4.0](#v040-2026-01-19) - 2026-01-19
- [v0.3.4](#v034-2026-01-16) - 2026-01-16
- [v0.3.2](#v032-2026-01-15) - 2026-01-15
- [v0.3.1](#v031-2025-01-14) - 2025-01-14
- [v0.3.0](#v030-2025-01-14) - 2025-01-14

---

## v0.4.0 (2026-01-19)

### Tag 信息
- **版本号**: v0.4.0
- **提交**: 36428f6
- **创建时间**: 2026-01-19
- **创建者**: Claude Code
- **类型**: Minor 版本（新功能）

### 变更内容
- **配置管理系统** - 完整的 JSON 配置文件管理解决方案
  - 新增 JSON 配置文件管理规范 (JSON_CONFIG_RULES.md)
  - 新增 JsonValidator 服务，提供 JSON 语法校验和 Schema 验证
  - 新增通用 JSON 编辑器界面 (JsonEditorScreen)
  - 支持格式化、压缩、重置、查看示例
  - 实时错误提示和行号定位
- **标签管理系统** - 插件分类和组织功能
  - 新增 TagModel 标签数据模型
  - 新增 TagManager 标签管理服务
  - 新增标签管理界面 (TagManagementScreen)
  - 新增标签过滤栏组件 (TagFilterBar)
  - 支持标签的创建、编辑、删除
  - 支持按标签过滤插件
- **插件描述符系统** - 统一的插件元数据管理
  - 新增截图插件描述符 (plugin_descriptor.json)
  - 新增计算器插件描述符 (plugin_descriptor.json)
  - 新增世界时钟插件描述符 (plugin_descriptor.json)
  - 规范插件 ID、版本、作者等信息
- **截图插件配置完善** - 可视化 + JSON 双模式编辑
  - 新增截图插件配置文件系统
  - 在设置页面集成 JSON 编辑器
  - 支持可视化界面和 JSON 两种编辑方式
  - 完整的配置校验和错误提示

### 技术实现
- **新增文件**:
  - `.claude/rules/JSON_CONFIG_RULES.md` - JSON 配置管理规范
  - `lib/core/services/json_validator.dart` - JSON 校验服务
  - `lib/core/models/tag_model.dart` - 标签数据模型
  - `lib/core/services/tag_manager.dart` - 标签管理服务
  - `lib/ui/screens/tag_management_screen.dart` - 标签管理界面
  - `lib/ui/widgets/json_editor_screen.dart` - JSON 编辑器组件
  - `lib/ui/widgets/tag_filter_bar.dart` - 标签过滤栏
  - `lib/plugins/screenshot/config/screenshot_config_defaults.dart` - 截图配置默认值
  - 多个 plugin_descriptor.json 文件
- **修改文件**:
  - `lib/plugins/screenshot/widgets/settings_screen.dart` - 集成 JSON 编辑器
  - `lib/l10n/app_zh.arb` - 中文翻译新增 70+ 条
  - `lib/l10n/app_en.arb` - 英文翻译新增 70+ 条
  - 规则文档索引更新

### 改进和修复
- **界面优化**:
  - 优化截图设置页面布局和响应式设计
  - 改进小屏幕下的显示效果
  - 统一使用国际化文本
- **Bug 修复**:
  - 修复截图设置页面编译错误 (Widget.children 访问问题)
  - 修复布局适配问题
- **国际化完善**:
  - 新增配置管理相关翻译 50+ 条
  - 新增标签管理相关翻译 20+ 条
  - 完善截图插件设置翻译
  - 所有新功能完整支持中英文

### 对话记录
- **对话时间**: 2026-01-19
- **对话主题**: 实现配置管理系统和界面优化
- **操作内容**:
  - 创建 JSON 配置文件管理规范
  - 实现 JsonValidator 服务
  - 实现通用 JSON 编辑器界面
  - 实现标签管理系统
  - 完善截图插件配置
  - 创建插件描述符系统
  - 修复编译错误
  - 完善国际化

### Git 提交
```
36428f6 docs: 更新 CHANGELOG.md，记录 v0.4.0 版本变更
9d911fb feat: 实现配置管理系统和界面优化 (v0.4.0)
d39db5d 整体国际化 & fix bug
aae8de0 temp
f6a6553 docs: 更新版本控制历史，记录 v0.3.4 tag
a6ca5f9 docs: 更新 CHANGELOG.md，记录 v0.3.4 版本变更
```

### Tag 注释
```
Release v0.4.0

## ✨ 新增功能
### 配置管理系统
- 新增 JSON 配置文件管理规范 (JSON_CONFIG_RULES.md)
- 新增 JsonValidator 服务，提供 JSON 校验和 Schema 验证
- 新增通用 JSON 编辑器界面 (JsonEditorScreen)
  - 支持 JSON 语法校验
  - 支持 Schema 校验
  - 支持格式化和压缩
  - 支持重置到默认配置
  - 支持查看示例配置
  - 实时错误提示

### 标签管理系统
- 新增 TagModel 标签数据模型
- 新增 TagManager 标签管理服务
- 新增标签管理界面 (TagManagementScreen)
- 新增标签过滤栏组件 (TagFilterBar)
- 支持标签的创建、编辑、删除
- 支持按标签过滤插件

### 截图插件配置
- 新增截图插件配置文件系统
  - screenshot_config_defaults.dart - 默认配置和示例
  - screenshot_config_schema.dart - JSON Schema 定义
- 在设置页面集成 JSON 编辑器
- 支持可视化和 JSON 两种编辑方式

### 插件描述符
- 新增截图插件描述符 (plugin_descriptor.json)
- 新增计算器插件描述符 (plugin_descriptor.json)
- 新增世界时钟插件描述符 (plugin_descriptor.json)
- 统一插件元数据管理

## 🔧 改进
### 界面优化
- 优化截图设置页面布局和响应式设计
- 改进小屏幕下的显示效果
- 统一使用国际化文本

### 国际化完善
- 新增配置管理相关翻译 50+ 条
- 新增标签管理相关翻译 20+ 条
- 完善截图插件设置翻译
- 所有新功能完整支持中英文

## 🐛 Bug 修复
- 修复截图设置页面编译错误 (Widget.children 访问问题)
- 修复布局适配问题

## 📝 完整提交历史
- 36428f6 docs: 更新 CHANGELOG.md，记录 v0.4.0 版本变更
- 9d911fb feat: 实现配置管理系统和界面优化 (v0.4.0)
- d39db5d 整体国际化 & fix bug
- aae8de0 temp
- f6a6553 docs: 更新版本控制历史，记录 v0.3.4 tag
- a6ca5f9 docs: 更新 CHANGELOG.md，记录 v0.3.4 版本变更
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.4.0.md`（待创建）

---

## v0.3.4 (2026-01-16)

### Tag 信息
- **版本号**: v0.3.4
- **提交**: a6ca5f9
- **创建时间**: 2026-01-16
- **创建者**: cyamz
- **类型**: Minor 版本（新功能）

### 变更内容
- **桌面级区域截图功能** - 实现真正的桌面级区域选择
  - 原生 Windows 全屏选择窗口，可跨应用选择任何屏幕区域
  - 半透明黑色遮罩效果，清晰显示选中区域
  - 红色边框和控制点，拖动选择时实时显示尺寸
  - 双缓冲绘制技术，消除拖拽时的闪烁
  - 支持 ESC 键取消选择

### 技术实现
- **新增文件**:
  - `windows/runner/native_screenshot_window.h` - 原生窗口头文件
  - `windows/runner/native_screenshot_window.cpp` - 原生窗口实现（400+ 行）
  - `lib/plugins/screenshot/widgets/screenshot_window.dart` - 截图窗口组件
- **修改文件**:
  - `windows/runner/flutter_window.cpp` - 添加 MethodChannel 处理
  - `windows/runner/CMakeLists.txt` - 添加 msimg32.lib 依赖
  - `lib/plugins/screenshot/platform/screenshot_platform_interface.dart` - 改用轮询机制
  - `lib/plugins/screenshot/widgets/screenshot_main_widget.dart` - 添加轮询逻辑

### 核心技术
- **桌面背景捕获**: 使用 BitBlt 捕获整个屏幕
- **双缓冲绘制**: 在内存 DC 完成所有绘制，避免闪烁
- **分段遮罩算法**: 分别绘制上、下、左、右四个区域的半透明遮罩
- **AlphaBlend 半透明混合**: 实现 63% 不透明度的遮罩效果
- **Windows 消息循环**: 完整的消息处理和窗口管理

### 对话记录
- **对话时间**: 2026-01-16
- **对话主题**: 实现桌面级区域截图功能
- **操作内容**:
  - 移除 WS_EX_LAYERED 窗口样式，使用普通窗口
  - 实现桌面背景捕获和显示
  - 实现分段遮罩绘制算法
  - 使用双缓冲技术消除闪烁
  - 添加 MethodChannel 轮询机制
  - 完整的日志输出用于调试

### Git 提交
```
a6ca5f9 docs: 更新 CHANGELOG.md，记录 v0.3.4 版本变更
d35b1bb feat: 实现桌面级区域截图功能
cac2d3a temp
3de9f65 docs: 更新 v0.3.2 版本记录，补充完整功能说明
```

### Tag 注释
```
Release v0.3.4

## ✨ 新增功能
### 桌面级区域截图
- 实现真正的桌面级区域选择，可跨应用选择任何屏幕区域
- 原生 Windows 截图选择窗口，支持全屏操作
- 半透明黑色遮罩效果，清晰显示选中区域
- 红色边框和控制点，拖动选择时实时显示尺寸
- 双缓冲绘制技术，消除拖拽时的闪烁

### 技术改进
- 新增 native_screenshot_window.h/cpp 实现原生窗口
- 桌面背景捕获和显示
- 双缓冲绘制技术，消除闪烁
- 分段遮罩算法，精确绘制非选中区域
- MethodChannel 轮询机制替代 EventChannel

## 🔧 改进
- 完整的日志输出，便于调试
- 窗口置顶和焦点管理优化
- 支持 ESC 键取消选择

## 📝 完整提交历史
- a6ca5f9 docs: 更新 CHANGELOG.md，记录 v0.3.4 版本变更
- d35b1bb feat: 实现桌面级区域截图功能
- cac2d3a temp
- 3de9f65 docs: 更新 v0.3.2 版本记录，补充完整功能说明
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.4.md`（待创建）

---

## v0.3.2 (2026-01-15)

### Tag 信息
- **版本号**: v0.3.2
- **提交**: fbc2838
- **创建时间**: 2026-01-15
- **创建者**: cyamz
- **类型**: Minor 版本（新功能）

### 变更内容
- **新增配置页面** - 实现应用配置管理功能
  - 新增 SettingsScreen，提供统一的应用设置入口
  - 实现语言切换功能，支持中文/英文即时切换
  - 友好的语言选择界面，显示当前语言状态
- **国际化完善** - 测试和配置页面完整国际化
  - 测试页面所有文本支持中英文切换
  - 配置页面所有文本支持中英文切换
  - 新增国际化翻译条目 30+ 条
- **开发工具** - 新增国际化更新脚本
  - `scripts/update-i18n.bat` - 一键生成国际化文件
- **Bug 修复** - 修复语言切换后 SnackBar 无法关闭的问题

### 对话记录
- **对话时间**: 2026-01-15
- **对话主题 1**: Tag 管理 - 创建 v0.3.2 并删除 v0.3.3
- **对话主题 2**: 更新 v0.3.2 tag 注释，补充完整功能说明
- **操作内容**:
  - 删除错误的 v0.3.3 tag
  - 创建 v0.3.2 tag
  - 更新 tag 注释，包含完整的功能变更
  - 更新 CHANGELOG.md，准确反映版本内容

### Git 提交
```
fbc2838 fix: 修复语言切换后 SnackBar 无法关闭的问题
```

### 新增文件
- `lib/ui/screens/settings_screen.dart` - 配置页面（150+ 行）
- `scripts/update-i18n.bat` - 国际化更新脚本
- `docs/releases/RELEASE_NOTES_v0.3.1.md` - v0.3.1 发布说明

### 修改文件
- `lib/ui/screens/main_platform_screen.dart` - 添加配置页面入口
- `lib/ui/screens/service_test_screen.dart` - 测试页面国际化
- `lib/l10n/app_zh.arb` - 中文翻译新增 30+ 条
- `lib/l10n/app_en.arb` - 英文翻译新增 30+ 条
- `lib/l10n/generated/*` - 自动生成的国际化代码

### Tag 注释
```
Release v0.3.2

## ✨ 新增功能
### 配置页面
- 新增应用配置页面 (SettingsScreen)
- 支持语言切换功能
- 提供友好的语言选择界面
- 为未来的主题设置预留扩展空间

### 国际化完善
- 测试页面完整国际化
- 配置页面完整国际化
- 新增国际化相关翻译条目

## 🔧 改进
### 用户体验优化
- 语言切换后即时生效，无需重启应用
- 界面统一使用国际化文本
- 语言显示名称本地化

### 开发工具
- 新增国际化更新脚本 (update-i18n.bat)
- 简化国际化工作流程

## 🐛 Bug 修复
- 修复语言切换后 SnackBar 无法关闭的问题

## 📁 技术细节
### 新增文件
- lib/ui/screens/settings_screen.dart - 配置页面
- scripts/update-i18n.bat - 国际化更新脚本
- docs/releases/RELEASE_NOTES_v0.3.1.md - v0.3.1 发布说明

### 修改文件
- lib/ui/screens/main_platform_screen.dart - 添加配置页面入口
- lib/ui/screens/service_test_screen.dart - 测试页面国际化
- lib/l10n/app_zh.arb - 中文翻译更新
- lib/l10n/app_en.arb - 英文翻译更新
- lib/l10n/generated/* - 自动生成的国际化代码

## 📝 完整提交历史
- fbc2838 fix: 修复语言切换后 SnackBar 无法关闭的问题
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.2.md`（待创建）

### 关联文档
- [版本控制规则](.claude/rules/VERSION_CONTROL_RULES.md) - 创建于本次对话

---

## v0.3.1 (2025-01-14)

### Tag 信息
- **版本号**: v0.3.1
- **提交**: 2951c49
- **创建时间**: 2025-01-14
- **创建者**: cyamz
- **类型**: Patch 版本（Bug 修复）

### 变更内容
- Windows 平台服务兼容性修复

### Git 提交
```
2951c49 fix: Windows 平台服务兼容性修复 (v0.3.1)
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.1.md`（已存在）

---

## v0.3.0 (2025-01-14)

### Tag 信息
- **版本号**: v0.3.0
- **提交**: fc55179
- **创建时间**: 2025-01-14
- **创建者**: cyamz
- **类型**: Minor 版本（新功能）

### 变更内容
- 添加 Windows 平台通知测试功能
- 增强通知服务的跨平台支持

### Git 提交
```
fc55179 feat: add Windows platform notice in notification test tab
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.0.md`（已存在）

---

## 对话历史记录

### 2026-01-15 - 建立版本控制规则体系

#### 对话主题
建立版本控制规则体系，完善 tag 管理流程

#### 操作内容
1. **创建版本控制规则体系**:
   - 版本控制与 Tag 管理规范 (VERSION_CONTROL_RULES.md)
   - 版本控制历史记录 (VERSION_CONTROL_HISTORY.md)
   - 规则文档索引 (README.md)

2. **Tag 管理操作**:
   - 删除错误的 v0.3.3 tag
   - 创建正确的 v0.3.2 tag
   - 准备 tag 注释和版本说明

3. **文档完善**:
   - 更新主指导文档 (CLAUDE.md)
   - 创建规则索引 (README.md)
   - 更新 CHANGELOG.md

#### Git 提交
```
f9342ce docs: 建立版本控制规则体系，完善 tag 管理流程
e6df091 docs: 更新 CHANGELOG.md，记录 v0.3.2 版本变更
```

#### 创建的文件
- `.claude/rules/VERSION_CONTROL_RULES.md` - 版本控制与 Tag 管理规范
- `.claude/rules/VERSION_CONTROL_HISTORY.md` - 版本控制历史记录
- `.claude/rules/README.md` - 规则文档索引

#### 修改的文件
- `.claude/CLAUDE.md` - 添加版本控制规则说明
- `CHANGELOG.md` - 添加 v0.3.2 版本记录

#### Push 状态
- ✅ 已提交 2 个提交
- ⏳ 尚未 push 到远程

---

## 统计信息

### 版本发布频率
- v0.3.0 → v0.3.1: 1 天
- v0.3.1 → v0.3.2: 1 天

### 提交类型分布
- Bug 修复: 2 个 (v0.3.1, v0.3.2)
- 新功能: 1 个 (v0.3.0)
- 文档更新: 2 个 (f9342ce, e6df091)

### 对话记录
- 本次对话: 2026-01-15
- 主题: 建立版本控制规则体系
- 提交数: 2 个
- 文件创建: 3 个
- 文件修改: 2 个

---

**维护说明**: 每次 tag 创建或重要 push 操作后，都需要更新此文档。

**文档版本**: v1.1.0
**最后更新**: 2026-01-15

