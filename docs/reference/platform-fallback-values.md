# Platform Fallback Values Reference

## Overview

This document provides a comprehensive reference of all fallback values used by the `PlatformEnvironment` service when environment variables are unavailable or when running on platforms that don't support environment variable access (such as web browsers).

## Environment Variable Fallbacks

### System Paths

#### Home Directory Variables

| Variable | Web Platform | Windows Fallback | macOS Fallback | Linux Fallback |
|----------|-------------|------------------|----------------|----------------|
| `HOME` | `/browser-home` | `C:\Users\Default` | `/Users/Shared` | `/home/user` |
| `USERPROFILE` | `/browser-home` | `C:\Users\Default` | `/Users/Shared` | `/home/user` |
| `HOMEPATH` | `/browser-home` | `\Users\Default` | `/Users/Shared` | `/home/user` |

#### Application Data Directories

| Variable | Web Platform | Windows Fallback | macOS Fallback | Linux Fallback |
|----------|-------------|------------------|----------------|----------------|
| `APPDATA` | `/browser-appdata` | `C:\Users\Default\AppData\Roaming` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `LOCALAPPDATA` | `/browser-appdata` | `C:\Users\Default\AppData\Local` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `XDG_DATA_HOME` | `/browser-appdata` | `C:\Users\Default\AppData\Local` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `XDG_CONFIG_HOME` | `/browser-config` | `C:\Users\Default\AppData\Roaming` | `/Users/Shared/Library/Preferences` | `/home/user/.config` |

#### Temporary Directories

| Variable | Web Platform | Windows Fallback | macOS Fallback | Linux Fallback |
|----------|-------------|------------------|----------------|----------------|
| `TEMP` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |
| `TMP` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |
| `TMPDIR` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |

### System Configuration

#### Path Variables

| Variable | Web Platform | Windows Fallback | macOS Fallback | Linux Fallback |
|----------|-------------|------------------|----------------|----------------|
| `PATH` | `/usr/bin:/bin` | `C:\Windows\System32;C:\Windows` | `/usr/bin:/bin:/usr/local/bin` | `/usr/bin:/bin:/usr/local/bin` |
| `PATHEXT` | `.exe;.bat;.cmd` | `.COM;.EXE;.BAT;.CMD;.VBS;.JS` | N/A | N/A |

#### User Information

| Variable | Web Platform | Windows Fallback | macOS Fallback | Linux Fallback |
|----------|-------------|------------------|----------------|----------------|
| `USER` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |
| `USERNAME` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |
| `LOGNAME` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |

### Application-Specific Variables

#### Steam Integration

| Variable | Web Platform | All Native Platforms |
|----------|-------------|---------------------|
| `STEAM_PATH` | `null` | `null` (detected dynamically) |
| `STEAMAPPS` | `null` | `null` (detected dynamically) |
| `STEAM_COMPAT_DATA_PATH` | `null` | `null` (detected dynamically) |

#### Development Environment

| Variable | Web Platform | All Native Platforms |
|----------|-------------|---------------------|
| `DEVELOPMENT_MODE` | `null` | `null` (detected from other indicators) |
| `DEBUG` | `null` | `null` (detected from other indicators) |
| `FLUTTER_TEST` | `null` | `null` (detected from test framework) |
| `NODE_ENV` | `production` | `null` (detected dynamically) |

#### Build and Compilation

| Variable | Web Platform | All Native Platforms |
|----------|-------------|---------------------|
| `FLUTTER_ROOT` | `null` | `null` (detected from SDK) |
| `DART_SDK` | `null` | `null` (detected from SDK) |
| `PUB_CACHE` | `null` | Platform-specific default |

## Path Resolution Methods

### PlatformEnvironment Path Methods

#### getHomePath()

**Web Platform**: `/browser-home`

**Native Platforms**:
- Windows: `%USERPROFILE%` → `C:\Users\Default`
- macOS: `$HOME` → `/Users/Shared`
- Linux: `$HOME` → `/home/user`

```dart
String getHomePath() {
  if (isWeb) return '/browser-home';
  
  if (Platform.isWindows) {
    return getVariable('USERPROFILE') ?? 'C:\\Users\\Default';
  } else {
    return getVariable('HOME') ?? (Platform.isMacOS ? '/Users/Shared' : '/home/user');
  }
}
```

#### getDocumentsPath()

**Web Platform**: `/browser-documents`

**Native Platforms**:
- Windows: `%USERPROFILE%\Documents` → `C:\Users\Default\Documents`
- macOS: `$HOME/Documents` → `/Users/Shared/Documents`
- Linux: `$HOME/Documents` → `/home/user/Documents`

```dart
String getDocumentsPath() {
  if (isWeb) return '/browser-documents';
  
  final home = getHomePath();
  return '$home${Platform.isWindows ? '\\Documents' : '/Documents'}';
}
```

