// 覆盖场景清单（F4-04 适配：screenCapture 已升级为 GDI 真实现，其测试
// 见 gdi_capture_test.dart；本文件保留系统路径 stub 场景）：
// 1. windowsSystemPaths 抛 capability.unsupported，
//    details 携带 capability='systemPaths' 与 platform='windows'。
library;

import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('windows 端 stub', () {
    test('systemPaths 抛出携带本端标签的 unsupported 失败', () {
      expect(
        () => windowsSystemPaths.hostDataRoot(),
        throwsA(
          isA<PluginFailure>()
              .having((f) => f.code, 'code', 'capability.unsupported')
              .having(
                (f) => f.details['capability'],
                'capability',
                'systemPaths',
              )
              .having((f) => f.details['platform'], 'platform', 'windows'),
        ),
      );
    });
  });
}
