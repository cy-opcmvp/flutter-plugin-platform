/// F4-04 Windows GDI 截图真机烟囱与纯逻辑分支。
///
/// 场景清单：
/// 1. 主屏全屏捕获（请求超大矩形，实现裁剪到主屏边界）→ PNG 魔数、
///    IHDR 宽高 > 0、字节量 > 0；产物落盘临时 PNG，路径打印到 stderr
///    供人工查看（文件保留不删除）；
/// 2. 零宽/零高 Rect → `capture.failed`（reason=noScreen），纯逻辑分支
///    不触碰 GDI。
@Timeout(Duration(seconds: 60))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:test/test.dart';

void main() {
  group('WindowsScreenCapture（真机烟囱）', () {
    test('主屏全屏捕获产出有效 PNG 并落盘供人工查验', () async {
      // 超大请求矩形经主屏边界裁剪等价于全屏捕获。
      final CaptureResult result = await windowsScreenCapture.captureRegion(
        Rect(left: 0, top: 0, width: 100000, height: 100000),
      );

      expect(result.succeeded, isTrue, reason: '捕获失败: ${result.failure}');
      final Uint8List bytes = result.bytes!;

      // PNG 魔数 \x89PNG\r\n\x1a\n。
      expect(bytes.sublist(0, 8), <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);

      // IHDR 宽高为 big-endian Uint32（字节 16..24）。
      final ByteData ihdr = ByteData.sublistView(bytes, 16, 24);
      final int width = ihdr.getUint32(0);
      final int height = ihdr.getUint32(4);
      expect(width, greaterThan(0));
      expect(height, greaterThan(0));
      expect(bytes.length, greaterThan(0));

      final Directory tempDir = await Directory.systemTemp.createTemp(
        'win_capture_smoke',
      );
      final File pngFile = File('${tempDir.path}/screen.png');
      await pngFile.writeAsBytes(bytes);
      // 保留临时文件供人工查验；路径与证据打印到 stderr。
      stderr.writeln(
        '烟囱捕获证据：width=$width height=$height '
        'bytes=${bytes.length} path=${pngFile.path}',
      );
    });

    test('零宽或零高区域返回结构化失败（纯逻辑分支，不触碰 GDI）', () async {
      final List<Rect> invalidRegions = <Rect>[
        Rect(left: 0, top: 0, width: 0, height: 10),
        Rect(left: 0, top: 0, width: 10, height: 0),
      ];

      for (final Rect region in invalidRegions) {
        final CaptureResult result = await windowsScreenCapture.captureRegion(
          region,
        );
        expect(result.succeeded, isFalse);
        expect(result.failure, isNotNull);
        expect(result.failure!.code, 'capture.failed');
        expect(result.failure!.details['reason'], 'noScreen');
      }
    });
  });
}
