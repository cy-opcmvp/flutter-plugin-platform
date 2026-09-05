/// 计算器表达式求值器（纯 Dart、零 Flutter、零 dart:io）。
///
/// 文法（递归下降，`%` 与 `*` `/` 同优先级、左结合）：
/// ```text
/// expression := term (('+' | '-') term)*
/// term       := unary (('*' | '/' | '%') unary)*
/// unary      := '-' unary | primary
/// primary    := NUMBER | '(' expression ')'
/// ```
/// 失败统一收敛为 `PluginFailure('calc.invalid_expression', ...)`，details
/// 携带 reason（empty | unexpectedToken | unbalancedParens | divideByZero）
/// 与 position（出错的字符偏移，从 0 起）；message 面向用户并含位置。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 词法单元：数字串或单字符运算符/括号/非法符号。
typedef _CalcToken = ({String text, int position});

/// 求值结果（值或结构化失败）。
sealed class CalcResult {
  const CalcResult();
}

/// 求值成功。
final class CalcValue extends CalcResult {
  /// 以数值构造成功结果。
  const CalcValue(this.value);

  /// 表达式的数值结果。
  final double value;
}

/// 求值失败。
final class CalcError extends CalcResult {
  /// 以结构化失败构造错误结果。
  const CalcError(this.failure);

  /// 统一错误码 `calc.invalid_expression` 及其 details。
  final PluginFailure failure;
}

/// 表达式求值器入口。
class ExpressionParser {
  /// 常量构造（无状态，可全局共享）。
  const ExpressionParser();

  /// 求值表达式；空输入、语法错误与除零均返回 [CalcError]。
  CalcResult evaluate(String input) {
    if (input.trim().isEmpty) {
      return CalcError(
        PluginFailure(
          'calc.invalid_expression',
          '表达式为空（位置：0）',
          <String, Object?>{'reason': 'empty', 'position': 0},
        ),
      );
    }
    final List<_CalcToken> tokens = _tokenize(input);
    final _TokenStream stream = _TokenStream(tokens);
    final CalcResult parsed = _parseExpression(stream, input);
    if (parsed is CalcError) {
      return parsed;
    }
    final _CalcToken? leftover = stream.peek();
    if (leftover != null) {
      return CalcError(_failure('unexpectedToken', leftover.position));
    }
    return CalcValue((parsed as CalcValue).value);
  }

  /// 扫描全部词法单元；数字串收集 `[0-9]` 与至多一个小数点。
  List<_CalcToken> _tokenize(String input) {
    final List<_CalcToken> tokens = <_CalcToken>[];
    int index = 0;
    while (index < input.length) {
      final String char = input[index];
      if (_isSkippable(char)) {
        index++;
        continue;
      }
      final int position = index;
      if (_isDigit(char) || char == '.') {
        final StringBuffer digits = StringBuffer();
        bool seenDot = false;
        while (index < input.length) {
          final String current = input[index];
          if (_isDigit(current)) {
            digits.write(current);
          } else if (current == '.' && !seenDot) {
            seenDot = true;
            digits.write(current);
          } else {
            break;
          }
          index++;
        }
        tokens.add((text: digits.toString(), position: position));
        continue;
      }
      tokens.add((text: char, position: position));
      index++;
    }
    return tokens;
  }

  static bool _isSkippable(String char) => char.trim().isEmpty;

  static bool _isDigit(String char) {
    final int code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  /// 构造统一错误码的失败；message 为面向用户的中文提示并含位置。
  PluginFailure _failure(String reason, int position) {
    final String describe = switch (reason) {
      'unexpectedToken' => '存在无法识别的符号',
      'unbalancedParens' => '括号未闭合',
      'divideByZero' => '除数不能为零',
      _ => '表达式无效',
    };
    return PluginFailure(
      'calc.invalid_expression',
      '$describe（位置：$position）',
      <String, Object?>{'reason': reason, 'position': position},
    );
  }

  CalcResult _parseExpression(_TokenStream stream, String input) {
    CalcResult left = _parseTerm(stream, input);
    if (left is CalcError) {
      return left;
    }
    while (true) {
      final _CalcToken? token = stream.peek();
      if (token == null || (token.text != '+' && token.text != '-')) {
        return left;
      }
      stream.advance();
      final CalcResult right = _parseTerm(stream, input);
      if (right is CalcError) {
        return right;
      }
      final double rhs = (right as CalcValue).value;
      final double lhs = (left as CalcValue).value;
      left = CalcValue(token.text == '+' ? lhs + rhs : lhs - rhs);
    }
  }

  CalcResult _parseTerm(_TokenStream stream, String input) {
    CalcResult left = _parseUnary(stream, input);
    if (left is CalcError) {
      return left;
    }
    while (true) {
      final _CalcToken? token = stream.peek();
      if (token == null ||
          (token.text != '*' && token.text != '/' && token.text != '%')) {
        return left;
      }
      stream.advance();
      final CalcResult right = _parseUnary(stream, input);
      if (right is CalcError) {
        return right;
      }
      final double rhs = (right as CalcValue).value;
      final double lhs = (left as CalcValue).value;
      if (rhs == 0 && token.text != '*') {
        return CalcError(_failure('divideByZero', token.position));
      }
      final double value = switch (token.text) {
        '*' => lhs * rhs,
        '/' => lhs / rhs,
        _ => lhs % rhs,
      };
      left = CalcValue(value);
    }
  }

  CalcResult _parseUnary(_TokenStream stream, String input) {
    final _CalcToken? token = stream.peek();
    if (token == null) {
      return CalcError(_failure('unexpectedToken', input.length));
    }
    if (token.text == '-') {
      stream.advance();
      final CalcResult operand = _parseUnary(stream, input);
      if (operand is CalcError) {
        return operand;
      }
      return CalcValue(-(operand as CalcValue).value);
    }
    return _parsePrimary(stream, input);
  }

  CalcResult _parsePrimary(_TokenStream stream, String input) {
    final _CalcToken? token = stream.peek();
    if (token == null) {
      return CalcError(_failure('unexpectedToken', input.length));
    }
    if (token.text == '(') {
      stream.advance();
      final CalcResult inner = _parseExpression(stream, input);
      if (inner is CalcError) {
        return inner;
      }
      final _CalcToken? closing = stream.peek();
      if (closing == null || closing.text != ')') {
        // 未闭合时报告起始括号位置，便于定位缺失一侧的括号。
        return CalcError(_failure('unbalancedParens', token.position));
      }
      stream.advance();
      return inner;
    }
    final double? value = double.tryParse(token.text);
    if (value == null) {
      return CalcError(_failure('unexpectedToken', token.position));
    }
    stream.advance();
    return CalcValue(value);
  }
}

/// 词法游标：顺序只读推进，支持预读一个单元。
final class _TokenStream {
  _TokenStream(this._tokens);

  final List<_CalcToken> _tokens;
  int _index = 0;

  _CalcToken? peek() => _index < _tokens.length ? _tokens[_index] : null;

  void advance() {
    _index++;
  }
}
