/// 计算器 UI 测试共享骨架：主题令牌注入 + 固定文案载体。
///
/// 插件包自身零 l10n 配置：文案经固定 [CalculatorStrings] 载体模拟
/// 宿主注入，页面/设置视图只消费载体。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

/// 固定文案函数（const 闭包不可用，以顶层函数 tear-off 满足 const 约束）。
String _unexpectedToken(int position) => '存在无法识别的符号（位置：$position）';

/// 固定文案函数：括号未闭合。
String _unbalancedParens(int position) => '括号未闭合（位置：$position）';

/// 固定文案函数：小数位数描述。
String _decimalsValue(int value) => '保留 $value 位小数';

/// 测试固定文案载体。
final CalculatorStrings kTestStrings = CalculatorStrings(
  displayHint: '输入表达式',
  historyTitle: '历史记录',
  clearHistory: '清空',
  historyEmpty: '暂无历史记录',
  errorEmpty: '表达式为空（位置：0）',
  errorUnexpectedToken: _unexpectedToken,
  errorUnbalancedParens: _unbalancedParens,
  errorDivideByZero: '除数不能为零',
  errorUnknown: '表达式无效',
  settingsDecimals: '小数位数',
  settingsDecimalsValue: _decimalsValue,
  settingsHistoryToggle: '显示历史记录',
);

/// 文案解析器：恒定返回测试载体（语言无关）。
CalculatorStringsResolver kTestResolver = _resolve;

/// 解析实现。
CalculatorStrings _resolve(BuildContext context) => kTestStrings;

/// 以主题令牌装配的 MaterialApp 包裹 [child] 供组件测试渲染。
Widget buildCalculatorHarness(Widget child) {
  return MaterialApp(
    theme: AppTheme.build(AppThemePreset.warmLife, Brightness.light),
    home: Scaffold(body: child),
  );
}

/// 放大测试视口，保证按键网格与历史区全部落在视口内可点击。
void enlargeTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
