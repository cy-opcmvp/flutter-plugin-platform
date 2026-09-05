/// Windows 端区域截图真实现：GDI 捕获 + PNG 编码（计划 F4-04）。
///
/// 失败路径全部结构化为 `capture.failed`，details.reason ∈
/// `noScreen | gdiError | encodeError`：
/// - `noScreen`：请求区域为零宽/零高、无法取得主屏设备信息或经主屏边界
///   裁剪后为空（不产出像素的确定性原因）；
/// - `gdiError`：GDI 捕获链路任一步骤失败；
/// - `encodeError`：PNG 编码失败。
library;

import 'dart:typed_data';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'gdi_capture.dart';
import 'png_encoder.dart';

/// 截图失败错误码（词汇表逐字对齐）。
const String _captureFailed = 'capture.failed';

/// 将 [value] 收缩到 `[low, high]` 区间（保持 int 静态类型）。
int _clampTo(int value, int low, int high) {
  if (value < low) {
    return low;
  }
  if (value > high) {
    return high;
  }
  return value;
}

/// Windows 端屏幕捕获能力默认实例（宿主组装根引用的顶层符号）。
const ScreenCapture windowsScreenCapture = WindowsScreenCapture();

/// Windows 端 GDI 截图实现。
///
/// MVP 语义（计划决策 2）：以虚拟屏幕坐标解释 [Rect]，仅支持主屏；区域先
/// 按主屏 DPI 缩放为物理像素，再裁剪到主屏边界。区域捕获全屏由调用方传入
/// 超大矩形配合边界裁剪达成。
final class WindowsScreenCapture implements ScreenCapture {
  /// 创建实现（无状态，可常量共享）。
  const WindowsScreenCapture();

  @override
  Future<CaptureResult> captureRegion(Rect region) async {
    // 零宽/零高请求不触碰 GDI：纯逻辑分支直接结构化失败。
    if (region.width <= 0 || region.height <= 0) {
      return CaptureResult.failure(
        _failure('noScreen', '请求区域宽高必须为正（region=$region）', <String, Object?>{
          'regionWidth': region.width,
          'regionHeight': region.height,
        }),
      );
    }

    final ScreenDeviceInfo? info;
    try {
      info = const GdiCapture().queryScreenInfo();
    } on Object catch (exception) {
      return CaptureResult.failure(
        _failure('noScreen', '无法查询主屏设备信息：$exception'),
      );
    }
    if (info == null) {
      return CaptureResult.failure(_failure('noScreen', '无法取得主屏设备上下文或屏幕尺寸非法'));
    }

    // 逻辑像素 → 物理像素（DPI 缩放，四舍五入）。
    final int physicalLeft = (region.left * info.scaleX).round();
    final int physicalTop = (region.top * info.scaleY).round();
    final int physicalWidth = (region.width * info.scaleX).round();
    final int physicalHeight = (region.height * info.scaleY).round();

    // 裁剪到主屏物理边界（MVP 仅主屏；越界与离屏区域直接收缩）。
    final int croppedLeft = _clampTo(physicalLeft, 0, info.screenPixelWidth);
    final int croppedTop = _clampTo(physicalTop, 0, info.screenPixelHeight);
    final int croppedWidth = _clampTo(
      physicalWidth,
      0,
      info.screenPixelWidth - croppedLeft,
    );
    final int croppedHeight = _clampTo(
      physicalHeight,
      0,
      info.screenPixelHeight - croppedTop,
    );
    if (croppedWidth <= 0 || croppedHeight <= 0) {
      return CaptureResult.failure(
        _failure(
          'noScreen',
          '请求区域位于主屏之外或经裁剪后为空（region=$region）',
          <String, Object?>{
            'regionWidth': region.width,
            'regionHeight': region.height,
            'screenPixelWidth': info.screenPixelWidth,
            'screenPixelHeight': info.screenPixelHeight,
          },
        ),
      );
    }

    final GdiPixels pixels;
    try {
      pixels = const GdiCapture().capturePhysical(
        left: croppedLeft,
        top: croppedTop,
        width: croppedWidth,
        height: croppedHeight,
      );
    } on Object catch (exception) {
      return CaptureResult.failure(_failure('gdiError', 'GDI 捕获失败：$exception'));
    }

    final Uint8List pngBytes;
    try {
      pngBytes = encodeBgraPng(
        pixels.bytes,
        width: pixels.width,
        height: pixels.height,
      );
    } on Object catch (exception) {
      return CaptureResult.failure(
        _failure('encodeError', 'PNG 编码失败：$exception'),
      );
    }
    if (pngBytes.isEmpty) {
      return CaptureResult.failure(_failure('encodeError', 'PNG 编码产出为空'));
    }

    return CaptureResult.success(pngBytes);
  }

  /// 组装 `capture.failed` 结构化失败值。
  PluginFailure _failure(
    String reason,
    String message, [
    Map<String, Object?>? extra,
  ]) {
    return PluginFailure(_captureFailed, message, <String, Object?>{
      'reason': reason,
      ...?extra,
    });
  }
}
