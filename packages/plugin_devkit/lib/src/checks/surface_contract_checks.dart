/// Surface 契约检查：插件作者自检 UI surface 实现与清单声明的一致性。
///
/// 检查失败时抛出 [StateError]（在 `test`/`testWidgets` 中未捕获即
/// 表现为用例失败），通过则静默返回。
library;

import 'package:flutter/widgets.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

/// 清单中页面 surface 的字面量。
const String surfacePage = 'page';

/// 清单中设置 surface 的字面量。
const String surfaceSettings = 'settings';

/// 清单中动作 surface 的字面量。
const String surfaceActions = 'actions';

/// UI surface 契约检查集合。
abstract final class SurfaceContractChecks {
  /// 检查 [provider] 的 `buildPage` 不抛异常且返回 Widget。
  static void checkPageProviderBuilds(
    BuildContext context,
    PluginPageProvider provider,
  ) {
    _checkBuilds(() => provider.buildPage(context), 'buildPage');
  }

  /// 检查 [provider] 的 `buildSettings` 不抛异常且返回 Widget。
  static void checkSettingsProviderBuilds(
    BuildContext context,
    PluginSettingsProvider provider,
  ) {
    _checkBuilds(() => provider.buildSettings(context), 'buildSettings');
  }

  /// 检查清单 [manifest] 的 surfaces 声明与实现族一致。
  ///
  /// 每个 `true` 的实现必须在清单中声明对应 surface；声明了却未实现
  /// 同样视为不一致。
  static void checkManifestSurfaceDeclared(
    PluginManifest manifest, {
    bool page = false,
    bool settings = false,
    bool actions = false,
  }) {
    final surfaces = manifest.surfaces;
    void requireConsistent(String surface, bool implemented) {
      if (implemented && !surfaces.contains(surface)) {
        throw StateError('清单未声明 surface "$surface"，但实现族已提供');
      }
      if (!implemented && surfaces.contains(surface)) {
        throw StateError('清单声明了 surface "$surface"，但实现族未提供');
      }
    }

    requireConsistent(surfacePage, page);
    requireConsistent(surfaceSettings, settings);
    requireConsistent(surfaceActions, actions);
  }

  /// 检查 [provider] 的 `actions` 返回非空列表。
  static void checkActionsNonEmpty(
    PluginActionProvider provider,
    BuildContext context,
  ) {
    if (provider.actions(context).isEmpty) {
      throw StateError('actions(context) 返回空列表，动作 surface 要求至少一个动作');
    }
  }

  static void _checkBuilds(Widget Function() build, String method) {
    // Widget 为非空类型：build 未抛异常即视为构建成功。
    try {
      build();
    } catch (error) {
      throw StateError('$method 抛出异常：$error');
    }
  }
}
