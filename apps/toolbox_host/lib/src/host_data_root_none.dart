/// 宿主数据根解析的 web（无 `dart:io`）实现。
///
/// 正常流程下 `HostCompositionRoot.create` 在 kIsWeb 分支直接使用
/// `kWebHostDataRoot` 占位常量，不会调用本函数；实现保留同字面量返回
/// 值，仅为条件导出在 web 目标下可编译。
library;

/// 占位数据根：与 `host_data_root.dart` 的 [kWebHostDataRoot] 字面量一致。
const String _kPlaceholderRoot = 'app-support://toolbox-host-web';

/// 默认数据根解析（web 目标恒返回占位常量）。
Future<String> resolveApplicationSupportRoot() async {
  return _kPlaceholderRoot;
}
