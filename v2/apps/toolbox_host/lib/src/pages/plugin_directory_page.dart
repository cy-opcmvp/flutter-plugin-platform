/// 插件目录页：注册清单 × 静态解析结果 → 卡片网格。
///
/// 状态优先级：宿主停用集合 → disabled；解析失败 → unavailable（含结构化
/// 原因文案）；否则 available。点击卡片进入详情页。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_runtime/plugin_runtime.dart';

import '../generated/host_l10n.dart';
import '../host_composition_root.dart';

/// 插件目录页。
final class PluginDirectoryPage extends StatelessWidget {
  /// 创建目录页；[disabledPluginIds] 为宿主侧停用的插件 ID 字符串集合。
  const PluginDirectoryPage({
    super.key,
    required this.root,
    required this.disabledPluginIds,
    required this.onOpenPlugin,
  });

  /// 宿主组装根（注册表 + 解析结果来源）。
  final HostCompositionRoot root;

  /// 宿主侧停用的插件 ID 字符串集合。
  final Set<String> disabledPluginIds;

  /// 点击卡片回调（打开详情页）。
  final ValueChanged<PluginManifest> onOpenPlugin;

  /// 目录卡片固定宽度。
  static const double _cardWidth = 280;

  @override
  Widget build(BuildContext context) {
    final HostL10n l10n = HostL10n.of(context);
    final TokenSpacingSet spacing = ThemeTokens.of(context).spacing;
    final List<Widget> cards = <Widget>[];
    for (final PluginRegistration registration
        in root.registry.registrations.values) {
      final PluginManifest manifest = registration.manifest;
      cards.add(
        SizedBox(width: _cardWidth, child: _buildCard(context, manifest)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.directoryTitle)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.space5),
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: spacing.space4,
            runSpacing: spacing.space4,
            children: cards,
          ),
        ),
      ),
    );
  }

  /// 组装单张插件卡片（状态判定 + 结构化原因映射）。
  Widget _buildCard(BuildContext context, PluginManifest manifest) {
    final HostL10n l10n = HostL10n.of(context);
    final PluginResolution? item = root.resolution.plugins[manifest.id];
    final StatusBadgeState state;
    String? reasonCode;
    String? reasonText;
    if (disabledPluginIds.contains(manifest.id.value)) {
      state = StatusBadgeState.disabled;
    } else if (item == null || !item.available) {
      state = StatusBadgeState.unavailable;
      final PluginFailure? failure = (item == null || item.failures.isEmpty)
          ? null
          : item.failures.first;
      if (failure != null) {
        reasonCode = failure.code;
        reasonText = failure.code == 'resolution.unsupported_target'
            ? l10n.reasonUnsupportedTarget
            : l10n.reasonGeneric(failure.code);
      }
    } else {
      state = StatusBadgeState.available;
    }
    return PluginCard(
      title: manifest.name,
      description: manifest.kind == PluginKind.builtin
          ? l10n.kindBuiltin
          : l10n.kindSidecar,
      version: manifest.version,
      state: state,
      reasonCode: reasonCode,
      reasonText: reasonText,
      onTap: () => onOpenPlugin(manifest),
    );
  }
}
