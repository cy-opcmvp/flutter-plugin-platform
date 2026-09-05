// 覆盖场景清单（剪贴板 + 已知目录接口，S1 批B）：
// 1. UnsupportedClipboard：三个写入方法均抛 capability.unsupported，
//    details 携带 capability/platform/action。
// 2. clipboardLockedFailure：code == clipboard.locked 且 details.reason
//    优先、补充上下文可叠加。
// 3. UnsupportedKnownFolders：pictures/documents 恒返回 null。
// （接口包零 dart:io/dart:ffi 边界扫描见 plugin_storage_test.dart，目录级
//  扫描自动覆盖本批新增的 clipboard.dart / known_folders.dart。）
library;

import 'dart:typed_data';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('UnsupportedClipboard', () {
    const UnsupportedClipboard clipboard = UnsupportedClipboard('web');

    test('writeText 抛 capability.unsupported 且 details 完整', () async {
      await expectLater(
        clipboard.writeText('hello'),
        throwsA(
          isA<PluginFailure>()
              .having((PluginFailure f) => f.code, 'code',
                  'capability.unsupported')
              .having(
                (PluginFailure f) => f.details,
                'details',
                <String, Object?>{
                  'capability': 'clipboard',
                  'platform': 'web',
                  'action': 'writeText',
                },
              ),
        ),
      );
    });

    test('writeImage 抛 capability.unsupported', () async {
      await expectLater(
        clipboard.writeImage(Uint8List.fromList(<int>[1, 2, 3])),
        throwsA(
          isA<PluginFailure>().having(
            (PluginFailure f) => f.details['action'],
            'details.action',
            'writeImage',
          ),
        ),
      );
    });

    test('writeFiles 抛 capability.unsupported', () async {
      await expectLater(
        clipboard.writeFiles(<String>['C:/a.png']),
        throwsA(
          isA<PluginFailure>().having(
            (PluginFailure f) => f.details['action'],
            'details.action',
            'writeFiles',
          ),
        ),
      );
    });
  });

  group('clipboardLockedFailure', () {
    test('code 为 clipboard.locked 且 details.reason 优先', () {
      final PluginFailure failure = clipboardLockedFailure(
        'openFailed',
        'OpenClipboard 失败',
      );
      expect(failure.code, 'clipboard.locked');
      expect(failure.details['reason'], 'openFailed');
    });

    test('补充上下文可叠加且不覆盖 reason', () {
      final PluginFailure failure = clipboardLockedFailure(
        'setDataFailed',
        'SetClipboardData 失败',
        <String, Object?>{'format': 17},
      );
      expect(failure.code, 'clipboard.locked');
      expect(failure.details['reason'], 'setDataFailed');
      expect(failure.details['format'], 17);
    });
  });

  group('UnsupportedKnownFolders', () {
    const UnsupportedKnownFolders folders = UnsupportedKnownFolders('web');

    test('pictures/documents 恒返回 null', () {
      expect(folders.pictures(), isNull);
      expect(folders.documents(), isNull);
    });
  });
}
