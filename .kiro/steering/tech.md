# Technology Stack

## Framework & Language

- **Primary**: Flutter/Dart (SDK ^3.10.0)
- **Package Name**: `plugin_platform`
- **Version**: 1.0.0+1

## Core Dependencies

### Flutter Core
- `flutter` (SDK)
- `cupertino_icons: ^1.0.8`

### Platform Services
- `path_provider: ^2.1.1` - File system access
- `shared_preferences: ^2.2.2` - Local preferences storage
- `sqflite: ^2.3.0` - Local database
- `connectivity_plus: ^5.0.2` - Network connectivity

### Desktop Platform
- `desktop_window: ^0.4.0` - Desktop window management
- `window_manager: ^0.3.7` - Advanced window controls

### Web Integration
- `webview_flutter: ^4.4.2` - External plugin UI rendering

### Networking & Security
- `http: ^1.1.0` - HTTP client
- `crypto: ^3.0.3` - Cryptographic operations

### CLI & Utilities
- `args: ^2.4.2` - Command line argument parsing
- `path: ^1.8.3` - Path manipulation

## Development Dependencies

### Testing
- `flutter_test` (SDK)
- `test: ^1.24.0` - Property-based testing
- `mockito: ^5.4.2` - Mocking framework
- `build_runner: ^2.4.7` - Code generation

### Code Quality
- `flutter_lints: ^6.0.0` - Linting rules

## Build System

### Common Commands

```bash
# Setup (Windows)
setup-cli.bat

# Setup (Linux/macOS)
chmod +x setup-cli.sh && ./setup-cli.sh

# Development
flutter run                    # Run the application
flutter test                   # Run all tests
flutter analyze               # Static analysis
flutter build <platform>      # Build for specific platform

# Plugin CLI
dart tools/plugin_cli.dart create-internal --name "Plugin Name" --type tool
dart tools/plugin_cli.dart list-templates
dart tools/plugin_cli.dart --help

# Testing
flutter test test/plugins/     # Test specific plugins
flutter test --coverage       # Run with coverage
```

### Platform-Specific Builds

```bash
# Desktop
flutter build windows
flutter build macos
flutter build linux

# Mobile
flutter build apk
flutter build ios

# Web
flutter build web
```

## Architecture Patterns

### Interface-Based Design
- All core services implement interfaces (I* pattern)
- Dependency injection through constructor parameters
- Mock implementations for testing

### Plugin Architecture
- Plugin lifecycle management through `IPlugin` interface
- State management with `PluginStateManager`
- Context-based dependency injection via `PluginContext`

### Cross-Platform Abstraction
- Platform-specific implementations with fallbacks
- Environment detection through `PlatformEnvironment`
- Conditional compilation for platform features

## Code Organization

### Naming Conventions
- **Files**: snake_case (e.g., `plugin_manager.dart`)
- **Classes**: PascalCase (e.g., `PluginManager`)
- **Variables/Methods**: camelCase (e.g., `pluginManager`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_TIMEOUT`)
- **Plugin IDs**: Reverse domain notation (e.g., `com.example.calculator`)

### Directory Structure
- `lib/core/` - Core platform services and interfaces
- `lib/plugins/` - Internal plugin implementations
- `lib/ui/` - User interface components
- `lib/platforms/` - Platform-specific implementations
- `lib/sdk/` - Plugin development SDK
- `tools/` - CLI tools and utilities
- `test/` - Test files
- `docs/` - Documentation

## Internationalization (国际化规范)

### Core Requirements
- **默认语言**: 中文 (zh_CN)
- **全局国际化**: 所有用户可见文本必须使用国际化
- **必须国际化的内容**:
  - 弹出提示 (SnackBar, Toast)
  - 错误消息和异常提示
  - 对话框 (Dialog) 标题和内容
  - 设置页面所有文本
  - 按钮文本和标签
  - 表单验证消息
  - 空状态提示
  - 加载状态文本

### Implementation Pattern

```dart
// 使用 flutter_localizations 和 intl 包
// 在 pubspec.yaml 中添加:
// dependencies:
//   flutter_localizations:
//     sdk: flutter
//   intl: ^0.18.0

// 创建 l10n.yaml 配置文件
// arb-dir: lib/l10n
// template-arb-file: app_zh.arb
// output-localization-file: app_localizations.dart

// 示例用法:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Text(AppLocalizations.of(context)!.welcomeMessage)
```

### File Structure
```
lib/l10n/
├── app_zh.arb          # 中文 (默认/模板)
├── app_en.arb          # 英文
└── app_*.arb           # 其他语言
```

### Naming Conventions for ARB Keys
- **通用**: `common_*` (如 `common_confirm`, `common_cancel`)
- **错误**: `error_*` (如 `error_network`, `error_unknown`)
- **提示**: `hint_*` (如 `hint_input_required`)
- **按钮**: `button_*` (如 `button_save`, `button_delete`)
- **对话框**: `dialog_*` (如 `dialog_confirm_title`)
- **设置**: `settings_*` (如 `settings_language`)

### Code Review Checklist
- [ ] 所有硬编码字符串已替换为国际化键
- [ ] 新增文本已添加到所有 ARB 文件
- [ ] 中文翻译作为默认值存在
- [ ] 错误消息对用户友好且已国际化

## Development Environment

### Required Tools
- Flutter SDK (^3.10.0)
- Dart SDK (included with Flutter)
- Platform-specific toolchains (Android Studio, Xcode, Visual Studio)

### IDE Configuration
- Analysis options configured in `analysis_options.yaml`
- Flutter lints enabled for code quality
- Material Design 3 theme system