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

### 已启用的平台服务

**音频服务** ✅: 已启用并正常工作。使用 `just_audio` 包实现：
- Windows 平台：使用 SystemSound（系统声音）作为回退方案
- 其他平台（macOS/Linux/Android/iOS）：使用 just_audio 完整功能
- 自动回退机制：如果 just_audio 初始化失败，自动使用 SystemSound
- 相关代码：`lib/core/services/audio/audio_service.dart`

**通知服务** ✅: 使用 `flutter_local_notifications`，支持所有平台
**任务调度服务** ✅: 使用 `flutter_local_notifications` 实现定时任务

### 暂时禁用的功能

**权限处理**: 由于 Windows 构建时的 NuGet 依赖问题暂时禁用。在移动平台需要时取消注释 `pubspec.yaml:71` 中的 `permission_handler`。

### 内置插件

项目包含 **3 个内置插件**：
1. **Calculator** (计算器) - 基础计算功能
2. **Screenshot** (截图) - 区域截图、历史记录、图片编辑
3. **World Clock** (世界时钟) - 多时区时钟显示

### 文件组织规则

严格遵守 `.claude/rules/FILE_ORGANIZATION_RULES.md`:
- 根目录只能保留: README.md, CHANGELOG.md, pubspec.yaml, 必要的入口文档
- 脚本文件放在 `scripts/` 目录
- 文档放在 `docs/` 目录（按类型分类：guides/, plugins/, releases/, reports/, troubleshooting/）
- 技术规范放在 `.kiro/specs/` 目录
- 插件详细文档放在 `docs/plugins/{plugin-name}/`，代码目录只保留简短的 README

### 版本控制规则

严格遵守 `.claude/rules/VERSION_CONTROL_RULES.md`:
- **每次对话都必须记录**：修改的文件、创建的文件、删除的文件、重构的内容
- **每次 push 前必须检查**：确认所有变更已提交、更新 CHANGELOG.md、运行测试
- **tag 创建规范**：详细的 tag 注释、完整的发布文档、版本历史记录
- **所有操作都要追溯**：在 `.claude/rules/VERSION_CONTROL_HISTORY.md` 中记录

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
final audioService = PlatformServiceManager.audio;
final taskScheduler = PlatformServiceManager.taskScheduler;

// 或通过 ServiceLocator
final service = ServiceLocator.instance.get<INotificationService>();

// 检查服务是否可用
if (PlatformServiceManager.isServiceAvailable<IAudioService>()) {
  final audio = PlatformServiceManager.audio;
}
```

**可用的平台服务**：
- **INotificationService** - 通知服务（已启用）
- **IAudioService** - 音频服务（已启用，Windows 使用 SystemSound）
- **ITaskSchedulerService** - 任务调度服务（已启用）

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

### 国际化约定（最高优先级）

**⚠️ 重要：国际化优先级高于所有其他开发任务，任何情况下都不可以跳过或延后。**

#### 基本规则
1. **所有面向用户的文本必须国际化** - 包括但不限于：
   - UI 标题和标签
   - 按钮文本
   - 提示信息
   - 错误消息
   - 对话框内容
   - 菜单项
   - 工具提示

2. **禁止硬编码文本** - 以下写法是**绝对禁止**的：
   ```dart
   // ❌ 错误：硬编码文本
   Text('Screenshot Plugin Config')
   const Text('General Settings')
   title: 'Behavior'

   // ✅ 正确：使用国际化
   Text(l10n.screenshot_config_title)
   Text(l10n.settings_general)
   title: l10n.settings_behavior
   ```

3. **开发流程要求**：
   - **第一步**：编写 UI 前先在 `lib/l10n/app_zh.arb` 和 `lib/l10n/app_en.arb` 添加翻译键
   - **第二步**：运行 `flutter gen-l10n` 生成本地化代码
   - **第三步**：在代码中使用 `AppLocalizations.of(context)!` 获取 `l10n` 实例
   - **第四步**：使用 `l10n.xxx` 访问翻译文本

4. **翻译键命名规范**：
   - 使用下划线分隔的小写字母：`settings_save_path`
   - 按功能分组：`screenshot_config_title`, `screenshot_config_save_path`
   - 通用命名：`common_save`, `common_cancel`, `common_confirm`
   - 错误消息：`error_network`, `error_load_failed`

5. **检查清单**（提交代码前必须确认）：
   - [ ] 所有用户可见的文本都使用了 `l10n.xxx`
   - [ ] 没有硬编码的中文字符串
   - [ ] 没有硬编码的英文字符串
   - [ ] 中文和英文翻译都已添加到 `.arb` 文件
   - [ ] 已运行 `flutter gen-l10n` 生成代码
   - [ ] 在中英文环境下都测试过 UI 显示

6. **例外情况**（极少数，需谨慎评估）：
   - 技术标识符：如 `"Ctrl+Shift+A"` 快捷键显示
   - 路径占位符：如 `"{documents}/Screenshots"`
   - 日志输出：`debugPrint()` 中的文本（但用户可见的日志需国际化）
   - API 返回的原始数据

#### 国际化代码示例
```dart
// 1. 在 .arb 文件中添加翻译
// app_zh.arb:
"settings_title": "设置",
"screenshot_config_title": "截图插件配置"

// app_en.arb:
"settings_title": "Settings",
"screenshot_config_title": "Screenshot Plugin Config"

// 2. 在代码中使用
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshot_config_title),  // ✅ 国际化
      ),
      body: ElevatedButton(
        onPressed: () {},
        child: Text(l10n.common_save),  // ✅ 国际化
      ),
    );
  }
}
```

#### 违规后果
- **代码审查不通过** - 任何国际化问题都会导致 PR 被拒绝
- **技术债务标记** - 硬编码文本会被标记为技术债务，必须立即修复
- **禁止合并** - 未完成国际化的功能禁止合并到主分支

### 提交信息
- 使用中文提交信息
- 遵循约定式提交: `feat:`, `fix:`, `docs:`, `refactor:`, `test:` 等
- 包含 Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

### 变更日志
- 所有重要变更必须更新 `CHANGELOG.md`
- 遵循 Keep a Changelog 规范
- 发布版本时创建 `docs/releases/RELEASE_NOTES_v{version}.md`
