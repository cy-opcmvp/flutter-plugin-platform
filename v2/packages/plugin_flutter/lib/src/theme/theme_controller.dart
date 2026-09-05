/// 主题方向控制器。
///
/// 持有当前方向并通过 [ValueNotifier] 通知监听者；持久化以回调注入
/// （宿主决定落地方式），本包不做任何 I/O。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_theme.dart';

/// 主题方向控制器：方向变化时通知监听者并触发注入的持久化回调。
final class ThemeController extends ValueNotifier<AppThemePreset> {
  /// 创建控制器；[initial] 为初始方向（平台默认 warm_life），[persist] 为
  /// 方向变化后的持久化回调（可空：为空时仅通知不持久化）。
  ThemeController(
    super._value, {
    Future<void> Function(AppThemePreset preset)? persist,
  }) : _persist = persist;

  final Future<void> Function(AppThemePreset preset)? _persist;

  @override
  set value(AppThemePreset next) {
    if (next == value) {
      return;
    }
    super.value = next;
    final Future<void> Function(AppThemePreset preset)? persist = _persist;
    if (persist != null) {
      unawaited(persist(next));
    }
  }

  /// 切换方向（与直接赋值 [value] 等价，语义化入口）。
  void select(AppThemePreset preset) {
    value = preset;
  }
}
