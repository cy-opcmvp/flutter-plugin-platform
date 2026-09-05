/// 计算器设置 surface：小数位数滑块（0..12）+ 历史显示开关。
///
/// 修改即时生效（写回共享 [CalculatorModel]）；文案经宿主注入的
/// [CalculatorStringsResolver] 获取，插件包内零样式字面量。
library;

import 'package:flutter/material.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'calculator_model.dart';
import 'calculator_strings.dart';

/// 计算器设置提供方（与页面提供方共享同一模型实例）。
final class CalculatorSettingsProvider implements PluginSettingsProvider {
  /// 创建设置提供方。
  const CalculatorSettingsProvider({
    required this.model,
    required this.stringsResolver,
  });

  /// 共享状态模型。
  final CalculatorModel model;

  /// 宿主文案解析器。
  final CalculatorStringsResolver stringsResolver;

  @override
  Widget buildSettings(BuildContext context) {
    return _CalculatorSettingsView(
      model: model,
      stringsResolver: stringsResolver,
    );
  }
}

final class _CalculatorSettingsView extends StatelessWidget {
  const _CalculatorSettingsView({
    required this.model,
    required this.stringsResolver,
  });

  final CalculatorModel model;
  final CalculatorStringsResolver stringsResolver;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = ThemeTokens.of(context);
    final CalculatorStrings strings = stringsResolver(context);
    return ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.settingsDecimals,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: model.settings.fractionDigits.toDouble(),
              min: 0,
              max: 12,
              divisions: 12,
              label: '${model.settings.fractionDigits}',
              onChanged: (double value) => model.updateSettings(
                model.settings.copyWith(fractionDigits: value.round()),
              ),
            ),
            Text(
              strings.settingsDecimalsValue(model.settings.fractionDigits),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.color.onSurfaceVariant,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsHistoryToggle),
              value: model.settings.showHistory,
              onChanged: (bool value) => model.updateSettings(
                model.settings.copyWith(showHistory: value),
              ),
            ),
          ],
        );
      },
    );
  }
}
