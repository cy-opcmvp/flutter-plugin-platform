import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:plugin_platform/core/services/desktop_pet_manager.dart';
import 'package:plugin_platform/core/models/platform_models.dart';

void main() {
  group('Desktop Pet Property Tests', () {
    // **Feature: web-platform-compatibility, Property 10: Desktop pet UI controls are hidden on web platform**
    test('Property 10: Desktop pet UI controls are hidden on web platform', () {
      if (kIsWeb) {
        // On web platform, desktop pet should not be supported
        expect(DesktopPetManager.isSupported(), isFalse);
      }
      // Note: On desktop platforms, this would be true, but we can't test that in web environment
    });

    // **Feature: web-platform-compatibility, Property 11: Desktop pet initialization is skipped on web platform**
    test(
      'Property 11: Desktop pet initialization is skipped on web platform',
      () async {
        final manager = DesktopPetManager();

        if (kIsWeb) {
          // On web platform, initialization should be skipped (no-op)
          expect(() => manager.initialize(), returnsNormally);

          // After initialization, static isSupported should still be false
          await manager.initialize();
          expect(DesktopPetManager.isSupported(), isFalse);
        }
      },
    );

    // **Feature: web-platform-compatibility, Property 12: Desktop pet unavailability does not cause errors**
    test(
      'Property 12: Desktop pet unavailability does not cause errors',
      () async {
        final manager = DesktopPetManager();

        // These operations should not throw exceptions regardless of platform support
        expect(() => manager.initialize(), returnsNormally);
        expect(() => DesktopPetManager.isSupported(), returnsNormally);
        expect(() => manager.enableDesktopPetMode(), returnsNormally);
        expect(() => manager.disableDesktopPetMode(), returnsNormally);

        // Initialize and then enable/disable should work without errors
        await manager.initialize();
        expect(() => manager.enableDesktopPetMode(), returnsNormally);
        expect(() => manager.disableDesktopPetMode(), returnsNormally);
      },
    );

    // **Feature: web-platform-compatibility, Property 17: Platform capability queries return accurate information**
    test(
      'Property 17: Platform capability queries return accurate information',
      () {
        // Test web platform capabilities
        if (kIsWeb) {
          final webCapabilities = PlatformCapabilities.forWeb();

          expect(webCapabilities.supportsEnvironmentVariables, isFalse);
          expect(webCapabilities.supportsFileSystem, isFalse);
          expect(webCapabilities.supportsSteamIntegration, isFalse);
          expect(webCapabilities.supportsNativeProcesses, isFalse);
          expect(webCapabilities.supportsDesktopPet, isFalse);
          expect(webCapabilities.supportsAlwaysOnTop, isFalse);
          expect(webCapabilities.supportsSystemTray, isFalse);
        }

        // Test native platform capabilities
        final nativeCapabilities = PlatformCapabilities.forNative();

        expect(nativeCapabilities.supportsEnvironmentVariables, isTrue);
        expect(nativeCapabilities.supportsFileSystem, isTrue);
        expect(nativeCapabilities.supportsSteamIntegration, isTrue);
        expect(nativeCapabilities.supportsNativeProcesses, isTrue);
        expect(nativeCapabilities.supportsDesktopPet, isTrue);
        expect(nativeCapabilities.supportsAlwaysOnTop, isTrue);
        expect(nativeCapabilities.supportsSystemTray, isTrue);
      },
    );
  });
}
