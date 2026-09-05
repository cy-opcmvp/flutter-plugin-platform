/// 设计令牌契约与令牌载体。
///
/// 依据冻结美术文档（`docs/superpowers/design/m3-art-direction.md`）定义统一
/// 令牌 schema：色彩（M3 角色全家 + success/warning 语义扩展 + 中性阶）、字体
/// （字族回退链 + 五级字号）、圆角四档、描边三档、间距七档、海拔、动效时长与
/// 缓动、可动效语义边界。
///
/// [ThemeTokens] 以 `ThemeExtension` 挂进 [ThemeData]，组件通过
/// [ThemeTokens.of] 取用。**任何具体取值只允许出现在 `presets/` 目录**，本
/// 文件与组件源码不得出现颜色/字号字面量（由静态扫描测试固化）。
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 单级字体规格：字号 / 行高 / 字重。
final class TokenTypeSpec {
  /// 创建字体规格；[size] 与 [lineHeight] 单位为逻辑像素。
  const TokenTypeSpec({
    required this.size,
    required this.lineHeight,
    required this.weight,
  });

  /// 字号（逻辑像素）。
  final double size;

  /// 行高（逻辑像素）。
  final double lineHeight;

  /// 字重。
  final FontWeight weight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenTypeSpec &&
          size == other.size &&
          lineHeight == other.lineHeight &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(size, lineHeight, weight);

  @override
  String toString() => 'TokenTypeSpec($size/$lineHeight/w${weight.index})';
}

/// 色彩令牌组：M3 颜色角色全家 + success/warning 语义扩展。
///
/// success/warning 不进入 [ColorScheme]（M3 无对应角色），随 [ThemeTokens]
/// 主题扩展下发；组件经 [ThemeTokens.color] 或 [ThemeTokens.semantic] 取用。
///
/// onSuccess/onWarning 已于 2026-09-05 补充定义（m3-art-direction.md
/// 补充定义节），三 preset 统一取值并经 WCAG 实测 ≥4.5。
final class TokenColors {
  /// 创建色彩令牌组；全部字段均为冻结文档中的必填角色。
  const TokenColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.scrim,
    required this.shadow,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color scrim;
  final Color shadow;
  final Color success;

  /// 语义色上的文字色（文档未定义，恒为 null，见类注释）。
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;

  /// 语义色上的文字色（文档未定义，恒为 null，见类注释）。
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// success/warning 语义色视图（与 M3 角色并列的扩展语义组）。
  SemanticColors get semantic => SemanticColors(
    success: success,
    onSuccess: onSuccess,
    successContainer: successContainer,
    onSuccessContainer: onSuccessContainer,
    warning: warning,
    onWarning: onWarning,
    warningContainer: warningContainer,
    onWarningContainer: onWarningContainer,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenColors &&
          primary == other.primary &&
          onPrimary == other.onPrimary &&
          primaryContainer == other.primaryContainer &&
          onPrimaryContainer == other.onPrimaryContainer &&
          secondary == other.secondary &&
          onSecondary == other.onSecondary &&
          secondaryContainer == other.secondaryContainer &&
          onSecondaryContainer == other.onSecondaryContainer &&
          tertiary == other.tertiary &&
          onTertiary == other.onTertiary &&
          tertiaryContainer == other.tertiaryContainer &&
          onTertiaryContainer == other.onTertiaryContainer &&
          error == other.error &&
          onError == other.onError &&
          errorContainer == other.errorContainer &&
          onErrorContainer == other.onErrorContainer &&
          surface == other.surface &&
          surfaceContainerLowest == other.surfaceContainerLowest &&
          surfaceContainerLow == other.surfaceContainerLow &&
          surfaceContainer == other.surfaceContainer &&
          surfaceContainerHigh == other.surfaceContainerHigh &&
          surfaceContainerHighest == other.surfaceContainerHighest &&
          surfaceVariant == other.surfaceVariant &&
          onSurface == other.onSurface &&
          onSurfaceVariant == other.onSurfaceVariant &&
          outline == other.outline &&
          outlineVariant == other.outlineVariant &&
          inverseSurface == other.inverseSurface &&
          onInverseSurface == other.onInverseSurface &&
          scrim == other.scrim &&
          shadow == other.shadow &&
          success == other.success &&
          onSuccess == other.onSuccess &&
          successContainer == other.successContainer &&
          onSuccessContainer == other.onSuccessContainer &&
          warning == other.warning &&
          onWarning == other.onWarning &&
          warningContainer == other.warningContainer &&
          onWarningContainer == other.onWarningContainer;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    primary,
    onPrimary,
    primaryContainer,
    onPrimaryContainer,
    secondary,
    onSecondary,
    secondaryContainer,
    onSecondaryContainer,
    tertiary,
    onTertiary,
    tertiaryContainer,
    onTertiaryContainer,
    error,
    onError,
    errorContainer,
    onErrorContainer,
    surface,
    surfaceContainerLowest,
    surfaceContainerLow,
    surfaceContainer,
    surfaceContainerHigh,
    surfaceContainerHighest,
    surfaceVariant,
    onSurface,
    onSurfaceVariant,
    outline,
    outlineVariant,
    inverseSurface,
    onInverseSurface,
    scrim,
    shadow,
    success,
    onSuccess,
    successContainer,
    onSuccessContainer,
    warning,
    onWarning,
    warningContainer,
    onWarningContainer,
  ]);
}

