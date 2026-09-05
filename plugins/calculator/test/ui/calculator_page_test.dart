/// 计算器页面与设置 surface 的组件测试。
///
/// 场景清单：
/// 1. 输入 2+3*4 并求值，显示 "= 14.00"（乘法优先 + 默认 2 位小数）；
/// 2. 输入 1/0 并求值，显示除零错误文案；
/// 3. 历史条目点击回填表达式到输入行；
/// 4. 设置视图关闭历史开关后，页面隐藏历史区；
/// 5. 小数位数改为 0 后，结果显示为整数。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// 渲染计算器页面（经 Builder 注入上下文）。
Widget _buildPage(CalculatorModel model) {
  return buildCalculatorHarness(
    Builder(
      builder: (BuildContext context) => CalculatorPageProvider(
        model: model,
        stringsResolver: kTestResolver,
      ).buildPage(context),
    ),
  );
}

/// 渲染计算器设置视图（经 Builder 注入上下文）。
Widget _buildSettings(CalculatorModel model) {
  return buildCalculatorHarness(
    Builder(
      builder: (BuildContext context) => CalculatorSettingsProvider(
        model: model,
        stringsResolver: kTestResolver,
      ).buildSettings(context),
    ),
  );
}

/// 点击指定按键（OutlinedButton 文本匹配）。
Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.widgetWithText(OutlinedButton, key));
  await tester.pump();
}

void main() {
  group('CalculatorPageProvider', () {
    testWidgets('输入 2+3*4 求值显示 = 14.00', (WidgetTester tester) async {
      // 场景 1：乘法优先 + 默认 2 位小数。
      enlargeTestViewport(tester);
      final CalculatorModel model = CalculatorModel();
      await tester.pumpWidget(_buildPage(model));

      await _tapKey(tester, '2');
      await _tapKey(tester, '+');
      await _tapKey(tester, '3');
      await _tapKey(tester, '*');
      await _tapKey(tester, '4');
      await tester.tap(find.widgetWithText(FilledButton, '='));
      await tester.pump();

      expect(find.text('= 14.00'), findsOneWidget);
    });

    testWidgets('输入 1/0 求值显示除零错误文案', (WidgetTester tester) async {
      // 场景 2：结构化错误经宿主文案载体映射展示。
      enlargeTestViewport(tester);
      final CalculatorModel model = CalculatorModel();
      await tester.pumpWidget(_buildPage(model));

      await _tapKey(tester, '1');
      await _tapKey(tester, '/');
      await _tapKey(tester, '0');
      await tester.tap(find.widgetWithText(FilledButton, '='));
      await tester.pump();

      expect(find.text('除数不能为零'), findsOneWidget);
    });

    testWidgets('历史条目点击回填表达式', (WidgetTester tester) async {
      // 场景 3：点击历史条目后表达式回到输入行且结果清空。
      enlargeTestViewport(tester);
      final CalculatorModel model = CalculatorModel();
      await tester.pumpWidget(_buildPage(model));

      await _tapKey(tester, '2');
      await _tapKey(tester, '+');
      await _tapKey(tester, '3');
      await tester.tap(find.widgetWithText(FilledButton, '='));
      await tester.pump();
      expect(find.text('= 5.00'), findsOneWidget);

      // 显示行与历史条目各渲染一份 "2+3"。
      expect(find.text('2+3'), findsNWidgets(2));
      await tester.tap(find.text('2+3').last);
      await tester.pump();

      expect(model.expression, '2+3');
      expect(find.text('= 5.00'), findsNothing);
    });
  });

  group('CalculatorSettingsProvider', () {
    testWidgets('关闭历史开关后页面隐藏历史区', (WidgetTester tester) async {
      // 场景 4：设置写回共享模型，页面即时响应。
      enlargeTestViewport(tester);
      final CalculatorModel model = CalculatorModel();
      await tester.pumpWidget(_buildSettings(model));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(model.settings.showHistory, isFalse);

      await tester.pumpWidget(_buildPage(model));
      await tester.pump();
      expect(find.text('历史记录'), findsNothing);
    });

    testWidgets('小数位数改为 0 后重新求值显示整数', (WidgetTester tester) async {
      // 场景 5：小数位数设置作用于求值结果格式化（已显示结果不变，
      // 重新求值后按新设置格式化）。
      enlargeTestViewport(tester);
      final CalculatorModel model = CalculatorModel();
      await tester.pumpWidget(_buildPage(model));

      await _tapKey(tester, '2');
      await _tapKey(tester, '+');
      await _tapKey(tester, '3');
      await tester.tap(find.widgetWithText(FilledButton, '='));
      await tester.pump();
      expect(find.text('= 5.00'), findsOneWidget);

      model.updateSettings(model.settings.copyWith(fractionDigits: 0));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '='));
      await tester.pump();

      expect(find.text('= 5'), findsOneWidget);
    });
  });
}
