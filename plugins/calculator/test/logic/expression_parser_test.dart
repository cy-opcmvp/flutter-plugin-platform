// 覆盖场景清单（计划 F4-03 Step 2，失败测试先行，相似断言合并）：
// 1. 四则与取模：运算优先级、左结合。
// 2. 括号改变优先级（含嵌套）。
// 3. 一元负号（表达式首位与运算符之后）。
// 4. 整数与小数字面量、前后空白容忍。
// 5. 除零与模零 → calc.invalid_expression / divideByZero。
// 6. 非法字符 → unexpectedToken（含位置）。
// 7. 未闭合括号 → unbalancedParens。
// 8. 空表达式（空串/纯空白）→ empty（position 0）。
// 9. 表达式后存在剩余 token → unexpectedToken（位置为剩余 token 起点）。
// 10. 错误结构完整：code 固定、details.reason / details.position、message 含位置。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/src/logic/expression_parser.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

void main() {
  const ExpressionParser parser = ExpressionParser();

  void expectValue(String input, double expected) {
    final CalcResult result = parser.evaluate(input);
    expect(result, isA<CalcValue>(), reason: '输入 "$input" 应求值成功');
    expect(
      (result as CalcValue).value,
      closeTo(expected, 1e-9),
      reason: '输入 "$input"',
    );
  }

  void expectFailure(String input, String reason, int position) {
    final CalcResult result = parser.evaluate(input);
    expect(result, isA<CalcError>(), reason: '输入 "$input" 应求值失败');
    final PluginFailure failure = (result as CalcError).failure;
    expect(failure.code, 'calc.invalid_expression');
    expect(failure.details['reason'], reason);
    expect(failure.details['position'], position);
    expect(failure.message, contains('位置'));
  }

  group('ExpressionParser.evaluate', () {
    test('四则与取模遵循优先级并左结合', () {
      expectValue('2+3*4', 14);
      expectValue('10-4-3', 3);
      expectValue('20/4/5', 1);
      expectValue('7%3', 1);
      expectValue('10%4*2', 4);
    });

    test('括号改变优先级（含嵌套）', () {
      expectValue('(2+3)*4', 20);
      expectValue('((1+2)*(3+4)-10)/4', 2.75);
    });

    test('一元负号出现在表达式首位与运算符之后', () {
      expectValue('-3+5', 2);
      expectValue('2*-3', -6);
      expectValue('-(2+3)', -5);
    });

    test('整数与小数字面量、前后空白容忍', () {
      expectValue('1.5*2', 3);
      expectValue(' 1+2 ', 3);
      expectValue('0.1+0.2', 0.3);
    });

    test('除零与模零给出 divideByZero（位置为运算符位置）', () {
      expectFailure('1/0', 'divideByZero', 1);
      expectFailure('5%0', 'divideByZero', 1);
      expectFailure('8/(3-3)', 'divideByZero', 1);
    });

    test('非法字符给出 unexpectedToken（位置为字符起点）', () {
      expectFailure('2+a', 'unexpectedToken', 2);
      expectFailure('1.2.3', 'unexpectedToken', 3);
    });

    test('未闭合括号给出 unbalancedParens', () {
      expectFailure('(1+2', 'unbalancedParens', 0);
      expectFailure('(1+(2-1)', 'unbalancedParens', 0);
    });

    test('空表达式给出 empty（position 0）', () {
      expectFailure('', 'empty', 0);
      expectFailure('   ', 'empty', 0);
    });

    test('表达式后存在剩余 token 给出 unexpectedToken', () {
      expectFailure('1 2', 'unexpectedToken', 2);
      expectFailure('2+3)', 'unexpectedToken', 3);
    });
  });
}