/// 语义扩展色组（success/warning）。
final class SemanticColors {
  /// 创建语义色组。
  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color success;

  /// 语义色上的文字色（文档未定义，恒为 null，见 [TokenColors] 注释）。
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;

  /// 语义色上的文字色（文档未定义，恒为 null，见 [TokenColors] 注释）。
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticColors &&
          success == other.success &&
          onSuccess == other.onSuccess &&
          successContainer == other.successContainer &&
          onSuccessContainer == other.onSuccessContainer &&
          warning == other.warning &&
          onWarning == other.onWarning &&
          warningContainer == other.warningContainer &&
          onWarningContainer == other.onWarningContainer;

  @override
  int get hashCode => Object.hash(
    success,
    onSuccess,
    successContainer,
    onSuccessContainer,
    warning,
    onWarning,
    warningContainer,
    onWarningContainer,
  );
}

/// 字体令牌组：字族回退链 + 五级字号规格。
final class TokenTypeSet {
  /// 创建字体令牌组。
  ///
  /// [familySerif] 为装饰衬线回退链，仅限空状态警句使用；未定义衬线的方向
  /// 传 null。[monoLabel] 为等宽读数标签规格，未定义等宽签名的方向传 null。
  const TokenTypeSet({
    required this.family,
    required this.familyMono,
    this.familySerif,
    required this.display,
    required this.title,
    required this.titleSecondary,
    required this.body,
    required this.label,
    this.monoLabel,
  });

  /// 界面主字族回退链（首项为首选字族，其余为回退）。
  final List<String> family;

  /// 等宽字族回退链。
  final List<String> familyMono;

  /// 装饰衬线回退链（仅空状态警句；无该令牌的方向为 null）。
  final List<String>? familySerif;

  /// display 级（页面主标题）。
  final TokenTypeSpec display;

  /// title 级（主标题）。
  final TokenTypeSpec title;

  /// title 次级。
  final TokenTypeSpec titleSecondary;

  /// body 级（正文）。
  final TokenTypeSpec body;

  /// label 级（辅助文本）。
  final TokenTypeSpec label;

  /// 等宽读数标签（无等宽签名的方向为 null，退回 [label]）。
  final TokenTypeSpec? monoLabel;

  /// 生效的等宽标签规格：未定义时回退到 [label]。
  TokenTypeSpec get effectiveMonoLabel => monoLabel ?? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenTypeSet &&
          _listEquals(family, other.family) &&
          _listEquals(familyMono, other.familyMono) &&
          _listEquals(familySerif, other.familySerif) &&
          display == other.display &&
          title == other.title &&
          titleSecondary == other.titleSecondary &&
          body == other.body &&
          label == other.label &&
          monoLabel == other.monoLabel;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(family),
    Object.hashAll(familyMono),
    familySerif == null ? null : Object.hashAll(familySerif!),
    display,
    title,
    titleSecondary,
    body,
    label,
    monoLabel,
  );
}

/// 形状令牌组：圆角四档 + 描边三档。
final class TokenShapeSet {
  /// 创建形状令牌组。
  const TokenShapeSet({
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.strokeHairline,
    required this.strokeAccent,
    required this.strokeFocus,
  });

  /// 圆角 xs 档。
  final double radiusXs;

  /// 圆角 sm 档。
  final double radiusSm;

  /// 圆角 md 档。
  final double radiusMd;

