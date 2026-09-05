import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:plugin_contracts/plugin_contracts.dart';

import 'package_builder.dart';
import 'package_paths.dart';

/// SCP1 容器魔数："SCP1" 的 ASCII 字节。
const List<int> _magicBytes = <int>[0x53, 0x43, 0x50, 0x31];

final RegExp _digestPattern = RegExp(r'^[0-9a-f]{64}$');

/// 索引中的单条目元数据。
typedef _IndexEntry = ({String path, int length, String digest});

/// 容器读取限制。
final class PackageLimits {
  const PackageLimits({
    this.maxEntries = 4096,
    this.maxEntryBytes = 64 * 1024 * 1024,
    this.maxTotalBytes = 256 * 1024 * 1024,
    this.maxIndexBytes = 1024 * 1024,
  });

  /// 条目数上限。
  final int maxEntries;

  /// 单条目字节上限。
  final int maxEntryBytes;

  /// 全部条目字节总量上限。
  final int maxTotalBytes;

  /// 索引 JSON 字节上限。
  final int maxIndexBytes;
}

/// 解析成功的安装包。
final class SidecarPackage {
  SidecarPackage({required this.manifest, required List<PackageEntry> entries})
    : entries = List<PackageEntry>.unmodifiable(entries);

  /// 清单；kind 必须为 PluginKind.sidecar。
  final PluginManifest manifest;

  /// 含 manifest 条目在内的全部条目，保持容器顺序。
  final List<PackageEntry> entries;

  PackageEntry? entryByPath(String path) {
    for (final entry in entries) {
      if (entry.path == path) {
        return entry;
      }
    }
    return null;
  }
}

/// SCP1 容器读取器；全程操作内存字节，不触碰文件系统。
final class PackageReader {
  PackageReader.fromBytes(this._bytes, {this.limits = const PackageLimits()});

  final Uint8List _bytes;

  final PackageLimits limits;

  /// 解析容器。
  ///
  /// 任何格式违规抛 [PackageException]（code 为 `package.bad_format`）；
  /// 路径违规则内嵌 `package.path_unsafe`。
  SidecarPackage read() {
    if (_bytes.length < 8) {
      throw _bad('truncated', 'container is shorter than the fixed header');
    }
    if (!_hasMagic()) {
      throw _bad('badMagic', 'container magic is not "SCP1"');
    }

    final indexLength = ByteData.sublistView(
      _bytes,
      4,
      8,
    ).getUint32(0, Endian.big);
    if (8 + indexLength > _bytes.length) {
      throw _bad('truncated', 'declared index length exceeds container size');
    }
    if (indexLength > limits.maxIndexBytes) {
      throw _bad('limitExceeded', 'index size exceeds the configured limit');
    }

    final indexEntries = _decodeIndex(
      Uint8List.sublistView(_bytes, 8, 8 + indexLength),
    );
    if (indexEntries.length > limits.maxEntries) {
      throw _bad('limitExceeded', 'entry count exceeds the configured limit');
    }
    _validateEntryPaths(indexEntries);
    final entries = _materializeEntries(indexEntries, 8 + indexLength);
    return _assemblePackage(entries);
  }

  bool _hasMagic() {
    for (var i = 0; i < _magicBytes.length; i++) {
      if (_bytes[i] != _magicBytes[i]) {
        return false;
      }
    }
    return true;
  }

  /// 严格解码索引 JSON；形状错误一律归入 `indexInvalid`。
  List<_IndexEntry> _decodeIndex(Uint8List indexBytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(indexBytes));
    } on FormatException {
      throw _bad('indexInvalid', 'index is not valid UTF-8 JSON');
    }

    if (decoded is! Map<String, Object?> ||
        decoded.length != 1 ||
        decoded.keys.single != 'entries') {
      throw _bad('indexInvalid', 'index must only contain "entries"');
    }

    final list = decoded['entries'];
    if (list is! List<Object?> || list.isEmpty) {
      throw _bad('indexInvalid', 'index "entries" must be a non-empty array');
    }

    final result = <_IndexEntry>[];
    for (final item in list) {
      if (item is! Map<String, Object?> || item.length != 3) {
        throw _bad('indexInvalid', 'index entry shape is invalid');
      }
      final path = item['path'];
      final length = item['length'];
      final digest = item['sha256'];
      if (path is! String ||
          length is! int ||
          length < 0 ||
          digest is! String ||
          !_digestPattern.hasMatch(digest)) {
        throw _bad('indexInvalid', 'index entry fields are invalid');
      }
      result.add((path: path, length: length, digest: digest));
    }
    return result;
  }

  /// 逐条执行路径安全校验与大小写折叠重复检测。
  void _validateEntryPaths(List<_IndexEntry> entries) {
    for (final entry in entries) {
      final result = validatePackagePath(entry.path);
      final failure = result.failure;
      if (failure != null) {
        throw PackageException(failure);
      }
    }
    final duplicate = detectDuplicatePaths(entries.map((entry) => entry.path));
    if (duplicate != null) {
      throw PackageException(duplicate);
    }
  }

  /// 按索引切分条目字节并校验摘要与容量限制。
  List<PackageEntry> _materializeEntries(List<_IndexEntry> entries, int start) {
    final result = <PackageEntry>[];
    var offset = start;
    var totalBytes = 0;
    for (final entry in entries) {
      if (entry.length > limits.maxEntryBytes) {
        throw _bad('limitExceeded', 'entry size exceeds the configured limit');
      }
      totalBytes += entry.length;
      if (totalBytes > limits.maxTotalBytes) {
        throw _bad(
          'limitExceeded',
          'total entry size exceeds the configured limit',
        );
      }
      if (offset + entry.length > _bytes.length) {
        throw _bad('truncated', 'entry bytes exceed container size');
      }

      final bytes = Uint8List.sublistView(
        _bytes,
        offset,
        offset + entry.length,
      );
      if (crypto.sha256.convert(bytes).toString() != entry.digest) {
        throw _bad('digestMismatch', 'entry digest does not match the index');
      }
      result.add(PackageEntry(path: entry.path, bytes: bytes));
      offset += entry.length;
    }
    return result;
  }

  /// 解码 `plugin.json` 并校验 sidecar 语义约束。
  SidecarPackage _assemblePackage(List<PackageEntry> entries) {
    PackageEntry? manifestEntry;
    for (final entry in entries) {
      if (entry.path == 'plugin.json') {
        manifestEntry = entry;
        break;
      }
    }
    if (manifestEntry == null) {
      throw _bad('manifestMissing', 'container has no "plugin.json" entry');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(manifestEntry.bytes));
    } on FormatException {
      throw _bad('indexInvalid', '"plugin.json" is not valid UTF-8 JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw _bad('indexInvalid', '"plugin.json" must be a JSON object');
    }

    final PluginManifest manifest;
    try {
      manifest = PluginManifestCodec.decode(decoded);
    } on FormatException {
      throw _bad('indexInvalid', '"plugin.json" is not a valid manifest');
    }
    if (manifest.kind != PluginKind.sidecar) {
      throw _bad('indexInvalid', 'manifest kind must be "sidecar"');
    }

    final hasEntrypoint = entries.any(
      (entry) => entry.path == manifest.entrypoint,
    );
    if (!hasEntrypoint) {
      throw _bad('entrypointMissing', 'manifest entrypoint has no entry');
    }

    return SidecarPackage(manifest: manifest, entries: entries);
  }

  PackageException _bad(String reason, String message) {
    return PackageException(
      PluginFailure('package.bad_format', message, <String, Object?>{
        'reason': reason,
      }),
    );
  }
}