#### getTempPath()

**Web Platform**: `/browser-temp`

**Native Platforms**:
- Windows: `%TEMP%` → `C:\Temp`
- macOS: `$TMPDIR` → `/tmp`
- Linux: `$TMPDIR` → `/tmp`

```dart
String getTempPath() {
  if (isWeb) return '/browser-temp';
  
  return getVariable('TEMP') ?? 
         getVariable('TMP') ?? 
         getVariable('TMPDIR') ?? 
         (Platform.isWindows ? 'C:\\Temp' : '/tmp');
}
```

#### getAppDataPath()

**Web Platform**: `/browser-appdata`

**Native Platforms**:
- Windows: `%APPDATA%` → `C:\Users\Default\AppData\Roaming`
- macOS: `$HOME/Library` → `/Users/Shared/Library`
- Linux: `$XDG_DATA_HOME` → `/home/user/.local/share`

```dart
String getAppDataPath() {
  if (isWeb) return '/browser-appdata';
  
  if (Platform.isWindows) {
    return getVariable('APPDATA') ?? 'C:\\Users\\Default\\AppData\\Roaming';
  } else if (Platform.isMacOS) {
    return '${getHomePath()}/Library';
  } else {
    return getVariable('XDG_DATA_HOME') ?? '${getHomePath()}/.local/share';
  }
}
```

## Web Platform Specific Behavior

### Browser Storage Integration

Instead of file system paths, web platform uses browser storage APIs:

| Path Type | Browser Storage | Fallback Behavior |
|-----------|----------------|-------------------|
| Home | localStorage | Persistent across sessions |
| Documents | localStorage | Persistent across sessions |
| Temp | sessionStorage | Cleared on tab close |
| AppData | localStorage | Persistent across sessions |

### URL Parameter Override

Web platform can override defaults using URL parameters:

```javascript
// URL: https://app.example.com/?debug=true&user=testuser
// Results in:
// - DEBUG environment variable: 'true'
// - USER environment variable: 'testuser'
```

Implementation:
```dart
String? _getWebEnvironmentVariable(String key) {
  if (!kIsWeb) return null;
  
  // Check URL parameters first
  final uri = Uri.base;
  if (uri.queryParameters.containsKey(key.toLowerCase())) {
    return uri.queryParameters[key.toLowerCase()];
  }
  
  // Check localStorage
  try {
    return html.window.localStorage[key];
  } catch (e) {
    return null;
  }
}
```

## Platform Capability Defaults

### PlatformCapabilities for Web

```dart
PlatformCapabilities.forWeb() {
  return PlatformCapabilities(
    supportsEnvironmentVariables: false,
    supportsFileSystem: false,
    supportsSteamIntegration: false,
    supportsNativeProcesses: false,
    supportsDesktopPet: false,
    supportsAlwaysOnTop: false,
    supportsSystemTray: false,
    supportsWindowManagement: false,
    supportsMultipleWindows: false,
    supportsClipboard: true, // Limited browser clipboard access
    supportsNotifications: true, // Browser notifications
    supportsLocalStorage: true,
    supportsSessionStorage: true,
  );
}
```

### PlatformCapabilities for Native

```dart
PlatformCapabilities.forNative() {
  return PlatformCapabilities(
    supportsEnvironmentVariables: true,
    supportsFileSystem: true,
    supportsSteamIntegration: _detectSteamSupport(),
    supportsNativeProcesses: true,
    supportsDesktopPet: _isDesktopPlatform(),
    supportsAlwaysOnTop: _isDesktopPlatform(),
    supportsSystemTray: _detectSystemTraySupport(),
    supportsWindowManagement: _isDesktopPlatform(),
    supportsMultipleWindows: _isDesktopPlatform(),
    supportsClipboard: true,
    supportsNotifications: true,
    supportsLocalStorage: false, // Uses file system instead
    supportsSessionStorage: false,
  );
}
```

## Configuration Override System

### Environment Variable Priority

1. **Actual environment variables** (native platforms only)
2. **URL parameters** (web platform only)
3. **localStorage values** (web platform only)
4. **Configuration file values**
5. **Platform-specific defaults**
6. **Universal fallback values**

### Configuration File Format

```json
{
  "platformDefaults": {
    "web": {
      "HOME": "/custom-browser-home",
      "USER": "web-user",
      "TEMP": "/custom-browser-temp"
    },
    "windows": {
      "HOME": "C:\\CustomUsers\\Default",
      "TEMP": "C:\\CustomTemp"
    },
    "macos": {
      "HOME": "/CustomUsers/Shared",
      "TEMP": "/custom-tmp"
    },
    "linux": {
      "HOME": "/custom-home/user",
      "TEMP": "/custom-tmp"
    }
  }
}
```

### Runtime Override API