  /// 圆角 lg 档。
  final double radiusLg;

  /// hairline 描边宽（逻辑像素）。
  final double strokeHairline;

  /// accent 描边宽（逻辑像素）。
  final double strokeAccent;

  /// focus 描边宽（逻辑像素）。
  final double strokeFocus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenShapeSet &&
          radiusXs == other.radiusXs &&
          radiusSm == other.radiusSm &&
          radiusMd == other.radiusMd &&
          radiusLg == other.radiusLg &&
          strokeHairline == other.strokeHairline &&
          strokeAccent == other.strokeAccent &&
          strokeFocus == other.strokeFocus;

  @override
  int get hashCode => Object.hash(
    radiusXs,
    radiusSm,
    radiusMd,
    radiusLg,
    strokeHairline,
    strokeAccent,
    strokeFocus,
  );
}

/// 间距令牌组：space.1..space.7 共七档。
final class TokenSpacingSet {
  /// 创建间距令牌组。
  const TokenSpacingSet({
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space7,
  });

  /// space.1。
  final double space1;

  /// space.2。
  final double space2;

  /// space.3。
  final double space3;

  /// space.4。
  final double space4;

  /// space.5。
  final double space5;

  /// space.6。
  final double space6;

  /// space.7。
  final double space7;

  /// 按序号取间距档位（1..7）。
  double at(int index) => switch (index) {
    1 => space1,
    2 => space2,
    3 => space3,
    4 => space4,
    5 => space5,
    6 => space6,
    7 => space7,
    _ => throw RangeError.range(index, 1, 7, 'index'),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenSpacingSet &&
          space1 == other.space1 &&
          space2 == other.space2 &&
          space3 == other.space3 &&
          space4 == other.space4 &&
          space5 == other.space5 &&
          space6 == other.space6 &&
          space7 == other.space7;

  @override
  int get hashCode =>
      Object.hash(space1, space2, space3, space4, space5, space6, space7);
}

/// 单级海拔阴影：偏移 / 模糊 / 颜色；无阴影层级为 null。
final class TokenShadow {
  /// 创建阴影；[offsetY] 为纵向偏移（横向偏移固定为 0）。
  const TokenShadow({
    required this.offsetY,
    required this.blurRadius,
    required this.color,
  });

  /// 纵向偏移（逻辑像素，可为负）。
  final double offsetY;

  /// 模糊半径（逻辑像素）。
  final double blurRadius;

  /// 阴影颜色（含透明度）。
  final Color color;

  /// 转为 Flutter 阴影（横向偏移固定 0，纵向偏移为 [offsetY]）。
  BoxShadow toBoxShadow() => BoxShadow(
    offset: Offset(0, offsetY),
    blurRadius: blurRadius,
    color: color,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenShadow &&
          offsetY == other.offsetY &&
          blurRadius == other.blurRadius &&
          color == other.color;

  @override
  int get hashCode => Object.hash(offsetY, blurRadius, color);
}

/// 海拔令牌组：e0..e3 四级（e0 恒为无阴影）。
final class TokenElevationSet {
  /// 创建海拔令牌组。
  const TokenElevationSet({
    required this.e1,
    required this.e2,
    required this.e3,
  });

  /// e1 卡片层级（无阴影的方向为 null，改用描边分层）。
  final TokenShadow? e1;

  /// e2 弹层/悬浮层级。
  final TokenShadow? e2;

  /// e3 对话框/模态层级。
  final TokenShadow? e3;

  /// e0 恒为无阴影。
  static const TokenShadow? e0 = null;

  /// 转为对应层级的阴影列表（无阴影时为空列表）。
  List<BoxShadow> shadowsFor(TokenShadow? shadow) =>
      shadow == null ? const <BoxShadow>[] : <BoxShadow>[shadow.toBoxShadow()];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenElevationSet &&
          e1 == other.e1 &&
          e2 == other.e2 &&
          e3 == other.e3;

  @override
  int get hashCode => Object.hash(e1, e2, e3);
}

/// 动效令牌组：时长、缓动与可动效语义边界。
final class TokenMotionSet {
  /// 创建动效令牌组。
  ///
  /// [canAnimate] 与 [neverAnimate] 为语义边界标签（来自冻结文档各方向的
  /// 允许/禁止动效清单）；组件用 [allows] 询问某一语义是否可动效。
  const TokenMotionSet({
    required this.durFast,
    required this.durBase,
    required this.durSlow,
    required this.curveEnter,
    required this.curveExit,
    required this.canAnimate,
    required this.neverAnimate,
  });

