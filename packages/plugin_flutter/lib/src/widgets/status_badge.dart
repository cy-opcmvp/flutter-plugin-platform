/// 可用性状态徽章。
///
/// 三态（可用 / 停用 / 不可用）+ 不可用原因的结构化呈现，并按主题方向做
/// 差异化（冻结美术文档「徽章形态」对照表）：
/// - precision_tools：4px 圆角小方读数徽章（状态点 + 双字短语）；不可用时
///   第二行展开等宽原因码。
/// - warm_life：缝线感胶囊徽章（容器色底 + 同系深色字）；不可用时附一句
///   柔和人话 + 「查看原因」链接（跳转由宿主注入）。
/// - dark_pro：断点圆点 + 等宽状态文案；点击展开原因明细。
library;

import 'package:flutter/material.dart';

import '../generated/plugin_flutter_l10n.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'token_text_style.dart';

/// 徽章状态：可用 / 停用（用户停用）/ 不可用（环境不满足）。
enum StatusBadgeState { available, disabled, unavailable }

/// 可用性状态徽章。
class StatusBadge extends StatefulWidget {
  /// 创建徽章；仅 [StatusBadgeState.unavailable] 时使用原因参数。
  const StatusBadge({
    super.key,
    required this.state,
    this.reasonCode,
    this.reasonText,
    this.onViewReason,
  });

  /// 徽章状态。
  final StatusBadgeState state;

  /// 结构化原因码（如 `resolution.unsupported_target`），可空。
  final String? reasonCode;

  /// 已本地化的人话原因，可空。
  final String? reasonText;

  /// 「查看原因」入口回调（warm_life 方向展示该链接；由宿主注入导航）。
  final VoidCallback? onViewReason;

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = PluginFlutterL10n.of(context);
    final label = switch (widget.state) {
      StatusBadgeState.available => l10n.statusAvailable,
      StatusBadgeState.disabled => l10n.statusDisabled,
      StatusBadgeState.unavailable => l10n.statusUnavailable,
    };
    switch (tokens.preset) {
      case AppThemePreset.precisionTools:
        return _buildPrecision(tokens, label);
      case AppThemePreset.warmLife:
        return _buildWarm(tokens, label);
      case AppThemePreset.darkPro:
        return _buildDarkPro(tokens, label);
    }
  }

  /// 徽章状态对应的（底色, 前景）容器对。
  ///
  /// 可用=success 容器对、停用=中性灰、不可用=warning 容器对（容器内文字
  /// 一律用 onXxxContainer，文档未定义 onSuccess/onWarning 文字角色）。
  (Color, Color) _stateColors(ThemeTokens tokens) {
    final scheme = Theme.of(context).colorScheme;
    return switch (widget.state) {
      StatusBadgeState.available => (
        tokens.color.successContainer,
        tokens.color.onSuccessContainer,
      ),
      StatusBadgeState.disabled => (
        scheme.surfaceContainerHighest,
        tokens.color.onSurfaceVariant,
      ),
      StatusBadgeState.unavailable => (
        tokens.color.warningContainer,
        tokens.color.onWarningContainer,
      ),
    };
  }

  /// precision_tools：4px 圆角小方徽章 + 等宽原因码第二行。
  Widget _buildPrecision(ThemeTokens tokens, String label) {
    final (bg, fg) = _stateColors(tokens);
    final shape = tokens.shape;
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.space2,
        vertical: tokens.spacing.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(shape.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _dot(tokens, fg),
          SizedBox(width: tokens.spacing.space1),
          Text(label, style: _tokenText(tokens.typography.label, fg)),
        ],
      ),
    );
    final code = widget.reasonCode;
    final showCode =
        widget.state == StatusBadgeState.unavailable && code != null;
    if (!showCode) {
      return pill;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        pill,
        SizedBox(height: tokens.spacing.space1),
        // 文档：不可用时在卡内第二行以等宽原因码展开（大写展示）。
        Text(
          code.toUpperCase(),
          style: _tokenText(tokens.typography.effectiveMonoLabel, fg),
        ),
      ],
    );
  }

  /// warm_life：缝线感胶囊 + 人话原因 + 「查看原因」链接。
  Widget _buildWarm(ThemeTokens tokens, String label) {
    final (bg, fg) = _stateColors(tokens);
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.space2,
        vertical: tokens.spacing.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.shape.radiusXs),
        // 缝线感：同系前景色的 hairline 描边。
        border: Border.all(color: fg, width: tokens.shape.strokeHairline),
      ),
      child: Text(label, style: _tokenText(tokens.typography.label, fg)),
    );
    if (widget.state != StatusBadgeState.unavailable) {
      return pill;
    }
    final onViewReason = widget.onViewReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        pill,
        SizedBox(height: tokens.spacing.space1),
        Text(
          widget.reasonText ?? widget.reasonCode ?? '',
          style: _tokenText(
            tokens.typography.label,
            tokens.color.onSurfaceVariant,
          ),
        ),
        if (onViewReason != null)
          TextButton(
            onPressed: onViewReason,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              PluginFlutterL10n.of(context).statusViewReason,
              style: _tokenText(tokens.typography.label, tokens.color.primary),
            ),
          ),
      ],
    );
  }

  /// dark_pro：断点圆点 + 等宽状态文案，点击展开原因明细。
  Widget _buildDarkPro(ThemeTokens tokens, String label) {
    final (bg, fg) = _stateColors(tokens);
    final code = widget.reasonCode;
    final hasReason =
        widget.state == StatusBadgeState.unavailable &&
        (code != null || widget.reasonText != null);
    final head = InkWell(
      onTap: hasReason ? () => setState(() => _expanded = !_expanded) : null,
      borderRadius: BorderRadius.circular(tokens.shape.radiusXs),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.space2,
          vertical: tokens.spacing.space1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.shape.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _dot(tokens, fg),
            SizedBox(width: tokens.spacing.space1),
            // 文档：状态以等宽码呈现，这里用等宽链渲染本地化短语。
            Text(label, style: _monoText(tokens, fg)),
          ],
        ),
      ),
    );
    if (!hasReason || !_expanded) {
      return head;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        head,
        SizedBox(height: tokens.spacing.space1),
        Text(
          widget.reasonText ?? code ?? '',
          style: _tokenText(
            tokens.typography.effectiveMonoLabel,
            tokens.color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 状态点：直径取 label 行高之半（由令牌派生，不发明新值）。
  Widget _dot(ThemeTokens tokens, Color color) {
    final diameter = tokens.typography.label.lineHeight / 2;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// 界面主字族样式。
  TextStyle _tokenText(TokenTypeSpec spec, Color color) {
    return buildTokenTextStyle(
      spec,
      familyChain: ThemeTokens.of(context).typography.family,
      color: color,
    );
  }

  /// 等宽字族样式。
  TextStyle _monoText(ThemeTokens tokens, Color color) {
    return buildTokenTextStyle(
      tokens.typography.effectiveMonoLabel,
      familyChain: tokens.typography.familyMono,
      color: color,
    );
  }
}
