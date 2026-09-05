/// UI Surface 契约：插件向宿主声明页面、设置与动作三类界面（规格 §9）。
///
/// 宿主在插件清单 [PluginManifest.surfaces] 中声明支持的 surface，
/// 并在运行时通过本文件定义的 Provider 接口族取回界面；
/// 未支持的 surface 统一经 [surfaceUnsupported] 返回
/// `PluginFailure('surface.unsupported')`。
library;

import 'package:flutter/widgets.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

/// 页面 surface 提供者：插件主界面。
abstract interface class PluginPageProvider {
  /// 所属插件标识。
  PluginId get pluginId;

  /// 构建插件主页面；不得返回空 Widget，不得抛出异常。
  Widget buildPage(BuildContext context);
}

/// 设置 surface 提供者：插件设置界面。
abstract interface class PluginSettingsProvider {
  /// 构建插件设置界面；不得返回空 Widget，不得抛出异常。
  Widget buildSettings(BuildContext context);
}

/// 动作 surface 提供者：菜单/工具栏动作集合。
abstract interface class PluginActionProvider {
  /// 返回当前可用的动作列表；允许为空列表。
  List<PluginAction> actions(BuildContext context);
}

/// 可触发动作：宿主以 [onTriggered] 回调通知插件。
final class PluginAction {
  /// 创建动作；[id] 与 [label] 均非空白。
  PluginAction({
    required String id,
    required String label,
    required this.onTriggered,
  }) : id = _requireNonBlank(id, 'id'),
       label = _requireNonBlank(label, 'label');

  /// 动作标识。
  final String id;

  /// 展示标签。
  final String label;

  /// 触发回调，携带宿主传入的 [BuildContext]。
  final void Function(BuildContext context) onTriggered;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginAction && id == other.id && label == other.label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// 与 `PluginFailure` 同义的别名，满足计划签名 `UnsupportedSurfaceFailure
/// surfaceUnsupported(String surface, PluginId id)`。
typedef UnsupportedSurfaceFailure = PluginFailure;

/// 构造 `surface.unsupported` 失败：details 携带 surface 类型与插件 ID。
UnsupportedSurfaceFailure surfaceUnsupported(String surface, PluginId id) {
  return PluginFailure(
    'surface.unsupported',
    '插件未声明该 surface：$surface',
    <String, Object?>{'surface': surface, 'pluginId': id.value},
  );
}

String _requireNonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, '不能为空白');
  }

  return value;
}
