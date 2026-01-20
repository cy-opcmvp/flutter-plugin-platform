import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:plugin_platform/core/config/platform_config.dart';
import 'package:plugin_platform/core/services/platform_environment.dart';

void main() {
  group('Platform Config Property Tests', () {
    late PlatformEnvironment platformEnvironment;

    setUp(() {
      platformEnvironment = PlatformEnvironment.instance;
      platformEnvironment.clearCache();
    });

    // **Feature: web-platform-compatibility, Property 6: Steam detection only runs on desktop platforms**
    test('Property 6: Steam detection only runs on desktop platforms', () {
      if (kIsWeb) {
        // On web platform, Steam detection should not run
        // Platform type should never be steam on web
        expect(() => PlatformConfig.currentPlatform, returnsNormally);

        // Platform should be web, not steam
        expect(PlatformConfig.currentPlatform, equals(PlatformType.web));
        expect(
          PlatformConfig.currentPlatform,
          isNot(equals(PlatformType.steam)),
        );
      }

      // The method should not throw exceptions regardless of platform
      expect(() => PlatformConfig.currentPlatform, returnsNormally);
    });

    // **Feature: web-platform-compatibility, Property 8: Native platforms derive paths from environment with fallbacks**
    test(
      'Property 8: Native platforms derive paths from environment with fallbacks',
      () {
        // Test that path resolution works with fallbacks
        final homePath = platformEnvironment.getHomePath();
        final docsPath = platformEnvironment.getDocumentsPath();
        final tempPath = platformEnvironment.getTempPath();
        final appDataPath = platformEnvironment.getAppDataPath();

        // All paths should be non-null and non-empty (fallbacks should work)
        expect(homePath, isNotNull);
        expect(homePath, isNotEmpty);
        expect(docsPath, isNotNull);
        expect(docsPath, isNotEmpty);
        expect(tempPath, isNotNull);
        expect(tempPath, isNotEmpty);
        expect(appDataPath, isNotNull);
        expect(appDataPath, isNotEmpty);

        if (!kIsWeb) {
          // On native platforms, paths should be derived from environment or use fallbacks
          // They should be reasonable file system paths
          expect(homePath.length, greaterThan(1));
          expect(docsPath.length, greaterThan(1));
          expect(tempPath.length, greaterThan(1));
          expect(appDataPath.length, greaterThan(1));
        } else {
          // On web platform, should use browser-appropriate defaults
          expect(homePath, equals('/home'));
          expect(docsPath, equals('/documents'));
          expect(tempPath, equals('/tmp'));
          expect(appDataPath, equals('/appdata'));
        }
      },
    );
  });
}
