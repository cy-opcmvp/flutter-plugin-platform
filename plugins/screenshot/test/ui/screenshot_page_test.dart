/// 截图页面与设置 surface 的精简组件测试。
///
/// 场景清单：
/// 1. 页面初始态：仅捕获按钮可见；
/// 2. 捕获成功：保存提示含落盘路径 + 图片/明细双结果区真实渲染；
/// 3. 捕获失败：结构化失败标题与 message 上屏；
/// 4. 设置提交：模板/质量文本与目录/格式/自动复制下拉写回模型
///    （下拉文案折算回稳定键，质量钳制 1-100）。
library;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui show Rect;

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

/// fake 写文件缝：忽略注入目录，恒定落 `/data/{filename}`。
Future<String> _fakeFileSaver(
  Uint8List bytes,
  String dir,
  String filename,
) async => '/data/$filename';

/// fake 字节加载器：恒定返回 1x1 PNG。
Future<Uint8List?> _fakeBytesLoader(String path) async => _tinyPng;

/// fake 区域选择缝：恒取消（本文件聚焦页面呈现，区域闭环另有专测）。
Future<ScreenRegion?> _fakeRegionSelector(
  Uint8List image,
  ui.Rect size,
) async => null;

/// 装配截图页面。
Widget _buildPage(CaptureController controller) {
  return Builder(
    builder: (BuildContext context) {
      return ScreenshotPageProvider(
        controller: controller,
        stringsResolver: kTestResolver,
        bytesLoader: _fakeBytesLoader,
        regionSelector: _fakeRegionSelector,
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

    testWidgets('捕获成功后展示保存路径、图片与落盘明细', (WidgetTester tester) async {
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

      // Assert：保存提示（默认模板 + /data/ 路径）+ 图片/明细双结果区。
      expect(capture.calls, 1);
      expect(find.textContaining('已保存：/data/screenshot-'), findsOneWidget);
      expect(find.text('最近截图'), findsOneWidget);
      expect(find.byType(ResultRenderer), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('保存路径'), findsOneWidget);
      expect(find.text('未复制'), findsOneWidget);
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

      // Assert：表单标题与默认格式选项在屏。
      expect(find.text('截图设置'), findsOneWidget);
      expect(find.text('PNG（无损）'), findsOneWidget);

      // Act：修改模板文本与质量数值（表单三个文本字段，热键保持默认）。
      await tester.enterText(find.byType(TextFormField).first, 'myshot-{seq}');
      await tester.enterText(find.byType(TextFormField).at(1), '60');
      // 依次切换目录/格式/自动复制下拉。
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('文档目录').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JPEG（压缩）').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复制文件路径').last);
      await tester.pumpAndSettle();
      // 提交（FilledButton.icon 是私有子类，按类型定位）。
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert：文案标签折算回稳定键写回模型，质量钳制生效。
      expect(model.settings.saveDir, '{documents}');
      expect(model.settings.filenameTemplate, 'myshot-{seq}');
      expect(model.settings.format, 'jpeg');
      expect(model.settings.jpegQuality, 60);
      expect(model.settings.autoCopy, 'path');
      expect(find.textContaining('文件名模板支持'), findsOneWidget);
    });
  });
}
