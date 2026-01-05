# Platform.environment Migration Guide

## Overview

This guide helps developers migrate from direct `Platform.environment` usage to the new `PlatformEnvironment` abstraction layer. This migration is required for web platform compatibility.

## Why Migrate?

The Flutter web platform does not support `Platform.environment` access, causing runtime errors when the application runs in browsers. The `PlatformEnvironment` service provides a unified API that works across all platforms.

## Quick Migration Checklist

- [ ] Replace all `Platform.environment` calls with `PlatformEnvironment.instance`
- [ ] Add appropriate default values for environment variables
- [ ] Use path resolution methods instead of environment variable parsing
- [ ] Add platform capability checks where needed
- [ ] Test on both web and native platforms

## Common Migration Patterns

### 1. Basic Environment Variable Access

#### Before (Web Incompatible)
```dart
import 'dart:io';

String? getValue() {
  return Platform.environment['MY_VAR'];
}
```

#### After (Web Compatible)
```dart
import 'package:your_app/core/services/platform_environment.dart';

String? getValue() {
  return PlatformEnvironment.instance.getVariable('MY_VAR');
}
```

### 2. Environment Variables with Defaults

#### Before
```dart
String getConfigPath() {
  return Platform.environment['CONFIG_PATH'] ?? '/default/config';
}
```

#### After
```dart
String getConfigPath() {
  return PlatformEnvironment.instance.getVariable(
    'CONFIG_PATH',
    defaultValue: '/default/config'
  ) ?? '/default/config';
}
```

### 3. Path Resolution

#### Before
```dart
String getHomePath() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
  } else {
    return Platform.environment['HOME'] ?? '/home/user';
  }
}
```

#### After
```dart
String getHomePath() {
  return PlatformEnvironment.instance.getHomePath();
}
```

### 4. Multiple Environment Variables

#### Before
```dart
Map<String, String> getSystemInfo() {
  return {
    'home': Platform.environment['HOME'] ?? 'unknown',
    'user': Platform.environment['USER'] ?? 'unknown',
    'path': Platform.environment['PATH'] ?? 'unknown',
  };
}
```

#### After
```dart
Map<String, String> getSystemInfo() {
  final env = PlatformEnvironment.instance;
  return {
    'home': env.getVariable('HOME', defaultValue: 'unknown') ?? 'unknown',
    'user': env.getVariable('USER', defaultValue: 'unknown') ?? 'unknown',
    'path': env.getVariable('PATH', defaultValue: 'unknown') ?? 'unknown',
  };
}
```

### 5. Platform-Specific Logic

#### Before
```dart
bool isSteamEnvironment() {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return false;
  }
  return Platform.environment.containsKey('STEAM_PATH') ||
         Platform.environment.containsKey('STEAMAPPS');
}
```

#### After
```dart
bool isSteamEnvironment() {
  final env = PlatformEnvironment.instance;
  
  // Skip Steam detection on web platform
  if (env.isWeb) {
    return false;
  }
  
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return false;
  }
  
  return env.containsKey('STEAM_PATH') || env.containsKey('STEAMAPPS');
}
```

### 6. Development Environment Detection

#### Before
```dart
bool isDevelopmentMode() {
  return Platform.environment['DEVELOPMENT_MODE'] == 'true' ||
         Platform.environment['DEBUG'] == '1' ||
         Platform.environment.containsKey('FLUTTER_TEST');
}
```

#### After
```dart
bool isDevelopmentMode() {
  final env = PlatformEnvironment.instance;
  
  // On web, use alternative detection methods
  if (env.isWeb) {
    return kDebugMode || 
           Uri.base.queryParameters.containsKey('debug') ||
           Uri.base.host == 'localhost';
  }
  
  return env.getVariable('DEVELOPMENT_MODE') == 'true' ||
         env.getVariable('DEBUG') == '1' ||
         env.containsKey('FLUTTER_TEST');
}
```

## File-by-File Migration Examples

### CLI Utilities

#### Before: `lib/cli/cli_utils.dart`
```dart
Map<String, dynamic> getSystemInfo() {
  return {
    'platform': Platform.operatingSystem,
    'environment': Platform.environment,
    'home': Platform.environment['HOME'],
  };
}
```

#### After: `lib/cli/cli_utils.dart`
```dart
Map<String, dynamic> getSystemInfo() {
  final env = PlatformEnvironment.instance;
  return {
    'platform': env.isWeb ? 'web' : Platform.operatingSystem,
    'environment': env.getAllVariables(),
    'home': env.getHomePath(),
  };
}
```

### Configuration Services

#### Before: `lib/core/config/platform_config.dart`
```dart
bool _isSteamEnvironment() {
  return Platform.environment.containsKey('STEAM_PATH');
}
```

#### After: `lib/core/config/platform_config.dart`
```dart
bool _isSteamEnvironment() {
  final env = PlatformEnvironment.instance;
  
  // Steam is only available on desktop platforms
  if (env.isWeb || !_isDesktopPlatform()) {
    return false;
  }
  
  return env.containsKey('STEAM_PATH');
}

bool _isDesktopPlatform() {
  return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}
```

