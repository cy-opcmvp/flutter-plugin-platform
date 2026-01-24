library;

/// 应用版本常量
///
/// **重要**: 每次发布新版本前，必须更新此文件中的版本号
/// 版本号格式遵循语义化版本规范: https://semver.org/lang/zh-CN/
///
/// 版本号格式: MAJOR.MINOR.PATCH
/// - MAJOR: 主版本号（不兼容的 API 变更）
/// - MINOR: 次版本号（向下兼容的功能性新增）
/// - PATCH: 修订号（向下兼容的问题修正）
class AppVersion {
  /// 应用名称
  static const String appName = 'Plugin Platform';

  /// 当前版本号
  ///
  /// 每次发布前更新此值，与 Git tag 保持一致
  /// 例如: Git tag 是 v0.4.3，则这里设置为 '0.4.3'
  static const String version = '0.4.3';

  /// 构建号
  ///
  /// 每次构建时自动递增的数字
  /// 用于区分相同版本号的不同构建
  static const int buildNumber = 1;

  /// 完整版本字符串（包含构建号）
  ///
  /// 格式: version+buildNumber
  /// 例如: 0.4.3+1
  static String get fullVersion => '$version+$buildNumber';

  /// 版本信息（用于显示）
  ///
  /// 返回人类可读的版本信息
  static String get versionInfo => 'v$version';

  /// 构建时间（编译时常量）
  ///
  /// 格式: yyyy-MM-dd HH:mm:ss
  static const String buildDate =
      '2026-01-24'; // 手动更新为实际发布日期

  /// 检查版本是否有效
  ///
  /// 版本号必须符合 semver 规范
  static bool get isValidVersion {
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  /// 版本比较
  ///
  /// 返回值:
  /// - 负数: 当前版本 < otherVersion
  /// - 0: 当前版本 == otherVersion
  /// - 正数: 当前版本 > otherVersion
  static int compareTo(String otherVersion) {
    final currentParts = version.split('.').map(int.parse).toList();
    final otherParts = otherVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] != otherParts[i]) {
        return currentParts[i] - otherParts[i];
      }
    }
    return 0;
  }

  /// 检查是否需要更新
  ///
  /// 如果 remoteVersion 高于当前版本，返回 true
  static bool needsUpdate(String remoteVersion) {
    return compareTo(remoteVersion) < 0;
  }
}
