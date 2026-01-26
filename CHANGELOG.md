# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - 剪贴板服务完整实现
- 📋 **Windows C++ 层实现** - 完成剪贴板服务的原生实现
  * 注册 MethodChannel: `com.example.screenshot/clipboard`
  * `getImageFromClipboard`: 从剪贴板获取 CF_DIB 格式图片
    - 使用 Windows Clipboard API (OpenClipboard, GetClipboardData)
    - 处理 BITMAPINFOHEADER 和像素数据
    - 支持自上而下和自下而上两种 DIB 方向
    - 计算行对齐（4字节边界）
  * `hasImage`: 使用 IsClipboardFormatAvailable(CF_DIB) 检查剪贴板是否有图片
  * `clearClipboard`: 使用 EmptyClipboard() 清空剪贴板
  * 添加完整的错误处理和日志输出

### Added - 系统级配置文件
- ⚙️ **GlobalConfig Schema** - 创建完整的 JSON Schema 定义
  * `global_config_schema.dart` (196 行)
  * 定义所有配置项的验证规则（类型、枚举、模式、范围）
  * 包含 $schema 声明（draft-07）
  * 提供 Schema 版本和创建日期元数据
- 📝 **GlobalConfig Defaults** - 创建默认配置和示例
  * `global_config_defaults.dart` (318 行)
  * `defaultConfig`: 干净的默认 JSON
  * `exampleConfig`: 带详细注释的示例（_help, _options 字段）
  * `cleanExample`: 自动清理注释后的示例
  * `schemaJson`: 内嵌的 JSON Schema
  * `_removeHelpFields()`: 递归清理帮助字段的工具方法

### Changed - 配置实施进度更新
- 📊 **更新进度文档** - 标记系统级配置为已完成
  * CONFIG_IMPLEMENTATION_PROGRESS.md
  * 系统级配置完成度：40% → 100%
  * 添加 global_config_schema.dart 和 global_config_defaults.dart 完成标记

### Technical Details
- **新增文件**:
  - lib/core/config/global_config_schema.dart (196 行)
  - lib/core/config/global_config_defaults.dart (318 行)
- **修改文件**:
  - windows/runner/flutter_window.h (+4 行)
  - windows/runner/flutter_window.cpp (+107 行)
  - docs/reports/CONFIG_IMPLEMENTATION_PROGRESS.md (进度更新)
- **总代码变更**: 5 个文件，+720 行，-49 行

## [0.4.4] - 2026-01-25

### Added - 外部插件国际化支持
- 🌍 **IPluginI18n 接口** - 为外部插件提供完整的国际化支持
  - 定义 IPluginI18n 接口，提供翻译、占位符替换、语言回退等功能
  - 实现 PluginI18nHelper 类，支持翻译注册和管理
  - 支持自动语言回退机制（zh_CN → zh）
  - 集成到 PluginContext，插件可通过 context.i18n 访问
- 📝 **文档更新** - 完善插件国际化文档
  - 更新 .claude/CLAUDE.md，添加外部插件国际化支持章节
  - 更新 external-plugin-development.md，添加完整国际化实现指南
  - 包含翻译文件组织、占位符使用、最佳实践等内容

### Added - 配置管理系统
- 📋 **配置管理文档** - 新增 CONFIG_MANAGEMENT.md 指南
  - 配置文件格式和结构说明
  - 全局配置和插件配置管理
  - 配置验证和错误处理
- 📄 **配置示例** - 新增 global_config.example.json 示例文件
  - 完整的配置结构示例
  - 包含桌面宠物、插件配置等示例
  - 提供配置验证规则

### Changed - 桌面宠物优化
- 🐾 **设置界面改进**
  - 优化宠物设置界面布局
  - 改进配置管理的实时保存机制
  - 增强用户体验和响应性
- ⚙️ **配置管理优化**
  - 改进配置的加载和保存流程
  - 优化配置验证逻辑

