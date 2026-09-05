/// 方向 A「精密工具风」（precision_tools）令牌预设。
///
/// 全部取值逐项对照冻结美术文档方向 A 的中性阶/语义色/M3 角色映射/字体/
/// 形状/间距/海拔/动效各表，亮暗各一套实例；本目录之外不得出现任何具体样式
/// 值。暗色海拔按文档改用「面板抬升 + 1px 描边」表达，故阴影层级均为 null。
library;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.dart';

/// 按明暗返回方向 A 的令牌实例。
ThemeTokens precisionToolsTokens(Brightness brightness) =>
    brightness == Brightness.light ? _lightTokens : _darkTokens;

/// 亮色实例：钢青蓝主色 + 蓝灰石墨中性阶。
final ThemeTokens _lightTokens = ThemeTokens(
  preset: AppThemePreset.precisionTools,
  color: TokenColors(
    primary: Color(0xFF24538F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7E4F4),
    onPrimaryContainer: Color(0xFF123152),
    secondary: Color(0xFF45586C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE4EC),
    onSecondaryContainer: Color(0xFF1F2C38),
    tertiary: Color(0xFF1F7A6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD2ECE6),
    onTertiaryContainer: Color(0xFF0E3A32),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE2E0),
    onErrorContainer: Color(0xFF96201A),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFE9EDF2),
    surfaceContainerHigh: Color(0xFFE2E8EE),
    surfaceContainerHighest: Color(0xFFDAE1E9),
    surfaceVariant: Color(0xFFE9EDF2),
    onSurface: Color(0xFF1A232D),
    onSurfaceVariant: Color(0xFF56636F),
    outline: Color(0xFF8A97A5),
    outlineVariant: Color(0xFFC9D2DB),
    inverseSurface: Color(0xFF2A333D),
    onInverseSurface: Color(0xFFEEF2F6),
    scrim: Color(0xFF0B0F14),
    shadow: Color(0xFF0B0F14),
    success: Color(0xFF1E7A3C),
    onSuccess: null,
    successContainer: Color(0xFFD9F0DF),
    onSuccessContainer: Color(0xFF175E2E),
    warning: Color(0xFF96610A),
    onWarning: null,
    warningContainer: Color(0xFFFBEACB),
    onWarningContainer: Color(0xFF794D05),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFFFFFFFF),
    n1: Color(0xFFF4F6F9),
    n2: Color(0xFFE9EDF2),
    n3: Color(0xFFC9D2DB),
    n4: Color(0xFF56636F),
    n5: Color(0xFF1A232D),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'HarmonyOS Sans SC',
      'MiSans',
      'Microsoft YaHei UI',
      'PingFang SC',
      'sans-serif',
    ],
    familyMono: <String>[
      'Cascadia Mono',
      'Consolas',
      'Courier New',
      'monospace',
    ],
    display: TokenTypeSpec(size: 28, lineHeight: 36, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 18, lineHeight: 26, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 15,
      lineHeight: 22,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 14, lineHeight: 22, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w500),
    monoLabel: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w400),
  ),
  shape: TokenShapeSet(
    radiusXs: 2,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 14,
    strokeHairline: 1,
    strokeAccent: 1.5,
    strokeFocus: 2,
  ),
  spacing: TokenSpacingSet(
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 24,
    space6: 32,
    space7: 48,
  ),
  elevation: TokenElevationSet(
    // E1/E2/E3 均为文档亮色阴影：0 1 3 / 0 4 12 / 0 8 24 rgba(16,24,36,α)。
    e1: TokenShadow(
      offsetY: 1,
      blurRadius: 3,
      color: Color.fromRGBO(16, 24, 36, 0.10),
    ),
    e2: TokenShadow(
      offsetY: 4,
      blurRadius: 12,
      color: Color.fromRGBO(16, 24, 36, 0.14),
    ),
    e3: TokenShadow(
      offsetY: 8,
      blurRadius: 24,
      color: Color.fromRGBO(16, 24, 36, 0.18),
    ),
  ),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 80),
    durBase: Duration(milliseconds: 160),
    durSlow: Duration(milliseconds: 240),
    curveEnter: Cubic(0.05, 0.7, 0.1, 1),
    curveExit: Cubic(0.3, 0, 0.8, 0.15),
    // 允许：悬停描边/容器亮度反馈、筛选列表位移淡入、启用开关滑块位移。
    canAnimate: <String>['hover_feedback', 'filter_reorder', 'toggle_slider'],
    // 禁止：读数 tween/滚动计数、spring 回弹、视差与背景装饰动画。
    neverAnimate: <String>[
      'reading_tween',
      'spring_bounce',
      'parallax_decoration',
    ],
  ),
);

