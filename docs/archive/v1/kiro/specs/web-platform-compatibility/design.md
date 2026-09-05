# Design Document

## Overview

This design implements a platform-aware environment variable access layer and desktop pet functionality management that resolves web compatibility issues caused by `Platform.environment` usage and desktop-specific features. The solution introduces a centralized `PlatformEnvironment` service that abstracts environment variable access, and updates the `DesktopPetManager` to be web-compatible. On web platforms, environment variables return safe defaults and desktop pet functionality is gracefully disabled; on native platforms, full functionality is maintained. This approach ensures backward compatibility while enabling web deployment.

## Architecture

The architecture follows a layered approach:

1. **Platform Detection Layer**: Uses Flutter's `kIsWeb` constant to detect the runtime platform
2. **Environment Abstraction Layer**: `PlatformEnvironment` service provides unified API for environment access
3. **Consumer Layer**: Existing services consume environment data through the abstraction layer
4. **Fallback Strategy**: Each environment variable access includes sensible defaults

```
┌─────────────────────────────────────┐
│     Application Services            │
│  (PlatformCore, CLI, Adapters)      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   PlatformEnvironment Service       │
│   (Abstraction Layer)               │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌─────────────┐  ┌──────────────┐
│  Web Mode   │  │ Native Mode  │
│  (Defaults) │  │ (Platform.*) │
└─────────────┘  └──────────────┘
```

## Components and Interfaces

### PlatformEnvironment Service

```dart
class PlatformEnvironment {
  // Singleton instance
  static final PlatformEnvironment instance = PlatformEnvironment._();
  
  // Check if running on web
  bool get isWeb;
  
  // Get environment variable with optional default
  String? getVariable(String key, {String? defaultValue});
  
  // Get all environment variables (empty map on web)
  Map<String, String> getAllVariables();
  
  // Check if variable exists
  bool containsKey(String key);
  
  // Platform-specific path resolution
  String getHomePath();
  String getDocumentsPath();
  String getTempPath();
  String getAppDataPath();
}
```

### Modified Services

Services that currently use `Platform.environment` will be updated to use `PlatformEnvironment`:

- `PlatformConfig`: Steam environment detection
- `CLIUtils`: System information gathering
- `DevelopmentModeManager`: Development environment detection
- `EnvironmentSupportSystem`: Environment variable parsing
- `PlatformAdapters`: Path and environment configuration
- `PlatformCore`: Platform capability detection
- `PlatformAPIAbstraction`: Path resolution

### Desktop Pet Services

Services related to desktop pet functionality will be updated for web compatibility:

- `DesktopPetManager`: Core desktop pet management with web-safe initialization
- `MainPlatformScreen`: UI controls that conditionally show desktop pet features
- `DesktopPetWidget`: Widget that gracefully handles platform limitations
- `DesktopPetScreen`: Screen that provides appropriate fallbacks for web platform

## Data Models

### EnvironmentVariable

```dart
class EnvironmentVariable {
  final String key;
  final String? value;
  final String defaultValue;
  final bool isAvailable;
  
  EnvironmentVariable({
    required this.key,
    this.value,
    required this.defaultValue,
  }) : isAvailable = value != null;
}
```

### PlatformCapabilities

```dart
class PlatformCapabilities {
  final bool supportsEnvironmentVariables;
  final bool supportsFileSystem;
  final bool supportsSteamIntegration;
  final bool supportsNativeProcesses;
  final bool supportsDesktopPet;
  final bool supportsAlwaysOnTop;
  final bool supportsSystemTray;
  
  factory PlatformCapabilities.forWeb() {
    return PlatformCapabilities(
      supportsEnvironmentVariables: false,
      supportsFileSystem: false,
      supportsSteamIntegration: false,
      supportsNativeProcesses: false,
      supportsDesktopPet: false,
      supportsAlwaysOnTop: false,
      supportsSystemTray: false,
    );
  }
  
  factory PlatformCapabilities.forNative() {
    return PlatformCapabilities(
      supportsEnvironmentVariables: true,
      supportsFileSystem: true,
      supportsSteamIntegration: true,
      supportsNativeProcesses: true,
      supportsDesktopPet: true,
      supportsAlwaysOnTop: true,
      supportsSystemTray: true,
    );
  }
}
```

### DesktopPetManager (Web-Compatible)

