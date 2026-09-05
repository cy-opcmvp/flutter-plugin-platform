/// 全局热键 windows 实现：RegisterHotKey（NULL hwnd）+ 16ms
/// PeekMessage 轮询 WM_HOTKEY（设计 §2.2，S1 批C）。
///
/// - 失败原因区分：combo 无法解析 → `invalid`；RegisterHotKey 返回
///   FALSE（组合键已被占用）→ `conflict`，经 [lastFailureReason] 暴露，
///   调用层据此折算 `hotkey.register_failed`；
/// - 注册 id 采用应用保留区（1..0xBFFF）空闲槽位策略，unregister 后
///   槽位可复用；
/// - 轮询泵仅在存在注册项时运行（首个注册成功启动，全部反注册停止）；
///   所有 FFI 调用与 WM_HOTKEY 投递都发生在主 isolate 线程，满足
///   RegisterHotKey 的线程亲和约束。
library;

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:platform_capabilities/platform_capabilities.dart';

import 'hotkey_ff.dart';

/// 全局热键能力 windows 实现。
final class WindowsGlobalHotkeys implements GlobalHotkeys {
  /// 创建实现；调用方持有单例（槽位与泵状态随实例）。
  WindowsGlobalHotkeys() {
    _msg = calloc<MsgStruct>();
  }

  static const Duration _pumpInterval = Duration(milliseconds: 16);

  late final Pointer<MsgStruct> _msg;

  final Map<String, int> _slotByHotkeyId = <String, int>{};

  final Set<int> _freeSlots = <int>{};

  final StreamController<String> _fired = StreamController<String>.broadcast();

  Timer? _pump;

  var _nextSlot = 1;

  String? _lastFailureReason;

  bool _disposed = false;

  /// 最近一次 [register] 失败原因（`invalid`/`conflict`；成功后清空）。
  String? get lastFailureReason => _lastFailureReason;

  @override
  Stream<String> get hotkeyFired => _fired.stream;

  @override
  Future<bool> register(String id, String combo) async {
    if (_disposed) {
      _lastFailureReason = 'invalid';
      return false;
    }
    if (_slotByHotkeyId.containsKey(id)) {
      _lastFailureReason = 'conflict';
      return false;
    }
    final (int, int)? parsed = parseHotkeyCombo(combo);
    if (parsed == null) {
      _lastFailureReason = 'invalid';
      return false;
    }
    final int slot = _acquireSlot();
    if (!callRegisterHotKey(slot, parsed.$1, parsed.$2)) {
      _freeSlots.add(slot);
      _lastFailureReason = 'conflict';
      return false;
    }
    _slotByHotkeyId[id] = slot;
    _lastFailureReason = null;
    _ensurePump();
    return true;
  }

  @override
  Future<void> unregister(String id) async {
    if (_disposed) {
      return;
    }
    final int? slot = _slotByHotkeyId.remove(id);
    if (slot == null) {
      return;
    }
    callUnregisterHotKey(slot);
    _freeSlots.add(slot);
    if (_slotByHotkeyId.isEmpty) {
      _pump?.cancel();
      _pump = null;
    }
  }

  /// 释放全部资源：反注册所有热键、停泵并关闭事件流。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final int slot in _slotByHotkeyId.values) {
      callUnregisterHotKey(slot);
    }
    _slotByHotkeyId.clear();
    _pump?.cancel();
    _pump = null;
    unawaited(_fired.close());
    calloc.free(_msg);
  }

  /// 测试注入：把 [id] 直接送入触发事件流（真按键无法在测试合成）。
  ///
  /// [id] 未注册时不广播。
  @visibleForTesting
  void debugTrigger(String id) {
    if (!_disposed && _slotByHotkeyId.containsKey(id)) {
      _fired.add(id);
    }
  }

  /// 分配空闲槽位：优先复用反注册释放的槽位，否则自增。
  int _acquireSlot() {
    if (_freeSlots.isNotEmpty) {
      final int slot = _freeSlots.first;
      _freeSlots.remove(slot);
      return slot;
    }
    final int slot = _nextSlot;
    _nextSlot = _nextSlot >= maxHotkeyId ? 1 : _nextSlot + 1;
    return slot;
  }

  /// 保证轮询泵运行；泵内连续取空 WM_HOTKEY 队列并按槽位映射广播。
  void _ensurePump() {
    _pump ??= Timer.periodic(_pumpInterval, (_) => _drain());
  }

  void _drain() {
    while (peekHotkeyMessage(_msg)) {
      final int slot = _msg.ref.wParam;
      for (final MapEntry<String, int> entry in _slotByHotkeyId.entries) {
        if (entry.value == slot) {
          _fired.add(entry.key);
          break;
        }
      }
    }
  }
}
