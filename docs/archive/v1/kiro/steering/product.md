# Product Overview

## Flutter Plugin Platform (插件平台)

A powerful, extensible Flutter plugin platform that supports both internal and external plugin development. The platform serves as an integrated environment for tools and mini-games with cross-platform compatibility.

### Core Features

- **Plugin System**: Supports both internal (integrated) and external (sandboxed) plugins
- **Multi-language Support**: Dart, Python, JavaScript, Java, C++, and more
- **Cross-platform**: Windows, macOS, Linux, Web, Mobile
- **Desktop Pet**: Desktop companion functionality (desktop platforms only)
- **Security Sandbox**: Permission management and resource limitations
- **Hot Reload**: Real-time updates during development
- **CLI Tools**: One-click creation, building, and testing

### Plugin Types

- **Tool Plugins**: Productivity applications (calculators, text editors, file managers)
- **Game Plugins**: Entertainment applications (puzzle games, mini-games)
- **Internal Plugins**: Run integrated within the main application (high performance, deep system integration)
- **External Plugins**: Run in separate processes (multi-language support, sandboxed security)

### Target Platforms

- Desktop: Windows, macOS, Linux (full feature support including Desktop Pet)
- Mobile: Android, iOS (mobile-optimized features)
- Web: Browser-based deployment (with platform compatibility considerations)
- Steam: Steam platform integration (desktop only)

### Architecture

The platform uses a modular architecture with:
- Core services for plugin management, networking, and state management
- Interface-based design for extensibility
- Platform-specific adapters for cross-platform compatibility
- Comprehensive permission and security system