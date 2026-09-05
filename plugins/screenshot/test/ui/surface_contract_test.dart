/// 截图 UI surface 契约走查（devkit SurfaceContractChecks）。
///
/// 场景清单：
/// 1. checkPageProviderBuilds：页面提供方在装配主题令牌的上下文中构建成功；
/// 2. checkSettingsProviderBuilds：设置提供方构建成功；
/// 3. checkManifestSurfaceDeclared：清单声明 page+settings 且实现族一致；
/// 4. 声明与实现族不一致（actions 未声明却标记实现）时抛 StateError。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_devkit/plugin_devkit.dart';
import 'package:screenshot/screenshot.dart';

import 'test_harness.dart';

/// 恒定成功的 fake：字节加载器返回 3 字节占位（契约走查不真实解码）。
Future<Uint8List?> _fakeBytesLoader(String path) async =>
    Uint8List.fromList(<int>[1, 2, 3]);

/// 恒定成功的 fake：写文件缝返回固定路径。
Future<String> _fakeFileSaver(Uint8List bytes, String filename) async =>
    '/data/$filename';

void main() {
  group('SurfaceContractChecks 走查（截图）', () {
    testWidgets('checkPageProviderBuilds 构建成功', (WidgetTester tester) async {
      // 场景 1：页面提供方构建不抛异常且返回 Widget。
      BuildContext? captured;
      await tester.pumpWidget(
        buildScreenshotHarness(
          Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final ScreenshotPageProvider provider = ScreenshotPageProvider(
        controller: CaptureController(
          screenCapture: _StubScreenCapture(),
          saveFile: _fakeFileSaver,
          model: ScreenshotModel(),
        ),
        stringsResolver: kTestResolver,
        bytesLoader: _fakeBytesLoader,
      );
      SurfaceContractChecks.checkPageProviderBuilds(captured!, provider);
    });

    testWidgets('checkSettingsProviderBuilds 构建成功', (
      WidgetTester tester,
    ) async {
      // 场景 2：设置提供方构建不抛异常且返回 Widget。
      BuildContext? captured;
      await tester.pumpWidget(
        buildScreenshotHarness(
          Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final ScreenshotSettingsProvider provider = ScreenshotSettingsProvider(
        model: ScreenshotModel(),
        stringsResolver: kTestResolver,
      );
      SurfaceContractChecks.checkSettingsProviderBuilds(captured!, provider);
    });

    test('checkManifestSurfaceDeclared 清单声明与实现族一致', () {
      // 场景 3：清单声明 page+settings，实现族提供 page+settings、无 actions。
      SurfaceContractChecks.checkManifestSurfaceDeclared(
        screenshotManifest(),
        page: true,
        settings: true,
        actions: false,
      );
    });

    test('声明与实现族不一致时抛 StateError', () {
      // 场景 4：清单未声明 actions，却标记 actions 已实现 → 契约不一致。
      expect(
        () => SurfaceContractChecks.checkManifestSurfaceDeclared(
          screenshotManifest(),
          page: true,
          settings: true,
          actions: true,
        ),
        throwsStateError,
      );
    });
  });
}

/// 恒定挂起的 fake：契约走查不触发真实捕获。
final class _StubScreenCapture implements ScreenCapture {
  @override
  Future<CaptureResult> captureRegion(Rect region) async {
    throw UnimplementedError();
  }
}
