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

## Development Environment

### Required Tools
- Flutter SDK (^3.10.0)
- Dart SDK (included with Flutter)
- Platform-specific toolchains (Android Studio, Xcode, Visual Studio)

### IDE Configuration
- Analysis options configured in `analysis_options.yaml`
- Flutter lints enabled for code quality
- Material Design 3 theme system