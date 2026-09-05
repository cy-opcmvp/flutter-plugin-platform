/// 插件目录卡片。
///
/// 名称 / 描述 / 版本 / 可用性徽章，并按主题方向做形态差异化（冻结美术
/// 文档「PluginCard」条目）：
/// - precision_tools：1px 描边平面卡（无阴影），版本号右对齐等宽。
/// - warm_life：浮起的圆角纸卡（e1 暖棕阴影），版本为容器色胶囊。
/// - dark_pro：6px 圆角行卡，左缘 2px gutter 状态线（可用=主色 /
///   停用=灰 / 不可用=断言红），ID 风格版本号等宽呈现。
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'status_badge.dart';
import 'token_text_style.dart';

/// 插件目录卡片。
class PluginCard extends StatelessWidget {
  /// 创建卡片；徽章原因参数仅不可用态需要。
  const PluginCard({
    super.key,
    required this.title,
    required this.description,
    required this.version,
    required this.state,
    this.reasonCode,
    this.reasonText,
    this.onViewReason,
    this.onTap,
  });

  /// 插件名称。
  final String title;

  /// 一句话描述。
  final String description;

  /// 版本号（如 `1.0.0`）。
  final String version;

  /// 可用性状态。
  final StatusBadgeState state;

  /// 结构化原因码（不可用时展示），可空。
  final String? reasonCode;

  /// 已本地化的人话原因，可空。
  final String? reasonText;

  /// 「查看原因」入口回调（透传给徽章），可空。
  final VoidCallback? onViewReason;

  /// 整卡点击回调（进入详情），可空。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final colors = tokens.color;
    final shape = tokens.shape;
    final radius = BorderRadius.circular(shape.radiusMd);
    final decoration = switch (tokens.preset) {
      AppThemePreset.warmLife => BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: tokens.elevation.shadowsFor(tokens.elevation.e1),
      ),
      AppThemePreset.precisionTools => BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: colors.outlineVariant,
          width: shape.strokeHairline,
        ),
      ),
      AppThemePreset.darkPro => BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border(
          top: _hairline(tokens),
          right: _hairline(tokens),
          bottom: _hairline(tokens),
          // 文档：左缘 2px gutter 状态线（方向 C 签名）。
          left: BorderSide(color: _gutterColor(tokens), width: 2),
        ),
      ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: decoration,
          padding: EdgeInsets.all(tokens.spacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.space2),
                  StatusBadge(
                    state: state,
                    reasonCode: reasonCode,
                    reasonText: reasonText,
                    onViewReason: onViewReason,
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.space1),
              _buildVersion(context, tokens),
              SizedBox(height: tokens.spacing.space2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BorderSide _hairline(ThemeTokens tokens) {
    return BorderSide(
      color: tokens.color.outlineVariant,
      width: tokens.shape.strokeHairline,
    );
  }

  /// gutter 状态线颜色：可用=主色、停用=中性灰、不可用=断言红。
  Color _gutterColor(ThemeTokens tokens) {
    return switch (state) {
      StatusBadgeState.available => tokens.color.primary,
      StatusBadgeState.disabled => tokens.neutral.n4,
      StatusBadgeState.unavailable => tokens.color.error,
    };
  }

  /// 版本呈现：warm_life 为容器色胶囊，其余方向右对齐等宽文本。
  Widget _buildVersion(BuildContext context, ThemeTokens tokens) {
    if (tokens.preset == AppThemePreset.warmLife) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.space2,
          vertical: tokens.spacing.space1,
        ),
        decoration: BoxDecoration(
          color: tokens.color.primaryContainer,
          borderRadius: BorderRadius.circular(tokens.shape.radiusXs),
        ),
        child: Text(
          'v$version',
          style: buildTokenTextStyle(
            tokens.typography.label,
            familyChain: tokens.typography.family,
            color: tokens.color.onPrimaryContainer,
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        version,
        style: buildTokenTextStyle(
          tokens.typography.effectiveMonoLabel,
          familyChain: tokens.typography.familyMono,
          color: tokens.color.onSurfaceVariant,
        ),
      ),
    );
  }
}
