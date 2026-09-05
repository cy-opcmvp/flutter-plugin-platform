/// 计算器页面状态模型（ChangeNotifier）。
///
/// 持有表达式、最近一次结果/错误、设置与历史记录；UI 经
/// [ListenableBuilder] 订阅刷新。错误文案映射交由 UI 层按宿主注入的
/// [CalculatorStrings] 完成，模型只保留结构化 [CalcError]。
///
/// 可选注入 [PluginStorage]（宿主组装根提供，KV 契约见能力接口包）：
/// [loadFromStorage] 恢复持久化设置，设置每次变更即异步写回；存储失败
/// 一律静默降级为内存态（debugPrint），不阻断交互。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import '../calculator_manifest.dart';
import '../logic/calculator_history.dart';
import '../logic/expression_parser.dart';
import 'calculator_strings.dart';

/// 计算器状态模型。
class CalculatorModel extends ChangeNotifier {
  /// 创建模型；缺省默认设置、内存历史与无存储（不持久化）。
  CalculatorModel({
    CalculatorSettings settings = const CalculatorSettings(),
    CalculatorHistory? history,
    PluginStorage? storage,
  }) : _settings = settings,
       _history = history ?? CalculatorHistory(),
       _storage = storage;

  static const ExpressionParser _parser = ExpressionParser();

  /// 设置项在本插件 KV 命名空间下的存储键。
  static const String _kSettingsKey = 'settings';

  final PluginStorage? _storage;

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

  /// 更新设置并异步写回存储（失败静默保留内存态）。
  void updateSettings(CalculatorSettings settings) {
    _settings = settings;
    notifyListeners();
    _persistSettings();
  }

  /// 从存储异步恢复设置（未注入存储时为无操作）。
  ///
  /// 无持久化值或值损坏时保持当前设置；存储失败静默降级。
  Future<void> loadFromStorage() async {
    final PluginStorage? storage = _storage;
    if (storage == null) {
      return;
    }
    final String? raw;
    try {
      raw = await storage.read(
        PluginId.parse(kCalculatorPluginId),
        _kSettingsKey,
      );
    } on PluginFailure catch (error) {
      _debugStorageFailure('read', error);
      return;
    }
    if (raw == null) {
      return;
    }
    try {
      final Map<String, Object?> data = jsonDecode(raw) as Map<String, Object?>;
      _settings = _settings.copyWith(
        fractionDigits: switch (data['fractionDigits']) {
          final int value => value,
          _ => null,
        },
        showHistory: switch (data['showHistory']) {
          final bool value => value,
          _ => null,
        },
      );
      notifyListeners();
    } on FormatException catch (error) {
      debugPrint('calculator settings 损坏，保持当前设置: ${error.message}');
    }
  }

  /// 把当前设置写回 KV（每次变更即写；失败静默保留内存态）。
  void _persistSettings() {
    final PluginStorage? storage = _storage;
    if (storage == null) {
      return;
    }
    final String raw = jsonEncode(<String, Object?>{
      'fractionDigits': _settings.fractionDigits,
      'showHistory': _settings.showHistory,
    });
    unawaited(_writeSettings(storage, raw));
  }

  Future<void> _writeSettings(PluginStorage storage, String raw) async {
    try {
      await storage.write(
        PluginId.parse(kCalculatorPluginId),
        _kSettingsKey,
        raw,
      );
    } on PluginFailure catch (error) {
      _debugStorageFailure('write', error);
    }
  }

  /// 输出存储失败的调试信息（宿主偏好静默降级约定）。
  void _debugStorageFailure(String reason, PluginFailure error) {
    debugPrint(
      'calculator settings $reason 失败: ${error.code} '
      '${error.details}',
    );
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
