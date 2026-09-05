import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:plugin_contracts/plugin_contracts.dart';

import 'package_paths.dart';

/// 安装包内的单个条目。
final class PackageEntry {
  const PackageEntry({required this.path, required this.bytes});

  /// 已验证的规范化相对路径。
  final String path;

  final List<int> bytes;
}

/// 打包或读取容器时的违规异常。
///
/// [failure] 通常为 `package.bad_format`；builder 路径校验失败时内嵌
/// `package.path_unsafe`。
final class PackageException implements Exception {
  PackageException(this.failure);

  final PluginFailure failure;

  @override
  String toString() => 'PackageException(${failure.code}: ${failure.message})';
}

/// 内存打包器：条目按加入顺序写入 SCP1 容器。
///
/// 索引 JSON 使用固定字段顺序（path、length、sha256），保证同一组条目
/// 序列化结果稳定。
final class PackageBuilder {
  final List<PackageEntry> _entries = <PackageEntry>[];

  /// 追加条目；路径非法时立即抛出 [PackageException]。
  PackageBuilder add(String path, List<int> bytes) {
    final result = validatePackagePath(path);
    final failure = result.failure;
    if (failure != null) {
      throw PackageException(failure);
    }
    _entries.add(PackageEntry(path: result.normalized, bytes: bytes));
    return this;
  }

  /// 生成 SCP1 容器；缺少 `plugin.json` 条目时抛出 [PackageException]。
  Uint8List build() {
    final hasManifest = _entries.any((entry) => entry.path == 'plugin.json');
    if (!hasManifest) {
      throw PackageException(
        PluginFailure(
          'package.bad_format',
          'package must contain a "plugin.json" entry',
          <String, Object?>{'reason': 'manifestMissing'},
        ),
      );
    }

    final payload = BytesBuilder();
    final indexEntries = <Map<String, Object?>>[];
    for (final entry in _entries) {
      indexEntries.add(<String, Object?>{
        'path': entry.path,
        'length': entry.bytes.length,
        'sha256': crypto.sha256.convert(entry.bytes).toString(),
      });
      payload.add(entry.bytes);
    }

    final indexBytes = utf8.encode(
      jsonEncode(<String, Object?>{'entries': indexEntries}),
    );
    final header = ByteData(8)
      ..setUint32(0, 0x53435031, Endian.big) // 魔数 "SCP1"
      ..setUint32(4, indexBytes.length, Endian.big);
    final out = BytesBuilder()
      ..add(header.buffer.asUint8List())
      ..add(indexBytes)
      ..add(payload.takeBytes());
    return out.takeBytes();
  }
}
