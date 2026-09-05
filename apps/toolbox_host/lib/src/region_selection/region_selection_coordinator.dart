/// 区域选择协调器 + 全局热键绑定（宿主组装根专用）。
///
/// [HostRegionSelectionCoordinator] 承接插件 [RegionSelector] 缝：推入
/// 全屏 overlay 路由，弹出后恢复窗口形态并短暂等待合成稳定，再放行
/// 插件侧的第二次区域捕获（避免拍到 overlay 自身）。
///
/// [RegionHotkeyBinding] 承接页面热键缝：以固定能力 id 注册/反注册
/// 全局热键，并把触发事件转发给页面回调。
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Rect;

import 'package:flutter/material.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:screenshot/screenshot.dart';

import '../generated/host_l10n.dart';
import '../host_window.dart';
import 'region_selection_overlay.dart';

/// 区域选择协调器。
final class HostRegionSelectionCoordinator {
  /// 创建协调器；[navigatorKey] 须挂到 MaterialApp，[windowOps] 负责
  /// overlay 前后的窗口形态切换。
  HostRegionSelectionCoordinator({
    required GlobalKey<NavigatorState> navigatorKey,
    required HostWindowOps windowOps,
    this.restoreDelay = const Duration(milliseconds: 120),
  }) : _navigatorKey = navigatorKey,
       _windowOps = windowOps;

  final GlobalKey<NavigatorState> _navigatorKey;

  final HostWindowOps _windowOps;

  /// 窗口恢复后的等待时长（避免第二次捕获拍到 overlay/恢复中窗口）。
  final Duration restoreDelay;

  /// 打开区域选择 overlay；返回 null 表示取消。
  ///
  /// [imageSize] 与 [RegionSelector] 缝一致，为 dart:ui 坐标系。
  Future<ScreenRegion?> select(Uint8List image, ui.Rect imageSize) async {
    await _windowOps.enterSelection();
    ScreenRegion? region;
    try {
      final BuildContext? context = _navigatorKey.currentContext;
      if (context == null) {
        return null;
      }
      region = await Navigator.of(context).push<ScreenRegion>(
        PageRouteBuilder<ScreenRegion>(
          opaque: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder:
              (BuildContext context, Animation<double> _, Animation<double> _) {
                final HostL10n l10n = HostL10n.of(context);
                return RegionSelectionOverlay(
                  imageBytes: image,
                  imageLogicalSize: imageSize,
                  saveLabel: l10n.regionSelectorSave,
                  copyLabel: l10n.regionSelectorCopy,
                  discardLabel: l10n.regionSelectorDiscard,
                  hint: l10n.regionSelectorHint,
                );
              },
          transitionsBuilder:
              (
                BuildContext _,
                Animation<double> _,
                Animation<double> _,
                Widget child,
              ) => child,
        ),
      );
    } finally {
      await _windowOps.exitSelection();
      await Future<void>.delayed(restoreDelay);
    }
    return region;
  }
}

/// 截图全局热键绑定（固定能力 id，重复绑定自动反绑旧的）。
final class RegionHotkeyBinding {
  /// 创建绑定；[hotkeys] 为宿主全局热键能力。
  RegionHotkeyBinding({required GlobalHotkeys hotkeys}) : _hotkeys = hotkeys;

  static const String _bindingId = 'screenshot.region';

  final GlobalHotkeys _hotkeys;

  StreamSubscription<String>? _subscription;

  void Function()? _fired;

  /// 注册 [combo] 并监听触发事件；注册失败时清理并返回 false。
  Future<bool> bind(String combo, void Function() fired) async {
    await unbind(combo);
    _fired = fired;
    _subscription = _hotkeys.hotkeyFired
        .where((String id) => id == _bindingId)
        .listen((String _) {
          _fired?.call();
        });
    final bool ok = await _hotkeys.register(_bindingId, combo);
    if (!ok) {
      await unbind(combo);
      return false;
    }
    return true;
  }

  /// 反绑（幂等）：取消订阅 + 注销能力 id。
  ///
  /// [combo] 与 [bind] 的缝签名对齐（插件页面按先前绑定的 combo 反绑）；
  /// 能力 id 固定为 [_bindingId]，参数本身不参与反注册。
  Future<void> unbind(String combo) async {
    _fired = null;
    final StreamSubscription<String>? subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }
    await _hotkeys.unregister(_bindingId);
  }
}
