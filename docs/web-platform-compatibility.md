# Web Platform Compatibility Guide

## Overview

This guide documents the web platform compatibility features implemented in the Flutter plugin platform. The system now supports both web and native platforms through a platform abstraction layer that handles environment variables and desktop-specific features gracefully.

## Platform Feature Matrix

### Core Features

| Feature | Web Platform | Native Platforms | Notes |
|---------|-------------|------------------|-------|
| Environment Variables | ❌ (Defaults) | ✅ (Full Access) | Web uses safe defaults |
| File System Access | ❌ (Browser Storage) | ✅ (Full Access) | Web uses localStorage/sessionStorage |
| Process Execution | ❌ (Disabled) | ✅ (Full Access) | Web cannot execute external processes |
| Steam Integration | ❌ (Disabled) | ✅ (When Available) | Web skips Steam detection entirely |
| Development Mode | ✅ (Limited) | ✅ (Full Detection) | Web uses alternative detection methods |
| Plugin System | ✅ (Core Features) | ✅ (Full Features) | Web supports most plugin functionality |

### Desktop Pet Features

| Feature | Web Platform | Windows | macOS | Linux | Mobile |
|---------|-------------|---------|-------|-------|--------|
| Desktop Pet Widget | ❌ | ✅ | ✅ | ✅ | ❌ |
| Always On Top | ❌ | ✅ | ✅ | ✅ | ❌ |
| System Tray | ❌ | ✅ | ✅ | ✅ | ❌ |
| Window Management | ❌ | ✅ | ✅ | ✅ | ❌ |
| Desktop Pet UI Controls | Hidden | Visible | Visible | Visible | Hidden |

### Path Resolution

| Path Type | Web Platform | Native Platforms |
|-----------|-------------|------------------|
| Home Directory | `/browser-home` | `$HOME` or equivalent |
| Documents | `/browser-documents` | Platform-specific documents folder |
| Temporary Files | `/browser-temp` | System temp directory |
| Application Data | `/browser-appdata` | Platform-specific app data folder |

## Migration Guide

### For Developers Using Platform.environment

If your code currently uses `Platform.environment` directly, follow these steps to migrate:

#### Before (Problematic on Web)
```dart
import 'dart:io';

// This will throw on web platform
String? steamPath = Platform.environment['STEAM_PATH'];
String home = Platform.environment['HOME'] ?? '/default';
```

#### After (Web Compatible)
```dart
import 'package:your_app/core/services/platform_environment.dart';

// This works on all platforms
String? steamPath = PlatformEnvironment.instance.getVariable('STEAM_PATH');
String home = PlatformEnvironment.instance.getHomePath();
```

### Step-by-Step Migration

1. **Replace Direct Platform.environment Calls**
   ```dart
   // Old
   Platform.environment['KEY']
   
   // New
   PlatformEnvironment.instance.getVariable('KEY')
   ```

2. **Add Default Values**
   ```dart
   // Old
   String value = Platform.environment['KEY'] ?? 'default';
   
   // New
   String value = PlatformEnvironment.instance.getVariable('KEY', defaultValue: 'default') ?? 'default';
   ```

3. **Use Path Resolution Methods**
   ```dart
   // Old
   String home = Platform.environment['HOME'] ?? '/';
   
   // New
   String home = PlatformEnvironment.instance.getHomePath();
   ```

4. **Check Platform Capabilities**
   ```dart
   // Old
   if (Platform.isWindows) { /* desktop logic */ }
   
   // New
   if (!PlatformEnvironment.instance.isWeb && Platform.isWindows) {
     /* desktop logic */
   }
   ```

## Environment Variable Defaults

### Web Platform Defaults

When running on web platform, the following default values are used:

| Environment Variable | Default Value | Purpose |
|---------------------|---------------|---------|
| `HOME` | `/browser-home` | User home directory |
| `USERPROFILE` | `/browser-home` | Windows user profile |
| `APPDATA` | `/browser-appdata` | Application data directory |
| `LOCALAPPDATA` | `/browser-appdata` | Local application data |
| `TEMP` | `/browser-temp` | Temporary files directory |
| `TMP` | `/browser-temp` | Temporary files directory |
| `PATH` | `/usr/bin:/bin` | Executable search path |
| `STEAM_PATH` | `null` | Steam installation path |
| `DEVELOPMENT_MODE` | `null` | Development mode indicator |

### Native Platform Behavior

On native platforms, actual environment variable values are returned. If a variable doesn't exist, the following fallbacks are used:

| Platform | HOME Fallback | TEMP Fallback | APPDATA Fallback |
|----------|---------------|---------------|------------------|
| Windows | `C:\Users\Default` | `C:\Temp` | `C:\Users\Default\AppData` |
| macOS | `/Users/Shared` | `/tmp` | `/Users/Shared/Library` |
| Linux | `/home/user` | `/tmp` | `/home/user/.local/share` |

## Desktop Pet Feature Documentation

### Platform Availability

