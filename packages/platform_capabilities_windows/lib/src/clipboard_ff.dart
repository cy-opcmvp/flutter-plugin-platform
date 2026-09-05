/// Windows 剪贴板与已知目录的 dart:ffi 声明（全部收敛于本文件）。
///
/// 覆盖三组 API：
/// - 剪贴板（user32）：`OpenClipboard/EmptyClipboard/SetClipboardData/
///   GetClipboardData/CloseClipboard/IsClipboardFormatAvailable`；
/// - 全局内存（kernel32）：`GlobalAlloc/GlobalLock/GlobalUnlock/
///   GlobalFree`（SetClipboardData 的数据句柄构造与失败释放）；
/// - 已知目录（shell32/ole32）：`SHGetKnownFolderPath` +
///   `CoTaskMemFree`。
library;

import 'dart:ffi';
import 'dart:io' show sleep;

import 'package:ffi/ffi.dart';

// ── 常量 ──────────────────────────────────────────────────────────────────────

/// 剪贴板格式：Unicode 文本。
const int kCfUnicodeText = 13;

/// 剪贴板格式：文件列表（HDROP）。
const int kCfHDrop = 15;

/// 剪贴板格式：DIB V5 位图。
const int kCfDibV5 = 17;

/// GlobalAlloc 标志：可移动内存（SetClipboardData 要求）。
const int kGmemMoveable = 0x0002;

/// BITMAPV5HEADER 结构体固定字节数。
const int kBitmapV5HeaderSize = 124;

/// BITMAPV5HEADER.biCompression：BI_BITFIELDS（显式通道掩码）。
const int kBiBitfields = 3;

/// LCS_sRGB：BITMAPV5HEADER.bV5CSType 的 sRGB 色彩空间标记。
const int kLcsSRgb = 0x73524742;

/// LCS_GM_IMAGES：BITMAPV5HEADER.bV5Intent 的图像感知意图。
const int kLcsGmImages = 4;

/// DROPFILES 结构体固定字节数（pFiles 偏移即此值）。
const int kDropFilesSize = 20;

/// SHGetKnownFolderPath 标志：返回当前用户默认路径（不强制创建）。
const int kKfFlagDefault = 0;

// ── FFI 绑定（本包唯一定义处） ────────────────────────────────────────────────

typedef _OpenClipboardNative = Int32 Function(IntPtr hwndNewOwner);
typedef _OpenClipboardDart = int Function(int hwndNewOwner);

typedef _CloseClipboardNative = Int32 Function();
typedef _CloseClipboardDart = int Function();

typedef _EmptyClipboardNative = Int32 Function();
typedef _EmptyClipboardDart = int Function();

typedef _SetClipboardDataNative = IntPtr Function(Uint32 uFormat, IntPtr hMem);
typedef _SetClipboardDataDart = int Function(int uFormat, int hMem);

typedef _GetClipboardDataNative = IntPtr Function(Uint32 uFormat);
typedef _GetClipboardDataDart = int Function(int uFormat);

typedef _IsClipboardFormatAvailableNative = Int32 Function(Uint32 format);
typedef _IsClipboardFormatAvailableDart = int Function(int format);

typedef _GlobalAllocNative = IntPtr Function(Uint32 uFlags, Size dwBytes);
typedef _GlobalAllocDart = int Function(int uFlags, int dwBytes);

typedef _GlobalLockNative = IntPtr Function(IntPtr hMem);
typedef _GlobalLockDart = int Function(int hMem);

typedef _GlobalUnlockNative = Int32 Function(IntPtr hMem);
typedef _GlobalUnlockDart = int Function(int hMem);

typedef _GlobalFreeNative = IntPtr Function(IntPtr hMem);
typedef _GlobalFreeDart = int Function(int hMem);

typedef _ShGetKnownFolderPathNative =
    Int32 Function(Pointer<_KnownFolderId> rfid, Uint32 dwFlags,
        IntPtr hToken, Pointer<Pointer<WChar>> ppszPath);
typedef _ShGetKnownFolderPathDart =
    int Function(Pointer<_KnownFolderId> rfid, int dwFlags, int hToken,
        Pointer<Pointer<WChar>> ppszPath);

