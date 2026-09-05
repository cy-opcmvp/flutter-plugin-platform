/// 方向 C「极简暗色专业风」（dark_pro）令牌预设。
///
/// 全部取值逐项对照冻结美术文档方向 C 的中性阶/语义色/M3 角色映射/字体/
/// 形状/间距/海拔/动效各表，暗亮各一套实例（文档暗色列在先，暗色为该方向
/// 主体验）。亮色 E1 为「0 1 2 rgba(20,18,29,0.06)」暖黑轻影。
library;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.dart';

/// 按明暗返回方向 C 的令牌实例。
ThemeTokens darkProTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _darkTokens : _lightTokens;

/// 暗色实例（主体验）：断点紫主色 + 暗夜紫黑中性阶。
final ThemeTokens _darkTokens = ThemeTokens(
  preset: AppThemePreset.darkPro,
  color: TokenColors(
    primary: Color(0xFFA18CFF),
    onPrimary: Color(0xFF221652),
    primaryContainer: Color(0xFF3A2E75),
    onPrimaryContainer: Color(0xFFDCD4FF),
    secondary: Color(0xFF5FC6CF),
    onSecondary: Color(0xFF063336),
    secondaryContainer: Color(0xFF1D4A50),
    onSecondaryContainer: Color(0xFFD6F3F5),
    tertiary: Color(0xFFD6689F),
    onTertiary: Color(0xFF42112B),
    tertiaryContainer: Color(0xFF53243D),
    onTertiaryContainer: Color(0xFFFAD2E5),
    error: Color(0xFFFF6E62),
    onError: Color(0xFF550F09),
    errorContainer: Color(0xFF55201B),
    onErrorContainer: Color(0xFFFFD9D4),
    surface: Color(0xFF1B1927),
    surfaceContainerLowest: Color(0xFF14121D),
    surfaceContainerLow: Color(0xFF171522),
    surfaceContainer: Color(0xFF1F1D2E),
    surfaceContainerHigh: Color(0xFF2A2740),
    surfaceContainerHighest: Color(0xFF322E4B),
    surfaceVariant: Color(0xFF232136),
    onSurface: Color(0xFFEBE9F6),
    onSurfaceVariant: Color(0xFFA29BBD),
    outline: Color(0xFF3B3752),
    outlineVariant: Color(0xFF2B2840),
    inverseSurface: Color(0xFFEBE9F6),
    onInverseSurface: Color(0xFF1B1927),
    scrim: Color(0xFF08070D),
    shadow: Color(0xFF000000),
    success: Color(0xFF63C97F),
    onSuccess: null,
    successContainer: Color(0xFF1C4A2A),
    onSuccessContainer: Color(0xFFC9F0D3),
    warning: Color(0xFFE5B54A),
    onWarning: null,
    warningContainer: Color(0xFF4E3D14),
    onWarningContainer: Color(0xFFFBE3B3),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFF14121D),
    n1: Color(0xFF1B1927),
    n2: Color(0xFF232136),
    n3: Color(0xFF2B2840),
    n4: Color(0xFFA29BBD),
    n5: Color(0xFFEBE9F6),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'HarmonyOS Sans SC',
      'MiSans',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    // 等宽为方向 C 的排版签名，使用面更广。
    familyMono: <String>[
      'Cascadia Code',
      'Cascadia Mono',
      'Consolas',
      'monospace',
    ],
    display: TokenTypeSpec(size: 26, lineHeight: 34, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 17, lineHeight: 24, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 14,
      lineHeight: 20,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 14, lineHeight: 21, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w600),
    monoLabel: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w400),
  ),
  shape: TokenShapeSet(
    radiusXs: 2,
    radiusSm: 4,
    radiusMd: 6,
    radiusLg: 10,
    strokeHairline: 1,
    strokeAccent: 1,
    strokeFocus: 1,
  ),
  spacing: TokenSpacingSet(
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 20,
    space6: 28,
    space7: 40,
  ),
  elevation: TokenElevationSet(
    // E1 为「surface + 1px 描边」表达，无阴影；E2/E3 用黑影。
    e1: null,
    e2: TokenShadow(
      offsetY: 2,
      blurRadius: 8,
      color: Color.fromRGBO(0, 0, 0, 0.40),
    ),
    e3: TokenShadow(
      offsetY: 8,
      blurRadius: 24,
      color: Color.fromRGBO(0, 0, 0, 0.50),
    ),
  ),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 60),
    durBase: Duration(milliseconds: 120),
    durSlow: Duration(milliseconds: 200),
    curveEnter: Cubic(0.4, 0, 0.6, 1),
    curveExit: Cubic(0.4, 0, 1, 1),
    // 允许：键盘焦点环、状态点颜色切换、结果面板展开。
    canAnimate: <String>[
      'focus_ring',
      'status_dot_color',
      'result_panel_expand',
    ],
    // 禁止：一切装饰动画、阴影/海拔过渡、光标闪烁与扫描线。
    neverAnimate: <String>[
      'decorative_motion',
      'elevation_transition',
      'cursor_blink',
    ],
  ),
);

