# Example Plugins

This directory contains example plugins that demonstrate how to implement tools and games for the Plugin Platform.

## Available Example Plugins

### 1. Calculator Plugin (`com.example.calculator`)
- **Type**: Tool
- **Description**: A simple calculator for basic arithmetic operations
- **Features**:
  - Basic arithmetic operations (+, -, ×, ÷)
  - Percentage calculations
  - Sign toggle
  - Clear function
  - State persistence across sessions
- **Permissions**: Notifications
- **Location**: `lib/plugins/calculator/`

### 2. Sliding Puzzle Game (`com.example.puzzle_game`)
- **Type**: Game
- **Description**: A classic sliding puzzle game with numbered tiles
- **Features**:
  - 3x3 sliding puzzle
  - Move counter
  - Timer
  - Game state persistence
  - Shuffle and new game functions
  - Win detection and celebration
- **Permissions**: Notifications, Storage
- **Location**: `lib/plugins/puzzle_game/`

## Plugin Structure

Each plugin follows this structure:
```
plugin_name/
├── plugin_name_plugin.dart          # Main plugin implementation
├── plugin_name_plugin_factory.dart  # Factory for creating plugin instances
└── plugin_descriptor.json           # Plugin metadata and configuration
```

## Plugin Implementation Guidelines

### 1. Plugin Interface Implementation
All plugins must implement the `IPlugin` interface:
- `id`: Unique identifier (reverse domain notation)
- `name`: Display name
- `version`: Semantic version
- `type`: Either `PluginType.tool` or `PluginType.game`
- `initialize()`: Setup plugin with context
- `dispose()`: Cleanup resources
- `buildUI()`: Create Flutter widget
- `onStateChanged()`: Handle state transitions
- `getState()`: Return current state data

### 2. State Management
- Use `PluginContext.dataStorage` to persist state
- Handle state changes in `onStateChanged()`
- Save critical state before disposal
- Restore state during initialization

### 3. Platform Services Usage
- Use `PluginContext.platformServices` for:
  - Showing notifications
  - Requesting permissions
  - Opening external URLs
  - Listening to platform events

### 4. Resource Management
- Properly dispose of resources in `dispose()`
- Handle plugin isolation and sandboxing
- Respect permission boundaries
- Manage memory and CPU usage efficiently

### 5. Error Handling
- Handle errors gracefully without crashing
- Provide user-friendly error messages
- Maintain plugin isolation (errors shouldn't affect other plugins)
- Reset to safe state on error

## Plugin Descriptor Format

```json
{
  "id": "com.example.plugin_name",
  "name": "Plugin Display Name",
  "version": "1.0.0",
  "type": "tool|game",
  "requiredPermissions": ["notifications", "storage"],
  "metadata": {
    "description": "Plugin description",
    "author": "Author Name",
    "category": "Category",
    "tags": ["tag1", "tag2"],
    "icon": "icon_name",
    "minPlatformVersion": "1.0.0",
    "supportedPlatforms": ["mobile", "desktop", "steam"]
  },
  "entryPoint": "lib/plugins/plugin_name/plugin_name_plugin.dart"
}
```

## Using Example Plugins

### In Plugin Manager
```dart
import 'package:flutter_app/plugins/plugin_registry.dart';

// Get all example plugin descriptors
final descriptors = ExamplePluginRegistry.getAllDescriptors();

// Create a specific plugin instance
final calculator = ExamplePluginRegistry.createPlugin('com.example.calculator');

// Get plugin descriptor
final descriptor = ExamplePluginRegistry.getDescriptor('com.example.calculator');
```

### Testing Plugins
These example plugins can be used to:
1. Test plugin loading and unloading
2. Verify plugin isolation and sandboxing
3. Test state persistence and recovery
4. Validate permission system
5. Test UI integration and navigation
6. Verify error handling and recovery

## Development Notes

### Calculator Plugin
- Demonstrates tool plugin implementation
- Shows state persistence for calculator operations
- Uses platform services for notifications
- Implements proper resource cleanup

### Puzzle Game Plugin
- Demonstrates game plugin implementation
- Shows complex state management (board, moves, timer)
- Implements game-specific features (shuffle, win detection)
- Demonstrates proper game state persistence
- Shows resource management for games

Both plugins serve as reference implementations for developers creating their own plugins for the platform.