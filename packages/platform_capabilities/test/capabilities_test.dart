// 覆盖场景清单（计划 F3-04 Step 2，相似断言合并）：
// 1. UnsupportedScreenCapture.captureRegion 返回结构化失败：
//    code == capability.unsupported，details 含 capability='screenCapture'
//    与注入的 platform 标签。
// 2. UnsupportedSystemPaths 两个方法均抛同一结构化失败：
//    capability='systemPaths' + platform 标签。
// 3. ResolvedSystemPaths：hostDataRoot 返回注入根目录；
//    pluginDataDir(PluginId) 返回 '<root>/<id>'（id 已由 PluginId 验证，
//    测试确认拼接结果、无路径穿越空间）。
// 4. CaptureResult 语义：success 携带字节且 succeeded；failure 携带
//    PluginFailure 且不成功；success 拒绝空字节。
// 5. Rect 负宽高拒绝。
library;

import 'dart:typed_data';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('UnsupportedScreenCapture', () {
    test('captureRegion 返回 capability.unsupported 失败值', () async {
      const capture = UnsupportedScreenCapture('test-platform');

      final result = await capture.captureRegion(
        Rect(left: 0, top: 0, width: 10, height: 10),
      );

      expect(result.succeeded, isFalse);
      expect(result.failure?.code, 'capability.unsupported');
      expect(result.failure?.details['capability'], 'screenCapture');
      expect(result.failure?.details['platform'], 'test-platform');
    });
  });

  group('UnsupportedSystemPaths', () {
    test('hostDataRoot / pluginDataDir 抛 capability.unsupported', () {
      const paths = UnsupportedSystemPaths('test-platform');
      final id = PluginId.parse('dev.example.tool');

      expect(
        () => paths.hostDataRoot(),
        throwsA(
          isA<PluginFailure>()
              .having((f) => f.code, 'code', 'capability.unsupported')
              .having(
                (f) => f.details['capability'],
                'capability',
                'systemPaths',
              )
              .having(
                (f) => f.details['platform'],
                'platform',
                'test-platform',
              ),
        ),
      );
      expect(() => paths.pluginDataDir(id), throwsA(isA<PluginFailure>()));
    });
  });

  group('ResolvedSystemPaths', () {
    test('hostDataRoot 与 pluginDataDir 拼接结果', () {
      const paths = ResolvedSystemPaths(hostDataRoot: '/var/lib/host');
      final id = PluginId.parse('dev.example.tool');

      expect(paths.hostDataRoot(), '/var/lib/host');
      expect(paths.pluginDataDir(id), '/var/lib/host/dev.example.tool');
    });
  });

  group('CaptureResult', () {
    test('success / failure 语义与空字节拒绝', () {
      final success = CaptureResult.success(Uint8List.fromList(<int>[1, 2]));
      final failure = CaptureResult.failure(
        PluginFailure('capability.unsupported', '不支持'),
      );

      expect(success.succeeded, isTrue);
      expect(success.bytes, isNotEmpty);
      expect(success.failure, isNull);
      expect(failure.succeeded, isFalse);
      expect(failure.failure?.code, 'capability.unsupported');
      expect(() => CaptureResult.success(Uint8List(0)), throwsArgumentError);
    });
  });

  group('Rect', () {
    test('负宽高拒绝', () {
      expect(
        () => Rect(left: 0, top: 0, width: -1, height: 10),
        throwsArgumentError,
      );
      expect(
        () => Rect(left: 0, top: 0, width: 10, height: -1),
        throwsArgumentError,
      );
    });
  });
}
