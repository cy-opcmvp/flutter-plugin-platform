/// 计算器插件宿主接线（F4-03）。
///
/// 计算器包自身零 l10n 配置：宿主经 [calculatorStrings] 把 `calc*` 文案
/// （宿主 arb）映射为插件包定义的 [CalculatorStrings] 载体，再由
/// [hostCalculatorStringsResolver] 在构建上下文时解析当前语言注入
/// 页面/设置提供方。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter/widgets.dart';

import '../generated/host_l10n.dart';

/// 把宿主 l10n 的计算器文案映射为插件文案载体（字段一一对应）。
CalculatorStrings calculatorStrings(HostL10n l10n) {
  return CalculatorStrings(
    displayHint: l10n.calcDisplayHint,
    historyTitle: l10n.calcHistoryTitle,
    clearHistory: l10n.calcClearHistory,
    historyEmpty: l10n.calcHistoryEmpty,
    errorEmpty: l10n.calcErrorEmpty,
    errorUnexpectedToken: l10n.calcErrorUnexpectedToken,
    errorUnbalancedParens: l10n.calcErrorUnbalancedParens,
    errorDivideByZero: l10n.calcErrorDivideByZero,
    errorUnknown: l10n.calcErrorUnknown,
    settingsDecimals: l10n.calcSettingsDecimals,
    settingsDecimalsValue: l10n.calcSettingsDecimalsValue,
    settingsHistoryToggle: l10n.calcSettingsHistoryToggle,
  );
}

/// 构建宿主文案解析器：从上下文取宿主 l10n 再映射为插件载体。
CalculatorStringsResolver hostCalculatorStringsResolver() {
  CalculatorStrings resolve(BuildContext context) {
    return calculatorStrings(HostL10n.of(context));
  }

  return resolve;
}
