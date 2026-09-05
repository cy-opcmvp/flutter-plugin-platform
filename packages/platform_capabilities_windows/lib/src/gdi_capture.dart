/// GDI 屏幕捕获：全部 dart:ffi 声明收敛于本文件。
///
/// 捕获序列（与旧工程原生实现的 API 顺序一致）：
/// `GetDC(0)` → `GetDeviceCaps`(DPI/尺寸) → `CreateCompatibleDC` →
/// `CreateCompatibleBitmap` → `SelectObject` → `BitBlt(SRCCOPY|CAPTUREBLT)`
/// → 恢复原位图（`GetDIBits` 要求位图未被选入 DC）→ `GetDIBits`
/// （BI_RGB 32bpp BGRA、正 `biHeight` 即自下而上行序）→
/// `DeleteObject`/`DeleteDC`/`ReleaseDC` 全路径 finally 释放。
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ── 常量 ──────────────────────────────────────────────────────────────────────

/// GetDeviceCaps：逻辑像素每英寸 X（水平 DPI）。
const int _gdiLogPixelsX = 88;

/// GetDeviceCaps：逻辑像素每英寸 Y（垂直 DPI）。
const int _gdiLogPixelsY = 90;

/// GetDeviceCaps：主屏物理像素宽。
const int _gdiHorzRes = 8;

/// GetDeviceCaps：主屏物理像素高。
const int _gdiVertRes = 10;

/// BitBlt 光栅操作：源拷贝。
const int _gdiSrcCopy = 0x00CC0020;

/// BitBlt 光栅操作：捕获含光标-layered 窗口。
const int _gdiCaptureBlt = 0x40000000;

/// BITMAPINFOHEADER.biCompression：无压缩 RGB。
const int _biRgb = 0;

/// GetDIBits：调色板为 RGB 颜色表。
const int _dibRgbColors = 0;

/// BITMAPINFOHEADER 结构体固定字节数。
const int _bitmapInfoHeaderSize = 40;

/// 基准 DPI（96 = 100% 缩放）。
const double _baselineDpi = 96.0;

// ── FFI 绑定（本包唯一定义处） ────────────────────────────────────────────────

typedef _GetDcNative = IntPtr Function(IntPtr hdc);
typedef _GetDcDart = int Function(int hdc);

typedef _ReleaseDcNative = Int32 Function(IntPtr hdc, IntPtr hdcRelease);
typedef _ReleaseDcDart = int Function(int hdc, int hdcRelease);

typedef _CreateCompatibleDcNative = IntPtr Function(IntPtr hdc);
typedef _CreateCompatibleDcDart = int Function(int hdc);

typedef _CreateCompatibleBitmapNative =
    IntPtr Function(IntPtr hdc, Int32 cx, Int32 cy);
typedef _CreateCompatibleBitmapDart = int Function(int hdc, int cx, int cy);

typedef _SelectObjectNative = IntPtr Function(IntPtr hdc, IntPtr hObject);
typedef _SelectObjectDart = int Function(int hdc, int hObject);

typedef _DeleteObjectNative = Int32 Function(IntPtr hObject);
typedef _DeleteObjectDart = int Function(int hObject);

typedef _DeleteDcNative = Int32 Function(IntPtr hdc);
typedef _DeleteDcDart = int Function(int hdc);

typedef _BitBltNative =
    Int32 Function(
      IntPtr hdcDest,
      Int32 x,
      Int32 y,
      Int32 cx,
      Int32 cy,
      IntPtr hdcSrc,
      Int32 x1,
      Int32 y1,
      Int32 rop,
    );
typedef _BitBltDart =
    int Function(
      int hdcDest,
      int x,
      int y,
      int cx,
      int cy,
      int hdcSrc,
      int x1,
      int y1,
      int rop,
    );

typedef _GetDeviceCapsNative = Int32 Function(IntPtr hdc, Int32 index);
typedef _GetDeviceCapsDart = int Function(int hdc, int index);

typedef _GetDIBitsNative =
    Int32 Function(
      IntPtr hdc,
      IntPtr hbm,
      Uint32 start,
      Uint32 cScanLines,
      Pointer<Uint8> lpvBits,
      Pointer<_BitmapInfo> lpbi,
      Uint32 usage,
    );
typedef _GetDIBitsDart =
    int Function(
      int hdc,
      int hbm,
      int start,
      int cScanLines,
      Pointer<Uint8> lpvBits,
      Pointer<_BitmapInfo> lpbi,
      int usage,
    );

final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
final DynamicLibrary _gdi32 = DynamicLibrary.open('gdi32.dll');