### Platform Adapters

#### Before: `lib/core/services/platform_adapters.dart`
```dart
String _getWindowsPath() {
  return Platform.environment['PATH'] ?? '';
}
```

#### After: `lib/core/services/platform_adapters.dart`
```dart
String _getWindowsPath() {
  return PlatformEnvironment.instance.getVariable(
    'PATH',
    defaultValue: 'C:\\Windows\\System32'
  ) ?? 'C:\\Windows\\System32';
}
```

## Testing Your Migration

### 1. Unit Tests

Create tests to verify your migration works correctly:

```dart
import 'package:test/test.dart';
import 'package:your_app/core/services/platform_environment.dart';

void main() {
  group('Platform Environment Migration', () {
    test('should handle missing environment variables gracefully', () {
      final result = PlatformEnvironment.instance.getVariable(
        'NONEXISTENT_VAR',
        defaultValue: 'fallback'
      );
      expect(result, equals('fallback'));
    });
    
    test('should return valid paths on all platforms', () {
      final homePath = PlatformEnvironment.instance.getHomePath();
      expect(homePath, isNotNull);
      expect(homePath, isNotEmpty);
    });
    
    test('should detect web platform correctly', () {
      final isWeb = PlatformEnvironment.instance.isWeb;
      expect(isWeb, equals(kIsWeb));
    });
  });
}
```

### 2. Integration Tests

Test your application on different platforms:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Platform Compatibility Integration Tests', () {
    testWidgets('app should start without errors on web', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Verify app loaded successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('environment-dependent features should work', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test that features requiring environment variables work
      // This should not throw exceptions on any platform
    });
  });
}
```

## Common Pitfalls and Solutions

### 1. Forgetting Platform Checks

**Problem**: Code assumes desktop platform capabilities on web
```dart
// Bad - will fail on web
if (Platform.isWindows) {
  // Desktop-specific logic
}
```

**Solution**: Always check web platform first
```dart
// Good - web-safe
if (!kIsWeb && Platform.isWindows) {
  // Desktop-specific logic
}
```

### 2. Not Providing Defaults

**Problem**: Null values when environment variables are missing
```dart
// Bad - can return null on web
String? path = PlatformEnvironment.instance.getVariable('MY_PATH');
```

**Solution**: Always provide sensible defaults
```dart
// Good - always returns a value
String path = PlatformEnvironment.instance.getVariable(
  'MY_PATH',
  defaultValue: '/default/path'
) ?? '/default/path';
```

### 3. Importing dart:io in Web-Compiled Code

**Problem**: Desktop pet or platform-specific code imports dart:io
```dart
// Bad - will break web compilation
import 'dart:io';

class DesktopPetManager {
  void initialize() {
    if (Platform.isWindows) { /* ... */ }
  }
}
```

**Solution**: Use conditional platform detection
```dart
// Good - web-safe
import 'package:flutter/foundation.dart';

class DesktopPetManager {
  void initialize() {
    if (!kIsWeb && Platform.isWindows) { /* ... */ }
  }
  
  static bool isSupported() {
    return !kIsWeb && _isDesktopPlatform();
  }
}
```

## Validation Checklist

After migration, verify:

- [ ] Application starts successfully on web platform
- [ ] No `Platform.environment` calls remain in web-compiled code
- [ ] All environment variable access has appropriate defaults
- [ ] Desktop pet features are properly disabled on web
- [ ] Path resolution works on all platforms
- [ ] Steam detection is skipped on web platform
- [ ] Development mode detection works on web
- [ ] Unit tests pass on all platforms
- [ ] Integration tests pass on web and native platforms

## Performance Impact

The migration should have minimal performance impact:

- **Positive**: Environment variable caching reduces system calls
- **Positive**: Lazy initialization of platform-specific features
- **Neutral**: Abstraction layer adds minimal overhead
- **Positive**: Web platform avoids unnecessary platform checks

## Rollback Plan

If issues arise, you can temporarily rollback by:

1. Keeping the old code in comments during migration
2. Using feature flags to switch between old and new implementations
3. Gradual migration - migrate one service at a time

```dart
// Feature flag approach
String getEnvironmentVariable(String key) {
  if (useNewPlatformEnvironment) {
    return PlatformEnvironment.instance.getVariable(key);
  } else {
    // Old implementation (web-incompatible)
    return Platform.environment[key];
  }
}
```

## Getting Help

If you encounter issues during migration:

1. Check the web platform compatibility documentation
2. Review the property-based tests for expected behavior
3. Test on both web and native platforms
4. File an issue with specific error messages and platform details

## Next Steps

After completing the migration:

1. Remove any commented-out old code
2. Update your CI/CD pipeline to test web platform
3. Consider adding web-specific features
4. Document any platform-specific behavior for your team