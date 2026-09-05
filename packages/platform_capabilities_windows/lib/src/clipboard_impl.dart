/// Windows 剪贴板与已知目录的 FFI 实现。
///
/// - [WindowsClipboard]：`writeText`（CF_UNICODETEXT）、`writeImage`
///   （PNG 经 `image` 包解码转 BGRA 自下而上位图 + BITMAPV5HEADER →
///   CF_DIBV5）、`writeFiles`（DROPFILES wide 路径双 NUL 结尾 →
///   CF_HDROP）；写入流程为 OpenClipboard → EmptyClipboard → 逐项
///   SetClipboardData → CloseClipboard，打开失败抛 `clipboard.locked`
///   （reason=openFailed），任一设置失败抛同码（reason=setDataFailed）
///   并回收句柄；
/// - 读取侧辅助（诊断与真机烟囱测试）：[WindowsClipboard.peekText] /
///   [WindowsClipboard.peekHeader] / [WindowsClipboard.peekPaths]；
/// - [WindowsKnownFolders]：`SHGetKnownFolderPath` 解析「图片/文档」
///   目录，失败返回 null（由调用方回退）。
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'clipboard_ff.dart';

// ── 位图头写入辅助 ────────────────────────────────────────────────────────────

void _writeU16(Uint8List b, int offset, int v) {
  b[offset] = v & 0xff;
  b[offset + 1] = (v >> 8) & 0xff;
}

void _writeU32(Uint8List b, int offset, int v) {
  b[offset] = v & 0xff;
  b[offset + 1] = (v >> 8) & 0xff;
  b[offset + 2] = (v >> 16) & 0xff;
  b[offset + 3] = (v >> 24) & 0xff;
}

int _readU16(List<int> b, int offset) => b[offset] | (b[offset + 1] << 8);

int _readU32(List<int> b, int offset) =>
    b[offset] |
    (b[offset + 1] << 8) |
    (b[offset + 2] << 16) |
    (b[offset + 3] << 24);

/// 读取侧解析出的 BITMAPV5HEADER 关键字段。
final class BitmapV5HeaderInfo {
  const BitmapV5HeaderInfo({
    required this.headerSize,
    required this.width,
    required this.height,
    required this.bitCount,
    required this.compression,
  });

  /// biSize（BITMAPV5HEADER 应为 124）。
  final int headerSize;

  /// biWidth。
  final int width;

  /// biHeight（正值 = 自下而上）。
  final int height;

  /// biBitCount。
  final int bitCount;

  /// biCompression。
  final int compression;
}

/// 文本 → UTF-16LE 字节（含结尾 NUL）。
Uint8List _utf16Le(String text) {
  final List<int> units = text.codeUnits;
  final Uint8List bytes = Uint8List((units.length + 1) * 2);
  for (int i = 0; i < units.length; i++) {
    _writeU16(bytes, i * 2, units[i]);
  }
  return bytes;
}

/// PNG → CF_DIBV5 位图字节（124 字节头 + BGRA 自下而上像素）。
Uint8List _dibV5Bytes(Uint8List pngBytes) {
  final img.Image? decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    throw clipboardLockedFailure(
      'setDataFailed',
      'PNG 解码失败，无法写入剪贴板图像',
    );
  }
  final img.Image rgba = decoded.convert(numChannels: 4);
  final int width = rgba.width;
  final int height = rgba.height;
  final Uint8List src = rgba.getBytes();

  const int headerSize = kBitmapV5HeaderSize;
  final int pixelBytes = width * height * 4;
  final Uint8List out = Uint8List(headerSize + pixelBytes);

  // BITMAPV5HEADER（小端，偏移按 MSDN 布局）。
  _writeU32(out, 0, headerSize);
  _writeU32(out, 4, width);
  _writeU32(out, 8, height); // 正值 = 自下而上
  _writeU16(out, 12, 1); // biPlanes
  _writeU16(out, 14, 32); // biBitCount
  _writeU32(out, 16, kBiBitfields); // biCompression
  _writeU32(out, 20, pixelBytes); // biSizeImage
  _writeU32(out, 40, 0x00FF0000); // bV5RedMask
  _writeU32(out, 44, 0x0000FF00); // bV5GreenMask
  _writeU32(out, 48, 0x000000FF); // bV5BlueMask
  _writeU32(out, 52, 0xFF000000); // bV5AlphaMask
  _writeU32(out, 56, kLcsSRgb); // bV5CSType
  _writeU32(out, 108, kLcsGmImages); // bV5Intent

  // 像素：BGRA，行序自下而上。
  int dst = headerSize;
  for (int y = height - 1; y >= 0; y--) {
    int srcOff = y * width * 4;
    for (int x = 0; x < width; x++) {
      out[dst] = src[srcOff + 2]; // B
      out[dst + 1] = src[srcOff + 1]; // G
      out[dst + 2] = src[srcOff]; // R
      out[dst + 3] = src[srcOff + 3]; // A
      dst += 4;
      srcOff += 4;
    }
  }
  return out;
}

