# 版本控制历史

本文档记录所有 tag 创建、push 操作和重要对话的详细历史，用于追溯项目演进过程。

## 版本索引

- [v0.4.3](#v043-2026-01-21) - 2026-01-21
- [v0.4.2](#v042-2026-01-21) - 2026-01-21
- [v0.4.1](#v041-2026-01-20) - 2026-01-20
- [v0.4.0](#v040-2026-01-19) - 2026-01-19
- [v0.3.4](#v034-2026-01-16) - 2026-01-16
- [v0.3.2](#v032-2026-01-15) - 2026-01-15
- [v0.3.1](#v031-2025-01-14) - 2025-01-14
- [v0.3.0](#v030-2025-01-14) - 2025-01-14

---

## v0.4.3 (2026-01-21)

### Tag 信息
- **版本号**: v0.4.3
- **提交**: 095f2d8, aa2a757, 9a26bee
- **创建时间**: 2026-01-21
- **创建者**: Claude Code
- **类型**: Patch 版本（文档更新）

### Push 信息
- **推送时间**: 2026-01-21
- **推送者**: Claude Code
- **提交范围**: 212bfd7..095f2d8
- **Tag**: v0.4.3

### 变更内容
- **文档全面中文化和重组** - 完成 docs/ 核心目录的全面优化
  - **文档重组**: guides/ 目录按受众类型分类
    - 创建 developer/ 目录（7 个开发者指南）
    - 创建 technical/ 目录（技术文档）
    - 创建 user/ 目录（2 个用户指南）
    - 创建 guides/README.md 文档导航索引
    - 移动音频文档到 troubleshooting/ 目录
  - **文档中文化**: 8 个英文文档转换为中文（约 2,192 行）
    - migration/platform-environment-migration.md（431 行）
    - reference/platform-fallback-values.md（476 行）
    - web-platform-compatibility.md（312 行）
    - examples/*.md（3 个文件，355 行）
    - releases/RELEASE_NOTES_v0.2.1.md 标题修正
  - **README 优化**: 根目录 README.md 完全重写
    - 添加项目徽章（Flutter 3.0+, Dart 3.0+, Apache 2.0）
    - 新增内置插件表格（5 个插件及其状态）
    - 新增版本信息和最新更新亮点
    - 更新文档导航（按新结构组织）
    - 更新项目结构（反映实际目录）
    - 新增开发规范章节（链接到 11 个规范文档）
    - 优化贡献指南和获取帮助部分
  - **新增文档和脚本**: 11 个新文档和脚本
    - DOCUMENTATION_CHANGE_MANAGEMENT.md
    - 7 个实施报告（DESKTOP_PET_DOCUMENTATION_ANALYSIS.md 等）
    - 6 个文档检查脚本（check-doc-coverage 等）
    - PULL_REQUEST_TEMPLATE.md

### 文档统计
- **转换文档数**: 8 个
- **新增文档数**: 11 个
- **移动文档数**: 7 个
- **删除文档数**: 5 个
- **代码变更**: 45 个文件，+7,671 行，-1,641 行
- **中文化比例**: docs/ 核心目录 100%

### 对话记录
- **对话时间**: 2026-01-21
- **对话主题**:
  1. Desktop Pet 文档价值评估和准确性验证
  2. guides/ 目录文档重组（developer/technical/user/）
  3. 英文文档转中文（guides/ → 100% 中文）
  4. 扩展中文化到整个 docs/ 目录（所有英文文档）
  5. 根目录 README.md 更新

- **操作内容**:
  - 分析 4 个 Desktop Pet 文档，确认全部准确且有价值
  - 创建 DESKTOP_PET_DOCUMENTATION_ANALYSIS.md
  - 重组 guides/ 目录，创建 3 个子目录和索引
  - 创建 GUIDES_REORGANIZATION.md
  - 转换 8 个英文文档为中文
  - 更新 ENGLISH_TO_CHINESE_CONVERSION.md
  - 完全重写根目录 README.md
  - 创建 v0.4.3 tag 和发布说明

### Git 提交
```
095f2d8 docs: 添加 v0.4.3 发布说明
9a26bee docs: 更新 CHANGELOG.md，记录 v0.4.3 版本变更
aa2a757 docs: 文档全面中文化、重组和优化（v0.4.3）
212bfd7 docs: 更新 CHANGELOG.md，记录编码规范修复
856947a fix: 修复所有静态分析错误，代码完全符合编码规则
```

### Tag 注释
```
Release v0.4.3

## 📚 文档全面中文化、重组和优化

### 主要更新

#### 文档重组
- 将 guides/ 目录按受众类型分为 developer/、technical/、user/
- 创建 guides/README.md 作为文档导航索引
- 新增 7 个开发者指南到 developer/ 目录
- 新增 1 个技术文档到 technical/ 目录
- 新增 2 个用户指南到 user/ 目录
- 移动音频文档到 troubleshooting/ 目录

#### 文档中文化（8 个文档，约 2,192 行）
- migration/platform-environment-migration.md（431 行）
- reference/platform-fallback-values.md（476 行）
- web-platform-compatibility.md（312 行）
- examples/*.md（3 个文件，355 行）
- releases/RELEASE_NOTES_v0.2.1.md 标题修正

#### README 优化
- 添加项目徽章（Flutter 3.0+, Dart 3.0+, Apache 2.0）
- 新增内置插件表格（5 个插件）
- 新增版本信息（v0.4.3）和最新更新亮点
- 更新文档导航（按新结构组织）
- 更新项目结构（反映实际目录）
- 新增开发规范章节（11 个规范文档）
- 优化贡献指南和获取帮助部分

#### 新增文档和脚本（11 个）
- DOCUMENTATION_CHANGE_MANAGEMENT.md
- DESKTOP_PET_DOCUMENTATION_ANALYSIS.md
- DOCUMENTATION_AUDIT_2026-01-21.md
- DOCUMENTATION_CLEANUP_SUMMARY.md
- DOCUMENTATION_IMPROVEMENTS_IMPLEMENTATION.md
- ENGLISH_TO_CHINESE_CONVERSION.md
- GUIDES_REORGANIZATION.md
- AUDIO_IMPLEMENTATION_STATUS.md
- check-doc-coverage.ps1/sh
- check-doc-links.ps1/sh
- check-docs.ps1/sh
- PULL_REQUEST_TEMPLATE.md

### 文档统计
- **转换文档数**: 8 个
- **新增文档数**: 11 个
- **移动文档数**: 7 个
- **代码变更**: 45 个文件，+7,671 行，-1,641 行
- **文档语言**: docs/ 核心目录 100% 中文化

### 版本信息
- **类型**: 文档版本（Patch 更新）
- **向后兼容**: 完全兼容，无破坏性变更
- **推荐升级**: 所有用户和开发者
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.4.3.md` - 完整的发布说明

---

## v0.4.2 (2026-01-21)

---

## v0.4.1 (2026-01-20)

### Push 信息
- **提交**: a1869ef, e34e5d1
- **推送时间**: 2026-01-20
- **推送者**: Claude Code
- **类型**: Patch 版本（文档和规范更新）

### 变更内容
- **开发规范体系完善** - 建立完整的编码规范体系
  - 新增 CODE_STYLE_RULES.md（代码风格规范）
    * 基于 Effective Dart 官方指南
    * 命名、格式化、注释、代码组织规范
    * UI 代码规范和最佳实践
  - 新增 TESTING_RULES.md（测试规范）
    * 测试文件组织和命名规范
    * AAA 测试模式（Arrange-Act-Assert）
    * Widget 测试和 Mock 使用规范
    * 测试覆盖率 ≥80% 要求
  - 新增 GIT_COMMIT_RULES.md（Git 提交规范）
    * 约定式提交格式
    * 10 种提交类型和范围定义
    * 分支策略和 PR 规范
  - 新增 ERROR_HANDLING_RULES.md（错误处理规范）
    * 异常类型使用和自定义异常
    * 输入验证和异步错误处理
    * 用户错误提示和日志规范
  - 新增 DOCUMENTATION_NAMING_RULES.md（文档命名规范）
    * 定义三级命名标准（kebab-case、UPPERCASE_CASE、snake_case）
  - 新增 PLUGIN_CONFIG_SPEC.md（插件配置规范）
    * 强制的配置文件结构
    * 配置功能检查清单
  - 新增 PLUGIN_SETTINGS_SCREEN_RULES.md（插件配置页面开发规范）
    * 统一的架构模式
    * 实时保存原则和 UI 组件规范

- **文档整理优化**
  - 删除 5 个过时文档
  - 归档 9 个历史文档到 docs/archive/
  - 重命名 9 个文档遵循 kebab-case 规范
  - 创建文档审计报告
  - 更新 MASTER_INDEX.md 索引

- **配置功能增强**
  - 添加插件配置基类 BasePluginSettings
  - 实现计算器插件配置系统
  - 实现世界时钟插件配置系统
  - 完善截图插件配置文档
  - 优化插件管理器，支持配置持久化
  - 新增配置功能审计报告

- **国际化完善**
  - 新增配置相关翻译 100+ 条
  - 完善配置界面翻译

### 技术实现
- **新增文件**:
  - `.claude/rules/CODE_STYLE_RULES.md` - 代码风格规范
  - `.claude/rules/TESTING_RULES.md` - 测试规范
  - `.claude/rules/GIT_COMMIT_RULES.md` - Git 提交规范
  - `.claude/rules/ERROR_HANDLING_RULES.md` - 错误处理规范
  - `.claude/rules/DOCUMENTATION_NAMING_RULES.md` - 文档命名规范
  - `.claude/rules/PLUGIN_CONFIG_SPEC.md` - 插件配置规范
  - `.claude/rules/PLUGIN_SETTINGS_SCREEN_RULES.md` - 插件配置页面开发规范
  - `.claude/rules/RULES_AUDIT_REPORT.md` - 规范审计报告
  - `lib/core/models/base_plugin_settings.dart` - 配置基类
  - `lib/plugins/calculator/config/` - 计算器配置文件
  - `lib/plugins/world_clock/config/` - 世界时钟配置文件
  - `docs/reports/CONFIG_FEATURE_AUDIT.md` - 配置功能审计
  - `docs/reports/CONFIG_IMPLEMENTATION_PROGRESS.md` - 配置实施进度
  - `docs/archive/` - 归档文档目录

- **修改文件**:
  - `.claude/rules/README.md` - 规范索引更新（修复格式错误）
  - `lib/core/interfaces/i_plugin_manager.dart` - 支持配置持久化
  - `lib/core/services/plugin_manager.dart` - 配置管理优化
  - 各插件配置系统实现
  - 国际化文件更新

- **删除文件**:
  - `CHANGELOG_NOTIFICATION_FIX.md`
  - `ICON_UPDATE_GUIDE.md`
  - `NOTIFICATION_FIX_SUMMARY.md`
  - `WINDOWS_PLATFORM_FIXES_REPORT.md`
  - `docs/index.md`
  - `scripts/verify-audio-fix.md`
  - `scripts/verify-notification-fix.md`

### 对话记录
- **对话时间**: 2026-01-20
- **对话主题**: 审计和清理开发规范，完善配置功能
- **操作内容**:
  - 外部插件文档评价分析（70% 准确）
  - 全面文档审计（110+ 文档）
  - 删除 5 个过时文档，归档 9 个历史文档
  - 重命名 9 个文档遵循统一命名规范
  - 创建 DOCUMENTATION_NAMING_RULES.md
  - 开发规范系统审计（8 个文档，3,632 行）
  - 创建 4 个缺失的关键规范文档
  - 更新规范索引，修复格式错误
  - 推送代码到远程仓库

### Git 提交
```
a1869ef docs: 调整配置相关代码，初步梳理开发规范和文档
e34e5d1 docs: 更新 CHANGELOG.md，记录 v0.4.1 版本变更
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.4.1.md`（待创建）

### 统计信息
- **规范文档**: 从 8 个扩展到 11 个（+3 个关键规范）
- **规范总行数**: 约 5,500+ 行
- **文档数量**: 从 110+ 优化到 95+
- **文件变更**: 76 个文件（新增、修改、删除、重命名）
- **代码行数**: +11,843 / -3,574

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

