library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screenshot_service.dart';

/// 热键服务
///
/// 负责管理系统级全局热键的注册
class HotkeyService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.screenshot/hotkey',
  );

  final Map<String, HotkeyCallback> _callbacks = {};
  bool _isInitialized = false;
  ScreenshotService? _screenshotService;

  /// 初始化热键服务
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    // 设置 MethodCallHandler 以接收来自原生的热键事件
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onHotkey') {
        // 接收到来自原生的热键触发事件
        final args = call.arguments as Map<dynamic, dynamic>;
        final actionId = args['actionId'] as String?;

        print('🔑 [HotkeyService] 收到原生热键事件: actionId=$actionId');

        if (actionId != null && _callbacks.containsKey(actionId)) {
          // 执行对应的回调
          final callback = _callbacks[actionId]!;
          print('🔑 [HotkeyService] ✅ 执行回调: $actionId');
          callback();
          return;
        }

        if (actionId == null) {
          print('🔑 [HotkeyService] ❌ actionId 为 null');
        } else {
          print('🔑 [HotkeyService] ❌ 未找到回调: $actionId');
        }
      }
      return null;
    });

    _isInitialized = true;
    return true;
  }

  /// 设置截图服务（用于原生区域选择窗口）
  void setScreenshotService(ScreenshotService service) {
    _screenshotService = service;
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
      print('🔑 [HotkeyService] 正在注册热键: actionId=$actionId, shortcut=$shortcut');
      final result = await _methodChannel.invokeMethod('registerHotkey', {
        'actionId': actionId,
        'shortcut': shortcut,
      });

      print('🔑 [HotkeyService] 原生层返回结果: $result');

      if (result == true) {
        _callbacks[actionId] = callback;
        print('🔑 [HotkeyService] ✅ 热键回调已保存: $actionId');
        print('🔑 [HotkeyService] ✅ 热键注册成功: $actionId');
        return true;
      }

      print('🔑 [HotkeyService] ❌ 热键注册失败（原生层返回 false）: $actionId');
      return false;
    } catch (e) {
      print('🔑 [HotkeyService] ❌ 热键注册异常: $actionId, error=$e');
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
        print('🔑 [HotkeyService] ✅ 热键已注销: $actionId');
        return true;
      }
      print('🔑 [HotkeyService] ❌ 热键注销失败: $actionId');
      return false;
    } catch (e) {
      print('🔑 [HotkeyService] ❌ 热键注销异常: $actionId, error=$e');
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

  /// 释放资源
  Future<void> dispose() async {
    await unregisterAll();
    _isInitialized = false;
  }

  /// 检查服务是否可用
  bool get isInitialized => _isInitialized;
}

/// 热键回调函数类型
typedef HotkeyCallback = void Function();
