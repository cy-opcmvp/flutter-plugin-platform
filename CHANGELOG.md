# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- [世界时钟实现文档](docs/plugins/world-clock/IMPLEMENTATION.md)
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