/// 区域选择纯逻辑单元测试（S1 批C）。
///
/// 场景清单：
/// 1. combo 校验：合法（大小写/空白容错、control 别名、F 键）与非法
///    （缺主键、修饰重复、未知修饰/主键、F13 越界）表驱动；
/// 2. 物理选区换算：DPI 比例放大、边界钳制与四舍五入；
/// 3. 拖拽模式判定：选区外新建、内部移动、边缘命中调整；
/// 4. 拖拽矩形计算：新建最小边长保证与视口钳制、移动不越界、
///    调整保持最小边长。
library;

import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  group('screenshotIsValidHotkeyCombo', () {
    test('合法 combo（表驱动）', () {
      // Arrange：覆盖修饰别名、空白容错、数字/F 键主键。
      const List<String> valid = <String>[
        'Ctrl+Shift+A',
        'control+alt+f12',
        'Ctrl + Alt + 0',
        'Win+F1',
        'Shift+Meta+K',
        'Alt+9',
      ];

      // Act / Assert：全部通过。
      for (final String combo in valid) {
        expect(screenshotIsValidHotkeyCombo(combo), isTrue, reason: combo);
      }
    });

    test('非法 combo（表驱动）', () {
      // Arrange：缺主键/修饰重复/未知修饰/未知主键/F 键越界/顺序颠倒。
      const List<String> invalid = <String>[
        '',
        'A',
        'Ctrl',
        'Ctrl+Ctrl+A',
        'Ctrl+Hyper+A',
        'Ctrl+@',
        'Ctrl+F13',
        'a+Ctrl',
      ];

      // Act / Assert：全部拒绝。
      for (final String combo in invalid) {
        expect(screenshotIsValidHotkeyCombo(combo), isFalse, reason: combo);
      }
    });
  });

  group('screenshotPhysicalRegionFromLogical', () {
    test('按视口与底图像素比例放大', () {
      // Arrange：视口 100x50、底图 200x150 → 比例 x2/y3。
      const Size viewport = Size(100, 50);
      final Rect logical = Rect.fromLTWH(10, 5, 20, 10);

      // Act
      final Rect physical = screenshotPhysicalRegionFromLogical(
        logical,
        viewport,
        200,
        150,
      );

      // Assert：坐标与宽高同比例放大。
      expect(physical, Rect.fromLTWH(20, 15, 40, 30));
    });

    test('越界选区钳制到底图边界并四舍五入', () {
      // Arrange：负起点与超出底图右下边界的选区；比例 x2/y1.5，
      // -5.2*2=-10.4 → round → clamp 0。
      const Size viewport = Size(100, 100);
      final Rect logical = Rect.fromLTWH(-5.2, 40, 200, 200);

      // Act
      final Rect physical = screenshotPhysicalRegionFromLogical(
        logical,
        viewport,
        200,
        150,
      );

      // Assert：left 钳 0、right 钳 200、bottom 钳 150。
      expect(physical.left, 0);
      expect(physical.top, 60);
      expect(physical.right, 200);
      expect(physical.bottom, 150);
    });
  });

  group('screenshotRegionDragModeFor', () {
    final Rect selection = Rect.fromLTWH(20, 20, 60, 40);

    test('无选区或选区外 → new', () {
      // Arrange / Act / Assert
      expect(screenshotRegionDragModeFor(const Offset(10, 40), null), 'new');
      expect(
        screenshotRegionDragModeFor(const Offset(10, 40), selection),
        'new',
      );
    });

    test('选区内部 → move', () {
      // Arrange / Act / Assert：远离四边的中心点。
      expect(
        screenshotRegionDragModeFor(const Offset(50, 40), selection),
        'move',
      );
    });

    test('边缘命中带内 → resize', () {
      // Arrange / Act / Assert：左缘 5px 内与右下角内侧点。
      expect(
        screenshotRegionDragModeFor(const Offset(25, 40), selection),
        'resize',
      );
      expect(
        screenshotRegionDragModeFor(const Offset(79.5, 59.5), selection),
        'resize',
      );
    });
  });

  group('screenshotRegionRectForDrag', () {
    const Size viewport = Size(200, 100);

    test('新建：正反方向拖拽归一化且保留原始跨度', () {
      // Act
      final Rect forward = screenshotRegionRectForDrag(
        dragMode: 'new',
        start: const Offset(10, 10),
        current: const Offset(50, 40),
        viewportSize: viewport,
      );
      final Rect backward = screenshotRegionRectForDrag(
        dragMode: 'new',
        start: const Offset(50, 40),
        current: const Offset(10, 10),
        viewportSize: viewport,
      );

      // Assert：fromPoints 归一化，两者同矩形。
      final Rect expected = Rect.fromLTWH(10, 10, 40, 30);
      expect(forward, expected);
      expect(backward, expected);
    });

    test('新建：跨度不足最小边长时按中心扩展', () {
      // Act
      final Rect grown = screenshotRegionRectForDrag(
        dragMode: 'new',
        start: const Offset(50, 50),
        current: const Offset(52, 52),
        viewportSize: viewport,
      );

      // Assert：中心 (51,51)，宽高扩展到 8。
      expect(grown, Rect.fromLTWH(47, 47, 8, 8));
    });

    test('新建：贴近视口右下角时钳制且保持最小边长', () {
      // Act
      final Rect clamped = screenshotRegionRectForDrag(
        dragMode: 'new',
        start: const Offset(197, 97),
        current: const Offset(500, 500),
        viewportSize: viewport,
      );

      // Assert：右下边贴住视口并向内扩展最小边长。
      expect(clamped, Rect.fromLTWH(192, 92, 8, 8));
    });

    test('移动：位移钳制在视口内', () {
      // Arrange：previous (10,10,50x30)，拖出视口右下很远。
      final Rect previous = Rect.fromLTWH(10, 10, 50, 30);

      // Act
      final Rect moved = screenshotRegionRectForDrag(
        dragMode: 'move',
        start: const Offset(30, 20),
        current: const Offset(500, 500),
        viewportSize: viewport,
        previous: previous,
      );

      // Assert：右/下边贴住视口边界（位移被钳制为 140/60）。
      expect(moved, Rect.fromLTWH(150, 70, 50, 30));
    });

    test('移动：无基准选区返回零矩形', () {
      // Act / Assert
      expect(
        screenshotRegionRectForDrag(
          dragMode: 'move',
          start: const Offset(30, 20),
          current: const Offset(40, 25),
          viewportSize: viewport,
        ),
        Rect.zero,
      );
    });

    test('调整：拖左上角收缩并保持最小边长', () {
      // Arrange：从左上角手柄向右下拖。
      final Rect previous = Rect.fromLTWH(20, 20, 60, 40);

      // Act
      final Rect resized = screenshotRegionRectForDrag(
        dragMode: 'resize',
        start: const Offset(21, 21),
        current: const Offset(90, 25),
        viewportSize: viewport,
        previous: previous,
      );

      // Assert：left 被钳制到 right-8，top 正常跟随。
      expect(resized, Rect.fromLTWH(72, 25, 8, 35));
    });

    test('调整：无基准选区返回零矩形', () {
      // Act / Assert
      expect(
        screenshotRegionRectForDrag(
          dragMode: 'resize',
          start: const Offset(21, 21),
          current: const Offset(30, 25),
          viewportSize: viewport,
        ),
        Rect.zero,
      );
    });
  });
}
