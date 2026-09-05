// 覆盖场景清单（计划 F3-04 Step 2，六端同构，仅平台标签不同）：
// 1. macosScreenCapture.captureRegion 返回 capability.unsupported，
//    details 携带 capability='screenCapture' 与 platform='macos'。
// 2. macosSystemPaths 抛 capability.unsupported，
//    details 携带 capability='systemPaths' 与 platform='macos'。
library;

import 'package:platform_capabilities_macos/platform_capabilities_macos.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('macos 端 stub', () {
    test('screenCapture 返回携带本端标签的 unsupported 失败', () async {
      final result = await macosScreenCapture.captureRegion(
        Rect(left: 0, top: 0, width: 1, height: 1),
      );

      expect(result.succeeded, isFalse);
      expect(result.failure?.code, 'capability.unsupported');
      expect(result.failure?.details['capability'], 'screenCapture');
      expect(result.failure?.details['platform'], 'macos');
    });

    test('systemPaths 抛出携带本端标签的 unsupported 失败', () {
      expect(
        () => macosSystemPaths.hostDataRoot(),
        throwsA(
          isA<PluginFailure>()
              .having((f) => f.code, 'code', 'capability.unsupported')
              .having(
                (f) => f.details['capability'],
                'capability',
                'systemPaths',
              )
              .having((f) => f.details['platform'], 'platform', 'macos'),
        ),
      );
    });
  });
}
