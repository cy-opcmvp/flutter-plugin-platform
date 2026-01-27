library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 热键服务
///
/// 负责管理系统级全局热键的注册和监听
class HotkeyService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.screenshot/hotkey',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.screenshot/hotkey_events',
  );

  StreamSubscription<dynamic>? _eventSubscription;
  final Map<String, HotkeyCallback> _callbacks = {};

  bool _isInitialized = false;

  /// 初始化热键服务
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // 监听热键事件
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          _handleHotkeyEvent(event as String);
        },
        onError: (dynamic error) {
          debugPrint('Hotkey event error: $error');
        },
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize hotkey service: $e');
      return false;
    }
  }

  /// 注册热键
  ///
  /// [actionId] - 操作 ID（如 'regionCapture', 'fullScreenCapture'）
  /// [shortcut] - 快捷键字符串（如 'Ctrl+Shift+A'）
  /// [callback] - 热键触发时的回调函数
  Future<bool> registerHotkey(
    String actionId,
    String shortcut,
    HotkeyCallback callback,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _methodChannel.invokeMethod('registerHotkey', {
        'actionId': actionId,
        'shortcut': shortcut,
      });

      if (result == true) {
        _callbacks[actionId] = callback;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to register hotkey: $e');
      return false;
    }
  }

  /// 注销热键
  Future<bool> unregisterHotkey(String actionId) async {
    try {
      final result = await _methodChannel.invokeMethod('unregisterHotkey', {
        'actionId': actionId,
      });

      if (result == true) {
        _callbacks.remove(actionId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to unregister hotkey: $e');
      return false;
    }
  }

  /// 注销所有热键
  Future<void> unregisterAll() async {
    final actionIds = _callbacks.keys.toList();
    for (final actionId in actionIds) {
      await unregisterHotkey(actionId);
    }
  }

  /// 更新热键
  Future<bool> updateHotkey(
    String actionId,
    String newShortcut,
    HotkeyCallback callback,
  ) async {
    await unregisterHotkey(actionId);
    return await registerHotkey(actionId, newShortcut, callback);
  }

  /// 处理热键事件
  void _handleHotkeyEvent(String actionId) {
    final callback = _callbacks[actionId];
    if (callback != null) {
      callback();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await unregisterAll();
    await _eventSubscription?.cancel();
    _isInitialized = false;
  }

  /// 检查服务是否可用
  bool get isInitialized => _isInitialized;
}

/// 热键回调函数类型
typedef HotkeyCallback = void Function();
