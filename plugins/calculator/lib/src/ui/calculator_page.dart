/// 计算器页面 surface：表达式显示行 + 4 列按键网格 + 可关闭历史区。
///
/// 全部样式经 [ThemeTokens] 与宿主 textTheme 取用，插件包内零样式字面量；
/// 文案经宿主注入的 [CalculatorStringsResolver] 获取。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import '../calculator_manifest.dart';
import '../logic/calculator_history.dart';
import '../logic/expression_parser.dart';
import 'calculator_model.dart';
import 'calculator_strings.dart';

/// 计算器页面提供方（builtin，宿主组装根注册）。
final class CalculatorPageProvider implements PluginPageProvider {
  /// 创建页面提供方；模型与文案解析器由宿主注入。
  const CalculatorPageProvider({
    required this.model,
    required this.stringsResolver,
  });

  /// 共享状态模型（与设置提供方共用同一实例）。
  final CalculatorModel model;

  /// 宿主文案解析器。
  final CalculatorStringsResolver stringsResolver;

  @override
  PluginId get pluginId => PluginId.parse(kCalculatorPluginId);

  @override
  Widget buildPage(BuildContext context) {
    return _CalculatorPageView(model: model, stringsResolver: stringsResolver);
  }
}

/// 按键网格布局（4 列 5 行）。
const List<List<String>> _kKeyRows = <List<String>>[
  <String>['C', '(', ')', '/'],
  <String>['7', '8', '9', '*'],
  <String>['4', '5', '6', '-'],
  <String>['1', '2', '3', '+'],
  <String>['0', '.', '%', '='],
];

final class _CalculatorPageView extends StatelessWidget {
  const _CalculatorPageView({
    required this.model,
    required this.stringsResolver,
  });

  final CalculatorModel model;
  final CalculatorStringsResolver stringsResolver;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? _) {
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final ThemeTokens tokens = ThemeTokens.of(context);
    final CalculatorStrings strings = stringsResolver(context);
    final CalculatorSettings settings = model.settings;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DisplayPanel(tokens: tokens, strings: strings, model: model),
          SizedBox(height: tokens.spacing.space3),
          Expanded(
            child: _KeyGrid(tokens: tokens, model: model),
          ),
          if (settings.showHistory) ...<Widget>[
            SizedBox(height: tokens.spacing.space4),
            _HistorySection(tokens: tokens, strings: strings, model: model),
          ],
        ],
      ),
    );
  }
}

/// 表达式显示面板：表达式行 + 结果行/错误行。
final class _DisplayPanel extends StatelessWidget {
  const _DisplayPanel({
    required this.tokens,
    required this.strings,
    required this.model,
  });

  final ThemeTokens tokens;
  final CalculatorStrings strings;
  final CalculatorModel model;

  @override
  Widget build(BuildContext context) {
    final TextStyle displayStyle =
        Theme.of(context).textTheme.titleLarge ?? const TextStyle();
    final CalcError? error = model.error;
    final String? result = model.result;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.space4),
      decoration: BoxDecoration(
        border: Border.all(
          color: tokens.color.outlineVariant,
          width: tokens.shape.strokeHairline,
        ),
        borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            model.expression.isEmpty ? strings.displayHint : model.expression,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: model.expression.isEmpty
                ? displayStyle.copyWith(
                    fontFamily: tokens.typography.familyMono.first,
                    color: tokens.color.onSurfaceVariant,
                  )
                : displayStyle.copyWith(
                    fontFamily: tokens.typography.familyMono.first,
                  ),
          ),
          SizedBox(height: tokens.spacing.space2),
          if (result != null)
            Text(
              '= $result',
              style: displayStyle.copyWith(
                fontFamily: tokens.typography.familyMono.first,
                color: tokens.color.primary,
              ),
            ),
          if (error != null)
            Text(
              calculatorErrorText(error, strings),
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.color.error),
            ),
        ],
      ),
    );
  }
}

/// 按键网格：数字/运算符用 OutlinedButton，等号用 FilledButton，C 清空。
final class _KeyGrid extends StatelessWidget {
  const _KeyGrid({required this.tokens, required this.model});

  final ThemeTokens tokens;
  final CalculatorModel model;

  @override
  Widget build(BuildContext context) {
    final List<Widget> keys = <Widget>[];
    for (final List<String> row in _kKeyRows) {
      for (final String key in row) {
        keys.add(_keyButton(context, key));
      }
    }
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: tokens.spacing.space2,
      crossAxisSpacing: tokens.spacing.space2,
      childAspectRatio: 1.6,
      children: keys,
    );
  }

  Widget _keyButton(BuildContext context, String key) {
    final bool isEquals = key == '=';
    final bool isClear = key == 'C';
    void onPressed() {
      if (isClear) {
        model.clear();
      } else if (isEquals) {
        model.evaluate();
      } else {
        model.appendSymbol(key);
      }
    }

    if (isEquals) {
      return FilledButton(
        onPressed: onPressed,
        child: Text(key, style: Theme.of(context).textTheme.titleMedium),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(key, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// 历史记录区：标题 + 清空按钮 + 可回填条目列表。
final class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.tokens,
    required this.strings,
    required this.model,
  });

  final ThemeTokens tokens;
  final CalculatorStrings strings;
  final CalculatorModel model;

  @override
  Widget build(BuildContext context) {
    final List<CalculatorHistoryEntry> entries = model.history.entries;
    return SizedBox(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  strings.historyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: model.history.clear,
                child: Text(strings.clearHistory),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.space1),
          Expanded(
            child: entries.isEmpty
                ? Text(
                    strings.historyEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.color.onSurfaceVariant,
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CalculatorHistoryEntry entry = entries[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          entry.expression,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontFamily: tokens.typography.familyMono.first,
                              ),
                        ),
                        trailing: Text(
                          entry.value.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: tokens.color.onSurfaceVariant),
                        ),
                        onTap: () => model.replaceExpression(entry.expression),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
