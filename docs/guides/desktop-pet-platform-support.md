# Desktop Pet Platform Support Guide

## Overview

The desktop pet feature provides an interactive desktop companion widget that can display on the user's desktop. This feature has different levels of support across platforms due to technical limitations and platform capabilities.

## Platform Support Matrix

### Full Support ✅

**Windows (Desktop)**
- Desktop pet widget: ✅ Fully supported
- Always on top: ✅ Supported
- System tray integration: ✅ Supported
- Window management: ✅ Full control
- Transparency effects: ✅ Supported
- Click-through mode: ✅ Supported
- Multi-monitor support: ✅ Supported

**macOS (Desktop)**
- Desktop pet widget: ✅ Fully supported
- Always on top: ✅ Supported
- System tray integration: ✅ Supported (menu bar)
- Window management: ✅ Full control
- Transparency effects: ✅ Supported
- Click-through mode: ✅ Supported
- Multi-monitor support: ✅ Supported

**Linux (Desktop)**
- Desktop pet widget: ✅ Fully supported
- Always on top: ✅ Supported
- System tray integration: ✅ Supported (varies by DE)
- Window management: ✅ Full control
- Transparency effects: ✅ Supported (compositor dependent)
- Click-through mode: ✅ Supported
- Multi-monitor support: ✅ Supported

### Not Supported ❌

**Web Platform**
- Desktop pet widget: ❌ Not available
- Always on top: ❌ Browser security limitation
- System tray integration: ❌ Not available in browsers
- Window management: ❌ Browser sandbox restriction
- Transparency effects: ❌ Limited browser support
- Click-through mode: ❌ Browser security limitation
- Multi-monitor support: ❌ Browser API limitation

**iOS**
- Desktop pet widget: ❌ No desktop environment
- Always on top: ❌ iOS app model limitation
- System tray integration: ❌ Not available
- Window management: ❌ Single app focus model

**Android**
- Desktop pet widget: ❌ No desktop environment
- Always on top: ❌ Limited overlay permissions
- System tray integration: ❌ Different notification model
- Window management: ❌ Activity-based model

## Technical Implementation Details

### Platform Detection

The desktop pet system uses multiple layers of platform detection:

```dart
class DesktopPetManager {
  /// Primary platform support check
  static bool isSupported() {
    // Web platform check first (compile-time constant)
    if (kIsWeb) return false;
    
    // Mobile platform check
    if (Platform.isIOS || Platform.isAndroid) return false;
    
    // Desktop platform check
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// Runtime capability check
  bool get hasWindowManagement {
    return isSupported() && _checkWindowManagerCapabilities();
  }
  
  /// System tray availability
  bool get hasSystemTray {
    if (!isSupported()) return false;
    
    // Platform-specific system tray checks
    if (Platform.isWindows) return true;
    if (Platform.isMacOS) return true;
    if (Platform.isLinux) return _checkLinuxSystemTray();
    
    return false;
  }
}
```

### Web Platform Behavior

On web platform, desktop pet functionality is completely disabled:

#### UI Behavior
- Desktop pet button is hidden from the main interface
- Desktop pet menu items are not displayed
- Desktop pet settings are not accessible
- Navigation to desktop pet screens shows fallback message

#### API Behavior
```dart
// All desktop pet APIs return safe fallback values on web
class DesktopPetManager {
  Future<void> initialize() async {
    if (!isSupported()) {
      // Graceful no-op - no errors thrown
      return;
    }
    // Native initialization only
  }
  
  Future<bool> showPet() async {
    if (!isSupported()) return false;
    // Native implementation
  }
  
  Future<void> hidePet() async {
    if (!isSupported()) return;
    // Native implementation
  }
}
```

#### Error Handling
```dart
// Web-safe error handling
try {
  await desktopPetManager.initialize();
} catch (e) {
  // This should never happen on web due to early returns
  logger.warning('Desktop pet initialization failed: $e');
}
```

### Native Platform Implementation

#### Windows-Specific Features
```dart
class WindowsDesktopPet {
  // Windows-specific window management
  Future<void> setAlwaysOnTop(bool enabled) async {
    if (!Platform.isWindows) return;
    // Windows API calls
  }
  
  // Windows system tray integration
  Future<void> createSystemTrayIcon() async {
    if (!Platform.isWindows) return;
    // Windows system tray implementation
  }
}
```

#### macOS-Specific Features
```dart
class MacOSDesktopPet {
  // macOS menu bar integration
  Future<void> createMenuBarItem() async {
    if (!Platform.isMacOS) return;
    // macOS menu bar implementation
  }
  
  // macOS window level management
  Future<void> setWindowLevel(int level) async {
    if (!Platform.isMacOS) return;
    // macOS window level API
  }
}
```

#### Linux-Specific Features
```dart
class LinuxDesktopPet {
  // Linux desktop environment detection
  String? detectDesktopEnvironment() {
    if (!Platform.isLinux) return null;
    
    final env = PlatformEnvironment.instance;
    return env.getVariable('XDG_CURRENT_DESKTOP') ??
           env.getVariable('DESKTOP_SESSION');
  }
  
  // Linux system tray (varies by DE)
  bool get supportsSystemTray {
    final de = detectDesktopEnvironment()?.toLowerCase();
    return de != null && (
      de.contains('gnome') ||
      de.contains('kde') ||
      de.contains('xfce') ||
      de.contains('mate')
    );
  }
}
```

## User Experience by Platform

### Desktop Platforms (Windows, macOS, Linux)

