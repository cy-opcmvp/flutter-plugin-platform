/// BGRA 原始像素 → RGB PNG 编码（基于纯 Dart `image` 包）。
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 将 32bpp BGRA 缓冲编码为 PNG 字节（RGB 通道，无 alpha）。
///
/// 输入 [bgra] 须为 GDI 正 `biHeight` 约定的自下而上行序、每行
/// `width * 4` 字节；编码时先翻转行序为自上而下，再剥离 alpha 字节。
/// 缓冲长度不足或宽高非法时抛 [ArgumentError]。
Uint8List encodeBgraPng(
  Uint8List bgra, {
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value(
      width <= 0 ? width : height,
      width <= 0 ? 'width' : 'height',
      '像素宽高必须为正',
    );
  }
  final int expectedLength = width * height * 4;
  if (bgra.length < expectedLength) {
    throw ArgumentError.value(
      bgra.length,
      'bgra',
      'BGRA 缓冲长度不足：期望至少 $expectedLength 字节',
    );
  }

  final Uint8List rgb = Uint8List(width * height * 3);
  int sourceOffset = (height - 1) * width * 4; // 自下而上：首行取最后一行
  int targetOffset = 0;
  for (int row = 0; row < height; row++) {
    int cursor = sourceOffset;
    for (int column = 0; column < width; column++) {
      rgb[targetOffset++] = bgra[cursor + 2]; // R
      rgb[targetOffset++] = bgra[cursor + 1]; // G
      rgb[targetOffset++] = bgra[cursor]; // B
      cursor += 4; // 跳过 alpha
    }
    sourceOffset -= width * 4; // 向上一行
  }

  final img.Image image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
  return Uint8List.fromList(img.encodePng(image));
}
