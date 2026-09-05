/// 截图设置 surface：FormRenderer 渲染文件名前缀与保存质量。
library;

import 'package:flutter/material.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'screenshot_model.dart';
import 'screenshot_strings.dart';

/// 表单字段 key：文件名前缀。
const String kSettingKeyFilenamePrefix = 'filenamePrefix';

/// 表单字段 key：保存质量。
const String kSettingKeyQuality = 'quality';

/// 构建设置表单描述符（文案经宿主载体注入）。
///
/// 质量下拉以展示文案为值，提交时经 [screenshotQualityKey] 折算回稳定键。
FormDescriptor screenshotSettingsForm(
  ScreenshotModel model,
  ScreenshotStrings strings,
) {
  return FormDescriptor(
    title: strings.settingsFormTitle,
    fields: <FormFieldSpec>[
      TextFieldSpec(
        key: kSettingKeyFilenamePrefix,
        label: strings.settingsFilenamePrefix,
        isRequired: true,
        defaultValue: model.settings.filenamePrefix,
        placeholder: strings.settingsFilenamePrefixPlaceholder,
      ),
      SelectFieldSpec(
        key: kSettingKeyQuality,
        label: strings.settingsQuality,
        options: <String>[
          for (final String key in kScreenshotQualityKeys)
            screenshotQualityLabel(strings, key),
        ],
        defaultValue: screenshotQualityLabel(strings, model.settings.quality),
      ),
    ],
  );
}

/// 截图设置提供方（builtin 实现，宿主组装根注册）。
final class ScreenshotSettingsProvider implements PluginSettingsProvider {
  /// 创建设置提供方。
  const ScreenshotSettingsProvider({
    required this.model,
    required this.stringsResolver,
  });

  /// 状态模型。
  final ScreenshotModel model;

  /// 文案解析器。
  final ScreenshotStringsResolver stringsResolver;

  @override
  Widget buildSettings(BuildContext context) {
    final ScreenshotStrings strings = stringsResolver(context);
    final ThemeTokens tokens = ThemeTokens.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FormRenderer(
              descriptor: screenshotSettingsForm(model, strings),
              onSubmit: (Map<String, Object?> values) =>
                  _apply(values, strings),
            ),
            SizedBox(height: tokens.spacing.space3),
            Text(
              strings.qualityNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.color.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 提交回填：前缀空白回退原值，质量文案折算回稳定键。
  void _apply(Map<String, Object?> values, ScreenshotStrings strings) {
    final Object? prefix = values[kSettingKeyFilenamePrefix];
    final Object? qualityLabel = values[kSettingKeyQuality];
    final String nextPrefix = prefix is String && prefix.trim().isNotEmpty
        ? prefix.trim()
        : model.settings.filenamePrefix;
    final String nextQuality = qualityLabel is String
        ? screenshotQualityKey(strings, qualityLabel)
        : model.settings.quality;
    model.updateSettings(
      model.settings.copyWith(filenamePrefix: nextPrefix, quality: nextQuality),
    );
  }
}