**Initial Setup**
1. Desktop pet button appears in main interface
2. User can click to access desktop pet settings
3. Desktop pet can be enabled/disabled
4. Customization options are available

**Runtime Behavior**
1. Desktop pet appears as overlay on desktop
2. Pet can be moved around the screen
3. Pet responds to user interactions
4. Pet can be minimized to system tray

**Features Available**
- Animated pet sprites
- Interactive behaviors
- Customizable appearance
- Always-on-top mode
- Click-through mode
- System tray integration
- Multi-monitor support

### Web Platform

**Initial Setup**
1. Desktop pet button is hidden
2. Desktop pet menu items not shown
3. Settings page excludes desktop pet options
4. No desktop pet-related notifications

**Runtime Behavior**
1. Application functions normally without desktop pet
2. No errors or warnings about missing features
3. Core plugin functionality remains available
4. Alternative engagement features may be provided

**User Communication**
- Clear documentation about platform limitations
- Alternative features highlighted for web users
- No confusing UI elements that suggest unavailable features

### Mobile Platforms (iOS, Android)

**Behavior**
- Same as web platform - desktop pet features hidden
- Mobile-optimized interface without desktop pet options
- Focus on mobile-appropriate plugin features

## Development Guidelines

### Adding Desktop Pet Features

When adding new desktop pet functionality:

1. **Always Check Platform Support**
   ```dart
   if (!DesktopPetManager.isSupported()) {
     return; // or provide alternative
   }
   ```

2. **Provide Web-Safe Alternatives**
   ```dart
   Widget buildPetControls() {
     if (DesktopPetManager.isSupported()) {
       return DesktopPetControls();
     } else {
       return WebAlternativeControls(); // or SizedBox.shrink()
     }
   }
   ```

3. **Use Conditional Imports Carefully**
   ```dart
   // Avoid direct dart:io imports in shared code
   import 'desktop_pet_stub.dart' 
     if (dart.library.io) 'desktop_pet_io.dart'
     if (dart.library.html) 'desktop_pet_web.dart';
   ```

### Testing Desktop Pet Features

#### Unit Tests
```dart
group('Desktop Pet Platform Support', () {
  test('should be supported on desktop platforms', () {
    // Mock platform detection
    expect(DesktopPetManager.isSupported(), isTrue);
  });
  
  test('should not be supported on web platform', () {
    // Mock web platform
    expect(DesktopPetManager.isSupported(), isFalse);
  });
});
```

#### Integration Tests
```dart
testWidgets('desktop pet UI should be hidden on web', (tester) async {
  // Simulate web platform
  await tester.pumpWidget(MyApp());
  
  // Verify desktop pet button is not present
  expect(find.byKey(Key('desktop_pet_button')), findsNothing);
});
```

### Error Handling Best Practices

1. **Graceful Degradation**
   ```dart
   Future<void> initializeDesktopPet() async {
     try {
       if (DesktopPetManager.isSupported()) {
         await desktopPetManager.initialize();
       }
     } catch (e) {
       logger.warning('Desktop pet initialization failed: $e');
       // Continue without desktop pet
     }
   }
   ```

2. **User-Friendly Messages**
   ```dart
   String getDesktopPetStatusMessage() {
     if (!DesktopPetManager.isSupported()) {
       if (kIsWeb) {
         return 'Desktop pet is not available in web browsers';
       } else {
         return 'Desktop pet is only available on desktop platforms';
       }
     }
     return 'Desktop pet is available';
   }
   ```

## Troubleshooting

### Common Issues

**Issue**: Desktop pet button appears on web platform
**Solution**: Check UI conditional rendering logic

**Issue**: Application crashes when accessing desktop pet on web
**Solution**: Verify platform checks are in place before desktop pet API calls

**Issue**: Desktop pet not working on Linux
**Solution**: Check desktop environment compatibility and system tray support

### Debugging Platform Detection

```dart
void debugPlatformSupport() {
  print('Platform: ${Platform.operatingSystem}');
  print('Is Web: $kIsWeb');
  print('Desktop Pet Supported: ${DesktopPetManager.isSupported()}');
  print('System Tray Available: ${desktopPetManager.hasSystemTray}');
  print('Window Management: ${desktopPetManager.hasWindowManagement}');
}
```

### Performance Considerations

- Desktop pet features are only initialized when supported
- Web platform avoids loading desktop pet assets
- Platform detection uses compile-time constants where possible
- Lazy loading of platform-specific implementations

## Future Enhancements

### Planned Improvements

1. **Enhanced Web Experience**
   - Web-based pet alternatives using CSS animations
   - Browser notification integration
   - Progressive Web App features

2. **Mobile Platform Support**
   - Widget-based pets for iOS/Android home screens
   - Notification-based interactions
   - Mobile-optimized pet behaviors

3. **Cross-Platform Synchronization**
   - Pet state sync across devices
   - Cloud-based pet progression
   - Multi-device pet interactions

### Experimental Features

- **Browser Extension Integration**: Desktop pet functionality through browser extensions
- **WebAssembly Performance**: Enhanced web pet performance using WASM
- **AR/VR Support**: Immersive pet experiences on supported platforms

## Support and Resources

For desktop pet platform support issues:

1. Check platform compatibility matrix above
2. Verify platform detection is working correctly
3. Review error logs for platform-specific issues
4. Test on target platforms during development
5. Consult platform-specific documentation for advanced features

For feature requests or platform-specific enhancements, file an issue with:
- Target platform details
- Specific feature requirements
- Use case description
- Technical constraints or considerations