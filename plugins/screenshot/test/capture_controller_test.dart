// 覆盖场景清单（S1 批B焦点测试：CaptureController 捕获落盘闭环）：
// 1. 成功路径：全屏请求、PNG 原样落盘、image 结果 + 落盘明细（尺寸解析）。
// 2. 失败路径：结构化透传 capture.failed（reason 原样），不触碰写文件缝。
// 3. 写文件缝异常：折算为 capture.failed / reason=saveError。
// 4. 捕获进行中 capturing 为真、重复触发被忽略、结束后复位。
// 5. 模板展开进文件名（{seq} 序号 + 扩展名按格式折算）。
// 6. 目录解析：{pictures}/{documents} 走已知目录，缺省回退插件数据目录。
// 7. 编码分派：png 原样透传；jpeg 经重编码产出非原样字节与 .jpg 扩展名。
// 8. 编码失败：折算 capture.encode_failed，不触碰写文件缝。
// 9. 自动复制分派：none 不写剪贴板；image 写原始 PNG；path 写文件路径。
// 10. 复制失败仅标记明细 failed，落盘结果不受影响。
// 11.（批C）区域闭环 save：二次捕获输入逻辑选区、走落盘 + 自动复制。
// 12.（批C）区域闭环 copy：写剪贴板、不落盘、lastRegionCopied 置位。
// 13.（批C）区域闭环取消/放弃/底图失败：状态干净或结构化透传。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:screenshot/screenshot.dart';

/// 固定 fake：恒定返回预设结果并记录调用。
final class _FakeScreenCapture implements ScreenCapture {
  _FakeScreenCapture(this.result);

  final CaptureResult result;

  int calls = 0;

  Rect? lastRegion;

  @override
  Future<CaptureResult> captureRegion(Rect region) {
    calls++;
    lastRegion = region;
    return Future<CaptureResult>.value(result);
  }
}

/// 可控时机 fake：由测试补全 Completer 推进捕获。
final class _GatedScreenCapture implements ScreenCapture {
  final Completer<CaptureResult> gate = Completer<CaptureResult>();

  @override
  Future<CaptureResult> captureRegion(Rect region) => gate.future;
}

/// 记录型剪贴板 fake：记录写入内容，[fail] 时抛结构化失败。
final class _RecordingClipboard implements Clipboard {
  int imageCalls = 0;

  int filesCalls = 0;

  Uint8List? lastImage;

  List<String>? lastPaths;

  bool fail = false;

  @override
  Future<void> writeText(String text) async {}

  @override
  Future<void> writeImage(Uint8List pngBytes) async {
    imageCalls++;
    lastImage = pngBytes;
    if (fail) {
      throw clipboardLockedFailure('openFailed', '注入的写图像失败');
    }
  }

  @override
  Future<void> writeFiles(List<String> paths) async {
    filesCalls++;
    lastPaths = paths;
    if (fail) {
      throw clipboardLockedFailure('openFailed', '注入的写文件失败');
    }
  }
}

/// 固定已知目录 fake：按构造返回预设目录（null 表示不可解析）。
final class _FixedKnownFolders implements KnownFolders {
  const _FixedKnownFolders({this.picturesDir, this.documentsDir});

  final String? picturesDir;

  final String? documentsDir;

  @override
  String? pictures() => picturesDir;

  @override
  String? documents() => documentsDir;
}

/// 1x1 透明 PNG（真实 PNG 头，供 IHDR 尺寸解析与 JPEG 重编码）。
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// 记录型写文件缝：按 `目录/文件名` 拼路径并记录入参。
final class _SavingSaver {
  Uint8List? lastBytes;

  String? lastDir;

  String? lastFilename;

  Future<String> save(Uint8List bytes, String dir, String filename) async {
    lastBytes = bytes;
    lastDir = dir;
    lastFilename = filename;
    return dir.isEmpty ? '/data/$filename' : '$dir/$filename';
  }
}

/// 测试用文件系统异常 stub（避免测试依赖 dart:io）。
final class FileSystemExceptionStub implements Exception {
  const FileSystemExceptionStub();

  @override
  String toString() => '写入失败';
}

/// 脚本化区域选择缝：恒定返回预设选区并记录入参。
final class _ScriptedRegionSelector {
  _ScriptedRegionSelector(this._region);

  final ScreenRegion? _region;

  int calls = 0;

  Uint8List? lastImage;

  ui.Rect? lastImageSize;

  Future<ScreenRegion?> select(Uint8List image, ui.Rect size) async {
    calls++;
    lastImage = image;
    lastImageSize = size;
    return _region;
  }
}