/// 亮色实例：靛紫主色 + 淡紫灰中性阶。
final ThemeTokens _lightTokens = ThemeTokens(
  preset: AppThemePreset.darkPro,
  color: TokenColors(
    primary: Color(0xFF5447B8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE2DDF8),
    onPrimaryContainer: Color(0xFF241A5E),
    secondary: Color(0xFF1F7680),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD2EEF1),
    onSecondaryContainer: Color(0xFF0E3338),
    tertiary: Color(0xFFAE4680),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF7D9E8),
    onTertiaryContainer: Color(0xFF43142E),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE2E0),
    onErrorContainer: Color(0xFF96201A),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAF9FC),
    surfaceContainer: Color(0xFFEDEBF5),
    surfaceContainerHigh: Color(0xFFE5E2F0),
    surfaceContainerHighest: Color(0xFFDCD9EA),
    surfaceVariant: Color(0xFFEDEBF5),
    onSurface: Color(0xFF262238),
    onSurfaceVariant: Color(0xFF67627E),
    outline: Color(0xFF8C87A3),
    outlineVariant: Color(0xFFD9D6E7),
    inverseSurface: Color(0xFF262238),
    onInverseSurface: Color(0xFFF6F5FA),
    scrim: Color(0xFF100E1A),
    shadow: Color(0xFF14121D),
    success: Color(0xFF1F7A46),
    onSuccess: null,
    successContainer: Color(0xFFD9EEDF),
    onSuccessContainer: Color(0xFF175E35),
    warning: Color(0xFF97690D),
    onWarning: null,
    warningContainer: Color(0xFFF5E8C9),
    onWarningContainer: Color(0xFF7A540A),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFFFFFFFF),
    n1: Color(0xFFF6F5FA),
    n2: Color(0xFFEDEBF5),
    n3: Color(0xFFD9D6E7),
    n4: Color(0xFF67627E),
    n5: Color(0xFF262238),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'HarmonyOS Sans SC',
      'MiSans',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    familyMono: <String>[
      'Cascadia Code',
      'Cascadia Mono',
      'Consolas',
      'monospace',
    ],
    display: TokenTypeSpec(size: 26, lineHeight: 34, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 17, lineHeight: 24, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 14,
      lineHeight: 20,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 14, lineHeight: 21, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w600),
    monoLabel: TokenTypeSpec(size: 12, lineHeight: 16, weight: FontWeight.w400),
  ),
  shape: TokenShapeSet(
    radiusXs: 2,
    radiusSm: 4,
    radiusMd: 6,
    radiusLg: 10,
    strokeHairline: 1,
    strokeAccent: 1,
    strokeFocus: 1,
  ),
  spacing: TokenSpacingSet(
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 20,
    space6: 28,
    space7: 40,
  ),
  elevation: TokenElevationSet(
    // 亮色轻影：0 1 2 / 0 4 10 / 0 10 24 rgba(20,18,29,α)。
    e1: TokenShadow(
      offsetY: 1,
      blurRadius: 2,
      color: Color.fromRGBO(20, 18, 29, 0.06),
    ),
    e2: TokenShadow(
      offsetY: 4,
      blurRadius: 10,
      color: Color.fromRGBO(20, 18, 29, 0.10),
    ),
    e3: TokenShadow(
      offsetY: 10,
      blurRadius: 24,
      color: Color.fromRGBO(20, 18, 29, 0.16),
    ),
  ),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 60),
    durBase: Duration(milliseconds: 120),
    durSlow: Duration(milliseconds: 200),
    curveEnter: Cubic(0.4, 0, 0.6, 1),
    curveExit: Cubic(0.4, 0, 1, 1),
    canAnimate: <String>[
      'focus_ring',
      'status_dot_color',
      'result_panel_expand',
    ],
    neverAnimate: <String>[
      'decorative_motion',
      'elevation_transition',
      'cursor_blink',
    ],
  ),
);
