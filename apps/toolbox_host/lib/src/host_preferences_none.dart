/// 宿主偏好读写（无 `dart:io` 平台的实现版）。
///
/// web 等无文件系统目标：加载恒为空偏好（全部启用），保存为无操作。
/// 不持久化，停用集合仅存在于当前会话内存。
library;

import 'host_preferences.dart';

/// 读取宿主偏好（web stub：恒返回空偏好）。
Future<HostPreferences> loadHostPreferences(String dataRoot) async {
  return const HostPreferences();
}

/// 保存宿主偏好（web stub：无操作）。
Future<void> saveHostPreferences(
  String dataRoot,
  HostPreferences prefs,
) async {}
