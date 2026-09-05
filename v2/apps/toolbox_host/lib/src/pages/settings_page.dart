/// 设置页：主题方向 / 明暗模式 / 语言三节。
///
/// 主题方向经 [ThemeController.select] 切换（触发宿主层监听与持久化注入点）；
/// 语言自称项（中文 / English）按惯例以自身语言显示，不属于硬编码文案。
library;

import 'package:flutter/material.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import '../brightness_mode.dart';
import '../generated/host_l10n.dart';

/// 宿主设置页。
final class SettingsPage extends StatelessWidget {
  /// 创建设置页；主题方向与语言变化分别回调控制器与宿主壳。
  const SettingsPage({
    super.key,
    required this.themeController,
    required this.brightnessMode,
    required this.onBrightnessModeChanged,
    required this.locale,
    required this.onLocaleChanged,
  });

  /// 主题方向控制器（读写当前 preset）。
  final ThemeController themeController;

  /// 当前明暗模式。
  final BrightnessMode brightnessMode;

  /// 明暗模式变化回调。
  final ValueChanged<BrightnessMode> onBrightnessModeChanged;

  /// 当前语言。
  final Locale locale;

  /// 语言变化回调。
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final HostL10n l10n = HostL10n.of(context);
    final TokenSpacingSet spacing = ThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.all(spacing.space5),
        children: <Widget>[
          _sectionTitle(context, l10n.settingsTheme),
          SegmentedButton<AppThemePreset>(
            segments: <ButtonSegment<AppThemePreset>>[
              ButtonSegment<AppThemePreset>(
                value: AppThemePreset.precisionTools,
                label: Text(l10n.themePrecisionTools),
              ),
              ButtonSegment<AppThemePreset>(
                value: AppThemePreset.warmLife,
                label: Text(l10n.themeWarmLife),
              ),
              ButtonSegment<AppThemePreset>(
                value: AppThemePreset.darkPro,
                label: Text(l10n.themeDarkPro),
              ),
            ],
            selected: <AppThemePreset>{themeController.value},
            onSelectionChanged: (Set<AppThemePreset> selection) =>
                themeController.select(selection.first),
          ),
          SizedBox(height: spacing.space7),
          _sectionTitle(context, l10n.settingsBrightness),
          SegmentedButton<BrightnessMode>(
            segments: <ButtonSegment<BrightnessMode>>[
              ButtonSegment<BrightnessMode>(
                value: BrightnessMode.system,
                label: Text(l10n.brightnessSystem),
              ),
              ButtonSegment<BrightnessMode>(
                value: BrightnessMode.light,
                label: Text(l10n.brightnessLight),
              ),
              ButtonSegment<BrightnessMode>(
                value: BrightnessMode.dark,
                label: Text(l10n.brightnessDark),
              ),
            ],
            selected: <BrightnessMode>{brightnessMode},
            onSelectionChanged: (Set<BrightnessMode> selection) =>
                onBrightnessModeChanged(selection.first),
          ),
          SizedBox(height: spacing.space7),
          _sectionTitle(context, l10n.settingsLanguage),
          SegmentedButton<String>(
            // 语言自名按行业惯例以本名呈现（「中文」/「English」不随界面语言
            // 翻译），属 i18n 豁免项，勿改为翻译键（G3-A minor 3 注释）。
            segments: <ButtonSegment<String>>[
              const ButtonSegment<String>(value: 'zh', label: Text('中文')),
              const ButtonSegment<String>(value: 'en', label: Text('English')),
            ],
            selected: <String>{locale.languageCode},
            onSelectionChanged: (Set<String> selection) =>
                onLocaleChanged(Locale(selection.first)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ThemeTokens.of(context).spacing.space3),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