final _GetDcDart _getDc = _user32.lookupFunction<_GetDcNative, _GetDcDart>(
  'GetDC',
);
final _ReleaseDcDart _releaseDc = _user32
    .lookupFunction<_ReleaseDcNative, _ReleaseDcDart>('ReleaseDC');
final _GetDeviceCapsDart _getDeviceCaps = _gdi32
    .lookupFunction<_GetDeviceCapsNative, _GetDeviceCapsDart>('GetDeviceCaps');
final _CreateCompatibleDcDart _createCompatibleDc = _gdi32
    .lookupFunction<_CreateCompatibleDcNative, _CreateCompatibleDcDart>(
      'CreateCompatibleDC',
    );
final _CreateCompatibleBitmapDart _createCompatibleBitmap = _gdi32
    .lookupFunction<_CreateCompatibleBitmapNative, _CreateCompatibleBitmapDart>(
      'CreateCompatibleBitmap',
    );
final _SelectObjectDart _selectObject = _gdi32
    .lookupFunction<_SelectObjectNative, _SelectObjectDart>('SelectObject');
final _DeleteObjectDart _deleteObject = _gdi32
    .lookupFunction<_DeleteObjectNative, _DeleteObjectDart>('DeleteObject');
final _DeleteDcDart _deleteDc = _gdi32
    .lookupFunction<_DeleteDcNative, _DeleteDcDart>('DeleteDC');
final _BitBltDart _bitBlt = _gdi32.lookupFunction<_BitBltNative, _BitBltDart>(
  'BitBlt',
);
final _GetDIBitsDart _getDIBits = _gdi32
    .lookupFunction<_GetDIBitsNative, _GetDIBitsDart>('GetDIBits');

/// BITMAPINFOHEADER（40 字节，BI_RGB 32bpp 场景无调色板项）。
final class _BitmapInfoHeader extends Struct {
  @Uint32()
  external int biSize;

  @Int32()
  external int biWidth;

  @Int32()
  external int biHeight;

  @Uint16()
  external int biPlanes;

  @Uint16()
  external int biBitCount;

  @Uint32()
  external int biCompression;

  @Uint32()
  external int biSizeImage;

  @Int32()
  external int biXPelsPerMeter;

  @Int32()
  external int biYPelsPerMeter;

  @Uint32()
  external int biClrUsed;

  @Uint32()
  external int biClrImportant;
}

/// BITMAPINFO：仅头部（32bpp BI_RGB 不需要调色板）。
final class _BitmapInfo extends Struct {
  external _BitmapInfoHeader bmiHeader;
}

// ── 值类型与实现 ──────────────────────────────────────────────────────────────

/// 主屏设备信息：逻辑到物理像素换算依据。
final class ScreenDeviceInfo {
  /// 创建设备信息；各字段由 GDI 查询产出，均应为正。
  const ScreenDeviceInfo({
    required this.scaleX,
    required this.scaleY,
    required this.screenPixelWidth,
    required this.screenPixelHeight,
  });

  /// 水平缩放系数（LOGPIXELSX / 96）。
  final double scaleX;

  /// 垂直缩放系数（LOGPIXELSY / 96）。
  final double scaleY;

  /// 主屏物理像素宽（HORZRES）。
  final int screenPixelWidth;

  /// 主屏物理像素高（VERTRES）。
  final int screenPixelHeight;
}

