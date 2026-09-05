/// 截图设置 surface：FormRenderer 渲染保存目录、文件名模板、格式、
/// JPEG 质量、自动复制与全局热键。
library;

import 'package:flutter/material.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'region_selection.dart';
import 'screenshot_model.dart';
import 'screenshot_strings.dart';

/// 表单字段 key：保存目录。
const String kSettingKeySaveDir = 'saveDir';

/// 表单字段 key：文件名模板。
const String kSettingKeyFilenameTemplate = 'filenameTemplate';

/// 表单字段 key：保存格式。
const String kSettingKeyFormat = 'format';

/// 表单字段 key：JPEG 质量。
const String kSettingKeyJpegQuality = 'jpegQuality';

/// 表单字段 key：自动复制。
const String kSettingKeyAutoCopy = 'autoCopy';

/// 表单字段 key：全局热键 combo（S1 批C）。
const String kSettingKeyHotkeyCombo = 'hotkeyCombo';

/// 构建设置表单描述符（文案经宿主载体注入）。
///
/// 下拉字段以展示文案为值，提交时经 `screenshot*Key` 折算回稳定键；
/// JPEG 质量为数值字段（声明式表单无 slider 规格，以 NumberFieldSpec
/// 承载 1-100 范围）。
FormDescriptor screenshotSettingsForm(
  ScreenshotModel model,
  ScreenshotStrings strings,
) {
  return FormDescriptor(
    title: strings.settingsFormTitle,
    fields: <FormFieldSpec>[
      SelectFieldSpec(
        key: kSettingKeySaveDir,
        label: strings.settingsSaveDir,
        options: <String>[
          for (final String key in kScreenshotSaveDirKeys)
            screenshotSaveDirLabel(strings, key),
        ],
        defaultValue: screenshotSaveDirLabel(strings, model.settings.saveDir),
      ),
      TextFieldSpec(
        key: kSettingKeyFilenameTemplate,
        label: strings.settingsFilenameTemplate,
        isRequired: true,
        defaultValue: model.settings.filenameTemplate,
        placeholder: strings.settingsFilenameTemplatePlaceholder,
      ),
      SelectFieldSpec(
        key: kSettingKeyFormat,
        label: strings.settingsFormat,
        options: <String>[
          for (final String key in kScreenshotFormatKeys)
            screenshotFormatLabel(strings, key),
        ],
        defaultValue: screenshotFormatLabel(strings, model.settings.format),
      ),
      NumberFieldSpec(
        key: kSettingKeyJpegQuality,
        label: strings.settingsJpegQuality,
        isRequired: true,
        min: 1,
        max: 100,
        defaultValue: model.settings.jpegQuality,
      ),
      SelectFieldSpec(
        key: kSettingKeyAutoCopy,
        label: strings.settingsAutoCopy,
        options: <String>[
          for (final String key in kScreenshotAutoCopyKeys)
            screenshotAutoCopyLabel(strings, key),
        ],
        defaultValue: screenshotAutoCopyLabel(strings, model.settings.autoCopy),
      ),
      TextFieldSpec(
        key: kSettingKeyHotkeyCombo,
        label: strings.settingsHotkey,
        isRequired: true,
        defaultValue: model.settings.hotkeyCombo,
        placeholder: kScreenshotDefaultHotkeyCombo,
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
              strings.formatNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.color.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 提交回填：模板空白回退原值，下拉文案折算回稳定键，质量越界
  /// 钳制到 1-100，热键 combo 非法时回退原值（静默降级，页面注册
  /// 前还会再校验）。
  void _apply(Map<String, Object?> values, ScreenshotStrings strings) {
    final Object? template = values[kSettingKeyFilenameTemplate];
    final Object? quality = values[kSettingKeyJpegQuality];
    model.updateSettings(
      model.settings.copyWith(
        saveDir: switch (values[kSettingKeySaveDir]) {
          final String label => screenshotSaveDirKey(strings, label),
          _ => model.settings.saveDir,
        },
        filenameTemplate: template is String && template.trim().isNotEmpty
            ? template.trim()
            : model.settings.filenameTemplate,
        format: switch (values[kSettingKeyFormat]) {
          final String label => screenshotFormatKey(strings, label),
          _ => model.settings.format,
        },
        jpegQuality: switch (quality) {
          final num value => value.toInt().clamp(1, 100),
          _ => model.settings.jpegQuality,
        },
        autoCopy: switch (values[kSettingKeyAutoCopy]) {
          final String label => screenshotAutoCopyKey(strings, label),
          _ => model.settings.autoCopy,
        },
        hotkeyCombo: switch (values[kSettingKeyHotkeyCombo]) {
          final String combo
              when combo.trim().isNotEmpty &&
                  screenshotIsValidHotkeyCombo(combo.trim()) =>
            combo.trim(),
          _ => model.settings.hotkeyCombo,
        },
      ),
    );
  }
}
