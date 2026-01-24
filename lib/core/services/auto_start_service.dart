/// Auto Start Service
///
/// Windows 平台开机自启服务
library;

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart' as win32;

/// 开机自启服务
class AutoStartService {
  static const String _registryKey =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _appName = 'PluginPlatform';

  bool _isEnabled = false;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否已启用开机自启
  bool get isEnabled => _isEnabled;

  /// 初始化服务
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    if (!Platform.isWindows) {
      if (kDebugMode) {
        debugPrint('AutoStartService: Only supported on Windows');
      }
      return false;
    }

    try {
      // 读取当前状态
      _isEnabled = await _checkRegistry();
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('AutoStartService: Initialized, enabled=$_isEnabled');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AutoStartService: Initialization failed: $e');
      }
      return false;
    }
  }

  /// 设置开机自启
  Future<bool> setEnabled(bool enabled) async {
    if (!Platform.isWindows) {
      if (kDebugMode) {
        debugPrint('AutoStartService: Only supported on Windows');
      }
      return false;
    }

    try {
      final exePath = _getExecutablePath();
      final hKeyPtr = calloc<win32.HKEY>();

      // 打开注册表
      final result = win32.RegOpenKeyEx(
        win32.HKEY_CURRENT_USER,
        TEXT(_registryKey),
        0,
        win32.KEY_SET_VALUE,
        hKeyPtr,
      );

      if (result == win32.ERROR_SUCCESS) {
        final hKey = hKeyPtr.value;
        if (enabled) {
          // 添加注册表项
          final pathPtr = TEXT(exePath);
          win32.RegSetValueEx(
            hKey,
            TEXT(_appName),
            0,
            win32.REG_SZ,
            pathPtr.cast(),
            (exePath.length + 1) * 2, // UTF-16 每个字符 2 字节
          );
          calloc.free(pathPtr);
        } else {
          // 删除注册表项
          win32.RegDeleteValue(hKey, TEXT(_appName));
        }

        win32.RegCloseKey(hKey);
        calloc.free(hKeyPtr);
        _isEnabled = enabled;

        if (kDebugMode) {
          debugPrint('AutoStartService: Set enabled=$enabled, exe=$exePath');
        }

        return true;
      } else {
        calloc.free(hKeyPtr);
        if (kDebugMode) {
          debugPrint('AutoStartService: Failed to open registry key');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AutoStartService: Error setting enabled: $e');
      }
      return false;
    }
  }

  /// 检查注册表中是否已启用
  Future<bool> _checkRegistry() async {
    try {
      final hKeyPtr = calloc<win32.HKEY>();
      final result = win32.RegOpenKeyEx(
        win32.HKEY_CURRENT_USER,
        TEXT(_registryKey),
        0,
        win32.KEY_READ,
        hKeyPtr,
      );

      if (result == win32.ERROR_SUCCESS) {
        final hKey = hKeyPtr.value;
        // 只检查键是否存在，不需要读取值
        final result2 = win32.RegGetValue(
          hKey,
          nullptr.cast<Utf16>(),
          TEXT(_appName),
          win32.RRF_RT_REG_SZ,
          nullptr.cast<Uint32>(),
          nullptr,
          nullptr.cast<Uint32>(),
        );

        win32.RegCloseKey(hKey);
        calloc.free(hKeyPtr);
        return result2 == win32.ERROR_SUCCESS;
      }
      calloc.free(hKeyPtr);
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AutoStartService: Error checking registry: $e');
      }
      return false;
    }
  }

  /// 获取可执行文件路径
  String _getExecutablePath() {
    if (Platform.isWindows) {
      // 使用 Platform.resolvedExecutable 获取实际 exe 路径
      return Platform.resolvedExecutable;
    }
    return '';
  }

  /// 将字符串转换为 LPWSTR（宽字符指针）
  static Pointer<Utf16> TEXT(String s) {
    return s.toNativeUtf16();
  }
}

/// nullptr 常量，用于表示空指针
final nullptr = Pointer<Void>.fromAddress(0);
