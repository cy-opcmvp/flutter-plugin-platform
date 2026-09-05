/// 宿主偏好读写（`dart:io` 实现版）。
///
/// 持久化到 `<dataRoot>/host-preferences.json`；读取时文件缺失视为空
/// 偏好，JSON 损坏按宿主偏好失败约定静默降级（debugPrint 后返回空集
/// 合）；写入采用临时文件 + rename 原子替换，任何 I/O 失败静默降级，
/// 由内存态继续承担会话内状态。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'host_preferences.dart';

/// 偏好文件名（固定落在数据根目录下）。
const String _kPreferencesFileName = 'host-preferences.json';

/// 读取宿主偏好；失败或文件缺失均返回空偏好（空停用集合）。
Future<HostPreferences> loadHostPreferences(String dataRoot) async {
  final File file = _preferencesFileOf(dataRoot);
  try {
    final String raw = await file.readAsString();
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return const HostPreferences();
    }
    final Object? rawDisabled = decoded['disabledPlugins'];
    if (rawDisabled is! List) {
      return const HostPreferences();
    }
    return HostPreferences(
      disabledPlugins: <String>{
        for (final Object? item in rawDisabled)
          if (item is String) item,
      },
    );
  } on FormatException catch (e) {
    _debugLog('读取宿主偏好失败（JSON 损坏，按空偏好处理）', e);
    return const HostPreferences();
  } on FileSystemException catch (e) {
    // 文件缺失（首次启动）属于正常路径，不告警；其余 I/O 错误降级。
    if (file.existsSync()) {
      _debugLog('读取宿主偏好失败（按空偏好处理）', e);
    }
    return const HostPreferences();
  } catch (e) {
    _debugLog('读取宿主偏好失败（按空偏好处理）', e);
    return const HostPreferences();
  }
}

/// 保存宿主偏好（临时文件 + rename 原子写）；失败静默降级。
Future<void> saveHostPreferences(String dataRoot, HostPreferences prefs) async {
  final File file = _preferencesFileOf(dataRoot);
  final File tmpFile = File('${file.path}.tmp');
  try {
    await tmpFile.parent.create(recursive: true);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String raw = encoder.convert(<String, Object?>{
      'disabledPlugins': <String>[...prefs.disabledPlugins]..sort(),
    });
    await tmpFile.writeAsString(raw, flush: true);
    await tmpFile.rename(file.path);
  } catch (e) {
    _debugLog('保存宿主偏好失败（保留内存态）', e);
  }
}

File _preferencesFileOf(String dataRoot) {
  return File('$dataRoot/$_kPreferencesFileName');
}

void _debugLog(String message, Object error) {
  debugPrint('[host_preferences] $message: $error');
}
