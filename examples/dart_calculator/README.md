# Calculator Plugin (Dart)

A simple calculator plugin demonstrating basic Plugin SDK usage with Dart/Flutter.

## Features

- Basic arithmetic operations (add, subtract, multiply, divide)
- Memory functions (store, recall, clear)
- History tracking
- Theme adaptation
- Keyboard shortcuts

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Plugin SDK
- Flutter Plugin Platform host

### Installation

1. Clone or download this example
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Build the plugin:
   ```bash
   plugin-cli build
   ```
4. Package for distribution:
   ```bash
   plugin-cli package --platform all --output calculator.pkg
   ```

### Testing

Test the plugin locally:

```bash
plugin-cli test --plugin calculator.pkg
```

## Code Structure

```
dart_calculator/
├── lib/
│   ├── main.dart              # Main entry point
│   ├── calculator_engine.dart # Calculation logic
│   ├── calculator_ui.dart     # User interface
│   └── calculator_history.dart # History management
├── plugin_manifest.json      # Plugin configuration
├── pubspec.yaml              # Dart dependencies
└── README.md                 # This file
```

## Key SDK Features Demonstrated

1. **Plugin Initialization**: Setting up the SDK connection
2. **Event Handling**: Responding to host events (theme changes, etc.)
3. **API Calls**: Calling host APIs for preferences and notifications
4. **Configuration**: Managing plugin settings
5. **Lifecycle Management**: Proper startup and shutdown
6. **Error Handling**: Graceful error handling and reporting

## Usage

Once installed in the Flutter Plugin Platform:

1. Open the calculator plugin from the plugin menu
2. Perform calculations using the on-screen buttons or keyboard
3. View calculation history in the history panel
4. Access settings through the plugin settings menu

## Configuration Options

The plugin supports the following configuration options:

- `precision`: Number of decimal places (default: 2)
- `show_history`: Show/hide history panel (default: true)
- `keyboard_shortcuts`: Enable keyboard shortcuts (default: true)
- `theme_mode`: Theme preference (auto, light, dark)

## API Integration

The plugin demonstrates integration with host APIs:

- `getUserPreference()`: Get user theme and locale preferences
- `showNotification()`: Display calculation results as notifications
- `saveUserData()`: Persist calculation history
- `loadUserData()`: Restore calculation history

## Development Notes

This example showcases best practices for Dart-based external plugins:

- Proper SDK initialization and cleanup
- Responsive UI that adapts to host theme
- Efficient state management
- Error handling and logging
- Configuration management
- Testing and debugging support