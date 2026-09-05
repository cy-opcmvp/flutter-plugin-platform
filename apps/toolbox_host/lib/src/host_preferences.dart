/// 宿主偏好（插件启用集合）的条件导出入口与数据载体。
///
/// 镜像 `host_bytes_loader` 的条件导出模式：io 目标读写
/// `<hostDataRoot>/host-preferences.json`（临时文件 + rename 原子写）；
/// web 等无 io 目标为无操作 stub（返回空集合）。失败约定：宿主偏好
/// 读写失败一律静默降级为内存态（debugPrint），不阻断应用启动与切换。
///
/// 两分支均提供同签名函数：
/// - `Future<HostPreferences> loadHostPreferences(String dataRoot)`
/// - `Future<void> saveHostPreferences(String dataRoot, HostPreferences prefs)`
library;

export 'host_preferences_none.dart'
    if (dart.library.io) 'host_preferences_io.dart';

/// 宿主偏好数据载体（当前仅插件停用集合）。
final class HostPreferences {
  /// 创建偏好载体；[disabledPlugins] 缺省为空集合（全部启用）。
  const HostPreferences({this.disabledPlugins = const <String>{}});

  /// 被停用插件的 ID 字符串集合。
  final Set<String> disabledPlugins;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! HostPreferences) {
      return false;
    }
    return disabledPlugins.length == other.disabledPlugins.length &&
        disabledPlugins.containsAll(other.disabledPlugins);
  }

  @override
  int get hashCode {
    final List<String> sorted = <String>[...disabledPlugins]..sort();
    return Object.hashAll(<Object>['host-preferences', ...sorted]);
  }
}