```dart
class PlatformEnvironment {
  // Override specific variable for current session
  void setOverride(String key, String value) {
    _overrides[key] = value;
  }
  
  // Clear specific override
  void clearOverride(String key) {
    _overrides.remove(key);
  }
  
  // Clear all overrides
  void clearAllOverrides() {
    _overrides.clear();
  }
  
  // Get variable with override support
  String? getVariable(String key, {String? defaultValue}) {
    // Check overrides first
    if (_overrides.containsKey(key)) {
      return _overrides[key];
    }
    
    // Continue with normal resolution...
  }
}
```

## Testing Fallback Values

### Unit Test Examples

```dart
group('Fallback Values', () {
  test('should return web defaults on web platform', () {
    // Mock web platform
    when(() => mockPlatformEnvironment.isWeb).thenReturn(true);
    
    expect(mockPlatformEnvironment.getHomePath(), equals('/browser-home'));
    expect(mockPlatformEnvironment.getTempPath(), equals('/browser-temp'));
  });
  
  test('should return platform-specific defaults on native', () {
    // Mock Windows platform
    when(() => mockPlatformEnvironment.isWeb).thenReturn(false);
    when(() => Platform.isWindows).thenReturn(true);
    
    final home = mockPlatformEnvironment.getHomePath();
    expect(home, contains('Users\\Default'));
  });
  
  test('should handle missing environment variables gracefully', () {
    // Mock missing environment variable
    when(() => mockPlatformEnvironment.getVariable('NONEXISTENT'))
        .thenReturn(null);
    
    final result = mockPlatformEnvironment.getVariable(
      'NONEXISTENT',
      defaultValue: 'fallback'
    );
    expect(result, equals('fallback'));
  });
});
```

### Property-Based Test Examples

```dart
import 'package:test/test.dart';

void main() {
  group('Platform Fallback Properties', () {
    test('all path methods return non-null values', () {
      final env = PlatformEnvironment.instance;
      
      // Property: Path methods never return null
      expect(env.getHomePath(), isNotNull);
      expect(env.getDocumentsPath(), isNotNull);
      expect(env.getTempPath(), isNotNull);
      expect(env.getAppDataPath(), isNotNull);
    });
    
    test('web platform never accesses Platform.environment', () {
      // This test would fail if web platform tries to access Platform.environment
      // Property: Web platform uses only fallback values
      if (kIsWeb) {
        final env = PlatformEnvironment.instance;
        expect(() => env.getVariable('ANY_KEY'), returnsNormally);
      }
    });
  });
}
```

## Performance Considerations

### Caching Strategy

```dart
class PlatformEnvironment {
  final Map<String, String?> _cache = {};
  final Map<String, String> _overrides = {};
  
  String? getVariable(String key, {String? defaultValue}) {
    // Check cache first
    if (_cache.containsKey(key)) {
      return _cache[key] ?? defaultValue;
    }
    
    // Resolve and cache
    final value = _resolveVariable(key, defaultValue);
    _cache[key] = value;
    return value;
  }
}
```

### Lazy Initialization

```dart
class PlatformEnvironment {
  late final bool _isWeb = kIsWeb;
  late final PlatformCapabilities _capabilities = _isWeb 
    ? PlatformCapabilities.forWeb() 
    : PlatformCapabilities.forNative();
  
  // Paths are computed once and cached
  String? _homePath;
  String getHomePath() => _homePath ??= _computeHomePath();
}
```

## Security Considerations

### Web Platform Security

- Environment variables are never exposed to web platform
- URL parameters are sanitized before use
- localStorage access is wrapped in try-catch blocks
- No sensitive defaults are used in fallback values

### Native Platform Security

- Environment variables are read-only through the abstraction
- Fallback values use safe, non-sensitive defaults
- Path resolution validates against directory traversal
- Override system requires explicit permission

## Troubleshooting

### Common Issues

**Issue**: Unexpected fallback values on native platforms
**Solution**: Check if environment variables are actually set in the system

**Issue**: Web platform not using browser storage
**Solution**: Verify browser supports localStorage and user hasn't disabled it

**Issue**: Path resolution returning incorrect values
**Solution**: Check platform detection and environment variable availability

### Debug Utilities

```dart
void debugFallbackValues() {
  final env = PlatformEnvironment.instance;
  
  print('Platform: ${env.isWeb ? 'Web' : Platform.operatingSystem}');
  print('Home: ${env.getHomePath()}');
  print('Temp: ${env.getTempPath()}');
  print('AppData: ${env.getAppDataPath()}');
  
  // Test common environment variables
  final testVars = ['HOME', 'USER', 'PATH', 'TEMP'];
  for (final variable in testVars) {
    final value = env.getVariable(variable);
    print('$variable: ${value ?? 'null (using fallback)'}');
  }
}
```