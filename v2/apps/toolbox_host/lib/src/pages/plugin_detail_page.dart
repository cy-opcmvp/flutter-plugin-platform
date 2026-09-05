/// 插件详情页：基本信息 / 启用开关 / 页面入口 / 表单演示 / Sidecar 命令面板。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import '../generated/host_l10n.dart';
import '../host_bytes_loader.dart';
import '../host_composition_root.dart';
import '../plugins/hash_tool_plugin.dart';
import '../plugins/welcome_plugin.dart';
import '../sidecar_command_bridge.dart';

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

  /// .scp 包路径输入控制器。
  final TextEditingController _scpPathController = TextEditingController();

  /// 面板异步操作进行中（安装/启动/停止互斥禁用）。
  bool _busy = false;

  /// hash_tool 当前安装状态（null 表示尚未查询）。
  bool? _installed;

  /// 面板状态提示（安装成功/失败等，随操作刷新）。
  String? _statusMessage;

  /// 状态提示是否为错误（决定文案颜色）。
  bool _statusIsError = false;

  /// 最近一次 hash.compute 命令的声明式结果。
  ResultDescriptor? _hashResult;

  /// 最近一次 hash.compute 命令的失败文案。
  String? _hashFailure;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
  }

  @override
  void dispose() {
    _scpPathController.dispose();
    super.dispose();
  }

  /// 查询 hash_tool 安装状态并回填面板。
  Future<void> _refreshInstalled() async {
    final bool installed = await widget.root.sidecarBridge.isInstalled();
    if (mounted) {
      setState(() => _installed = installed);
    }
  }

  /// 安装 .scp 包：读文件字节 → installFromBytes → 回填状态。
  Future<void> _installPackage() async {
    final HostL10n l10n = HostL10n.of(context);
    setState(() {
      _busy = true;
      _statusIsError = false;
      _statusMessage = null;
    });
    final Uint8List? bytes = await loadHostImageBytes(
      _scpPathController.text.trim(),
    );
    final BridgeInstallResult result;
    if (bytes == null) {
      result = BridgeInstallResult(
        succeeded: false,
        failure: PluginFailure(
          'sidecar.install_failed',
          'package file missing or unreadable',
          <String, Object?>{'reason': 'packageFileMissing'},
        ),
      );
    } else {
      result = await widget.root.sidecarBridge.installFromBytes(bytes);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _statusIsError = !result.succeeded;
      _statusMessage = result.succeeded
          ? l10n.hashInstallSuccess
          : l10n.hashInstallFailed(result.failure?.code ?? 'unknown');
      if (result.succeeded) {
        _installed = true;
      }
    });
  }

  /// 启动 hash_tool 会话。
  Future<void> _startSession() async {
    final HostL10n l10n = HostL10n.of(context);
    setState(() {
      _busy = true;
      _statusIsError = false;
      _statusMessage = null;
    });
    final BridgeStartOutcome outcome = await widget.root.sidecarBridge.start();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _statusIsError = !outcome.succeeded;
      _statusMessage = outcome.succeeded
          ? null
          : _failureText(l10n, outcome.failure);
    });
  }

  /// 停止 hash_tool 会话（幂等）。
  Future<void> _stopSession() async {
    setState(() => _busy = true);
    await widget.root.sidecarBridge.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _statusIsError = false;
      _statusMessage = null;
    });
  }

  /// 运行 hash.compute：表单值 → 桥 → 声明式结果回填。
  Future<void> _runCommand(Map<String, Object?> values) async {
    final HostL10n l10n = HostL10n.of(context);
    setState(() => _busy = true);
    final BridgeRunResult result = await widget.root.sidecarBridge.run(
      values,
      strings: hashToolStrings(l10n),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _hashResult = result.result;
      _hashFailure = result.succeeded
          ? null
          : _failureText(l10n, result.failure);
    });
  }

  /// 把结构化失败映射为用户可读文案（未安装优先给专门提示）。
  String _failureText(HostL10n l10n, PluginFailure? failure) {
    if (failure == null) {
      return l10n.hashCommandFailed('unknown');
    }
    if (failure.code == 'bridge.not_installed') {
      return l10n.hashNotInstalled;
    }
    final Object? cause = failure.details['cause'];
    return l10n.hashCommandFailed(cause?.toString() ?? failure.code);
  }

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
          // 设置区（F4-03）：清单声明 settings 时内嵌宿主设置提供方。
          if (manifest.surfaces.contains('settings')) ...<Widget>[
            SizedBox(height: spacing.space7),
            _sectionTitle(context, l10n.detailSettings),
            Card(
              child: Padding(
                padding: EdgeInsets.all(spacing.space4),
                child: _settingsBody(context, manifest),
              ),
            ),
          ],
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
              // F4-02：注入宿主图片字节加载器，image 类结果真实解码。
              bytesLoader: widget.root.bytesLoader,
            ),
          ],
          // Sidecar 命令面板（F4-06）：sidecar 插件显示安装/启动/停止与
          // hash 命令表单；内置插件不显示该区。
          if (manifest.kind == PluginKind.sidecar) ...<Widget>[
            SizedBox(height: spacing.space7),
            _sectionTitle(context, l10n.detailSidecarPanel),
            Card(
              child: Padding(
                padding: EdgeInsets.all(spacing.space4),
                child: _sidecarPanel(context, l10n, manifest, spacing),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sidecar 面板主体：hash_tool 接命令桥；其余 sidecar 显示占位文案。
  Widget _sidecarPanel(
    BuildContext context,
    HostL10n l10n,
    PluginManifest manifest,
    TokenSpacingSet spacing,
  ) {
    if (manifest.id.value != kHashToolPluginId) {
      return Text(l10n.hashPanelUnsupported);
    }
    final bool installed = _installed ?? false;
    final Color? statusColor = _statusIsError
        ? Theme.of(context).colorScheme.error
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          installed ? l10n.hashInstalled : l10n.hashNotInstalled,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: installed
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.error,
          ),
        ),
        SizedBox(height: spacing.space3),
        TextField(
          controller: _scpPathController,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: l10n.hashInstallPathLabel,
            hintText: l10n.hashInstallPathPlaceholder,
          ),
        ),
        SizedBox(height: spacing.space3),
        Wrap(
          spacing: spacing.space3,
          runSpacing: spacing.space2,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _busy ? null : _installPackage,
              icon: const Icon(Icons.download),
              label: Text(l10n.hashInstallButton),
            ),
            OutlinedButton.icon(
              onPressed: installed && !_busy ? _startSession : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.hashStartButton),
            ),
            OutlinedButton.icon(
              onPressed: installed && !_busy ? _stopSession : null,
              icon: const Icon(Icons.stop),
              label: Text(l10n.hashStopButton),
            ),
          ],
        ),
        if (_statusMessage != null) ...<Widget>[
          SizedBox(height: spacing.space3),
          Text(_statusMessage!, style: TextStyle(color: statusColor)),
        ],
        SizedBox(height: spacing.space4),
        FormRenderer(
          descriptor: widget.root.sidecarBridge.formDescriptor(
            hashToolStrings(l10n),
          ),
          onSubmit: _runCommand,
        ),
        if (_hashFailure != null) ...<Widget>[
          SizedBox(height: spacing.space3),
          Text(
            _hashFailure!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_hashResult != null) ...<Widget>[
          SizedBox(height: spacing.space5),
          _sectionTitle(context, l10n.hashResultTitle),
          ResultRenderer(
            descriptor: _hashResult!,
            bytesLoader: widget.root.bytesLoader,
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ThemeTokens.of(context).spacing.space3),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  /// 设置区主体：有宿主设置提供方时内嵌其设置 UI，否则显示占位文案。
  Widget _settingsBody(BuildContext context, PluginManifest manifest) {
    final PluginSettingsProvider? settingsProvider = widget.root
        .settingsProviderFor(manifest.id);
    if (settingsProvider != null) {
      return settingsProvider.buildSettings(context);
    }
    return Text(
      HostL10n.of(context).detailNoSettings,
      style: Theme.of(context).textTheme.bodyMedium,
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
