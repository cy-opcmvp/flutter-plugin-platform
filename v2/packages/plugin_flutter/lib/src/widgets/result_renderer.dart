/// 声明式结果渲染器。
///
/// 按 [ResultDescriptor] 渲染四类结果（text / table / image / fields）。
/// 图片因包内不得依赖 dart:io，渲染为结构化占位框（accent 描边 + 等宽
/// 路径 + 说明文案），位图解码延后至宿主提供文件能力（已记偏差）。
library;

import 'package:flutter/material.dart';

import '../generated/plugin_flutter_l10n.dart';
import '../surface/declarative_result.dart';
import '../theme/tokens.dart';
import 'token_text_style.dart';

/// 声明式结果渲染器。
class ResultRenderer extends StatelessWidget {
  /// 创建渲染器。
  const ResultRenderer({super.key, required this.descriptor});

  /// 结果描述符。
  final ResultDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return switch (descriptor) {
      TextResultDescriptor result => _buildText(context, tokens, result),
      TableResultDescriptor result => _buildTable(context, tokens, result),
      ImageResultDescriptor result => _buildImage(context, tokens, result),
      FieldsResultDescriptor result => _buildFields(context, tokens, result),
    };
  }

  Widget _buildText(
    BuildContext context,
    ThemeTokens tokens,
    TextResultDescriptor result,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.space3),
      decoration: BoxDecoration(
        color: tokens.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
      ),
      child: Text(result.text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildTable(
    BuildContext context,
    ThemeTokens tokens,
    TableResultDescriptor result,
  ) {
    final l10n = PluginFlutterL10n.of(context);
    if (result.rows.isEmpty) {
      return Text(
        l10n.resultTableEmpty,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: tokens.color.onSurfaceVariant),
      );
    }
    final List<Widget> children = <Widget>[
      Row(
        children: <Widget>[
          for (final String column in result.columns)
            Expanded(
              child: Text(
                column,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: buildTokenTextStyle(
                  tokens.typography.label,
                  familyChain: tokens.typography.family,
                  color: tokens.color.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      Container(
        height: tokens.shape.strokeHairline,
        color: tokens.color.outlineVariant,
      ),
      for (final List<String> row in result.rows) ...<Widget>[
        Row(
          children: <Widget>[
            for (final String cell in row)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: tokens.spacing.space2,
                  ),
                  child: Text(
                    cell,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
        Container(
          height: tokens.shape.strokeHairline,
          color: tokens.color.outlineVariant,
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildImage(
    BuildContext context,
    ThemeTokens tokens,
    ImageResultDescriptor result,
  ) {
    final l10n = PluginFlutterL10n.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.space4),
      decoration: BoxDecoration(
        border: Border.all(
          color: tokens.color.primary,
          width: tokens.shape.strokeAccent,
        ),
        borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.image_outlined, color: tokens.color.onSurfaceVariant),
          SizedBox(width: tokens.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  result.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: buildTokenTextStyle(
                    tokens.typography.effectiveMonoLabel,
                    familyChain: tokens.typography.familyMono,
                    color: tokens.color.onSurface,
                  ),
                ),
                SizedBox(height: tokens.spacing.space1),
                Text(
                  l10n.resultImageUnavailable(result.path),
                  style: buildTokenTextStyle(
                    tokens.typography.label,
                    familyChain: tokens.typography.family,
                    color: tokens.color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(
    BuildContext context,
    ThemeTokens tokens,
    FieldsResultDescriptor result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final ResultField field in result.fields)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    field.label,
                    style: buildTokenTextStyle(
                      tokens.typography.label,
                      familyChain: tokens.typography.family,
                      color: tokens.color.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    field.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
