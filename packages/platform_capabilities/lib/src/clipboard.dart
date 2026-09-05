/// 系统剪贴板能力接口与默认不支持实现（设计 §2.3，S1 批B）。
///
/// 剪贴板写入属平台专属能力：宿主按端注入实现，接口保持零平台依赖
/// （本文件不 import `dart:io` / `dart:ffi`）。
///
/// 实现方约定：
/// - 失败抛结构化失败（[PluginFailure]）而非裸异常；剪贴板被占用或
///   数据设置失败抛 `clipboard.locked`，`details['reason']` 为
///   `openFailed` / `setDataFailed`（见 [clipboardLockedFailure]）；
/// - 不支持的平台抛 `capability.unsupported`；
/// - `writeImage` 接收 PNG 字节，实现方负责转码为平台原生格式
///   （Windows 下 CF_DIBV5）；`writeFiles` 接收绝对路径列表
///   （Windows 下 CF_HDROP）。
library;

import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';

/// 构造 `clipboard.locked` 结构化失败值。
///
/// [reason] 为失败阶段（`openFailed`：OpenClipboard 失败；`setDataFailed`：
/// SetClipboardData 失败）；[message] 为实现方的可读描述；[details] 允许
/// 补充实现方上下文（如格式号）。
PluginFailure clipboardLockedFailure(
  String reason,
  String message, [
  Map<String, Object?> details = const <String, Object?>{},
]) {
  return PluginFailure('clipboard.locked', message, <String, Object?>{
    'reason': reason,
    ...details,
  });
}

/// 系统剪贴板写入能力接口。
abstract interface class Clipboard {
  /// 写入纯文本（Windows 下 CF_UNICODETEXT）。
  Future<void> writeText(String text);

  /// 写入图像；[pngBytes] 为 PNG 编码字节（Windows 下转 CF_DIBV5）。
  Future<void> writeImage(Uint8List pngBytes);

  /// 写入文件引用列表；[paths] 为绝对路径（Windows 下 CF_HDROP）。
  Future<void> writeFiles(List<String> paths);
}

/// 各端默认实现：一律抛 `capability.unsupported` 结构化失败。
final class UnsupportedClipboard implements Clipboard {
  /// 创建不支持实现；[platform] 为平台标签（web/macos/…）。
  const UnsupportedClipboard(this.platform);

  /// 平台标签，写入失败 details 便于定位来源端。
  final String platform;

  PluginFailure _failure(String action) {
    return PluginFailure(
      'capability.unsupported',
      '当前平台不支持剪贴板写入',
      <String, Object?>{
        'capability': 'clipboard',
        'platform': platform,
        'action': action,
      },
    );
  }

  @override
  Future<void> writeText(String text) async => throw _failure('writeText');

  @override
  Future<void> writeImage(Uint8List pngBytes) async =>
      throw _failure('writeImage');

  @override
  Future<void> writeFiles(List<String> paths) async =>
      throw _failure('writeFiles');
}
