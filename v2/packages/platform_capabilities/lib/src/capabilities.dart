/// 区域截图能力接口与默认不支持实现（规格 §10 平台策略）。
///
/// 截图属平台专属能力：宿主按端注入实现，接口与值类型保持零平台依赖。
/// 不支持的平台返回结构化失败值（[CaptureResult.failure]）而非抛异常，
/// 与词汇表错误码 `capability.unsupported` 一致。
library;

import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';

/// 截图区域：以虚拟屏幕坐标描述的矩形（宽高非负）。
final class Rect {
  /// 创建截图区域；[width] 与 [height] 均不得为负。
  Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) {
    if (width < 0) {
      throw ArgumentError.value(width, 'width', '不能为负');
    }
    if (height < 0) {
      throw ArgumentError.value(height, 'height', '不能为负');
    }
  }

  /// 区域左上角横坐标（虚拟屏幕坐标）。
  final double left;

  /// 区域左上角纵坐标（虚拟屏幕坐标）。
  final double top;

  /// 区域宽度（像素），非负。
  final double width;

  /// 区域高度（像素），非负。
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'Rect(left: $left, top: $top, width: $width, height: $height)';
}

/// 区域截图结果：成功携带像素字节，失败携带结构化失败值。
final class CaptureResult {
  const CaptureResult._({this.bytes, this.failure});

  /// 创建成功结果；[bytes] 为编码后的截图像素字节，不得为空。
  factory CaptureResult.success(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', '截图像素字节不能为空');
    }
    return CaptureResult._(bytes: bytes);
  }

  /// 创建失败结果（如 `capability.unsupported`）。
  factory CaptureResult.failure(PluginFailure failure) {
    return CaptureResult._(failure: failure);
  }

  /// 截图像素字节（成功时非空）。
  final Uint8List? bytes;

  /// 结构化失败（失败时非空）。
  final PluginFailure? failure;

  /// 是否成功。
  bool get succeeded => failure == null;
}

/// 区域截图能力接口。
abstract interface class ScreenCapture {
  /// 捕获 [region] 指定区域；不支持的平台返回结构化失败而非抛异常。
  Future<CaptureResult> captureRegion(Rect region);
}

/// 各端默认实现：一律返回 `capability.unsupported`。
final class UnsupportedScreenCapture implements ScreenCapture {
  /// 创建不支持实现；[platform] 为平台标签（windows/macos/…）。
  const UnsupportedScreenCapture(this.platform);

  /// 平台标签，写入失败 details 便于定位来源端。
  final String platform;

  @override
  Future<CaptureResult> captureRegion(Rect region) {
    return Future<CaptureResult>.value(
      CaptureResult.failure(
        PluginFailure(
          'capability.unsupported',
          '当前平台不支持区域截图',
          <String, Object?>{
            'capability': 'screenCapture',
            'platform': platform,
          },
        ),
      ),
    );
  }
}