### Changed - 插件配置优化
- 🔧 **计算器插件** - 优化配置界面布局
- 🕐 **世界时钟插件** - 改进配置界面
- 📸 **截图插件** - 修复配置相关问题

### Fixed - 国际化问题
- 🐛 **修复编译错误** - 修复 7 个国际化相关编译错误
  - 修复 screenshot_main_widget.dart 中的 replaceAll 错误
  - 修复 _ScreenshotListItem context 访问问题
  - 修复函数调用占位符错误
- 📝 **补充翻译键** - 添加缺失的 common_add 翻译键
  - 添加到 app_zh.arb: "添加"
  - 添加到 app_en.arb: "Add"

### Technical Details
- **新增文件**:
  - lib/core/interfaces/i_plugin_i18n.dart (76 行)
  - lib/core/services/plugin_i18n_helper.dart (129 行)
  - assets/config/global_config.example.json
  - docs/guides/CONFIG_MANAGEMENT.md
- **修改文件**: 27 个文件，+2781/-469 行

### Known Issues
- 🐾 **宠物窗口缩小时有背景闪烁** - 预留问题，下版本修复

### Next Version Plans
- 验证和修复各插件的配置功能
- 优化部分插件功能
- 修复宠物窗口缩小时的背景闪烁问题

## [0.4.3] - 2026-01-21

### Added - 文档全面中文化和重组
- 📚 **文档重组** - guides/ 目录按受众类型分类
  - 创建 developer/ 目录（7 个开发者指南）
  - 创建 technical/ 目录（技术文档）
  - 创建 user/ 目录（2 个用户指南）
  - 新增 guides/README.md 作为文档导航索引
