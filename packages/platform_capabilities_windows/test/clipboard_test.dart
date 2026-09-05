// 真机烟囱测试（本机即 Windows，直接 dart test）：
// 1. writeText → peekText 往返一致（含中文）。
// 2. writeImage → peekHeader 断言 BITMAPV5HEADER 关键字段（124 头、
//    宽高、32bpp、BI_BITFIELDS）。
// 3. writeFiles → peekPaths 往返一致。
// 4. WindowsKnownFolders：pictures/documents 返回真实绝对路径。
// 5. 并发打开失败（openFailed）：需另一进程持有剪贴板才可复现，
//    单测进程内无法确定性构造——标注跳过理由，不在本套件覆盖。
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:test/test.dart';

void main() {
  const WindowsClipboard clipboard = WindowsClipboard();

  group('writeText', () {
    test('写入后 peekText 往返一致（含中文）', () async {
      const String text = 'hello 剪贴板 123';
      await clipboard.writeText(text);
      expect(clipboard.peekText(), text);
    });

    test('覆盖写入：新值替换旧值', () async {
      await clipboard.writeText('first');
      await clipboard.writeText('second');
      expect(clipboard.peekText(), 'second');
    });
  });

  group('writeImage', () {
    test('写入后 peekHeader 断言 V5 头与宽高', () async {
      final img.Image image = img.Image(width: 7, height: 3);
      img.fillRect(image, x1: 0, y1: 0, x2: 6, y2: 2,
          color: img.ColorRgb8(30, 60, 90));
      final Uint8List png = Uint8List.fromList(img.encodePng(image));

      await clipboard.writeImage(png);

      final BitmapV5HeaderInfo? header = clipboard.peekHeader();
      expect(header, isNotNull);
      expect(header!.headerSize, 124, reason: 'BITMAPV5HEADER 固定 124 字节');
      expect(header.width, 7);
      expect(header.height, 3, reason: '正值表示自下而上行序');
      expect(header.bitCount, 32);
      expect(header.compression, 3, reason: 'BI_BITFIELDS');
    });
  });

  group('writeFiles', () {
    test('写入后 peekPaths 往返一致', () async {
      final List<String> paths = <String>[
        r'C:\Users\test\Pictures\a.png',
        r'C:\Users\test\Pictures\b.png',
      ];
      await clipboard.writeFiles(paths);
      expect(clipboard.peekPaths(), paths);
    });
  });

  group('WindowsKnownFolders', () {
    const WindowsKnownFolders folders = WindowsKnownFolders();

    test('pictures 返回真实「图片」目录', () {
      final String? path = folders.pictures();
      expect(path, isNotNull);
      expect(path!, matches(RegExp(r'^[A-Za-z]:\\')));
      expect(path.toLowerCase(), contains('pictures'));
    });

    test('documents 返回真实「文档」目录', () {
      final String? path = folders.documents();
      expect(path, isNotNull);
      expect(path!, matches(RegExp(r'^[A-Za-z]:\\')));
      expect(path.toLowerCase(), contains('documents'));
    });
  });

  test(
    '并发占用剪贴板 → clipboard.locked(openFailed)',
    skip:
        'OpenClipboard 失败需要另一进程持有剪贴板打开状态，'
        '单测进程内无法确定性构造（依赖外部时序），不在自动化套件覆盖。',
    () {},
  );
}