/// GDI 捕获产物：32bpp BGRA 原始像素，自下而上行序，每行 `width * 4` 字节。
final class GdiPixels {
  /// 创建捕获产物；[bytes] 长度应为 `width * height * 4`。
  const GdiPixels({
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// BGRA 像素缓冲（自下而上）。
  final Uint8List bytes;

  /// 像素宽。
  final int width;

  /// 像素高。
  final int height;
}

/// GDI 捕获失败异常（API 返回失败或参数非法时抛出）。
final class GdiCaptureException implements Exception {
  /// 创建异常；[message] 描述失败的 GDI 调用。
  const GdiCaptureException(this.message);

  /// 失败描述。
  final String message;

  @override
  String toString() => 'GdiCaptureException: $message';
}

/// GDI 主屏区域捕获器。
final class GdiCapture {
  /// 创建捕获器（无状态，可常量共享）。
  const GdiCapture();

  /// 查询主屏设备信息；任一 API 失败或数值非法时返回 null（不抛异常）。
  ScreenDeviceInfo? queryScreenInfo() {
    final int screenDc = _getDc(0);
    if (screenDc == 0) {
      return null;
    }
    try {
      final int dpiX = _getDeviceCaps(screenDc, _gdiLogPixelsX);
      final int dpiY = _getDeviceCaps(screenDc, _gdiLogPixelsY);
      final int pixelWidth = _getDeviceCaps(screenDc, _gdiHorzRes);
      final int pixelHeight = _getDeviceCaps(screenDc, _gdiVertRes);
      if (dpiX <= 0 || dpiY <= 0 || pixelWidth <= 0 || pixelHeight <= 0) {
        return null;
      }
      return ScreenDeviceInfo(
        scaleX: dpiX / _baselineDpi,
        scaleY: dpiY / _baselineDpi,
        screenPixelWidth: pixelWidth,
        screenPixelHeight: pixelHeight,
      );
    } finally {
      _releaseDc(0, screenDc);
    }
  }

  /// 捕获物理像素矩形 `[left, top, width, height)`。
  ///
  /// 所有 GDI 句柄在 finally 中逐级释放：位图先恢复原选中对象再
  /// `DeleteObject`，内存 DC `DeleteDC`，屏幕 DC `ReleaseDC`；任何一步失败
  /// 抛 [GdiCaptureException] 时句柄同样被释放（泄漏零容忍）。
  GdiPixels capturePhysical({
    required int left,
    required int top,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError.value(
        width <= 0 ? width : height,
        width <= 0 ? 'width' : 'height',
        '捕获区域宽高必须为正',
      );
    }

    final int screenDc = _getDc(0);
    if (screenDc == 0) {
      throw const GdiCaptureException('GetDC 失败：无法取得屏幕设备上下文');
    }
    int memoryDc = 0;
    int bitmap = 0;
    try {
      memoryDc = _createCompatibleDc(screenDc);
      if (memoryDc == 0) {
        throw const GdiCaptureException('CreateCompatibleDC 失败');
      }
      bitmap = _createCompatibleBitmap(screenDc, width, height);
      if (bitmap == 0) {
        throw const GdiCaptureException('CreateCompatibleBitmap 失败');
      }
      final int previousObject = _selectObject(memoryDc, bitmap);
      if (previousObject == 0) {
        throw const GdiCaptureException('SelectObject 失败');
      }
      try {
        final int rop = _gdiSrcCopy | _gdiCaptureBlt;
        final int blitted = _bitBlt(
          memoryDc,
          0,
          0,
          width,
          height,
          screenDc,
          left,
          top,
          rop,
        );
        if (blitted == 0) {
          throw const GdiCaptureException('BitBlt 失败');
        }
      } finally {
        // GetDIBits 要求位图未被选入设备上下文：恢复原对象（解除选中）。
        _selectObject(memoryDc, previousObject);
      }
      return _readPixels(
        screenDc: screenDc,
        bitmap: bitmap,
        width: width,
        height: height,
      );
    } finally {
      if (bitmap != 0) {
        _deleteObject(bitmap);
      }
      if (memoryDc != 0) {
        _deleteDc(memoryDc);
      }
      _releaseDc(0, screenDc);
    }
  }

  /// 从兼容位图读出 BGRA 像素（自下而上）。
  GdiPixels _readPixels({
    required int screenDc,
    required int bitmap,
    required int width,
    required int height,
  }) {
    final int byteLength = width * height * 4;
    final Pointer<Uint8> pixelBuffer = calloc<Uint8>(byteLength);
    try {
      final Pointer<_BitmapInfo> info = calloc<_BitmapInfo>();
      try {
        info.ref.bmiHeader
          ..biSize = _bitmapInfoHeaderSize
          ..biWidth = width
          // 正 biHeight：行序自下而上（GDI 默认），行序翻转交由 PNG 编码器。
          ..biHeight = height
          ..biPlanes = 1
          ..biBitCount = 32
          ..biCompression = _biRgb
          ..biSizeImage = 0
          ..biXPelsPerMeter = 0
          ..biYPelsPerMeter = 0
          ..biClrUsed = 0
          ..biClrImportant = 0;
        final int scanned = _getDIBits(
          screenDc,
          bitmap,
          0,
          height,
          pixelBuffer,
          info,
          _dibRgbColors,
        );
        if (scanned != height) {
          throw GdiCaptureException('GetDIBits 失败：扫描行数 $scanned != $height');
        }
      } finally {
        calloc.free(info);
      }
      return GdiPixels(
        bytes: Uint8List.fromList(pixelBuffer.asTypedList(byteLength)),
        width: width,
        height: height,
      );
    } finally {
      calloc.free(pixelBuffer);
    }
  }
}
