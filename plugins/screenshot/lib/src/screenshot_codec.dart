/// 截图字节编码分派（纯 Dart，image 包）。
///
/// 捕获能力产出 PNG 原始字节；落盘格式为 `png` 时原样透传，`jpeg`
/// 时经 image 包解码后按质量重编码。解码/编码失败折算为结构化失败
/// `capture.encode_failed`。
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:plugin_contracts/plugin_contracts.dart';

/// 编码失败的结构化失败码。
const String kScreenshotEncodeFailureCode = 'capture.encode_failed';

/// 构造编码失败的结构化失败（[reason]：decode/encode）。
PluginFailure screenshotEncodeFailure(String reason, String message) {
  return PluginFailure(kScreenshotEncodeFailureCode, message, <String, Object?>{
    'reason': reason,
  });
}

/// 保存格式稳定键 → 文件扩展名（jpeg 用 `jpg`）。
String screenshotExtensionForFormat(String format) =>
    format == 'jpeg' ? 'jpg' : 'png';

/// 读取 PNG 头部 IHDR 的像素尺寸（宽, 高）。
///
/// 供区域选择换算（选区逻辑坐标 → 底图像素坐标）使用；PNG 签名 8 字节
/// + IHDR 长度 4 + 类型 4，宽高位于偏移 16/20（大端）。数据不足或非
/// PNG 时返回 null。
(int, int)? screenshotPngDimensions(Uint8List png) {
  if (png.length < 24) {
    return null;
  }
  const int pngSignature1 = 0x89;
  const int pngSignature2 = 0x50;
  if (png[0] != pngSignature1 || png[1] != pngSignature2) {
    return null;
  }
  final ByteData data = ByteData.sublistView(png);
  final int width = data.getUint32(16, Endian.big);
  final int height = data.getUint32(20, Endian.big);
  return (width, height);
}

/// 按保存格式编码截图字节。
///
/// `png` 原样透传（零成本）；`jpeg` 解码 PNG 后以 [quality]（1-100）
/// 重编码。解码失败或编码异常抛 `capture.encode_failed`。
Uint8List encodeScreenshotBytes(
  Uint8List pngBytes,
  String format,
  int quality,
) {
  if (format != 'jpeg') {
    return pngBytes;
  }
  final img.Image? decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    throw screenshotEncodeFailure('decode', '截图解码失败，无法编码为 JPEG');
  }
  try {
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  } on Exception catch (error) {
    throw screenshotEncodeFailure('encode', 'JPEG 编码失败：$error');
  }
}
