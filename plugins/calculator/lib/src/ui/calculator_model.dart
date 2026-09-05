/// 计算器页面状态模型（ChangeNotifier）。
///
/// 持有表达式、最近一次结果/错误、设置与历史记录；UI 经
/// [ListenableBuilder] 订阅刷新。错误文案映射交由 UI 层按宿主注入的
/// [CalculatorStrings] 完成，模型只保留结构化 [CalcError]。
library;

import 'package:flutter/foundation.dart';

import '../logic/calculator_history.dart';
import '../logic/expression_parser.dart';
import 'calculator_strings.dart';

/// 计算器状态模型。
class CalculatorModel extends ChangeNotifier {
  /// 创建模型；缺省默认设置与内存历史。
  CalculatorModel({
    CalculatorSettings settings = const CalculatorSettings(),
    CalculatorHistory? history,
  }) : _settings = settings,
       _history = history ?? CalculatorHistory();

  static const ExpressionParser _parser = ExpressionParser();

  CalculatorSettings _settings;
  final CalculatorHistory _history;
  String _expression = '';
  String? _result;
  CalcError? _error;

  /// 当前表达式原文。
  String get expression => _expression;

  /// 最近一次成功求值的格式化结果（无则为 null）。
  String? get result => _result;

  /// 最近一次失败的结构化错误（无则为 null）。
  CalcError? get error => _error;

  /// 当前设置。
  CalculatorSettings get settings => _settings;

  /// 历史记录门面（条目快照经 [CalculatorHistory.entries] 取用）。
  CalculatorHistory get history => _history;

  /// 向表达式末尾追加符号并清除既有错误显示。
  void appendSymbol(String symbol) {
    _error = null;
    _expression += symbol;
    notifyListeners();
  }

  /// 清空表达式与结果/错误。
  void clear() {
    _expression = '';
    _result = null;
    _error = null;
    notifyListeners();
  }

  /// 用给定表达式整体替换当前输入（历史回填入口）。
  void replaceExpression(String expression) {
    _expression = expression;
    _result = null;
    _error = null;
    notifyListeners();
  }

  /// 更新设置。
  void updateSettings(CalculatorSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  /// 求值当前表达式：成功记录格式化结果（按设置写入历史），失败记录错误。
  void evaluate() {
    final CalcResult outcome = _parser.evaluate(_expression);
    switch (outcome) {
      case CalcValue(:final double value):
        _result = value.toStringAsFixed(_settings.fractionDigits);
        _error = null;
        if (_settings.showHistory) {
          _history.add(
            CalculatorHistoryEntry(expression: _expression, value: value),
          );
        }
      case CalcError():
        _error = outcome;
        _result = null;
    }
    notifyListeners();
  }
}

/// 把结构化错误映射为宿主语言的展示文案。
String calculatorErrorText(CalcError error, CalculatorStrings strings) {
  final Map<String, Object?> details = error.failure.details;
  final String reason = '${details['reason']}';
  final int position = switch (details['position']) {
    final int value => value,
    _ => 0,
  };
  return switch (reason) {
    'empty' => strings.errorEmpty,
    'unexpectedToken' => strings.errorUnexpectedToken(position),
    'unbalancedParens' => strings.errorUnbalancedParens(position),
    'divideByZero' => strings.errorDivideByZero,
    _ => strings.errorUnknown,
  };
}
