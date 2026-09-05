# Project Structure

## Root Directory Layout

```
flutter_app/
├── lib/                    # Main application source code
├── test/                   # Test files
├── docs/                   # Documentation
├── tools/                  # CLI tools and utilities
├── android/                # Android platform files
├── ios/                    # iOS platform files
├── linux/                  # Linux platform files
├── macos/                  # macOS platform files
├── windows/                # Windows platform files
├── web/                    # Web platform files
├── build/                  # Build output (generated)
├── .dart_tool/             # Dart tooling (generated)
└── .kiro/                  # Kiro IDE configuration
```

## Core Application Structure (`lib/`)

### Core System (`lib/core/`)
```
lib/core/
├── interfaces/             # Interface definitions
│   ├── i_plugin.dart      # Base plugin interface
│   ├── i_plugin_manager.dart
│   ├── i_platform_core.dart
│   ├── i_platform_services.dart
│   ├── i_state_manager.dart
│   ├── i_network_manager.dart
│   └── i_*.dart           # Other core interfaces
├── models/                 # Data models and DTOs
│   ├── plugin_models.dart # Plugin-related models
│   ├── platform_models.dart
│   └── external_plugin_models.dart
├── services/               # Core service implementations
│   ├── platform_core.dart # Main platform orchestrator
│   ├── plugin_manager.dart
│   ├── state_manager.dart
│   ├── network_manager.dart
│   ├── platform_services.dart
│   ├── external_plugin_manager.dart
│   ├── desktop_pet_manager.dart
│   └── *.dart             # Other service implementations
└── config/                 # Configuration classes
    └── platform_config.dart
```

### Plugin System (`lib/plugins/`)
```
lib/plugins/
├── plugin_registry.dart    # Central plugin registry
├── calculator/             # Example internal plugin
│   ├── calculator_plugin.dart
│   ├── calculator_plugin_factory.dart
│   ├── plugin_descriptor.json
│   ├── widgets/           # Plugin-specific widgets
│   ├── models/            # Plugin-specific models
│   └── README.md
└── [plugin_name]/         # Additional plugins follow same structure
    ├── [plugin_name]_plugin.dart
    ├── [plugin_name]_plugin_factory.dart
    ├── plugin_descriptor.json
    ├── widgets/
    ├── models/
    └── README.md
```

### User Interface (`lib/ui/`)
```
lib/ui/
├── screens/                # Main application screens
│   ├── main_platform_screen.dart
│   ├── plugin_management_screen.dart
│   ├── external_plugin_management_screen.dart
│   └── desktop_pet_screen.dart
└── widgets/                # Reusable UI components
    ├── plugin_card.dart
    ├── plugin_details_dialog.dart
    ├── plugin_ui_container.dart
    ├── desktop_pet_widget.dart
    ├── web_view_container.dart
    └── *.dart
```

### Platform Abstractions (`lib/platforms/`)
```
lib/platforms/
├── mobile/                 # Mobile-specific implementations
│   ├── mobile_services.dart
│   └── mobile_services_impl.dart
└── steam/                  # Steam platform integration
    ├── steam_integration.dart
    └── steam_integration_impl.dart
```

### Plugin SDK (`lib/sdk/`)
```
lib/sdk/
├── sdk.dart               # Main SDK export
├── plugin_sdk.dart       # Core SDK functionality
└── plugin_helpers.dart   # Helper utilities for plugin development
```

## Testing Structure (`test/`)

```
test/
├── plugins/               # Plugin-specific tests
│   ├── calculator_test.dart
│   └── [plugin_name]_test.dart
├── core/                  # Core system tests
├── platform_config_test.dart
├── platform_environment_test.dart
└── desktop_pet_test.dart
```

## Documentation (`docs/`)

```
docs/
├── README.md              # Main documentation index
├── index.md               # Documentation overview
├── project-structure.md   # This file
├── web-platform-compatibility.md
├── guides/                # Development guides
│   ├── getting-started.md
│   ├── internal-plugin-development.md
│   ├── external-plugin-development.md
│   ├── plugin-sdk-guide.md
│   ├── desktop-pet-guide.md
│   ├── desktop-pet-platform-support.md
│   └── backend-integration.md
├── examples/              # Code examples
│   ├── dart-calculator.md
│   ├── python-weather.md
│   └── built-in-plugins.md
├── tools/                 # Tool documentation
│   └── plugin-cli.md
├── templates/             # Plugin templates
│   └── README.md
├── migration/             # Migration guides
│   ├── migration-guide.md
│   └── platform-environment-migration.md
├── reference/             # Reference documentation
│   └── platform-fallback-values.md
└── troubleshooting/       # Problem resolution
    └── desktop-pet-fix.md
```

## CLI Tools (`tools/`)

```
tools/
├── plugin_cli.dart        # Main CLI tool
├── pubspec.yaml           # CLI tool dependencies
└── .dart_tool/            # CLI tool build artifacts
```

## File Naming Conventions

### Dart Files
- **Core services**: `[service_name].dart` (e.g., `plugin_manager.dart`)
- **Interfaces**: `i_[interface_name].dart` (e.g., `i_plugin.dart`)
- **Models**: `[domain]_models.dart` (e.g., `plugin_models.dart`)
- **Plugins**: `[plugin_name]_plugin.dart` (e.g., `calculator_plugin.dart`)
- **Factories**: `[plugin_name]_plugin_factory.dart`
- **Tests**: `[file_name]_test.dart`

### Configuration Files
- **Plugin descriptors**: `plugin_descriptor.json`
- **Analysis options**: `analysis_options.yaml`
- **Package config**: `pubspec.yaml`

## Key Architecture Principles

### Separation of Concerns
- **Core**: Platform services and infrastructure
- **Plugins**: Business logic and UI for specific features
- **UI**: Presentation layer and user interaction
- **Platforms**: Platform-specific implementations

### Interface-Based Design
- All major components implement interfaces
- Enables dependency injection and testing
- Supports multiple implementations per interface

### Plugin Isolation
- Each plugin has its own directory
- Self-contained with models, widgets, and logic
- Standardized structure for consistency

### Cross-Platform Support
- Platform-specific code isolated in `lib/platforms/`
- Conditional compilation for platform features
- Fallback implementations for unsupported platforms