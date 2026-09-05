/// 区域选择 overlay widget 测试（S1 批C）。
///
/// 场景清单：
/// 1. 初始：操作提示在屏，无尺寸标签与工具条；
/// 2. 拖拽框选：尺寸标签与工具条出现，Enter 确认返回 save 选区，
///    逻辑/物理矩形与视口:底图 1:1 比例一致；
/// 3. Esc 取消：pop null；
/// 4. 工具条复制按钮：返回 copy 选区；
/// 5. 工具条放弃按钮：pop null；
/// 6. 选区过小：Enter 确认被忽略（不退出）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show Rect;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:toolbox_host/src/region_selection/region_selection_overlay.dart';

/// 1x1 透明 PNG（overlay 底图占位）。
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// 推入 overlay 并返回捕获 pop 结果的 Completer。
Future<Completer<ScreenRegion?>> _pushOverlay(
  WidgetTester tester, {
  ui.Rect imageSize = const ui.Rect.fromLTWH(0, 0, 800, 600),
}) async {
  final Completer<ScreenRegion?> done = Completer<ScreenRegion?>();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push<ScreenRegion>(
                    MaterialPageRoute<ScreenRegion>(
                      builder: (BuildContext context) => RegionSelectionOverlay(
                        imageBytes: _tinyPng,
                        imageLogicalSize: imageSize,
                        saveLabel: '保存',
                        copyLabel: '复制',
                        discardLabel: '放弃',
                        hint: '拖拽框选，Esc 取消，Enter 保存',
                      ),
                    ),
                  )
                  .then(done.complete);
            },
            child: const Text('open'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // 启动过渡 + 跑完 MaterialPageRoute 默认过渡时长，保证 overlay
  // 完全就位（零偏移）后再进行拖拽/按键。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return done;
}

void main() {
  testWidgets('初始：提示在屏，无尺寸标签与工具条', (WidgetTester tester) async {
    // Arrange / Act：推入 overlay（未框选）。
    await _pushOverlay(tester);

    // Assert：操作提示可见；框选产物（尺寸标签文本、工具条按钮）不存在。
    expect(find.byType(RegionSelectionOverlay), findsOneWidget);
    expect(find.text('拖拽框选，Esc 取消，Enter 保存'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('拖拽 + Enter：返回 save 选区且逻辑/物理矩形一致', (WidgetTester tester) async {
    // Arrange：底图 800x600 与视口同尺寸（比例 1:1）。
    final Completer<ScreenRegion?> done = await _pushOverlay(tester);

    // Act：框选 120x80 后 Enter 确认。
    await tester.dragFrom(const Offset(100, 100), const Offset(120, 80));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('120×80'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    final ScreenRegion? region = await done.future.timeout(
      const Duration(seconds: 5),
    );

    // Assert：逻辑矩形 = 拖拽矩形（dragFrom 手势存在亚像素 touch-slop
    // 偏移，按 0.5px 容差断言）；物理矩形因 1:1 比例相同。
    expect(region, isNotNull);
    expect(region!.action, ScreenRegionAction.save);
    expect(region.logicalRect.left, closeTo(100, 0.5));
    expect(region.logicalRect.top, closeTo(100, 0.5));
    expect(region.logicalRect.width, closeTo(120, 0.5));
    expect(region.logicalRect.height, closeTo(80, 0.5));
    expect(region.physicalRect.left, closeTo(100, 0.5));
    expect(region.physicalRect.top, closeTo(100, 0.5));
    expect(region.physicalRect.width, closeTo(120, 0.5));
    expect(region.physicalRect.height, closeTo(80, 0.5));
  });

  testWidgets('Esc：取消并 pop null', (WidgetTester tester) async {
    // Arrange
    final Completer<ScreenRegion?> done = await _pushOverlay(tester);

    // Act
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));
    final ScreenRegion? region = await done.future.timeout(
      const Duration(seconds: 5),
    );

    // Assert
    expect(region, isNull);
  });

  testWidgets('工具条复制按钮：返回 copy 选区', (WidgetTester tester) async {
    // Arrange：框选出合法选区，工具条出现。
    final Completer<ScreenRegion?> done = await _pushOverlay(tester);
    await tester.dragFrom(const Offset(100, 100), const Offset(120, 80));
    await tester.pump(const Duration(milliseconds: 50));

    // Act
    await tester.tap(find.text('复制'));
    await tester.pump(const Duration(milliseconds: 50));
    final ScreenRegion? region = await done.future.timeout(
      const Duration(seconds: 5),
    );

    // Assert
    expect(region, isNotNull);
    expect(region!.action, ScreenRegionAction.copy);
  });

  testWidgets('工具条放弃按钮：pop null', (WidgetTester tester) async {
    // Arrange
    final Completer<ScreenRegion?> done = await _pushOverlay(tester);
    await tester.dragFrom(const Offset(100, 100), const Offset(120, 80));
    await tester.pump(const Duration(milliseconds: 50));

    // Act
    await tester.tap(find.text('放弃'));
    await tester.pump(const Duration(milliseconds: 50));
    final ScreenRegion? region = await done.future.timeout(
      const Duration(seconds: 5),
    );

    // Assert
    expect(region, isNull);
  });

  testWidgets('无选区时 Enter：确认被忽略', (WidgetTester tester) async {
    // Arrange：未框选（新建选区经最小边长扩展恒 >= 8，故这里验证
    // selection == null 的防御分支）。
    final Completer<ScreenRegion?> done = await _pushOverlay(tester);

    // Act：直接按 Enter。
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    // Assert：确认被忽略，overlay 仍在屏（未 pop）。
    expect(done.isCompleted, isFalse);
    expect(find.byType(RegionSelectionOverlay), findsOneWidget);
  });
}
