import 'dart:io';

import 'sidecar_installer.dart';

/// [PackageFileSystem] 的 `dart:io` 适配实现。
///
/// 本文件是包内仅有的两处 `dart:io` 使用点之一（另一处为进程启动适配）。
final class IoPackageFileSystem implements PackageFileSystem {
  const IoPackageFileSystem();

  @override
  Future<void> createDir(String path, {bool recursive = true}) async {
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<bool> exists(String path) async {
    final type = await FileSystemEntity.type(path);
    return type != FileSystemEntityType.notFound;
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    final file = File(path);
    // 条目路径可能带嵌套目录，写入前确保父目录存在。
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> deleteTree(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) {
      return; // 不存在时为 no-op。
    }
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
      return;
    }
    await File(path).delete();
  }

  @override
  Future<void> renameDir(String from, String to) async {
    await Directory(from).rename(to);
  }
}
