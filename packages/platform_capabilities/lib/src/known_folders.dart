/// 系统已知目录能力接口与默认不支持实现（设计 §2.4，S1 批B）。
///
/// 供截图保存目录占位符（`{pictures}` / `{documents}`）解析使用：
/// 接口保持零平台依赖（本文件不 import `dart:io` / `dart:ffi`），
/// Windows 端经 `SHGetKnownFolderPath` FFI 实现。
///
/// 实现方约定：
/// - 解析失败（API 失败、目录不存在）返回 null，由调用方回退
///   （如插件数据目录），不算失败；
/// - 不支持的平台同样返回 null（不抛异常，保持解析链无副作用）。
library;

/// 系统已知目录能力接口。
abstract interface class KnownFolders {
  /// 当前用户「图片」目录；不可解析时返回 null。
  String? pictures();

  /// 当前用户「文档」目录；不可解析时返回 null。
  String? documents();
}

/// 各端默认实现：一律返回 null（调用方按约定回退）。
final class UnsupportedKnownFolders implements KnownFolders {
  /// 创建不支持实现；[platform] 为平台标签（web/macos/…）。
  const UnsupportedKnownFolders(this.platform);

  /// 平台标签，调试定位来源端。
  final String platform;

  @override
  String? pictures() => null;

  @override
  String? documents() => null;
}
