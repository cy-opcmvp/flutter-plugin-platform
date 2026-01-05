# Plugin Platform - Project Structure

This document outlines the core project structure and interfaces for the Plugin Platform.

## Directory Structure

```
lib/
├── core/
│   ├── interfaces/          # Core abstractions and contracts
│   │   ├── i_plugin.dart           # Base plugin interface
│   │   ├── i_platform_services.dart # Platform services interface
│   │   ├── i_plugin_manager.dart    # Plugin management interface
│   │   ├── i_network_manager.dart   # Network management interface
│   │   ├── i_state_manager.dart     # State management interface
│   │   └── i_platform_core.dart     # Core platform orchestration
│   ├── models/              # Data models and enums
│   │   ├── plugin_models.dart       # Plugin-related models
│   │   └── platform_models.dart     # Platform-related models
│   └── config/              # Configuration classes
│       └── platform_config.dart     # Platform-specific configuration
├── platforms/               # Platform-specific implementations
│   ├── steam/
│   │   └── steam_integration.dart   # Steam-specific features
│   └── mobile/
│       └── mobile_services.dart     # Mobile-specific services
└── main.dart               # Application entry point
```

## Core Interfaces

### IPlugin
Base interface that all plugins must implement. Defines the contract for plugin lifecycle management, UI rendering, and state handling.

### IPlatformServices
Interface for platform services available to plugins, including notifications, permissions, and external URL handling.

### IPluginManager
Interface for managing plugin lifecycle, installation, and security validation.

### INetworkManager
Interface for network management and API communications.

### IStateManager
Interface for application and plugin state management.

### IPlatformCore
Core platform interface that orchestrates all services and manages operation modes.

## Key Models

### PluginDescriptor
Contains metadata about plugins including ID, name, version, type, and required permissions.

### UserProfile
User information including preferences, installed plugins, and sync data.

### BackendConfig
Configuration for API endpoints and authentication.

### Platform Events
Various event types for plugin state changes, network connectivity, and operation mode changes.

## Testing

The project includes comprehensive testing with both unit tests and property-based tests:

- **Unit Tests**: Verify specific functionality and edge cases
- **Property Tests**: Verify universal properties across random inputs (100 iterations each)

## Multi-Platform Support

The platform is designed to support:
- **Mobile**: iOS and Android with touch-optimized interfaces
- **Desktop**: Windows, macOS, and Linux
- **Steam**: Desktop pet mode and Steam Workshop integration

## Operation Modes

- **Local Mode**: Offline operation with local data storage
- **Online Mode**: Network-enabled with cloud synchronization and multiplayer features