/// DROPFILES 头 + wide 路径（各自 NUL，末尾再补一个 NUL）。
Uint8List _hDropBytes(List<String> paths) {
  final List<Uint8List> chunks = paths.map(_utf16Le).toList();
  int total = kDropFilesSize + 2;
  for (final Uint8List c in chunks) {
    total += c.length;
  }
  final Uint8List out = Uint8List(total);
  _writeU32(out, 0, kDropFilesSize); // pFiles
  _writeU32(out, 4, 0); // pt.x
  _writeU32(out, 8, 0); // pt.y
  _writeU32(out, 12, 0); // fNC
  _writeU32(out, 16, 1); // fWide = TRUE
  int dst = kDropFilesSize;
  for (final Uint8List c in chunks) {
    out.setAll(dst, c);
    dst += c.length;
  }
  // 末尾双 NUL（每个路径已带一个，这里再补一个终止符）。
  return out;
}

// ── 实现 ─────────────────────────────────────────────────────────────────────

/// Windows 剪贴板实现（CF_UNICODETEXT / CF_DIBV5 / CF_HDROP）。
final class WindowsClipboard implements Clipboard {
  /// 创建实现；[ff] 默认全局 FFI 包装（测试可注入替身）。
  const WindowsClipboard({ClipboardFf ff = const ClipboardFf()}) : _ff = ff;

  final ClipboardFf _ff;

  PluginFailure _openFailed(int format) => clipboardLockedFailure(
    'openFailed',
    'OpenClipboard 失败（剪贴板被占用？）',
    <String, Object?>{'format': format},
  );

  /// 单格式写入：Open → Empty → Set → Close，任一失败结构化抛出并
  /// 保证 CloseClipboard 与句柄回收。
  void _writeSingle(int format, Uint8List data) {
    if (!_ff.open()) {
      throw _openFailed(format);
    }
    int handle = 0;
    try {
      _ff.empty();
      handle = _ff.allocMoveable(data.length);
      if (handle == 0) {
        throw clipboardLockedFailure(
          'setDataFailed',
          'GlobalAlloc 失败',
          <String, Object?>{'format': format, 'bytes': data.length},
        );
      }
      final Pointer<Uint8> ptr = _ff.lock(handle);
      if (ptr == nullptr) {
        _ff.free(handle);
        handle = 0;
        throw clipboardLockedFailure(
          'setDataFailed',
          'GlobalLock 失败',
          <String, Object?>{'format': format},
        );
      }
      try {
        ptr.asTypedList(data.length).setAll(0, data);
      } finally {
        _ff.unlock(handle);
      }
      if (_ff.setData(format, handle) == 0) {
        _ff.free(handle);
        handle = 0;
        throw clipboardLockedFailure(
          'setDataFailed',
          'SetClipboardData 失败',
          <String, Object?>{'format': format},
        );
      }
      handle = 0; // SetClipboardData 成功后所有权移交系统。
    } finally {
      if (handle != 0) {
        _ff.free(handle);
      }
      _ff.close();
    }
  }

