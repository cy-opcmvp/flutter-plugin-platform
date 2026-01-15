# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Flutter Plugin Platform 是一个可扩展的跨平台插件系统，支持内部插件（Dart）和外部插件（Python, JS, Java, C++），提供平台服务层（通知、音频、任务调度等），目标平台包括 Windows, macOS, Linux, Web, Android, iOS, Steam。

### 核心架构

**插件系统**: 基于 `IPlugin` 接口的插件架构，每个插件实现 `initialize()`, `dispose()`, `buildUI()`, `onStateChanged()`, `getState()` 方法。插件通过 `PluginContext` 获取平台服务、数据存储和网络访问权限。

**服务定位器模式**: `ServiceLocator` (单例) 负责服务的注册和检索，支持单例 (`registerSingleton`) 和工厂 (`registerFactory`) 两种注册方式。`PlatformServiceManager` 作为统一入口初始化和访问所有平台服务。

**状态管理**: `PluginStateManager` 管理插件生命周期状态转换（inactive → loading → active/paused → error），包含状态历史记录和验证逻辑。

**数据模型**:
- `PluginDescriptor`: 插件元数据（包含 `isValid()` 验证反向域命名格式和语义版本）
- `PluginRuntimeInfo`: 组合描述符和状态管理器的运行时信息
- `PluginContext`: 提供给插件的上下文（platformServices, dataStorage, networkAccess, configuration）

## 常用开发命令

```bash
# 运行应用
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d chrome     # Web

# 获取依赖
flutter pub get

# 运行测试
flutter test                              # 所有测试
flutter test test/plugins/world_clock_test.dart  # 单个测试文件

# 构建
flutter build windows --release
flutter build macos --release
flutter build apk --release               # Android
flutter build web --release

# 清理
flutter clean

# 代码生成（国际化等）
flutter gen-l10n

# 创建内部插件（使用 CLI 工具）
dart tools/plugin_cli.dart create-internal --name "Plugin Name" --type tool --author "Author"
```

## 项目结构关键点

### 核心代码组织

```
lib/core/
├── interfaces/          # 接口定义
│   ├── i_plugin.dart                 # IPlugin 接口 + PluginContext
│   └── services/                     # 平台服务接口
│       ├── i_notification_service.dart
│       ├── i_audio_service.dart
│       └── i_task_scheduler_service.dart
├── models/             # 数据模型
│   └── plugin_models.dart            # PluginDescriptor, PluginStateManager, 等
└── services/           # 核心服务实现
    ├── service_locator.dart          # 服务定位器（单例模式）
    ├── platform_service_manager.dart  # 服务管理器（初始化入口）
    └── [notification|audio|task_scheduler]/
lib/plugins/            # 插件实现
    └── {plugin_name}/
        ├── {plugin_name}_plugin.dart   # 实现 IPlugin 接口
        ├── models/                     # 插件特定模型
        └── widgets/                    # 插件 UI 组件
```

### 应用启动流程 (main.dart)

1. `WidgetsFlutterBinding.ensureInitialized()` - 初始化 Flutter 绑定
2. `windowManager.ensureInitialized()` - 桌面平台窗口管理（非 Web）
3. `PlatformServiceManager.initialize()` - 初始化所有平台服务
4. `LocaleProvider().loadSavedLocale()` - 加载保存的语言设置
5. `runApp(PluginPlatformApp)` - 运行应用

### 插件开发关键点

**插件 ID 格式**: 必须使用反向域命名，如 `com.example.worldclock`

**插件实现要求**:
- 实现 `IPlugin` 接口的所有方法
- 通过 `_context.platformServices` 访问平台服务
- 使用 `_context.dataStorage` 进行持久化存储
- 在 `dispose()` 中保存状态和清理资源
- 状态更新时调用 `_onStateChanged?.call()` 触发 UI 刷新

**插件状态机**: inactive → loading → active → (paused/inactive/error)

## 重要注意事项

### 暂时禁用的功能

