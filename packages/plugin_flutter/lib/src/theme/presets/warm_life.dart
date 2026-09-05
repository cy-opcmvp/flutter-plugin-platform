/// 方向 B「温暖生活风」（warm_life）令牌预设（平台默认方向）。
///
/// 全部取值逐项对照冻结美术文档方向 B 的中性阶/语义色/M3 角色映射/字体/
/// 形状/间距/海拔/动效各表，亮暗各一套实例。方向 B 无等宽字体签名，等宽
/// 字族链复用界面主字族（文档未定义等宽字族，不发明新值）；暗色阴影按文档
/// 收敛为统一的 E1 表达。
library;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.dart';

/// 按明暗返回方向 B 的令牌实例。
ThemeTokens warmLifeTokens(Brightness brightness) =>
    brightness == Brightness.light ? _lightTokens : _darkTokens;

/// 亮色实例：陶土柿主色 + 奶油纸感中性阶。
final ThemeTokens _lightTokens = ThemeTokens(
  preset: AppThemePreset.warmLife,
  color: TokenColors(
    primary: Color(0xFFB4512F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF7DECF),
    onPrimaryContainer: Color(0xFF43170A),
    secondary: Color(0xFF6E5140),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEBDCCF),
    onSecondaryContainer: Color(0xFF2C1D14),
    tertiary: Color(0xFF75905F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE2EBD4),
    onTertiaryContainer: Color(0xFF2A3A1E),
    error: Color(0xFFB03A2A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9E1DB),
    onErrorContainer: Color(0xFF932F22),
    surface: Color(0xFFFFFDF8),
    surfaceContainerLowest: Color(0xFFFFFDF8),
    surfaceContainerLow: Color(0xFFFBF7EF),
    surfaceContainer: Color(0xFFF2E9DB),
    surfaceContainerHigh: Color(0xFFEDE2D2),
    surfaceContainerHighest: Color(0xFFE6D9C7),
    surfaceVariant: Color(0xFFF2E9DB),
    onSurface: Color(0xFF3A2E24),
    onSurfaceVariant: Color(0xFF6F5E4D),
    outline: Color(0xFFA08B77),
    outlineVariant: Color(0xFFDFD3C2),
    inverseSurface: Color(0xFF3A2E24),
    onInverseSurface: Color(0xFFFAF5EC),
    scrim: Color(0xFF241A12),
    shadow: Color(0xFF3B2A1C),
    success: Color(0xFF4A7D38),
    onSuccess: null,
    successContainer: Color(0xFFDFEED4),
    onSuccessContainer: Color(0xFF3A6429),
    warning: Color(0xFF93630A),
    onWarning: null,
    warningContainer: Color(0xFFF8E9C8),
    onWarningContainer: Color(0xFF7D530A),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFFFFFDF8),
    n1: Color(0xFFFAF5EC),
    n2: Color(0xFFF2E9DB),
    n3: Color(0xFFDFD3C2),
    n4: Color(0xFF6F5E4D),
    n5: Color(0xFF3A2E24),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'MiSans',
      'HarmonyOS Sans SC',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    // 文档未为方向 B 定义等宽字族，回退链复用界面主字族（不发明新值）。
    familyMono: <String>[
      'MiSans',
      'HarmonyOS Sans SC',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    // 装饰衬线：仅空状态警句/欢迎语使用，正文与按钮禁用。
    familySerif: <String>[
      'Source Han Serif SC',
      'Noto Serif SC',
      'SimSun',
      'serif',
    ],
    display: TokenTypeSpec(size: 30, lineHeight: 40, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 20, lineHeight: 30, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 16,
      lineHeight: 24,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 15, lineHeight: 24, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 13, lineHeight: 18, weight: FontWeight.w500),
  ),
  shape: TokenShapeSet(
    radiusXs: 6,
    radiusSm: 12,
    radiusMd: 20,
    radiusLg: 28,
    strokeHairline: 1,
    strokeAccent: 2,
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
    // 暖棕软阴影：0 2 6 / 0 6 16 / 0 12 28 rgba(59,42,28,α)。
    e1: TokenShadow(
      offsetY: 2,
      blurRadius: 6,
      color: Color.fromRGBO(59, 42, 28, 0.08),
    ),
    e2: TokenShadow(
      offsetY: 6,
      blurRadius: 16,
      color: Color.fromRGBO(59, 42, 28, 0.10),
    ),
    e3: TokenShadow(
      offsetY: 12,
      blurRadius: 28,
      color: Color.fromRGBO(59, 42, 28, 0.14),
    ),
  ),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 120),
    durBase: Duration(milliseconds: 240),
    durSlow: Duration(milliseconds: 400),
    curveEnter: Cubic(0.05, 0.7, 0.1, 1),
    // 文档未为方向 B 定义退出缓动，复用进入曲线（缺口已记偏差）。
    curveExit: Cubic(0.05, 0.7, 0.1, 1),
    // 允许：卡片悬停上浮+阴影加深、空状态插图呼吸、开关柔和过冲。
    canAnimate: <String>[
      'card_hover_lift',
      'empty_state_breathing',
      'switch_overshoot',
    ],
    // 禁止：表单错误抖动、超长列表级联入场、正文逐字/逐行动画。
    neverAnimate: <String>[
      'form_error_shake',
      'long_list_cascade',
      'text_reveal',
    ],
  ),
);