typedef _CoTaskMemFreeNative = Void Function(Pointer<NativeType> lpv);
typedef _CoTaskMemFreeDart = void Function(Pointer<NativeType> lpv);

final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');
final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');
final DynamicLibrary _ole32 = DynamicLibrary.open('ole32.dll');

final _OpenClipboardDart _openClipboard = _user32.lookupFunction<
    _OpenClipboardNative,
    _OpenClipboardDart>('OpenClipboard');
final _CloseClipboardDart _closeClipboard =
    _user32.lookupFunction<_CloseClipboardNative, _CloseClipboardDart>(
        'CloseClipboard');
final _EmptyClipboardDart _emptyClipboard =
    _user32.lookupFunction<_EmptyClipboardNative, _EmptyClipboardDart>(
        'EmptyClipboard');
final _SetClipboardDataDart _setClipboardData =
    _user32.lookupFunction<_SetClipboardDataNative, _SetClipboardDataDart>(
        'SetClipboardData');
final _GetClipboardDataDart _getClipboardData =
    _user32.lookupFunction<_GetClipboardDataNative, _GetClipboardDataDart>(
        'GetClipboardData');
final _IsClipboardFormatAvailableDart _isClipboardFormatAvailable =
    _user32.lookupFunction<_IsClipboardFormatAvailableNative,
        _IsClipboardFormatAvailableDart>('IsClipboardFormatAvailable');

final _GlobalAllocDart _globalAlloc = _kernel32
    .lookupFunction<_GlobalAllocNative, _GlobalAllocDart>('GlobalAlloc');
final _GlobalLockDart _globalLock = _kernel32
    .lookupFunction<_GlobalLockNative, _GlobalLockDart>('GlobalLock');
final _GlobalUnlockDart _globalUnlock = _kernel32
    .lookupFunction<_GlobalUnlockNative, _GlobalUnlockDart>('GlobalUnlock');
final _GlobalFreeDart _globalFree = _kernel32
    .lookupFunction<_GlobalFreeNative, _GlobalFreeDart>('GlobalFree');

final _ShGetKnownFolderPathDart _shGetKnownFolderPath = _shell32
    .lookupFunction<_ShGetKnownFolderPathNative, _ShGetKnownFolderPathDart>(
        'SHGetKnownFolderPath');
final _CoTaskMemFreeDart _coTaskMemFree =
    _ole32.lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>(
        'CoTaskMemFree');

// ── 结构体 ────────────────────────────────────────────────────────────────────

/// Windows `GUID`（REFKNOWNFOLDERID 指向的值，16 字节）。
final class _KnownFolderId extends Struct {
  @Uint32()
  external int data1;

  @Uint16()
  external int data2;

  @Uint16()
  external int data3;

  @Uint8()
  external int data4a;

  @Uint8()
  external int data4b;

  @Uint8()
  external int data4c;

  @Uint8()
  external int data4d;

  @Uint8()
  external int data4e;

  @Uint8()
  external int data4f;

  @Uint8()
  external int data4g;

  @Uint8()
  external int data4h;
}

// ── 可导出的包装 API ──────────────────────────────────────────────────────────

/// 剪贴板 FFI 的薄包装：实现层唯一入口，便于单文件收敛与查证。
final class ClipboardFf {
  /// 创建包装（无状态，可常量共享）。
  const ClipboardFf();

  /// OpenClipboard；成功返回 true。
  ///
  /// Windows 下剪贴板在被其他进程短暂持有/系统投递消息期间
  /// `OpenClipboard` 会瞬时失败（ERROR_ACCESS_TIMEOUT 等），这是
  /// 官方文档明示的预期行为；因此带小步重试（默认 10 次 × 5ms，
  /// 最多阻塞约 50ms），真正的长期占用仍返回 false。
  bool open({int attempts = 10, int retryDelayMs = 5}) {
    for (int i = 0; i < attempts; i++) {
      if (_openClipboard(0) != 0) {
        return true;
      }
      if (i < attempts - 1) {
        sleep(Duration(milliseconds: retryDelayMs));
      }
    }
    return false;
  }

  /// CloseClipboard。
  void close() {
    _closeClipboard();
  }

  /// EmptyClipboard。
  void empty() {
    _emptyClipboard();
  }

