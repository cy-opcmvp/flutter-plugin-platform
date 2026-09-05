/// 截图页面与设置 surface 的精简组件测试。
///
/// 场景清单：
/// 1. 页面初始态：仅捕获按钮可见；
/// 2. 捕获成功：保存提示含落盘路径 + 结果区经 bytesLoader 真实渲染；
/// 3. 捕获失败：结构化失败标题与 message 上屏；
/// 4. 设置提交：前缀与质量下拉写回模型（质量文案折算回稳定键）。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:screenshot/screenshot.dart';

import 'test_harness.dart';

/// 1x1 透明 PNG（测试用最小合法图像，避免真实解码失败）。
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// 恒定成功 fake：返回 1x1 PNG 并记录全屏请求。
final class _SuccessScreenCapture implements ScreenCapture {
  int calls = 0;

  @override
  Future<CaptureResult> captureRegion(Rect region) async {
    calls++;
    return CaptureResult.success(_tinyPng);
  }
}

/// 恒定失败 fake：结构化 noScreen 失败。
final class _FailureScreenCapture implements ScreenCapture {
  @override
  Future<CaptureResult> captureRegion(Rect region) async {
    return CaptureResult.failure(
      PluginFailure('capture.failed', '无法获取屏幕', <String, Object?>{
        'reason': 'noScreen',
      }),
    );
  }
}

/// fake 写文件缝：返回 `/data/{filename}`。
Future<String> _fakeFileSaver(Uint8List bytes, String filename) async =>
    '/data/$filename';

/// fake 字节加载器：恒定返回 1x1 PNG。
Future<Uint8List?> _fakeBytesLoader(String path) async => _tinyPng;

/// 装配截图页面。
Widget _buildPage(CaptureController controller) {
  return Builder(
    builder: (BuildContext context) {
      return ScreenshotPageProvider(
        controller: controller,
        stringsResolver: kTestResolver,
        bytesLoader: _fakeBytesLoader,
      ).buildPage(context);
    },
  );
}

/// 装配截图设置视图。
Widget _buildSettings(ScreenshotModel model) {
  return Builder(
    builder: (BuildContext context) {
      return ScreenshotSettingsProvider(
        model: model,
        stringsResolver: kTestResolver,
      ).buildSettings(context);
    },
  );
}

void main() {
  group('ScreenshotPageProvider', () {
    testWidgets('初始态仅显示捕获按钮', (WidgetTester tester) async {
      // Arrange：成功 fake + 默认模型。
      enlargeTestViewport(tester);
      final CaptureController controller = CaptureController(
        screenCapture: _SuccessScreenCapture(),
        saveFile: _fakeFileSaver,
        model: ScreenshotModel(),
      );

      // Act：渲染页面。
      await tester.pumpWidget(buildScreenshotHarness(_buildPage(controller)));

      // Assert：按钮在、结果区与提示未出现。
      expect(find.text('截图'), findsOneWidget);
      expect(find.byType(ResultRenderer), findsNothing);
      expect(find.textContaining('已保存'), findsNothing);
    });

    testWidgets('捕获成功后展示保存路径与图片结果', (WidgetTester tester) async {
      // Arrange：成功 fake。
      enlargeTestViewport(tester);
      final _SuccessScreenCapture capture = _SuccessScreenCapture();
      final CaptureController controller = CaptureController(
        screenCapture: capture,
        saveFile: _fakeFileSaver,
        model: ScreenshotModel(),
      );
      await tester.pumpWidget(buildScreenshotHarness(_buildPage(controller)));

      // Act：点击捕获按钮（FilledButton.icon 是私有子类，按文案定位）。
      await tester.tap(find.text('截图'));
      await tester.pumpAndSettle();

      // Assert：保存提示（含 /data/ 路径）+ 结果区 + 真实解码的图片。
      expect(capture.calls, 1);
      expect(find.textContaining('已保存：/data/shot-'), findsOneWidget);
      expect(find.text('最近截图'), findsOneWidget);
      expect(find.byType(ResultRenderer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('截图失败'), findsNothing);
    });

    testWidgets('捕获失败后展示结构化失败文案', (WidgetTester tester) async {
      // Arrange：失败 fake（reason=noScreen）。
      enlargeTestViewport(tester);
      final CaptureController controller = CaptureController(
        screenCapture: _FailureScreenCapture(),
        saveFile: _fakeFileSaver,
        model: ScreenshotModel(),
      );
      await tester.pumpWidget(buildScreenshotHarness(_buildPage(controller)));

      // Act：点击捕获按钮（FilledButton.icon 是私有子类，按文案定位）。
      await tester.tap(find.text('截图'));
      await tester.pumpAndSettle();

      // Assert：失败标题 + 能力层 message 上屏；无结果区。
      expect(find.text('截图失败：无法获取屏幕'), findsOneWidget);
      expect(find.byType(ResultRenderer), findsNothing);
    });
  });

  group('ScreenshotSettingsProvider', () {
    testWidgets('表单展示设置默认值并可提交写回模型', (WidgetTester tester) async {
      // Arrange：默认模型 + 设置视图。
      enlargeTestViewport(tester);
      final ScreenshotModel model = ScreenshotModel();
      await tester.pumpWidget(buildScreenshotHarness(_buildSettings(model)));

      // Assert：表单标题与质量默认选项在屏。
      expect(find.text('截图设置'), findsOneWidget);
      expect(find.text('无损（PNG）'), findsOneWidget);

      // Act：修改前缀并选择“标准”。
      await tester.enterText(find.byType(TextFormField), 'myshot');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert：文案标签折算回稳定键写回模型。
      expect(model.settings.filenamePrefix, 'myshot');
      expect(model.settings.quality, 'standard');
      expect(find.text('PNG 为无损格式，质量选项暂以原图保存。'), findsOneWidget);
    });
  });
}
