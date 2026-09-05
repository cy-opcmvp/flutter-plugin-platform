/// 计算器设置模型与文案数据载体。
///
/// 插件包自身零 l10n 配置：用户可见文案由宿主经
/// [CalculatorStringsResolver] 注入 [CalculatorStrings] 载体提供，
/// 插件 UI 只消费载体，不感知具体语言。
library;

import 'package:flutter/widgets.dart';

/// 计算器运行设置。
final class CalculatorSettings {
  /// 创建设置；小数位数限定 0..12。
  const CalculatorSettings({this.fractionDigits = 2, this.showHistory = true})
    : assert(
        fractionDigits >= 0 && fractionDigits <= 12,
        'fractionDigits 必须在 0..12 之间',
      );

  /// 结果展示的小数位数（0..12）。
  final int fractionDigits;

  /// 是否显示历史记录区。
  final bool showHistory;

  /// 复制并替换部分字段。
  CalculatorSettings copyWith({int? fractionDigits, bool? showHistory}) {
    return CalculatorSettings(
      fractionDigits: fractionDigits ?? this.fractionDigits,
      showHistory: showHistory ?? this.showHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorSettings &&
          fractionDigits == other.fractionDigits &&
          showHistory == other.showHistory;

  @override
  int get hashCode => Object.hash(fractionDigits, showHistory);
}

/// 计算器用户可见文案载体（宿主按当前语言填充）。
///
/// 携带位置参数的字段为函数形态，与宿主 arb 的占位符消息一一对应。
final class CalculatorStrings {
  /// 创建文案载体；全部字段必填。
  const CalculatorStrings({
    required this.displayHint,
    required this.historyTitle,
    required this.clearHistory,
    required this.historyEmpty,
    required this.errorEmpty,
    required this.errorUnexpectedToken,
    required this.errorUnbalancedParens,
    required this.errorDivideByZero,
    required this.errorUnknown,
    required this.settingsDecimals,
    required this.settingsDecimalsValue,
    required this.settingsHistoryToggle,
  });

  /// 表达式显示行为空时的占位提示。
  final String displayHint;

  /// 历史记录区标题。
  final String historyTitle;

  /// 清空历史按钮文案。
  final String clearHistory;

  /// 历史为空时的占位文案。
  final String historyEmpty;

  /// 空表达式错误。
  final String errorEmpty;

  /// 无法识别符号错误（参数：position）。
  final String Function(int position) errorUnexpectedToken;

  /// 括号未闭合错误（参数：position）。
  final String Function(int position) errorUnbalancedParens;

  /// 除零错误。
  final String errorDivideByZero;

  /// 未归类错误兜底。
  final String errorUnknown;

  /// 设置项：小数位数标题。
  final String settingsDecimals;

  /// 小数位数当前值描述（参数：value）。
  final String Function(int value) settingsDecimalsValue;

  /// 设置项：显示历史开关标题。
  final String settingsHistoryToggle;
}

/// 文案解析器签名：由宿主注入，从上下文解析当前语言文案。
typedef CalculatorStringsResolver =
    CalculatorStrings Function(BuildContext context);
