/// 方向枚举与主题构建入口。
///
/// 三方向 × 明暗共六套 [ThemeData]；所有取值由 `presets/` 目录按冻结美术
/// 文档逐值提供，本文件只做令牌到 Material 组件的装配，不发明任何样式值。
library;

import 'package:flutter/material.dart';

import 'presets/dark_pro.dart';
import 'presets/precision_tools.dart';
import 'presets/token_text_style.dart';
import 'presets/warm_life.dart';
import 'tokens.dart';

/// 主题方向。
enum AppThemePreset {
  /// A 方向：精密工具风（钢青蓝、信息密度、等宽签名）。
  precisionTools,

  /// B 方向：温暖生活风（陶土柿、默认方向）。
  warmLife,

  /// C 方向：极简暗色专业风（断点紫）。
  darkPro,
}

/// 主题构建入口。
abstract final class AppTheme {
  /// 按方向与明暗构建 [ThemeData]。
  ///
  /// M3 颜色角色映射进 [ColorScheme]；success/warning 语义色与全部令牌随
  /// [ThemeTokens] 主题扩展下发；字号映射遵循冻结文档：display→headline
  /// Medium、title（主/次）→titleLarge/titleMedium、body→bodyLarge/body
  /// Medium、label→labelMedium/labelSmall。
  static ThemeData build(AppThemePreset preset, Brightness brightness) {
    final ThemeTokens tokens = switch (preset) {
      AppThemePreset.precisionTools => precisionToolsTokens(brightness),
      AppThemePreset.warmLife => warmLifeTokens(brightness),
      AppThemePreset.darkPro => darkProTokens(brightness),
    };
    final TokenColors colors = tokens.color;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      surface: colors.surface,
      surfaceContainerLowest: colors.surfaceContainerLowest,
      surfaceContainerLow: colors.surfaceContainerLow,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerHigh: colors.surfaceContainerHigh,
      surfaceContainerHighest: colors.surfaceContainerHighest,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      scrim: colors.scrim,
      shadow: colors.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: <ThemeExtension<Object?>>[tokens as ThemeExtension<Object?>],
      textTheme: _textTheme(tokens),
      scaffoldBackgroundColor: colors.surface,
      dividerColor: colors.outlineVariant,
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.shape.radiusLg),
        ),
      ),
    );
  }

  /// 按冻结文档映射规则装配 TextTheme；未映射角色不覆写。
  static TextTheme _textTheme(ThemeTokens tokens) {
    final TokenTypeSet typography = tokens.typography;
    TextStyle style(TokenTypeSpec spec, {List<String>? familyChain}) {
      final List<String> chain = familyChain ?? typography.family;
      return buildTokenTextStyle(
        spec,
        familyChain: chain,
        color: tokens.color.onSurface,
      );
    }

    return TextTheme(
      headlineMedium: style(typography.display),
      titleLarge: style(typography.title),
      titleMedium: style(typography.titleSecondary),
      bodyLarge: style(typography.body),
      bodyMedium: style(typography.body),
      labelMedium: style(typography.label),
      labelSmall: style(typography.label),
    );
  }
}