- 🌏 **文档中文化** - 8 个英文文档转换为中文（约 2,192 行）
  - migration/platform-environment-migration.md（431 行）
  - reference/platform-fallback-values.md（476 行）
  - web-platform-compatibility.md（312 行）
  - examples/*.md（3 个文件，355 行）
  - releases/RELEASE_NOTES_v0.2.1.md 标题修正
- 📝 **README 优化** - 根目录 README 完全重写
  - 添加项目徽章（Flutter, Dart, License）
  - 新增内置插件表格
  - 新增版本信息和最新更新
  - 更新文档导航（按新结构组织）
  - 更新项目结构（反映实际目录）
  - 新增开发规范章节
  - 优化贡献指南和获取帮助部分

### Added - 新增文档和脚本
- 📋 **新增规范文档**
  - DOCUMENTATION_CHANGE_MANAGEMENT.md（文档变更管理）
- 📊 **新增实施报告**
  - DESKTOP_PET_DOCUMENTATION_ANALYSIS.md（Desktop Pet 文档分析）
  - DOCUMENTATION_AUDIT_2026-01-21.md（文档审计报告）
  - DOCUMENTATION_CLEANUP_SUMMARY.md（文档清理总结）
  - DOCUMENTATION_IMPROVEMENTS_IMPLEMENTATION.md（文档改进实施）
  - ENGLISH_TO_CHINESE_CONVERSION.md（英文转中文记录）
  - GUIDES_REORGANIZATION.md（文档重组记录）
  - AUDIO_IMPLEMENTATION_STATUS.md（音频实施状态）
- 🔧 **新增检查脚本**
  - check-doc-coverage.ps1/sh（文档覆盖率检查）
  - check-doc-links.ps1/sh（文档链接检查）
  - check-docs.ps1/sh（文档综合检查）
- 📋 **新增 GitHub 资源**
  - PULL_REQUEST_TEMPLATE.md（PR 模板）

### Changed - 文档移动和整理
- 📂 **文档移动**
  - 音频文档移动到 troubleshooting/ 目录
  - guides/ 文档按类型重新组织到 developer/、technical/、user/
- 🗑️ **删除过时文档**
  - 删除 assets/audio/README.md
  - 删除 ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md
  - 删除过时的音频快速参考文档

### 文档统计
- **转换文档数**: 8 个
- **新增文档数**: 11 个
- **移动文档数**: 7 个
- **代码变更**: 44 个文件，+7,609 行，-1,641 行
- **文档语言**: docs/ 核心目录 100% 中文化

### 版本信息
- **类型**: 文档版本（Patch 更新）
- **向后兼容**: 完全兼容，无破坏性变更
- **推荐升级**: 所有用户和开发者

## [0.4.2] - 2026-01-21

### Fixed - Windows 编译问题
- 🔧 **GDI+ 编译错误修复** - 解决 Windows 平台 GDI+ min/max 宏冲突问题
  * 在 `screenshot_plugin.h` 中正确包含 `<algorithm>` 头文件
  * 在包含 `gdiplus.h` 之前使用 `using std::min/max` 声明
  * 在 `CMakeLists.txt` 中禁用 C4458 警告（GDI+ 头文件遮蔽成员变量）
  * Release 和 Debug 模式均可成功编译
  * 修复了从 v0.3.4 开始就存在的长期编译问题

### Fixed - 编码规范完全符合
- ✅ **静态分析错误全部修复** - 0 errors, 0 warnings
  * 添加 8 个缺失的国际化翻译键
  * 修复 `plugin_settings_screen_base.dart` 基类设计问题
  * 修复 `external_plugin_management_screen.dart` 参数传递问题
  * 添加 dart:convert import 支持 JSON 编解码
- ✅ **代码质量**: 232 个 info 级别提示（仅代码风格建议，不影响功能）
- ✅ **编译验证**: Windows Release 模式编译成功

### Technical Details
- **根本原因**: Windows SDK 的 `<windows.h>` 定义了 min/max 宏，而 GDI+ 头文件内部使用 min/max 时期望 std::min/std::max
- **解决方案**: 定义 NOMINMAX 禁用 Windows 宏，同时在包含 GDI+ 前提供 std::min/max
- **验证**: Release (189KB) 和 Debug 模式均编译通过
- **代码规范**: 完全符合项目编码规则要求

## [0.4.1] - 2026-01-20

### Added - 开发规范体系完善
- 📋 **开发规范系统** - 建立完整的编码规范体系
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

### Added - 文档整理优化
- 📚 **文档审计和清理**
  - 删除 5 个过时文档（CHANGELOG_NOTIFICATION_FIX.md、NOTIFICATION_FIX_SUMMARY.md 等）
  - 归档 9 个历史文档到 docs/archive/
  - 创建文档审计报告
- 📝 **文档命名标准化**
  - 重命名 9 个文档遵循 kebab-case 规范
  - 统一文档命名风格
  - 更新所有交叉引用
- 📖 **文档索引更新**
  - 更新 MASTER_INDEX.md
  - 添加 archive 部分
  - 更新文档统计

### Added - 配置功能增强
- 🔧 **插件配置系统**
  - 添加插件配置基类 BasePluginSettings
  - 实现计算器插件配置系统
  - 实现世界时钟插件配置系统
  - 完善截图插件配置文档
  - 新增配置功能审计报告
- 💾 **配置持久化**
  - 优化插件管理器，支持配置持久化
  - 更新各插件支持配置功能
  - 配置自动保存和加载

### Changed
- 🌍 **国际化完善**
  - 新增配置相关翻译 100+ 条
  - 完善配置界面翻译
  - 统一使用国际化文本

### Technical Details
- 📁 新增文件：
  - `.claude/rules/CODE_STYLE_RULES.md` - 代码风格规范
  - `.claude/rules/TESTING_RULES.md` - 测试规范
  - `.claude/rules/GIT_COMMIT_RULES.md` - Git 提交规范
  - `.claude/rules/ERROR_HANDLING_RULES.md` - 错误处理规范
  - `.claude/rules/DOCUMENTATION_NAMING_RULES.md` - 文档命名规范
  - `.claude/rules/PLUGIN_CONFIG_SPEC.md` - 插件配置规范
  - `.claude/rules/PLUGIN_SETTINGS_SCREEN_RULES.md` - 插件配置页面开发规范
  - `lib/core/models/base_plugin_settings.dart` - 配置基类
  - `lib/plugins/calculator/config/` - 计算器配置文件
  - `lib/plugins/world_clock/config/` - 世界时钟配置文件
  - `docs/reports/CONFIG_FEATURE_AUDIT.md` - 配置功能审计
  - `docs/reports/CONFIG_IMPLEMENTATION_PROGRESS.md` - 配置实施进度
- 📝 修改文件：
  - `.claude/rules/README.md` - 规范索引更新
  - `lib/core/interfaces/i_plugin_manager.dart` - 支持配置持久化
  - `lib/core/services/plugin_manager.dart` - 配置管理优化
  - 各插件配置系统实现
  - 国际化文件更新

### Developer Experience
- ✨ **规范体系完整**
  - 从 8 个规范文档扩展到 11 个
  - 覆盖开发全流程：代码、测试、提交、错误处理
  - 总计约 5,500+ 行规范文档
- 📖 **文档优化**
  - 文档数量从 110+ 优化到 95+
  - 统一命名标准
  - 清晰的归档体系

---

## [0.4.0] - 2026-01-19

### Added - 配置管理系统与界面优化
- 🔧 **JSON 配置管理系统** - 完整的配置文件管理解决方案
  - 新增 JSON 配置文件管理规范 (JSON_CONFIG_RULES.md)
  - 新增 JsonValidator 服务，提供 JSON 语法校验和 Schema 验证
  - 新增通用 JSON 编辑器界面 (JsonEditorScreen)
  - 支持格式化、压缩、重置、查看示例
  - 实时错误提示和行号定位
- 🏷️ **标签管理系统** - 插件分类和组织功能
  - 新增 TagModel 标签数据模型
  - 新增 TagManager 标签管理服务
  - 新增标签管理界面 (TagManagementScreen)
  - 新增标签过滤栏组件 (TagFilterBar)
  - 支持标签的创建、编辑、删除
  - 支持按标签过滤插件
- 📋 **插件描述符系统** - 统一的插件元数据管理
  - 新增截图插件描述符 (plugin_descriptor.json)
  - 新增计算器插件描述符 (plugin_descriptor.json)
  - 新增世界时钟插件描述符 (plugin_descriptor.json)
  - 规范插件 ID、版本、作者等信息
- 🎨 **截图插件配置完善** - 可视化 + JSON 双模式编辑
  - 新增截图插件配置文件系统
    - screenshot_config_defaults.dart - 默认配置和示例
    - screenshot_config_schema.dart - JSON Schema 定义
  - 在设置页面集成 JSON 编辑器
  - 支持可视化界面和 JSON 两种编辑方式
  - 完整的配置校验和错误提示

### Changed
- 🎨 **界面优化**
  - 优化截图设置页面布局和响应式设计
  - 改进小屏幕下的显示效果
  - 统一使用国际化文本
- 🌍 **国际化完善**
  - 新增配置管理相关翻译 50+ 条
  - 新增标签管理相关翻译 20+ 条
  - 完善截图插件设置翻译
  - 所有新功能完整支持中英文

### Fixed
- 🐛 **编译错误修复**
  - 修复截图设置页面编译错误 (Widget.children 访问问题)
  - 修复布局适配问题

### Technical Details
- 📁 新增文件：
  - `.claude/rules/JSON_CONFIG_RULES.md` - JSON 配置管理规范
  - `lib/core/services/json_validator.dart` - JSON 校验服务
  - `lib/core/models/tag_model.dart` - 标签数据模型
  - `lib/core/services/tag_manager.dart` - 标签管理服务
  - `lib/ui/screens/tag_management_screen.dart` - 标签管理界面
  - `lib/ui/widgets/json_editor_screen.dart` - JSON 编辑器组件
  - `lib/ui/widgets/tag_filter_bar.dart` - 标签过滤栏
  - `lib/plugins/screenshot/config/screenshot_config_defaults.dart` - 截图配置默认值
  - 多个 plugin_descriptor.json 文件
- 📝 修改文件：
  - `lib/plugins/screenshot/widgets/settings_screen.dart` - 集成 JSON 编辑器
  - `lib/l10n/app_zh.arb` - 中文翻译新增 70+ 条
  - `lib/l10n/app_en.arb` - 英文翻译新增 70+ 条
  - 规则文档索引更新

### Developer Experience
- ✨ **配置管理规范**
  - 建立 JSON 配置文件管理标准
  - 提供配置校验和 Schema 定义
  - 支持默认值、示例、说明文档
  - 强制保存前校验，防止配置错误
- 📖 **文档完善**
  - 新增图标生成指南
  - 更新规则文档索引
  - 更新版本控制历史

---

## [0.3.4] - 2026-01-16

### Added - 桌面级区域截图
- 🖼️ **真正的桌面级区域选择** - 可跨应用选择任何屏幕区域
  - 实现原生 Windows 全屏选择窗口
  - 支持在整个桌面范围内拖拽选择区域
  - 不受 Flutter 应用窗口限制
- 🎨 **专业的视觉效果**
  - 半透明黑色遮罩（63% 不透明度）突出显示选中区域
  - 明显的红色边框（4px）和控制点（8px）
  - 实时显示选区尺寸信息
  - 双缓冲绘制技术，消除拖拽时的闪烁
- ⌨️ **交互优化**
  - 支持 ESC 键取消选择
  - 完整的 Windows 消息循环处理
  - 窗口置顶和焦点管理优化

### Technical Details
- 📁 新增文件：
  - `windows/runner/native_screenshot_window.h` - 原生窗口头文件
  - `windows/runner/native_screenshot_window.cpp` - 原生窗口实现（400+ 行）
  - `lib/plugins/screenshot/widgets/screenshot_window.dart` - 截图窗口组件
- 📝 修改文件：
  - `windows/runner/flutter_window.cpp` - 添加 MethodChannel 处理
  - `windows/runner/CMakeLists.txt` - 添加 msimg32.lib 依赖
  - `lib/plugins/screenshot/platform/screenshot_platform_interface.dart` - 改用轮询机制
- 🔧 核心技术：
  - 桌面背景捕获（BitBlt）
  - 双缓冲绘制（CreateCompatibleDC）
  - 分段遮罩算法（上、下、左、右独立绘制）
  - AlphaBlend 半透明混合

## [0.3.2] - 2026-01-15

### Added - 配置页面与国际化
- ⚙️ **新增配置页面** - 实现应用配置管理功能
  - 新增 SettingsScreen，提供统一的应用设置入口
  - 实现语言切换功能，支持中文/英文即时切换
  - 友好的语言选择界面，显示当前语言状态
  - 为未来的主题、通知等设置预留扩展空间
- 🌍 **国际化完善** - 测试和配置页面完整国际化
  - 测试页面所有文本支持中英文切换
  - 配置页面所有文本支持中英文切换
  - 新增国际化翻译条目 30+ 条
  - 语言显示名称本地化（如"简体中文"、"English"）
- 🛠️ **开发工具** - 新增国际化更新脚本
  - `scripts/update-i18n.bat` - 一键生成国际化文件
  - 简化国际化工作流程，提高开发效率

### Changed
- 🎨 **用户体验优化**
  - 语言切换后即时生效，无需重启应用
  - 界面统一使用国际化文本，消除硬编码
  - 主平台屏幕添加配置页面入口

### Fixed
- 🐛 **语言切换修复** - 修复语言切换后 SnackBar 无法关闭的问题
  - 解决了 widget 重建导致的 context 失效问题
  - 提前捕获 ScaffoldMessenger 引用
  - 确保语言切换后通知提示框可以正常关闭

### Technical Details
- 📁 新增文件：
  - `lib/ui/screens/settings_screen.dart` - 配置页面（150+ 行）
  - `scripts/update-i18n.bat` - 国际化更新脚本
  - `docs/releases/RELEASE_NOTES_v0.3.1.md` - v0.3.1 发布说明
- 📝 修改文件：
  - `lib/ui/screens/main_platform_screen.dart` - 添加配置页面入口
  - `lib/ui/screens/service_test_screen.dart` - 测试页面国际化
  - `lib/l10n/app_zh.arb` - 中文翻译新增 30+ 条
  - `lib/l10n/app_en.arb` - 英文翻译新增 30+ 条
  - `lib/l10n/generated/*` - 自动生成的国际化代码

### Developer Experience
- ✨ **国际化工作流改进**
  - 新增自动化脚本，简化国际化文件生成
  - 统一的翻译管理，易于维护
  - 清晰的文件组织，便于添加新语言

---

## [0.3.1] - 2026-01-15

### Fixed - Windows Platform Services Compatibility
- 🔔 **通知服务修复** - 修复 Windows 平台通知服务崩溃问题
  - 解决 `flutter_local_notifications` 在 Windows 上的 `LateInitializationError`
  - 实现 SnackBar 作为 Windows 平台的通知替代方案
  - 事件驱动架构，保持 API 兼容性
- 🎵 **音频服务修复** - 修复 Windows 平台音频服务不支持问题
  - 解决 `just_audio` 在 Windows 上的 `MissingPluginException`
  - 使用 SystemSound 作为 Windows 平台的音频替代方案
  - 实现音效序列模式，让不同音效类型更容易区分
- ✨ **改进音效体验** - 为每种音效类型创建独特的音效模式
  - Notification: alert + click (两声)
  - Click: click + alert (两声)
  - Alarm: alert + alert + click (三声)
  - Success: click + alert (两声)
  - Error: alert + alert + click (三声)
  - Warning: alert + click + alert (三声)

### Technical Details
- 📁 修改文件：
  - `lib/core/services/notification/notification_service.dart` - Windows 平台特殊处理
  - `lib/ui/screens/service_test_screen.dart` - SnackBar 显示逻辑
  - `lib/core/services/audio/audio_service.dart` - SystemSound 集成和音效序列
- 🏗️ 架构改进：
  - 事件驱动架构，服务层与 UI 层解耦
  - 命名空间导入解决类型冲突
  - 平台检测模式，自动降级到备用方案
- 📚 新增文档：
  - `WINDOWS_PLATFORM_FIXES_REPORT.md` - 完整修复报告
  - `NOTIFICATION_FIX_SUMMARY.md` - 通知服务快速参考
  - `CHANGELOG_NOTIFICATION_FIX.md` - 通知服务变更日志
  - `scripts/verify-notification-fix.md` - 通知测试指南
  - `scripts/verify-audio-fix.md` - 音频测试指南
  - `docs/platform-services/notification-windows-fix.md` - 架构文档

### Platform Compatibility
- ✅ Windows: 通知和音频服务正常工作
- ✅ Android/iOS/Linux/macOS/Web: 保持原有功能

### Testing
- 🔍 通知服务：3/3 测试通过
- 🔍 音频服务：7/7 测试通过
- 🔍 总体通过率：100%

---

## [0.3.0] - 2026-01-15

### Added - Documentation & Build System Improvements
- 📚 **完整的文档体系** - 重组和整理所有项目文档
- 🤖 **AI 编码规则** - 建立 Claude Code 和 AI 助手的编码规范
- 📁 **文件组织规范** - 明确的文件分类和组织规则
- 🔧 **Windows 构建修复** - 解决 Windows 平台构建问题
- 📋 **文档主索引** - 创建完整的文档导航中心

### Documentation
- [文档主索引](docs/MASTER_INDEX.md) - 50+ 个文档的导航中心
- [文档重组记录](docs/DOCS_REORGANIZATION.md) - 文档组织说明
- [AI 编码规则](.claude/rules.md) - Claude Code 编码规范主入口
- [项目概览](.claude/PROJECT_OVERVIEW.md) - AI 助手项目理解指南
- [文件组织规范](.claude/rules/FILE_ORGANIZATION_RULES.md) - 详细的文件组织规则
- [Windows 分发指南](docs/WINDOWS_DISTRIBUTION_GUIDE.md) - Windows 平台产品化指南
- [Windows 构建修复](docs/troubleshooting/WINDOWS_BUILD_FIX.md) - Windows 构建问题解决方案

### Changes
- 📂 移动所有根目录临时文档到合理的子目录
  - 插件文档 → `docs/plugins/{plugin-name}/`
  - 发布文档 → `docs/releases/`
  - 实施报告 → `docs/reports/`
  - 脚本文件 → `scripts/`
  - 故障排除 → `docs/troubleshooting/`
- 🔗 建立 `.claude/` 和 `.kiro/` 的关联
- ✅ 根目录保持简洁，只保留核心文件

### Build System
- ✅ 修复 Windows 构建依赖问题
- ✅ 创建 NuGet 包修复脚本
- ✅ 临时禁用有问题的依赖（audioplayers, permission_handler）
- ✅ 应用成功在 Windows 上运行

### Developer Experience
- 📖 更新 CHANGELOG.md，添加完整版本历史
- 🤖 建立 AI 编码助手工作流程
- 📋 创建文件组织决策树
- ✨ 改进文档导航和交叉引用

## [1.0.0] - 2026-01-15

### Added - Platform Services Complete
- 🔧 **平台通用服务系统** - 完整的跨平台服务架构
- ✅ **通知服务** - 即时通知、定时通知、权限管理
- 🔊 **音频服务** - 系统音效、背景音乐、音量控制
- ⏰ **任务调度服务** - 倒计时、周期性任务、任务持久化
- 📍 **服务定位器模式** - 统一的服务注册和管理
- 🧪 **服务测试界面** - 内置的测试和验证界面

### Features
- 服务接口定义（INotificationService, IAudioService, ITaskSchedulerService）
- 跨平台支持（Windows, macOS, Linux, Android, iOS）
- 事件驱动架构（使用 Dart Streams）
- 资源生命周期管理
- 完整的单元测试（28个测试用例全部通过）

### Documentation
- [平台服务架构设计](.kiro/specs/platform-services/design.md)
- [平台服务实施计划](.kiro/specs/platform-services/implementation-plan.md)
- [平台服务测试文档](.kiro/specs/platform-services/testing-validation.md)
- [平台服务快速开始](docs/platform-services/PLATFORM_SERVICES_README.md)
- [平台服务用户指南](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)
- [实施完成报告](docs/reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)

### Technical Implementation
- 5000+ 行核心代码
- 服务管理器（PlatformServiceManager）
- 通知服务实现（flutter_local_notifications）
- 音频服务实现（audioplayers）
- 任务调度实现（Timer + SharedPreferences）

## [0.2.1] - 2026-01-13

### Added
- 🌍 **世界时钟插件** - 功能完整的世界时钟和倒计时应用
  - 多时区显示（10+预定义时区）
  - 倒计时提醒功能
  - 实时时间更新
  - 完成通知
  - 数据持久化
- 🎨 **Material Design 3** UI改进
- 🌐 **国际化支持** - 中文和英文
- ⚙️ **设置功能** - 24小时制、显示秒数、通知开关、动画开关

### Fixed
- 🐛 修复世界时钟插件ID验证问题（com.example.world_clock → com.example.worldclock）
- 🐛 修复添加时钟/倒计时按钮无法点击的问题
- 🐛 修复UI状态管理问题
- 📝 统一文档示例与插件ID验证规则

### Documentation
- [世界时钟实现文档](docs/plugins/world-clock/implementation.md)
- [世界时钟更新说明](docs/plugins/world-clock/UPDATE_v1.1.md)
- [插件ID修复报告](docs/reports/PLUGIN_ID_FIX_SUMMARY.md)
- [v0.2.1 发布说明](docs/releases/RELEASE_NOTES_v0.2.1.md)
- 增强内部插件开发指南（添加插件ID命名规范章节）

### Test Coverage
- 完整的单元测试（test/plugins/world_clock_test.dart）
- 插件生命周期测试
- 数据模型序列化测试
- 时区处理测试

## [0.2.0] - 2026-01-10

### Added
- 🔧 **平台服务架构基础**
  - 服务定位器（ServiceLocator）
  - 可释放资源接口（Disposable）
  - 依赖注入支持
- 📚 **文档体系重组**
  - 创建文档主索引（docs/MASTER_INDEX.md）
  - 重组所有文档到合理目录结构
  - 新增50+个技术文档

### Documentation
- 完整的文档导航系统
- 插件文档、发布文档、实施报告分类
- 技术规范文档（.kiro/specs/）
- 交叉引用更新

## [0.1.0] - 2026-01-05

### Added
- 🎉 Initial release of Flutter Plugin Platform
- 🔌 Plugin system supporting both internal and external plugins
- 🌍 Multi-language support (Dart, Python, JavaScript, Java, C++)
- 🖥️ Cross-platform compatibility (Windows, macOS, Linux, Web, Mobile)
- 🔒 Security sandbox with permission management
- 🔥 Hot reload support for development
- 🛠️ CLI tools for plugin creation and management
- 🐾 Desktop Pet functionality (desktop platforms only)
- 📚 Comprehensive documentation and examples
- 🧮 Built-in calculator plugin as example
- 🎮 Plugin support for both tools and games
- 🏗️ Modular architecture with interface-based design
- 🔧 Platform-specific implementations with fallbacks
- 📱 Mobile-optimized features
- 🌐 Web platform compatibility
- 🎯 Steam platform integration support
- 🧪 Comprehensive testing framework
- 📖 Plugin SDK for easy development
- 🎨 Material Design 3 theme system

### Features
- Plugin lifecycle management
- State management with PluginStateManager
- Context-based dependency injection
- External plugin sandboxing
- Network connectivity management
- Local database support (SQLite)
- File system access
- Shared preferences storage
- Desktop window management
- WebView integration for external plugins
- Command line interface tools
- Plugin templates and examples

### Documentation
- [文档主索引](docs/MASTER_INDEX.md) - 完整的文档导航中心
- [Getting started guide](docs/guides/getting-started.md)
- [Internal plugin development guide](docs/guides/internal-plugin-development.md)
- [External plugin development guide](docs/guides/external-plugin-development.md)
- [Plugin SDK documentation](docs/guides/plugin-sdk-guide.md)
- [Desktop Pet guide](docs/guides/desktop-pet-guide.md)
- [CLI tools documentation](docs/tools/plugin-cli.md)
- [Migration guides](docs/migration/)
- [Troubleshooting documentation](docs/troubleshooting/)
- [API reference](docs/reference/)
- [Code examples](docs/examples/)

### Supported Platforms
- ✅ Windows (full support including Desktop Pet)
- ✅ macOS (full support including Desktop Pet)  
- ✅ Linux (full support including Desktop Pet)
- ✅ Web (with platform compatibility considerations)
- ✅ Android (mobile-optimized features)
- ✅ iOS (mobile-optimized features)
- ✅ Steam (desktop integration)

[0.3.0]: https://github.com/your-username/flutter-plugin-platform/releases/tag/v0.3.0
[1.0.0]: https://github.com/your-username/flutter-plugin-platform/releases/tag/v1.0.0
[0.2.1]: https://github.com/your-username/flutter-plugin-platform/releases/tag/v0.2.1
[0.2.0]: https://github.com/your-username/flutter-plugin-platform/releases/tag/v0.2.0
[0.1.0]: https://github.com/your-username/flutter-plugin-platform/releases/tag/v0.1.0