/// 内置欢迎插件（F3-06）。
///
/// 以最小 builtin 清单注册进宿主注册表，并经 [PluginPageProvider] 提供
/// 欢迎页面：说明内容 + [FormRenderer] 演示表单，提交后经 [ResultRenderer]
/// 以字段列表形式回填呈现。表单描述符由 [welcomeDemoForm] 共享，详情页的
/// 表单演示与结果映射也复用同一份字段与文案。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import '../generated/host_l10n.dart';

/// 欢迎插件 ID 字符串。
const String kWelcomePluginId = 'com.toolbox.welcome';

/// 构建欢迎插件清单（宿主组装根注册用）。
PluginManifest welcomeManifest() {
  return PluginManifest(
    id: PluginId.parse(kWelcomePluginId),
    name: 'Welcome',
    version: '1.0.0',
    apiVersion: 1,
    kind: PluginKind.builtin,
    targets: const <PluginTarget>[
      PluginTarget.windows,
      PluginTarget.macos,
      PluginTarget.linux,
    ],
    entrypoint: 'builtin://com.toolbox.welcome',
    provides: <CapabilityDescriptor>[
      CapabilityDescriptor('toolbox.page.welcome', 1),
    ],
    requires: const <CapabilityRequirement>[],
    surfaces: const <String>['directory', 'detail'],
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}

/// 构建演示表单描述符：欢迎页与详情页表单演示共用（文案取自宿主 l10n）。
FormDescriptor welcomeDemoForm(HostL10n l10n) {
  return FormDescriptor(
    title: l10n.welcomeFormTitle,
    fields: <FormFieldSpec>[
      TextFieldSpec(
        key: 'name',
        label: l10n.welcomeFormName,
        isRequired: true,
        placeholder: l10n.welcomeFormNamePlaceholder,
      ),
      NumberFieldSpec(
        key: 'score',
        label: l10n.welcomeFormScore,
        min: 1,
        max: 5,
      ),
      SelectFieldSpec(
        key: 'channel',
        label: l10n.welcomeFormChannel,
        isRequired: true,
        options: <String>[
          l10n.welcomeFormChannelEmail,
          l10n.welcomeFormChannelPush,
        ],
        defaultValue: l10n.welcomeFormChannelEmail,
      ),
      CheckboxFieldSpec(key: 'subscribe', label: l10n.welcomeFormSubscribe),
      ToggleGroupSpec(
        key: 'topics',
        label: l10n.welcomeFormTopics,
        options: <String>[
          l10n.welcomeFormTopicDesign,
          l10n.welcomeFormTopicPlugins,
        ],
      ),
    ],
  );
}

/// 把演示表单的提交值映射为结果字段：label 取字段标签，value 字符串化。
///
/// 空值与空集合统一显示为 `-`（[ResultField] 要求值非空白）。
List<ResultField> welcomeFormResultFields(
  HostL10n l10n,
  Map<String, Object?> values,
) {
  final FormDescriptor descriptor = welcomeDemoForm(l10n);
  final List<ResultField> fields = <ResultField>[];
  for (final FormFieldSpec spec in descriptor.fields) {
    final Object? value = values[spec.key];
    final String text = switch (value) {
      null => '-',
      final List<Object?> list => list.isEmpty ? '-' : list.join(', '),
      _ => value.toString(),
    };
    fields.add(ResultField(label: spec.label, value: text));
  }
  return fields;
}

/// 内置欢迎插件：页面提供方实现。
final class WelcomePlugin implements PluginPageProvider {
  /// 创建欢迎插件（常量，宿主组装根持有单例）。
  const WelcomePlugin();

  @override
  PluginId get pluginId => PluginId.parse(kWelcomePluginId);

  @override
  Widget buildPage(BuildContext context) {
    return const _WelcomePageView();
  }
}

/// 欢迎页面视图：说明内容 + 演示表单 + 提交结果回填。
final class _WelcomePageView extends StatefulWidget {
  const _WelcomePageView();

  @override
  State<_WelcomePageView> createState() => _WelcomePageViewState();
}

class _WelcomePageViewState extends State<_WelcomePageView> {
  Map<String, Object?>? _submittedValues;

  @override
  Widget build(BuildContext context) {
    final HostL10n l10n = HostL10n.of(context);
    final TokenSpacingSet spacing = ThemeTokens.of(context).spacing;
    final Map<String, Object?>? submittedValues = _submittedValues;
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.welcomePageTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: spacing.space3),
          Text(l10n.welcomeBody, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: spacing.space6),
          FormRenderer(
            descriptor: welcomeDemoForm(l10n),
            onSubmit: (Map<String, Object?> values) =>
                setState(() => _submittedValues = values),
          ),
          if (submittedValues != null) ...<Widget>[
            SizedBox(height: spacing.space6),
            Text(
              l10n.formDemoResultTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: spacing.space3),
            ResultRenderer(
              descriptor: FieldsResultDescriptor(
                fields: welcomeFormResultFields(l10n, submittedValues),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