  /// fast 时长。
  final Duration durFast;

  /// base 时长。
  final Duration durBase;

  /// slow 时长。
  final Duration durSlow;

  /// 进入缓动。
  final Curve curveEnter;

  /// 退出缓动。
  final Curve curveExit;

  /// 允许动效的语义边界标签。
  final List<String> canAnimate;

  /// 禁止动效的语义边界标签。
  final List<String> neverAnimate;

  /// 询问 [tag] 语义是否允许动效：须在允许清单且不在禁止清单。
  bool allows(String tag) =>
      canAnimate.contains(tag) && !neverAnimate.contains(tag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenMotionSet &&
          durFast == other.durFast &&
          durBase == other.durBase &&
          durSlow == other.durSlow &&
          curveEnter == other.curveEnter &&
          curveExit == other.curveExit &&
          _listEquals(canAnimate, other.canAnimate) &&
          _listEquals(neverAnimate, other.neverAnimate);

  @override
  int get hashCode => Object.hash(
    durFast,
    durBase,
    durSlow,
    curveEnter,
    curveExit,
    Object.hashAll(canAnimate),
    Object.hashAll(neverAnimate),
  );
}

/// 中性阶令牌组：N0（最浅背景）到 N5（最强前景），暗色方向物理翻转。
final class TokenNeutralSet {
  /// 创建中性阶；[n0]..[n5] 与冻结文档 neutral.N0..N5 一一对应。
  const TokenNeutralSet({
    required this.n0,
    required this.n1,
    required this.n2,
    required this.n3,
    required this.n4,
    required this.n5,
  });

  /// neutral.N0 最浅背景。
  final Color n0;

  /// neutral.N1。
  final Color n1;

  /// neutral.N2。
  final Color n2;

  /// neutral.N3。
  final Color n3;

  /// neutral.N4。
  final Color n4;

  /// neutral.N5 最强前景。
  final Color n5;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenNeutralSet &&
          n0 == other.n0 &&
          n1 == other.n1 &&
          n2 == other.n2 &&
          n3 == other.n3 &&
          n4 == other.n4 &&
          n5 == other.n5;

  @override
  int get hashCode => Object.hash(n0, n1, n2, n3, n4, n5);
}

/// 设计令牌契约。
///
/// 以 `ThemeExtension` 挂进 [ThemeData]；组件经 [ThemeTokens.of] 取用。具体
/// 取值全部由 `presets/` 目录按冻结文档逐值提供，本契约不持有任何字面量。
abstract final class ThemeTokens implements ThemeExtension<ThemeTokens> {
  /// 创建令牌实例（仅供 presets/ 目录使用）。
  factory ThemeTokens({
    required AppThemePreset preset,
    required TokenColors color,
    required TokenNeutralSet neutral,
    required TokenTypeSet typography,
    required TokenShapeSet shape,
    required TokenSpacingSet spacing,
    required TokenElevationSet elevation,
    required TokenMotionSet motion,
  }) = _ThemeTokensData;

  /// 从上下文取当前设计令牌；未注册时抛出带指引的 [StateError]。
  static ThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<ThemeTokens>();
    if (tokens == null) {
      throw StateError(
        'ThemeTokens 未注册：请通过 AppTheme.build 构建主题并注入 extensions。',
      );
    }
    return tokens;
  }

  /// 本令牌集所属的方向（组件据此做方向差异化呈现）。
  AppThemePreset get preset;

  /// 色彩令牌组（M3 角色全家 + success/warning 语义扩展）。
  TokenColors get color;

  /// 中性阶令牌组。
  TokenNeutralSet get neutral;

  /// 字体令牌组。
  TokenTypeSet get typography;

  /// 形状令牌组。
  TokenShapeSet get shape;

  /// 间距令牌组。
  TokenSpacingSet get spacing;

  /// 海拔令牌组。
  TokenElevationSet get elevation;