Desktop pet functionality is only available on desktop platforms (Windows, macOS, Linux). The feature is completely disabled on web and mobile platforms.

### Web Platform Behavior

On web platform:
- Desktop pet UI controls are hidden from the interface
- Desktop pet manager initialization is skipped
- All desktop pet API calls return safe fallback values
- No errors are thrown when desktop pet features are accessed

### Implementation Details

```dart
// Desktop pet availability check
bool isDesktopPetSupported() {
  return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}

// Safe desktop pet initialization
class DesktopPetManager {
  static bool isSupported() {
    return !kIsWeb && _isDesktopPlatform();
  }
  
  Future<void> initialize() async {
    if (!isSupported()) {
      // Graceful no-op on unsupported platforms
      return;
    }
    // Native initialization logic
  }
}
```

### UI Behavior by Platform

#### Web Platform
- Desktop pet button: Hidden
- Desktop pet screen: Shows "Feature not available" message
- Desktop pet widget: Returns empty container
- Navigation: Gracefully handles unavailable routes

#### Desktop Platforms
- Desktop pet button: Visible and functional
- Desktop pet screen: Full functionality
- Desktop pet widget: Complete feature set
- Navigation: Full desktop pet navigation available

#### Mobile Platforms
- Desktop pet button: Hidden
- Desktop pet functionality: Disabled (same as web)

## Development and Debugging

### Debug Mode Features

When running in debug mode, additional logging is available:

```dart
// Enable detailed platform logging
PlatformLogger.setLevel(LogLevel.debug);

// Check platform capabilities
PlatformCapabilities caps = PlatformEnvironment.instance.capabilities;
print('Environment variables supported: ${caps.supportsEnvironmentVariables}');
print('Desktop pet supported: ${caps.supportsDesktopPet}');
```

### Common Issues and Solutions

#### Issue: Application crashes on web with Platform.environment error
**Solution**: Replace direct `Platform.environment` usage with `PlatformEnvironment.instance.getVariable()`

#### Issue: Desktop pet features not working on web
**Solution**: This is expected behavior. Desktop pet features are disabled on web platform.

#### Issue: File paths not working on web
**Solution**: Use `PlatformEnvironment.instance.getHomePath()` and similar methods instead of environment variables.

#### Issue: Steam integration not detected on web
**Solution**: Steam integration is intentionally disabled on web platform.

### Testing Platform Compatibility

```dart
// Test environment variable access
test('environment variables work on all platforms', () {
  String? value = PlatformEnvironment.instance.getVariable('HOME');
  expect(value, isNotNull); // Should never be null due to fallbacks
});

// Test desktop pet availability
test('desktop pet availability matches platform', () {
  bool expected = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  expect(DesktopPetManager.isSupported(), equals(expected));
});
```

## Best Practices

### 1. Always Use Platform Abstraction
```dart
// Good
String home = PlatformEnvironment.instance.getHomePath();

// Bad
String home = Platform.environment['HOME'] ?? '/';
```

### 2. Check Platform Capabilities
```dart
// Good
if (PlatformEnvironment.instance.capabilities.supportsDesktopPet) {
  // Desktop pet logic
}

// Bad
if (Platform.isWindows) {
  // This doesn't account for web platform
}
```

### 3. Provide Graceful Fallbacks
```dart
// Good
Widget buildDesktopPetButton() {
  if (!DesktopPetManager.isSupported()) {
    return SizedBox.shrink(); // Hidden on unsupported platforms
  }
  return ElevatedButton(/* desktop pet button */);
}
```

### 4. Use Appropriate Defaults
```dart
// Good
String configPath = PlatformEnvironment.instance.getVariable(
  'CONFIG_PATH',
  defaultValue: '/default/config'
);

// Bad
String configPath = Platform.environment['CONFIG_PATH']; // Crashes on web
```

## Performance Considerations

- Environment variable lookups are cached to avoid repeated system calls
- Platform detection uses compile-time constants where possible (`kIsWeb`)
- Desktop pet initialization is lazy and only occurs when needed
- Web platform avoids importing `dart:io` in desktop pet modules

## Security Considerations

- Web platform cannot access actual environment variables (browser security)
- Default values are safe and don't expose sensitive information
- Desktop pet features require explicit user permission on desktop platforms
- File system access is sandboxed appropriately for each platform

## Future Enhancements

Planned improvements for web platform compatibility:

1. **Enhanced Web Storage**: Better integration with browser storage APIs
2. **Progressive Web App Features**: Support for PWA-specific capabilities
3. **Web-Specific Plugins**: Plugins designed specifically for web platform
4. **Improved Fallbacks**: More sophisticated fallback mechanisms for missing features

## Support and Troubleshooting

For issues related to web platform compatibility:

1. Check the browser console for detailed error messages
2. Verify that `kIsWeb` detection is working correctly
3. Ensure no direct `dart:io` imports in web-compiled code
4. Test platform-specific features on their target platforms

For additional support, refer to the main documentation or file an issue with platform-specific details.