/// 插件详情页：基本信息 / 启用开关 / 页面入口 / 表单演示 / Sidecar 面板占位。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import '../generated/host_l10n.dart';
import '../host_composition_root.dart';
import '../plugins/welcome_plugin.dart';

/// 插件详情页。
final class PluginDetailPage extends StatefulWidget {
  /// 创建详情页；[enabled] 为当前启用状态，[onToggleEnabled] 回调宿主壳。
  const PluginDetailPage({
    super.key,
    required this.root,
    required this.manifest,
    required this.enabled,
    required this.onToggleEnabled,
  });

  /// 宿主组装根。
  final HostCompositionRoot root;

  /// 展示的插件清单。
  final PluginManifest manifest;

  /// 当前是否启用（宿主停用集合的镜像）。
  final bool enabled;

  /// 启用开关回调（pluginId 字符串, 是否启用）。
  final void Function(String pluginId, bool enabled) onToggleEnabled;

  @override
  State<PluginDetailPage> createState() => _PluginDetailPageState();
}

class _PluginDetailPageState extends State<PluginDetailPage> {
  /// 最近一次表单演示的提交值（用于结果回填）。
  Map<String, Object?>? _submittedValues;

  void _openPluginPage(BuildContext context) {
    final PluginPageProvider? provider = widget.root.pageProviderFor(
      widget.manifest.id,
    );
    if (provider == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(widget.manifest.name)),
          body: provider.buildPage(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HostL10n l10n = HostL10n.of(context);
    final TokenSpacingSet spacing = ThemeTokens.of(context).spacing;
    final PluginManifest manifest = widget.manifest;
    final PluginPageProvider? provider = widget.root.pageProviderFor(
      manifest.id,
    );
    return Scaffold(
      appBar: AppBar(title: Text(manifest.name)),
      body: ListView(
        padding: EdgeInsets.all(spacing.space5),
        children: <Widget>[
          _sectionTitle(context, l10n.detailBasicInfo),
          Card(
            child: Padding(
              padding: EdgeInsets.all(spacing.space4),
              child: Column(
                children: <Widget>[
                  _infoRow(l10n.detailFieldId, manifest.id.value, spacing),
                  _infoRow(l10n.detailFieldVersion, manifest.version, spacing),
                  _infoRow(
                    l10n.detailFieldKind,
                    manifest.kind == PluginKind.builtin
                        ? l10n.kindBuiltin
                        : l10n.kindSidecar,
                    spacing,
                  ),
                  _infoRow(
                    l10n.detailFieldTargets,
                    manifest.targets
                        .map((PluginTarget target) => target.name)
                        .join(', '),
                    spacing,
                  ),
                  _infoRow(
                    l10n.detailFieldSurfaces,
                    manifest.surfaces.join(', '),
                    spacing,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.space5),
          SwitchListTile(
            title: Text(l10n.detailEnableToggle),
            value: widget.enabled,
            onChanged: (bool value) =>
                widget.onToggleEnabled(manifest.id.value, value),
          ),
          SizedBox(height: spacing.space5),
          OutlinedButton.icon(
            onPressed: provider == null ? null : () => _openPluginPage(context),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              provider == null ? l10n.detailNoPage : l10n.detailOpenPage,
            ),
          ),
          SizedBox(height: spacing.space7),
          _sectionTitle(context, l10n.detailFormDemo),
          FormRenderer(
            descriptor: welcomeDemoForm(l10n),
            onSubmit: (Map<String, Object?> values) =>
                setState(() => _submittedValues = values),
          ),
          if (_submittedValues != null) ...<Widget>[
            SizedBox(height: spacing.space5),
            _sectionTitle(context, l10n.formDemoResultTitle),
            ResultRenderer(
              descriptor: FieldsResultDescriptor(
                fields: welcomeFormResultFields(l10n, _submittedValues!),
              ),
            ),
          ],
          SizedBox(height: spacing.space7),
          _sectionTitle(context, l10n.detailSidecarPanel),
          Card(
            child: Padding(
              padding: EdgeInsets.all(spacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.sidecarPlaceholder),
                  SizedBox(height: spacing.space3),
                  _infoRow(
                    l10n.sidecarRootDir,
                    widget.root.sidecarInstaller.rootDir,
                    spacing,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ThemeTokens.of(context).spacing.space3),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _infoRow(String label, String value, TokenSpacingSet spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