  /// 动效令牌组。
  TokenMotionSet get motion;
}

final class _ThemeTokensData extends ThemeExtension<ThemeTokens>
    implements ThemeTokens {
  _ThemeTokensData({
    required this.preset,
    required this.color,
    required this.neutral,
    required this.typography,
    required this.shape,
    required this.spacing,
    required this.elevation,
    required this.motion,
  });

  @override
  final AppThemePreset preset;
  @override
  final TokenColors color;
  @override
  final TokenNeutralSet neutral;
  @override
  final TokenTypeSet typography;
  @override
  final TokenShapeSet shape;
  @override
  final TokenSpacingSet spacing;
  @override
  final TokenElevationSet elevation;
  @override
  final TokenMotionSet motion;

  @override
  ThemeTokens copyWith({
    AppThemePreset? preset,
    TokenColors? color,
    TokenNeutralSet? neutral,
    TokenTypeSet? typography,
    TokenShapeSet? shape,
    TokenSpacingSet? spacing,
    TokenElevationSet? elevation,
    TokenMotionSet? motion,
  }) {
    return _ThemeTokensData(
      preset: preset ?? this.preset,
      color: color ?? this.color,
      neutral: neutral ?? this.neutral,
      typography: typography ?? this.typography,
      shape: shape ?? this.shape,
      spacing: spacing ?? this.spacing,
      elevation: elevation ?? this.elevation,
      motion: motion ?? this.motion,
    );
  }

  @override
  ThemeTokens lerp(covariant ThemeTokens? other, double t) {
    if (other == null) {
      return this;
    }
    if (other.preset != preset) {
      // 跨方向切换不做逐值插值，直接按进度切换，避免发明中间取值。
      return t < 0.5 ? this : other;
    }
    return _ThemeTokensData(
      preset: preset,
      color: _lerpColors(color, other.color, t),
      neutral: TokenNeutralSet(
        n0: Color.lerp(neutral.n0, other.neutral.n0, t)!,
        n1: Color.lerp(neutral.n1, other.neutral.n1, t)!,
        n2: Color.lerp(neutral.n2, other.neutral.n2, t)!,
        n3: Color.lerp(neutral.n3, other.neutral.n3, t)!,
        n4: Color.lerp(neutral.n4, other.neutral.n4, t)!,
        n5: Color.lerp(neutral.n5, other.neutral.n5, t)!,
      ),
      typography: TokenTypeSet(
        family: typography.family,
        familyMono: typography.familyMono,
        familySerif: typography.familySerif,
        display: _lerpSpec(typography.display, other.typography.display, t),
        title: _lerpSpec(typography.title, other.typography.title, t),
        titleSecondary: _lerpSpec(
          typography.titleSecondary,
          other.typography.titleSecondary,
          t,
        ),
        body: _lerpSpec(typography.body, other.typography.body, t),
        label: _lerpSpec(typography.label, other.typography.label, t),
        monoLabel:
            typography.monoLabel == null || other.typography.monoLabel == null
            ? null
            : _lerpSpec(typography.monoLabel!, other.typography.monoLabel!, t),
      ),
      shape: TokenShapeSet(
        radiusXs: _lerpDouble(shape.radiusXs, other.shape.radiusXs, t),
        radiusSm: _lerpDouble(shape.radiusSm, other.shape.radiusSm, t),
        radiusMd: _lerpDouble(shape.radiusMd, other.shape.radiusMd, t),
        radiusLg: _lerpDouble(shape.radiusLg, other.shape.radiusLg, t),
        strokeHairline: _lerpDouble(
          shape.strokeHairline,
          other.shape.strokeHairline,
          t,
        ),
        strokeAccent: _lerpDouble(
          shape.strokeAccent,
          other.shape.strokeAccent,
          t,
        ),
        strokeFocus: _lerpDouble(shape.strokeFocus, other.shape.strokeFocus, t),
      ),
      spacing: TokenSpacingSet(
        space1: _lerpDouble(spacing.space1, other.spacing.space1, t),
        space2: _lerpDouble(spacing.space2, other.spacing.space2, t),
        space3: _lerpDouble(spacing.space3, other.spacing.space3, t),
        space4: _lerpDouble(spacing.space4, other.spacing.space4, t),
        space5: _lerpDouble(spacing.space5, other.spacing.space5, t),
        space6: _lerpDouble(spacing.space6, other.spacing.space6, t),
        space7: _lerpDouble(spacing.space7, other.spacing.space7, t),
      ),
      elevation: TokenElevationSet(
        e1: _lerpShadow(elevation.e1, other.elevation.e1, t),
        e2: _lerpShadow(elevation.e2, other.elevation.e2, t),
        e3: _lerpShadow(elevation.e3, other.elevation.e3, t),
      ),
      motion: t < 0.5 ? motion : other.motion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThemeTokensData &&
          preset == other.preset &&
          color == other.color &&
          neutral == other.neutral &&
          typography == other.typography &&
          shape == other.shape &&
          spacing == other.spacing &&
          elevation == other.elevation &&
          motion == other.motion;

  @override
  int get hashCode => Object.hash(
    preset,
    color,
    neutral,
    typography,
    shape,
    spacing,
    elevation,
    motion,
  );
}

TokenColors _lerpColors(TokenColors a, TokenColors b, double t) {
  Color l(Color x, Color y) => Color.lerp(x, y, t)!;

  // 可空角色（onSuccess/onWarning）任一侧为 null 时不插值，按进度切换。
  return TokenColors(
    primary: l(a.primary, b.primary),
    onPrimary: l(a.onPrimary, b.onPrimary),
    primaryContainer: l(a.primaryContainer, b.primaryContainer),
    onPrimaryContainer: l(a.onPrimaryContainer, b.onPrimaryContainer),
    secondary: l(a.secondary, b.secondary),
    onSecondary: l(a.onSecondary, b.onSecondary),
    secondaryContainer: l(a.secondaryContainer, b.secondaryContainer),
    onSecondaryContainer: l(a.onSecondaryContainer, b.onSecondaryContainer),
    tertiary: l(a.tertiary, b.tertiary),
    onTertiary: l(a.onTertiary, b.onTertiary),
    tertiaryContainer: l(a.tertiaryContainer, b.tertiaryContainer),
    onTertiaryContainer: l(a.onTertiaryContainer, b.onTertiaryContainer),
    error: l(a.error, b.error),
    onError: l(a.onError, b.onError),
    errorContainer: l(a.errorContainer, b.errorContainer),
    onErrorContainer: l(a.onErrorContainer, b.onErrorContainer),
    surface: l(a.surface, b.surface),
    surfaceContainerLowest: l(
      a.surfaceContainerLowest,
      b.surfaceContainerLowest,
    ),
    surfaceContainerLow: l(a.surfaceContainerLow, b.surfaceContainerLow),
    surfaceContainer: l(a.surfaceContainer, b.surfaceContainer),
    surfaceContainerHigh: l(a.surfaceContainerHigh, b.surfaceContainerHigh),
    surfaceContainerHighest: l(
      a.surfaceContainerHighest,
      b.surfaceContainerHighest,
    ),
    surfaceVariant: l(a.surfaceVariant, b.surfaceVariant),
    onSurface: l(a.onSurface, b.onSurface),
    onSurfaceVariant: l(a.onSurfaceVariant, b.onSurfaceVariant),
    outline: l(a.outline, b.outline),
    outlineVariant: l(a.outlineVariant, b.outlineVariant),
    inverseSurface: l(a.inverseSurface, b.inverseSurface),
    onInverseSurface: l(a.onInverseSurface, b.onInverseSurface),
    scrim: l(a.scrim, b.scrim),
    shadow: l(a.shadow, b.shadow),
    success: l(a.success, b.success),
    onSuccess: l(a.onSuccess, b.onSuccess),
    successContainer: l(a.successContainer, b.successContainer),
    onSuccessContainer: l(a.onSuccessContainer, b.onSuccessContainer),
    warning: l(a.warning, b.warning),
    onWarning: l(a.onWarning, b.onWarning),
    warningContainer: l(a.warningContainer, b.warningContainer),
    onWarningContainer: l(a.onWarningContainer, b.onWarningContainer),
  );
}

TokenTypeSpec _lerpSpec(TokenTypeSpec a, TokenTypeSpec b, double t) {
  return TokenTypeSpec(
    size: _lerpDouble(a.size, b.size, t),
    lineHeight: _lerpDouble(a.lineHeight, b.lineHeight, t),
    weight: t < 0.5 ? a.weight : b.weight,
  );
}

TokenShadow? _lerpShadow(TokenShadow? a, TokenShadow? b, double t) {
  if (a == null && b == null) {
    return null;
  }
  if (a == null || b == null) {
    return t < 0.5 ? a : b;
  }
  return TokenShadow(
    offsetY: _lerpDouble(a.offsetY, b.offsetY, t),
    blurRadius: _lerpDouble(a.blurRadius, b.blurRadius, t),
    color: Color.lerp(a.color, b.color, t)!,
  );
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null || b == null) {
    return identical(a, b);
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