  @override
  Future<void> writeText(String text) async {
    _writeSingle(kCfUnicodeText, _utf16Le(text));
  }

  @override
  Future<void> writeImage(Uint8List pngBytes) async {
    _writeSingle(kCfDibV5, _dibV5Bytes(pngBytes));
  }

  @override
  Future<void> writeFiles(List<String> paths) async {
    _writeSingle(kCfHDrop, _hDropBytes(paths));
  }

  // ── 读取侧辅助（诊断/真机烟囱测试用） ─────────────────────────────────────

  /// 读取当前剪贴板 CF_UNICODETEXT 文本；无数据或读取失败返回 null。
  String? peekText() {
    return _withOpen(() {
      final int handle = _ff.getData(kCfUnicodeText);
      if (handle == 0) {
        return null;
      }
      final Pointer<Uint8> ptr = _ff.lock(handle);
      if (ptr == nullptr) {
        return null;
      }
      try {
        final Pointer<Uint16> units = ptr.cast<Uint16>();
        const int maxUnits = 1 << 24; // 防御性上限（16 Mi 个码元）。
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
        _ff.unlock(handle);
      }
    });
  }

  /// 读取当前剪贴板 CF_DIBV5 位图头关键字段；无数据返回 null。
  BitmapV5HeaderInfo? peekHeader() {
    return _withOpen(() {
      final int handle = _ff.getData(kCfDibV5);
      if (handle == 0) {
        return null;
      }
      final Pointer<Uint8> ptr = _ff.lock(handle);
      if (ptr == nullptr) {
        return null;
      }
      try {
        final Uint8List head = ptr.asTypedList(kBitmapV5HeaderSize);
        return BitmapV5HeaderInfo(
          headerSize: _readU32(head, 0),
          width: _readU32(head, 4).toSigned(32),
          height: _readU32(head, 8).toSigned(32),
          bitCount: _readU16(head, 14),
          compression: _readU32(head, 16),
        );
      } finally {
        _ff.unlock(handle);
      }
    });
  }

  /// 读取当前剪贴板 CF_HDROP 文件路径列表；无数据返回 null。
  List<String>? peekPaths() {
    return _withOpen(() {
      final int handle = _ff.getData(kCfHDrop);
      if (handle == 0) {
        return null;
      }
      final Pointer<Uint8> ptr = _ff.lock(handle);
      if (ptr == nullptr) {
        return null;
      }
      try {
        if (_readU32(ptr.asTypedList(20), 16) != 1) {
          return null; // fWide != TRUE，非 wide 布局。
        }
        final Pointer<Uint16> units = ptr.cast<Uint16>();
        final List<String> paths = <String>[];
        final StringBuffer current = StringBuffer();
        // 从 DROPFILES 头之后开始按 UTF-16 码元解析（pFiles 对齐 4
        // 字节且头为 20 字节，码元偏移即 10）。
        for (int i = kDropFilesSize ~/ 2; i < 1 << 24; i++) {
          final int u = units[i];
          if (u == 0) {
            if (current.isEmpty) {
              break; // 双 NUL 终止。
            }
            paths.add(current.toString());
            current.clear();
            continue;
          }
          current.writeCharCode(u);
        }
        return paths;
      } finally {
        _ff.unlock(handle);
      }
    });
  }

  T? _withOpen<T>(T? Function() body) {
    if (!_ff.open()) {
      return null;
    }
    try {
      return body();
    } finally {
      _ff.close();
    }
  }
}

/// Windows 已知目录实现（SHGetKnownFolderPath）。
final class WindowsKnownFolders implements KnownFolders {
  /// 创建实现；[ff] 默认全局 FFI 包装（测试可注入替身）。
  const WindowsKnownFolders({ClipboardFf ff = const ClipboardFf()})
    : _ff = ff;

  final ClipboardFf _ff;

  @override
  String? pictures() => _ff.knownFolderPath(GuidParts.pictures);

  @override
  String? documents() => _ff.knownFolderPath(GuidParts.documents);
}
