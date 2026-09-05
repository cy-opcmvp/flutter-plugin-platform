/// 计算器 UI surface 契约走查（devkit SurfaceContractChecks）。
///
/// 场景清单：
/// 1. checkPageProviderBuilds：页面提供方在装配主题令牌的上下文中构建成功；
/// 2. checkSettingsProviderBuilds：设置提供方构建成功；
/// 3. checkManifestSurfaceDeclared：清单声明 page+settings 且实现族一致；
/// 4. 声明与实现族不一致（actions 未声明却标记实现）时抛 StateError。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_devkit/plugin_devkit.dart';

import 'test_harness.dart';

void main() {
  group('SurfaceContractChecks 走查（计算器）', () {
    testWidgets('checkPageProviderBuilds 构建成功', (WidgetTester tester) async {
      // 场景 1：页面提供方构建不抛异常且返回 Widget。
      BuildContext? captured;
      await tester.pumpWidget(
        buildCalculatorHarness(
          Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final CalculatorPageProvider provider = CalculatorPageProvider(
        model: CalculatorModel(),
        stringsResolver: kTestResolver,
      );
      SurfaceContractChecks.checkPageProviderBuilds(captured!, provider);
    });

    testWidgets('checkSettingsProviderBuilds 构建成功', (
      WidgetTester tester,
    ) async {
      // 场景 2：设置提供方构建不抛异常且返回 Widget。
      BuildContext? captured;
      await tester.pumpWidget(
        buildCalculatorHarness(
          Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final CalculatorSettingsProvider provider = CalculatorSettingsProvider(
        model: CalculatorModel(),
        stringsResolver: kTestResolver,
      );
      SurfaceContractChecks.checkSettingsProviderBuilds(captured!, provider);
    });

    test('checkManifestSurfaceDeclared 清单声明与实现族一致', () {
      // 场景 3：清单声明 page+settings，实现族提供 page+settings、无 actions。
      SurfaceContractChecks.checkManifestSurfaceDeclared(
        calculatorManifest(),
        page: true,
        settings: true,
        actions: false,
      );
    });

    test('声明与实现族不一致时抛 StateError', () {
      // 场景 4：清单未声明 actions，却标记 actions 已实现 → 契约不一致。
      expect(
        () => SurfaceContractChecks.checkManifestSurfaceDeclared(
          calculatorManifest(),
          page: true,
          settings: true,
          actions: true,
        ),
        throwsStateError,
      );
    });
  });
}