**音频服务**: 由于 Windows 构建时的 NuGet 依赖问题，音频服务已暂时禁用。相关代码在 `pubspec.yaml` 和 `platform_service_manager.dart` 中已注释。待实现 Windows 特定的音频播放方案（如 Win32 API）后再启用。

**权限处理**: 同样因 NuGet 依赖问题暂时禁用。在移动平台需要时重新启用。

### 文件组织规则

严格遵守 `.claude/rules/FILE_ORGANIZATION_RULES.md`:
- 根目录只能保留: README.md, CHANGELOG.md, pubspec.yaml, 必要的入口文档
- 脚本文件放在 `scripts/` 目录
- 文档放在 `docs/` 目录（按类型分类：guides/, plugins/, releases/, reports/, troubleshooting/）
- 技术规范放在 `.kiro/specs/` 目录
- 插件详细文档放在 `docs/plugins/{plugin-name}/`，代码目录只保留简短的 README

### 国际化 (i18n)

项目已实现完整的国际化支持（中文/英文）：
- 语言文件: `lib/l10n/`
- 使用 `AppLocalizations.of(context)!.messageKey` 访问翻译
- 支持的语言: 中文（默认）、英文
- LocaleProvider 管理语言切换，使用 SharedPreferences 持久化

### 平台服务访问

```dart
// 通过 PlatformServiceManager 静态方法访问
final notificationService = PlatformServiceManager.notification;
final taskScheduler = PlatformServiceManager.taskScheduler;

// 或通过 ServiceLocator
final service = ServiceLocator.instance.get<INotificationService>();

// 检查服务是否可用
if (PlatformServiceManager.isServiceAvailable<IAudioService>()) {
  final audio = PlatformServiceManager.audio;
}
```

### 测试策略

- 单元测试: `test/` 目录，使用 `flutter test` 运行
- 集成测试: `integration_test/` 目录
- 测试覆盖率: 使用 `coverage` 包
- 测试工具: mockito 用于 mock，test 用于属性测试

## 已知问题和解决方案

### Windows 构建问题
- NuGet 包冲突: 参考 `docs/troubleshooting/WINDOWS_BUILD_FIX.md`
- CppWinRT 安装: 使用 `scripts/setup/install-cppwinrt.ps1`
- 详细指南: `docs/guides/WINDOWS_DISTRIBUTION_GUIDE.md`

### 时区处理
- 世界时钟插件使用 IANA 时区标识符（如 `Asia/Shanghai`）
- 时区列表在插件的 `_timeZones` 变量中定义

## 文档资源

- **文档主索引**: `docs/MASTER_INDEX.md` - 所有文档的导航中心
- **平台服务**: `docs/platform-services/` - 服务架构和使用指南
- **插件开发**: `docs/guides/internal-plugin-development.md` - 内部插件开发指南
- **技术规范**: `.kiro/specs/` - 架构设计和实施计划
- **项目概览**: `.claude/PROJECT_OVERVIEW.md` - 项目结构和特性总览

## 开发约定

### 代码风格
- 使用 `library` 指令标记库文件
- 接口命名以 `I` 开头（如 `IPlugin`, `INotificationService`）
- 实现类以 `Impl` 结尾（如 `NotificationServiceImpl`）
- 使用私有方法和类（下划线前缀）隐藏实现细节

### 插件约定
- 插件类实现 `IPlugin` 接口
- 插件 Widget 使用私有类（如 `_WorldClockPluginWidget`）
- 数据模型提供 `fromJson()`/`toJson()` 方法
- 验证逻辑放在模型的 `isValid()` 方法中

### 提交信息
- 使用中文提交信息
- 遵循约定式提交: `feat:`, `fix:`, `docs:`, `refactor:`, `test:` 等
- 包含 Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

### 变更日志
- 所有重要变更必须更新 `CHANGELOG.md`
- 遵循 Keep a Changelog 规范
- 发布版本时创建 `docs/releases/RELEASE_NOTES_v{version}.md`
