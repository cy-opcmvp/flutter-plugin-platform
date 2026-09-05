// 覆盖场景清单（F4-05 焦点测试：CaptureController 编排两路 + 防重入 + 前缀）：
// 1. 成功路径：全屏矩形请求、写文件缝落盘、产出 image 结果（路径一致）。
// 2. 失败路径：结构化透传 capture.failed（reason 原样），不触碰写文件缝。
// 3. 写文件缝异常：折算为 capture.failed / reason=saveError。
// 4. 捕获进行中 capturing 为真、重复触发被忽略、结束后复位。
// 5. 设置前缀进入文件名（`{prefix}-{时间戳}.png`）。
library;

import 'dart:async';
import 'dart:typed_data';

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

final Uint8List _pngBytes = Uint8List.fromList(<int>[1, 2, 3]);

void main() {
  group('CaptureController', () {
    test('成功路径：全屏捕获并经写文件缝落盘产出 image 结果', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final ScreenshotModel model = ScreenshotModel();
      Uint8List? savedBytes;
      String? savedFilename;
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String filename) async {
          savedBytes = bytes;
          savedFilename = filename;
          return '/data/$filename';
        },
        model: model,
      );

      await controller.capture();

      expect(capture.calls, 1);
      expect(capture.lastRegion, kFullscreenRegion);
      expect(savedBytes, _pngBytes);
      expect(savedFilename, startsWith('shot-'));
      expect(savedFilename, endsWith('.png'));
      expect(controller.capturing, isFalse);
      expect(controller.lastFailure, isNull);
      expect(controller.lastSavedPath, '/data/$savedFilename');
      expect(controller.lastResult, isA<ImageResultDescriptor>());
      expect(controller.lastResult!.path, controller.lastSavedPath);
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
        saveFile: (Uint8List bytes, String filename) async {
          saveCalled = true;
          return '/data/$filename';
        },
        model: ScreenshotModel(),
      );

      await controller.capture();

      expect(controller.lastFailure, isA<PluginFailure>());
      expect(controller.lastFailure!.code, 'capture.failed');
      expect(controller.lastFailure!.details['reason'], 'noScreen');
      expect(saveCalled, isFalse);
      expect(controller.lastResult, isNull);
      expect(controller.lastSavedPath, isNull);
    });

    test('写文件缝异常折算为 capture.failed / reason=saveError', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String filename) async {
          throw const FileSystemExceptionStub();
        },
        model: ScreenshotModel(),
      );

      await controller.capture();

      expect(controller.lastFailure!.code, 'capture.failed');
      expect(controller.lastFailure!.details['reason'], 'saveError');
      expect(controller.lastResult, isNull);
    });

    test('捕获进行中 capturing 为真、重复触发被忽略、结束后复位', () async {
      final _GatedScreenCapture capture = _GatedScreenCapture();
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String filename) async => '/data/$filename',
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
      expect(controller.lastResult, isNotNull);
      expect(
        controller.lastResult!.path,
        '/data/${controller.lastSavedPath!.split('/').last}',
      );
    });

    test('设置前缀进入保存文件名', () async {
      final _FakeScreenCapture capture = _FakeScreenCapture(
        CaptureResult.success(_pngBytes),
      );
      final ScreenshotModel model = ScreenshotModel();
      model.updateSettings(ScreenshotSettings(filenamePrefix: 'vacation'));
      String? savedFilename;
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: (Uint8List bytes, String filename) async {
          savedFilename = filename;
          return '/data/$filename';
        },
        model: model,
      );

      await controller.capture();

      expect(savedFilename, startsWith('vacation-'));
    });
  });
}

/// 测试用文件系统异常 stub（避免测试依赖 dart:io）。
final class FileSystemExceptionStub implements Exception {
  const FileSystemExceptionStub();

  @override
  String toString() => '写入失败';
}