void main() {
  group('CaptureController', () {
    test('成功路径：全屏捕获、PNG 透传落盘并产出明细', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final _SavingSaver saver = _SavingSaver();
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(),
      );

      await controller.capture();

      expect(capture.calls, 1);
      expect(capture.lastRegion, kFullscreenRegion);
      expect(saver.lastBytes, same(_pngBytes));
      expect(saver.lastFilename, startsWith('screenshot-'));
      expect(saver.lastFilename, endsWith('.png'));
      expect(controller.capturing, isFalse);
      expect(controller.lastFailure, isNull);
      expect(controller.lastSavedPath, '/data/${saver.lastFilename}');
      expect(controller.lastResult, isA<ImageResultDescriptor>());
      expect(controller.lastResult!.path, controller.lastSavedPath);
      expect(controller.lastDetails, isNotNull);
      expect(controller.lastDetails!.path, controller.lastSavedPath);
      expect(controller.lastDetails!.width, 1);
      expect(controller.lastDetails!.height, 1);
      expect(controller.lastDetails!.copyKey, 'none');
    });

    test('失败路径：结构化透传 capture.failed 且不写文件', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.failure(
          PluginFailure('capture.failed', '捕获失败', <String, Object?>{
            'reason': 'noScreen',
          }),
        ),
      );
      var saveCalled = false;
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String dir, String filename) async {
          saveCalled = true;
          return '$dir/$filename';
        },
        model: ScreenshotModel(),
      );

      await controller.capture();

      expect(controller.lastFailure, isA<PluginFailure>());
      expect(controller.lastFailure!.code, 'capture.failed');
      expect(controller.lastFailure!.details['reason'], 'noScreen');
      expect(saveCalled, isFalse);
      expect(controller.lastResult, isNull);
      expect(controller.lastDetails, isNull);
      expect(controller.lastSavedPath, isNull);
    });

    test('写文件缝异常折算为 capture.failed / reason=saveError', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String dir, String filename) async {
          throw const FileSystemExceptionStub();
        },
        model: ScreenshotModel(),
      );

      await controller.capture();

      expect(controller.lastFailure!.code, 'capture.failed');
      expect(controller.lastFailure!.details['reason'], 'saveError');
      expect(controller.lastResult, isNull);
      expect(controller.lastDetails, isNull);
    });

    test('捕获进行中 capturing 为真、重复触发被忽略、结束后复位', () async {
      final _GatedScreenCapture capture = _GatedScreenCapture();
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: _SavingSaver().save,
        model: ScreenshotModel(),
      );

      final Future<void> running = controller.capture();
      expect(controller.capturing, isTrue);

      final Future<void> ignored = controller.capture();
      await ignored;

      capture.gate.complete(CaptureResult.success(_pngBytes));
      await running;

      expect(controller.capturing, isFalse);
      expect(controller.lastFailure, isNull);
      expect(controller.lastDetails, isNotNull);
      expect(
        controller.lastResult!.path,
        '/data/${controller.lastSavedPath!.split('/').last}',
      );
    });

    test('模板展开进文件名：{seq} 序号与扩展名按格式折算', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final _SavingSaver saver = _SavingSaver();
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(
          settings: ScreenshotSettings(
            filenameTemplate: 'vacation-{seq}',
            format: 'jpeg',
          ),
        ),
      );

      await controller.capture();

      expect(saver.lastFilename, 'vacation-1.jpg');
    });

    test('目录解析：已知目录优先，缺省回退插件数据目录', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final _SavingSaver saver = _SavingSaver();

      // {documents} → 已知文档目录。
      CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(
          settings: ScreenshotSettings(saveDir: '{documents}'),
        ),
        knownFolders: const _FixedKnownFolders(documentsDir: '/docs'),
      );
      await controller.capture();
      expect(saver.lastDir, '/docs');

      // {pictures} 已知目录不可解析 → 回退插件数据目录。
      controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(
          settings: ScreenshotSettings(saveDir: '{pictures}'),
        ),
        knownFolders: const _FixedKnownFolders(),
        pluginDataDir: '/plugin-data',
      );
      await controller.capture();
      expect(saver.lastDir, '/plugin-data');

      // {pluginData} → 插件数据目录。
      controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(
          settings: ScreenshotSettings(saveDir: '{pluginData}'),
        ),
        knownFolders: const _FixedKnownFolders(picturesDir: '/pics'),
        pluginDataDir: '/plugin-data',
      );
      await controller.capture();
      expect(saver.lastDir, '/plugin-data');
    });

    test('编码分派：png 原样透传，jpeg 重编码为非原样字节', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final _SavingSaver saver = _SavingSaver();

      final CaptureController pngController = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(settings: ScreenshotSettings(format: 'png')),
      );
      await pngController.capture();
      expect(saver.lastBytes, same(_pngBytes));
      expect(pngController.lastFailure, isNull);

      final CaptureController jpegController = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(
          settings: ScreenshotSettings(format: 'jpeg', jpegQuality: 80),
        ),
      );
      await jpegController.capture();
      expect(saver.lastBytes, isNot(same(_pngBytes)));
      expect(saver.lastBytes, isNot(_pngBytes));
      expect(jpegController.lastFailure, isNull);
    });

    test('编码失败折算 capture.encode_failed 且不写文件', () async {
      var saveCalled = false;
      final CaptureController controller = CaptureController(
        screenCapture: _FakeScreenCapture(
          CaptureResult.success(Uint8List.fromList(<int>[1, 2, 3])),
        ),
        saveFile: (Uint8List bytes, String dir, String filename) async {
          saveCalled = true;
          return '$dir/$filename';
        },
        model: ScreenshotModel(settings: ScreenshotSettings(format: 'jpeg')),
      );

      await controller.capture();

      expect(controller.lastFailure!.code, 'capture.encode_failed');
      expect(controller.lastFailure!.details['reason'], 'decode');
      expect(saveCalled, isFalse);
      expect(controller.lastResult, isNull);
      expect(controller.lastDetails, isNull);
    });

    test('自动复制分派：none 跳过、image 写原始 PNG、path 写文件路径', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final _RecordingClipboard clipboard = _RecordingClipboard();
      final _SavingSaver saver = _SavingSaver();

      // none：不触碰剪贴板。
      CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(settings: ScreenshotSettings(autoCopy: 'none')),
        clipboard: clipboard,
      );
      await controller.capture();
      expect(clipboard.imageCalls, 0);
      expect(clipboard.filesCalls, 0);
      expect(controller.lastDetails!.copyKey, 'none');

      // image（默认）：写入原始 PNG 字节。
      controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(),
        clipboard: clipboard,
      );
      await controller.capture();
      expect(clipboard.imageCalls, 1);
      expect(clipboard.lastImage, same(_pngBytes));
      expect(clipboard.filesCalls, 0);
      expect(controller.lastDetails!.copyKey, 'image');

      // path：写入落盘完整路径。
      controller = CaptureController(
        screenCapture: capture,
        saveFile: saver.save,
        model: ScreenshotModel(settings: ScreenshotSettings(autoCopy: 'path')),
        clipboard: clipboard,
      );
      await controller.capture();
      final String savedPath = controller.lastSavedPath!;
      expect(clipboard.filesCalls, 1);
      expect(clipboard.lastPaths, <String>[savedPath]);
      expect(controller.lastDetails!.copyKey, 'path');
    });

    test('复制失败仅标记明细 failed，落盘结果不受影响', () async {
      final _SavingSaver saver = _SavingSaver();
      final CaptureController controller = CaptureController(
        screenCapture: _FakeScreenCapture(CaptureResult.success(_pngBytes)),
        saveFile: saver.save,
        model: ScreenshotModel(),
        clipboard: _RecordingClipboard()..fail = true,
      );

      await controller.capture();

      expect(controller.lastFailure, isNull);
      expect(controller.lastResult, isNotNull);
      expect(controller.lastDetails!.path, controller.lastSavedPath);
      expect(controller.lastDetails!.copyKey, 'failed');
    });

    group('区域截图闭环（S1 批C）', () {
      test('save：二次捕获逻辑选区并走落盘 + 自动复制', () async {
        // Arrange：底图与选区同字节（1x1 PNG）；selector 返回 save 选区。
        final _FakeScreenCapture capture = _FakeScreenCapture(
          CaptureResult.success(_pngBytes),
        );
        final _SavingSaver saver = _SavingSaver();
        final _RecordingClipboard clipboard = _RecordingClipboard();
        final CaptureController controller = CaptureController(
          screenCapture: capture,
          saveFile: saver.save,
          model: ScreenshotModel(),
          clipboard: clipboard,
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(
          ScreenRegion(
            logicalRect: ui.Rect.fromLTWH(10, 20, 30, 40),
            physicalRect: ui.Rect.fromLTWH(20, 40, 60, 80),
            action: ScreenRegionAction.save,
          ),
        );

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：底图 + 选区共两次捕获，二次捕获输入逻辑选区
        // （capabilities 矩形逐字段拷贝）；落盘 + 默认 autoCopy=image。
        expect(capture.calls, 2);
        expect(capture.lastRegion!.left, 10);
        expect(capture.lastRegion!.top, 20);
        expect(capture.lastRegion!.width, 30);
        expect(capture.lastRegion!.height, 40);
        expect(selector.lastImageSize!.width, 1);
        expect(selector.lastImageSize!.height, 1);
        expect(controller.lastFailure, isNull);
        expect(controller.lastSavedPath, isNotNull);
        expect(controller.lastDetails!.copyKey, 'image');
        expect(clipboard.imageCalls, 1);
      });

      test('copy：写剪贴板、不落盘、lastRegionCopied 置位', () async {
        // Arrange：selector 返回 copy 选区。
        final _FakeScreenCapture capture = _FakeScreenCapture(
          CaptureResult.success(_pngBytes),
        );
        final _SavingSaver saver = _SavingSaver();
        final _RecordingClipboard clipboard = _RecordingClipboard();
        final CaptureController controller = CaptureController(
          screenCapture: capture,
          saveFile: saver.save,
          model: ScreenshotModel(),
          clipboard: clipboard,
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(
          ScreenRegion(
            logicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            physicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            action: ScreenRegionAction.copy,
          ),
        );

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：仅复制不落盘；结果/明细保持 null；复制标志置位。
        expect(capture.calls, 2);
        expect(saver.lastBytes, isNull);
        expect(clipboard.imageCalls, 1);
        expect(controller.lastRegionCopied, isTrue);
        expect(controller.lastSavedPath, isNull);
        expect(controller.lastDetails, isNull);
        expect(controller.lastFailure, isNull);
      });

      test('copy：剪贴板能力未注入时结构化失败', () async {
        // Arrange：不注入 clipboard。
        final CaptureController controller = CaptureController(
          screenCapture: _FakeScreenCapture(CaptureResult.success(_pngBytes)),
          saveFile: _SavingSaver().save,
          model: ScreenshotModel(),
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(
          ScreenRegion(
            logicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            physicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            action: ScreenRegionAction.copy,
          ),
        );

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：clipboardUnavailable 失败，复制标志保持 false。
        expect(controller.lastFailure!.code, 'capture.failed');
        expect(
          controller.lastFailure!.details['reason'],
          'clipboardUnavailable',
        );
        expect(controller.lastRegionCopied, isFalse);
      });

      test('copy：写剪贴板失败时 lastRegionCopied 为 false', () async {
        // Arrange：剪贴板写入抛错。
        final _RecordingClipboard clipboard = _RecordingClipboard()
          ..fail = true;
        final CaptureController controller = CaptureController(
          screenCapture: _FakeScreenCapture(CaptureResult.success(_pngBytes)),
          saveFile: _SavingSaver().save,
          model: ScreenshotModel(),
          clipboard: clipboard,
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(
          ScreenRegion(
            logicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            physicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            action: ScreenRegionAction.copy,
          ),
        );

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：copyError 失败，复制标志保持 false。
        expect(controller.lastFailure!.code, 'capture.failed');
        expect(controller.lastFailure!.details['reason'], 'copyError');
        expect(controller.lastRegionCopied, isFalse);
      });

      test('selector 取消：仅底图捕获一次，状态保持干净', () async {
        // Arrange：selector 恒返回 null（ESC/关闭 overlay）。
        final _FakeScreenCapture capture = _FakeScreenCapture(
          CaptureResult.success(_pngBytes),
        );
        final _SavingSaver saver = _SavingSaver();
        final CaptureController controller = CaptureController(
          screenCapture: capture,
          saveFile: saver.save,
          model: ScreenshotModel(),
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(null);

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：无二次捕获、无落盘、无失败。
        expect(capture.calls, 1);
        expect(saver.lastBytes, isNull);
        expect(controller.lastFailure, isNull);
        expect(controller.lastRegionCopied, isFalse);
      });

      test('discard 动作：同取消，不二次捕获', () async {
        // Arrange：selector 返回 discard。
        final _FakeScreenCapture capture = _FakeScreenCapture(
          CaptureResult.success(_pngBytes),
        );
        final CaptureController controller = CaptureController(
          screenCapture: capture,
          saveFile: _SavingSaver().save,
          model: ScreenshotModel(),
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(
          ScreenRegion(
            logicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            physicalRect: ui.Rect.fromLTWH(0, 0, 50, 50),
            action: ScreenRegionAction.discard,
          ),
        );

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：discard 不触发二次捕获。
        expect(capture.calls, 1);
        expect(controller.lastFailure, isNull);
      });

      test('底图捕获失败：结构化透传且 selector 未被调用', () async {
        // Arrange：底图捕获失败（noScreen）。
        final CaptureController controller = CaptureController(
          screenCapture: _FakeScreenCapture(
            CaptureResult.failure(
              PluginFailure('capture.failed', '无法获取屏幕', <String, Object?>{
                'reason': 'noScreen',
              }),
            ),
          ),
          saveFile: _SavingSaver().save,
          model: ScreenshotModel(),
        );
        final _ScriptedRegionSelector selector = _ScriptedRegionSelector(null);

        // Act
        await controller.captureWithRegionSelector(selector.select);

        // Assert：失败原样透传，overlay 未打开。
        expect(controller.lastFailure!.code, 'capture.failed');
        expect(controller.lastFailure!.details['reason'], 'noScreen');
        expect(selector.calls, 0);
      });
    });
  });
}