/// 暗色实例：浅钢蓝主色 + 石墨黑画布；阴影层级为 null（描边分层）。
final ThemeTokens _darkTokens = ThemeTokens(
  preset: AppThemePreset.precisionTools,
  color: TokenColors(
    primary: Color(0xFF85B3E8),
    onPrimary: Color(0xFF0C2745),
    primaryContainer: Color(0xFF1E4468),
    onPrimaryContainer: Color(0xFFD3E5F8),
    secondary: Color(0xFFAFC3D6),
    onSecondary: Color(0xFF16222E),
    secondaryContainer: Color(0xFF37465A),
    onSecondaryContainer: Color(0xFFDFE8F0),
    tertiary: Color(0xFF6BC2B2),
    onTertiary: Color(0xFF062A23),
    tertiaryContainer: Color(0xFF17453C),
    onTertiaryContainer: Color(0xFFD2F0E8),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF4C1512),
    errorContainer: Color(0xFF5C1F1B),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1A2028),
    surfaceContainerLowest: Color(0xFF0F1319),
    surfaceContainerLow: Color(0xFF161B22),
    surfaceContainer: Color(0xFF1F262F),
    surfaceContainerHigh: Color(0xFF232A34),
    surfaceContainerHighest: Color(0xFF2C3440),
    surfaceVariant: Color(0xFF242C36),
    onSurface: Color(0xFFE5EAF0),
    onSurfaceVariant: Color(0xFFA3B0BC),
    outline: Color(0xFF46525F),
    outlineVariant: Color(0xFF333E4A),
    inverseSurface: Color(0xFFE5EAF0),
    onInverseSurface: Color(0xFF1A2028),
    scrim: Color(0xFF05070A),
    shadow: Color(0xFF000000),
    success: Color(0xFF74C68C),
    onSuccess: null,
    successContainer: Color(0xFF1E4A2B),
    onSuccessContainer: Color(0xFFC9F0D3),
    warning: Color(0xFFF0B445),
    onWarning: null,
    warningContainer: Color(0xFF4A370F),
    onWarningContainer: Color(0xFFFBE3B3),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFF12161D),
    n1: Color(0xFF1A2028),
    n2: Color(0xFF242C36),
    n3: Color(0xFF333E4A),
    n4: Color(0xFFA3B0BC),
    n5: Color(0xFFE5EAF0),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'HarmonyOS Sans SC',
      'MiSans',
      'Microsoft YaHei UI',
      'PingFang SC',
      'sans-serif',
    ],
    familyMono: <String>[
      'Cascadia Mono',
      'Consolas',
      'Courier New',
      'monospace',
    ],
    display: TokenTypeSpec(size: 28, lineHeight: 36, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 18, lineHeight: 26, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 15,
      lineHeight: 22,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 14, lineHeight: 22, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w500),
    monoLabel: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w400),
  ),
  shape: TokenShapeSet(
    radiusXs: 2,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 14,
    strokeHairline: 1,
    strokeAccent: 1.5,
    strokeFocus: 2,
  ),
  spacing: TokenSpacingSet(
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 24,
    space6: 32,
    space7: 48,
  ),
  // 暗色海拔按文档改用「面板抬升 + 1px 描边」表达，不使用阴影。
  elevation: TokenElevationSet(e1: null, e2: null, e3: null),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 80),
    durBase: Duration(milliseconds: 160),
    durSlow: Duration(milliseconds: 240),
    curveEnter: Cubic(0.05, 0.7, 0.1, 1),
    curveExit: Cubic(0.3, 0, 0.8, 0.15),
    canAnimate: <String>['hover_feedback', 'filter_reorder', 'toggle_slider'],
    neverAnimate: <String>[
      'reading_tween',
      'spring_bounce',
      'parallax_decoration',
    ],
  ),
);