/// 暗色实例：浅陶土主色 + 深咖啡画布；阴影收敛为统一 E1 表达。
final ThemeTokens _darkTokens = ThemeTokens(
  preset: AppThemePreset.warmLife,
  color: TokenColors(
    primary: Color(0xFFE58F68),
    onPrimary: Color(0xFF3F1305),
    primaryContainer: Color(0xFF6E2C17),
    onPrimaryContainer: Color(0xFFFADFD2),
    secondary: Color(0xFFD2B49E),
    onSecondary: Color(0xFF2C1D12),
    secondaryContainer: Color(0xFF4A382B),
    onSecondaryContainer: Color(0xFFF1E5DA),
    tertiary: Color(0xFFA9C28F),
    onTertiary: Color(0xFF22301A),
    tertiaryContainer: Color(0xFF3B4A2D),
    onTertiaryContainer: Color(0xFFE1EFD3),
    error: Color(0xFFF0A79A),
    onError: Color(0xFF4F150C),
    errorContainer: Color(0xFF57201A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF2B231C),
    surfaceContainerLowest: Color(0xFF1F1913),
    surfaceContainerLow: Color(0xFF271F18),
    surfaceContainer: Color(0xFF31281F),
    surfaceContainerHigh: Color(0xFF3E3328),
    surfaceContainerHighest: Color(0xFF473A2D),
    surfaceVariant: Color(0xFF362C23),
    onSurface: Color(0xFFF5EEE3),
    onSurfaceVariant: Color(0xFFC0AC97),
    outline: Color(0xFF524537),
    outlineVariant: Color(0xFF3E3329),
    inverseSurface: Color(0xFFF5EEE3),
    onInverseSurface: Color(0xFF2B231C),
    scrim: Color(0xFF140E09),
    shadow: Color(0xFF000000),
    success: Color(0xFF93CB7E),
    onSuccess: null,
    successContainer: Color(0xFF2C4A20),
    onSuccessContainer: Color(0xFFDCEFCE),
    warning: Color(0xFFE8B35B),
    onWarning: null,
    warningContainer: Color(0xFF4E3B14),
    onWarningContainer: Color(0xFFFBE3B3),
  ),
  neutral: TokenNeutralSet(
    n0: Color(0xFF221B15),
    n1: Color(0xFF2B231C),
    n2: Color(0xFF362C23),
    n3: Color(0xFF3E3329),
    n4: Color(0xFFC0AC97),
    n5: Color(0xFFF5EEE3),
  ),
  typography: TokenTypeSet(
    family: <String>[
      'MiSans',
      'HarmonyOS Sans SC',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    familyMono: <String>[
      'MiSans',
      'HarmonyOS Sans SC',
      'Microsoft YaHei UI',
      'sans-serif',
    ],
    familySerif: <String>[
      'Source Han Serif SC',
      'Noto Serif SC',
      'SimSun',
      'serif',
    ],
    display: TokenTypeSpec(size: 30, lineHeight: 40, weight: FontWeight.w600),
    title: TokenTypeSpec(size: 20, lineHeight: 30, weight: FontWeight.w600),
    titleSecondary: TokenTypeSpec(
      size: 16,
      lineHeight: 24,
      weight: FontWeight.w500,
    ),
    body: TokenTypeSpec(size: 15, lineHeight: 24, weight: FontWeight.w400),
    label: TokenTypeSpec(size: 13, lineHeight: 18, weight: FontWeight.w500),
  ),
  shape: TokenShapeSet(
    radiusXs: 6,
    radiusSm: 12,
    radiusMd: 20,
    radiusLg: 28,
    strokeHairline: 1,
    strokeAccent: 2,
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
  // 暗色阴影按文档收敛为 E1「0 2 8 rgba(0,0,0,0.28)」，三个层级同值。
  elevation: TokenElevationSet(
    e1: TokenShadow(
      offsetY: 2,
      blurRadius: 8,
      color: Color.fromRGBO(0, 0, 0, 0.28),
    ),
    e2: TokenShadow(
      offsetY: 2,
      blurRadius: 8,
      color: Color.fromRGBO(0, 0, 0, 0.28),
    ),
    e3: TokenShadow(
      offsetY: 2,
      blurRadius: 8,
      color: Color.fromRGBO(0, 0, 0, 0.28),
    ),
  ),
  motion: TokenMotionSet(
    durFast: Duration(milliseconds: 120),
    durBase: Duration(milliseconds: 240),
    durSlow: Duration(milliseconds: 400),
    curveEnter: Cubic(0.05, 0.7, 0.1, 1),
    curveExit: Cubic(0.05, 0.7, 0.1, 1),
    canAnimate: <String>[
      'card_hover_lift',
      'empty_state_breathing',
      'switch_overshoot',
    ],
    neverAnimate: <String>[
      'form_error_shake',
      'long_list_cascade',
      'text_reveal',
    ],
  ),
);
