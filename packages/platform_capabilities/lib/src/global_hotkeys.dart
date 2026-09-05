/// 全局热键能力接口与默认不支持实现（设计 §2.2，S1 批C）。
///
/// 全局热键注册属平台专属能力：宿主按端注入实现，接口保持零平台依赖
/// （本文件不 import `dart:io` / `dart:ffi`）。截图与未来 PetLink 共用
/// 本契约（双消费方）。
///
/// 实现方约定：
/// - [GlobalHotkeys.register] 组合键冲突或 combo 非法时返回 `false`
///   而非抛异常；错误码语义由调用层经 [hotkeyRegisterFailedFailure]
///   折算（`hotkey.register_failed`，`details['reason']` 为 `conflict` /
///   `invalid` / `unsupported`）；
/// - combo 形如 `Ctrl+Shift+A`（修饰键 Ctrl/Alt/Shift/Win + 字母数字
///   或 F1-F12），大小写与空白容错；
/// - [GlobalHotkeys.hotkeyFired] 携带注册时的 id。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 构造 `hotkey.register_failed` 结构化失败值。
///
/// [reason] 为失败原因（`conflict`：组合键已被占用；`invalid`：combo
/// 无法解析；`unsupported`：当前平台不支持全局热键）。
PluginFailure hotkeyRegisterFailedFailure(String reason, String message) {
  return PluginFailure('hotkey.register_failed', message, <String, Object?>{
    'reason': reason,
  });
}

/// 全局热键能力接口。
abstract interface class GlobalHotkeys {
  /// 注册全局热键；[combo] 形如 `Ctrl+Shift+A`。
  ///
  /// 返回是否注册成功：组合键冲突或 combo 非法返回 `false`。
  Future<bool> register(String id, String combo);

  /// 反注册全局热键；未注册的 [id] 为无操作。
  Future<void> unregister(String id);

  /// 热键触发事件流，携带注册时的 id。
  Stream<String> get hotkeyFired;
}

/// 各端默认实现：[register] 一律返回 `false`（reason=unsupported），
/// [hotkeyFired] 为永不广播的空流。
final class UnsupportedGlobalHotkeys implements GlobalHotkeys {
  /// 创建不支持实现；[platform] 为平台标签（web/macos/…）。
  const UnsupportedGlobalHotkeys(this.platform);

  /// 平台标签，写入失败 details 便于定位来源端。
  final String platform;

  @override
  Future<bool> register(String id, String combo) => Future<bool>.value(false);

  @override
  Future<void> unregister(String id) async {}

  @override
  Stream<String> get hotkeyFired => const Stream<String>.empty();
}