  /// SetClipboardData；成功返回数据句柄，失败返回 0。
  int setData(int format, int handle) => _setClipboardData(format, handle);

  /// GetClipboardData；格式不存在返回 0。
  int getData(int format) => _getClipboardData(format);

  /// IsClipboardFormatAvailable。
  bool isFormatAvailable(int format) =>
      _isClipboardFormatAvailable(format) != 0;

  /// GlobalAlloc(GMEM_MOVEABLE)；失败返回 0。
  int allocMoveable(int bytes) => _globalAlloc(kGmemMoveable, bytes);

  /// GlobalLock；失败返回空指针。
  Pointer<Uint8> lock(int handle) =>
      Pointer<Uint8>.fromAddress(_globalLock(handle));

  /// GlobalUnlock。
  void unlock(int handle) {
    _globalUnlock(handle);
  }

  /// GlobalFree（SetClipboardData 失败时回收句柄所有权）。
  void free(int handle) {
    _globalFree(handle);
  }

  /// SHGetKnownFolderPath：返回 UTF-16 路径字符串；失败返回 null。
  ///
  /// [data] 为 KNOWNFOLDERID 的 11 段小端展开（与 [GuidParts] 一致）；
  /// 成功时内部负责 CoTaskMemFree 释放系统返回的缓冲。
  String? knownFolderPath(GuidParts data) {
    final Pointer<_KnownFolderId> id = calloc<_KnownFolderId>();
    try {
      id.ref
        ..data1 = data.data1
        ..data2 = data.data2
        ..data3 = data.data3
        ..data4a = data.data4[0]
        ..data4b = data.data4[1]
        ..data4c = data.data4[2]
        ..data4d = data.data4[3]
        ..data4e = data.data4[4]
        ..data4f = data.data4[5]
        ..data4g = data.data4[6]
        ..data4h = data.data4[7];
      final Pointer<Pointer<WChar>> out = calloc<Pointer<WChar>>();
      try {
        final int hr = _shGetKnownFolderPath(id, kKfFlagDefault, 0, out);
        if (hr != 0) {
          return null;
        }
        final Pointer<WChar> path = out.value;
        if (path == nullptr) {
          return null;
        }
        try {
          // WChar 在 Windows 为 2 字节 UTF-16；手动读取至 NUL（package:ffi
          // 未提供 Pointer<WChar> 的字符串扩展）。
          final Pointer<Uint16> units = path.cast<Uint16>();
          const int maxUnits = 1 << 16;
          final List<int> codes = <int>[];
          for (int i = 0; i < maxUnits; i++) {
            final int u = units[i];
            if (u == 0) {
              break;
            }
            codes.add(u);
          }
          return String.fromCharCodes(codes);
        } finally {
          _coTaskMemFree(path);
        }
      } finally {
        calloc.free(out);
      }
    } finally {
      calloc.free(id);
    }
  }
}

/// KNOWNFOLDERID 的小端展开（[String? knownFolderPath] 参数形态）。
final class GuidParts {
  /// 创建 GUID 展开值；[data4] 必须为 8 字节（超长段被忽略，调用方
  /// 站点均为本文件常量，无运行时校验必要）。
  const GuidParts(this.data1, this.data2, this.data3, this.data4);

  /// FOLDERID_Pictures：{33E28130-4E1E-4676-835A-98395C3BC3BB}。
  static const GuidParts pictures = GuidParts(
    0x33E28130,
    0x4E1E,
    0x4676,
    <int>[0x83, 0x5A, 0x98, 0x39, 0x5C, 0x3B, 0xC3, 0xBB],
  );

  /// FOLDERID_Documents：{FDD39AD0-238F-46AF-ADB4-6C85480369C7}。
  static const GuidParts documents = GuidParts(
    0xFDD39AD0,
    0x238F,
    0x46AF,
    <int>[0xAD, 0xB4, 0x6C, 0x85, 0x48, 0x03, 0x69, 0xC7],
  );

  /// GUID 第一段（Uint32）。
  final int data1;

  /// GUID 第二段（Uint16）。
  final int data2;

  /// GUID 第三段（Uint16）。
  final int data3;

  /// GUID 第四段（8 字节）。
  final List<int> data4;
}