```dart
class DesktopPetManager {
  // Use conditional imports or platform detection instead of direct dart:io
  bool get isSupported => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  Future<void> initialize() async {
    if (!isSupported) {
      // Graceful no-op on unsupported platforms
      return;
    }
    // Native initialization logic
  }
  
  static bool isSupported() {
    return !kIsWeb && _isDesktopPlatform();
  }
  
  static bool _isDesktopPlatform() {
    // Use kIsWeb check first to avoid dart:io on web
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Web platform environment access never throws exceptions

*For any* environment variable key, when the platform is web, calling `PlatformEnvironment.getVariable(key)` should return either null or a default value without throwing an exception

**Validates: Requirements 1.1, 2.2**

### Property 2: Web platform uses default values

*For any* environment variable key, when the platform is web, calling `PlatformEnvironment.getVariable(key)` should return the provided default value or null, never attempting to access `Platform.environment`

**Validates: Requirements 1.2**

### Property 3: Native platform returns actual environment values

*For any* environment variable that exists in the native system environment, when the platform is native, calling `PlatformEnvironment.getVariable(key)` should return the actual system environment value

**Validates: Requirements 1.4, 2.3**

### Property 4: Fallback values are always provided

*For any* environment variable access with a specified default value, when the variable is unavailable or the platform doesn't support environment variables, the returned value should be the non-null default value

**Validates: Requirements 2.4**

### Property 5: Platform detection is consistent

*For any* sequence of calls to `PlatformEnvironment.isWeb` within a single application execution, all calls should return the same boolean value

**Validates: Requirements 2.2, 2.3**

### Property 6: Steam detection only runs on desktop platforms

*For any* platform type, Steam environment variable checks should only execute when the platform is a native desktop platform (Windows, macOS, or Linux), not on web or mobile

**Validates: Requirements 3.1, 3.4**

### Property 7: Path resolution always returns valid paths

*For any* path type request (home, documents, temp, appData), the `PlatformEnvironment` service should return a non-null, non-empty string value that is appropriate for the current platform

**Validates: Requirements 5.1, 5.4**

### Property 8: Native platforms derive paths from environment with fallbacks

*For any* path request on native platforms, when environment variables are available, paths should be derived from them; when unavailable, safe default paths should be used

**Validates: Requirements 5.3**

### Property 9: System continues operation after feature degradation

*For any* platform-specific feature that becomes unavailable, the system should continue executing without throwing exceptions or halting

**Validates: Requirements 6.4**

### Property 10: Desktop pet UI controls are hidden on web platform

*For any* web platform instance, desktop pet UI controls should not be rendered or accessible in the user interface

**Validates: Requirements 7.1**

### Property 11: Desktop pet initialization is skipped on web platform

*For any* web platform instance, desktop pet manager initialization should be skipped without attempting to access desktop-specific APIs

**Validates: Requirements 7.2**

### Property 12: Desktop pet unavailability does not cause errors

*For any* platform where desktop pet features are unavailable, the system should continue normal operation without throwing exceptions

**Validates: Requirements 7.3**

### Property 13: Desktop platforms maintain full desktop pet functionality

*For any* desktop platform (Windows, macOS, Linux), desktop pet functionality should be fully available and operational

**Validates: Requirements 7.4**

### Property 14: Web compilation avoids dart:io in desktop pet modules

*For any* web platform compilation, desktop pet modules should not attempt to import or use dart:io APIs

**Validates: Requirements 8.1**

### Property 15: Desktop pet manager uses platform detection

*For any* platform, desktop pet manager initialization should use platform detection before accessing platform-specific APIs

**Validates: Requirements 8.2**

### Property 16: Desktop pet web access returns fallback responses

*For any* desktop pet feature access on web platform, the system should return appropriate fallback responses instead of errors

**Validates: Requirements 8.3**

### Property 17: Platform capability queries return accurate information

*For any* platform type, capability queries should return accurate information about what features are supported on that platform

**Validates: Requirements 8.4**

## Error Handling

### Web Platform Errors

- **Environment Access**: Return null or default values instead of throwing
- **File System Access**: Log warning and use browser storage APIs
- **Process Execution**: Disable features gracefully with user-friendly messages
- **Desktop Pet Access**: Return false from `isSupported()` and skip initialization
- **Platform-Specific APIs**: Check `kIsWeb` before accessing dart:io APIs

### Native Platform Errors

- **Missing Environment Variables**: Use fallback defaults from configuration
- **Invalid Paths**: Validate and sanitize before use
- **Permission Errors**: Log detailed error and attempt alternative paths

### Logging Strategy

```dart
enum LogLevel { debug, info, warning, error }

class PlatformLogger {
  void logEnvironmentAccess(String key, bool found, String? value) {
    if (kDebugMode) {
      // Detailed logging in debug mode
    } else {
      // Minimal logging in production
    }
  }
  
  void logFeatureDegradation(String feature, String reason) {
    // Always log feature unavailability
  }
}
```

## Testing Strategy

### Unit Testing

Unit tests will verify:
- `PlatformEnvironment` returns correct values for known variables on native platforms
- `PlatformEnvironment` returns defaults on web platform
- Path resolution returns valid paths for each platform
- Steam detection correctly identifies Steam environment
- Development mode detection works with and without environment variables

### Property-Based Testing

Property-based tests will use the `test` package with custom generators. Each test will run a minimum of 100 iterations.

**Testing Framework**: Dart's built-in `test` package with custom property testing utilities

Property tests will verify:
- **Property 1**: Generate random environment variable keys, verify no exceptions on web
- **Property 2**: Generate random valid environment keys, verify actual values returned on native
- **Property 3**: Generate random keys with defaults, verify non-null safe values returned
- **Property 4**: Verify `isWeb` consistency across multiple checks in same execution
- **Property 5**: Verify Steam detection only runs on desktop platforms
- **Property 6**: Generate random path requests, verify non-null responses
- **Property 7**: Test development mode detection with various platform configurations

Each property-based test will be tagged with: `**Feature: web-platform-compatibility, Property {number}: {property_text}**`

### Integration Testing

- Test full application initialization on web platform
- Verify all services work correctly with `PlatformEnvironment`
- Test graceful degradation of Steam features on non-Steam platforms
- Verify file operations work correctly on each platform

## Implementation Notes

### Migration Strategy

1. Create `PlatformEnvironment` service
2. Update one service at a time to use new abstraction
3. Test each service individually
4. Remove direct `Platform.environment` usage
5. Add deprecation warnings for any remaining direct access

### Performance Considerations

- Cache environment variable lookups to avoid repeated system calls
- Use lazy initialization for platform detection
- Minimize overhead of abstraction layer (inline simple checks)

### Web-Specific Considerations

- Use `window.localStorage` for persistent data instead of file system
- Provide clear UI feedback when features are unavailable
- Consider using URL parameters for configuration instead of environment variables
- Document which features are available on web vs native platforms
- Hide desktop pet UI controls completely on web platform
- Use `kIsWeb` constant for platform detection before importing dart:io
- Provide graceful fallbacks for all desktop-specific functionality
- Ensure compilation succeeds on web platform without conditional compilation flags
