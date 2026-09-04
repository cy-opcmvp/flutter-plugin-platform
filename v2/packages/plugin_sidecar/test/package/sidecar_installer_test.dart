// 覆盖场景清单：
// 1. install 成功：<root>/<id>/ 出现全部条目、entrypoint 文件存在且内容一致、
//    isInstalled == true、outcome 到 installed；installBytes 便捷入口同样成功。
// 2. 重复 install → alreadyInstalled，原目录内容未被触碰，staging 不残留。
// 3. 解包前 staging 残留 → 先清理再写，残留文件不进入最终目录。
// 4. 写入条目异常（fake fs 注入）→ stagingFailed，staging 被清理，
//    状态回 notInstalled。
// 5. rename 异常（fake fs 注入）→ commitFailed，staging 被清理，最终目录不存在。
// 6. uninstall 成功：目录消失、无 trash 残留、isInstalled == false、
//    状态 notInstalled。
// 7. uninstall 不存在 → uninstall_failed(notInstalled)，状态 notInstalled。
// 8. uninstall rename 失败（fake fs 注入）→ renameFailed，状态回 installed，
//    原目录保留。
// 9. trash 删除失败（fake fs 注入）→ 仍算成功（failure == null，best-effort）。
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 故障注入用文件系统 fake：以路径集合模拟实体存在性。
final class _FakeFileSystem implements PackageFileSystem {
  _FakeFileSystem({
    Object? writeError,
    Object? renameError,
    Object? deleteError,
  }) : _writeError = writeError,
       _renameError = renameError,
       _deleteError = deleteError;

  final Object? _writeError;
  final Object? _renameError;
  final Object? _deleteError;

  /// 模拟存在的文件/目录路径集合。
  final Set<String> entities = <String>{};
  final List<String> writtenPaths = <String>[];
  final List<String> deletedPaths = <String>[];
  final List<String> renamedFrom = <String>[];

  /// 预置一个已存在的实体（如已安装目录）。
  void seed(String path) {
    entities.add(path);
  }

  @override
  Future<void> createDir(String path, {bool recursive = true}) async {
    entities.add(path);
  }

  @override
  Future<bool> exists(String path) async => entities.contains(path);

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    final error = _writeError;
    if (error != null) {
      throw error;
    }
    writtenPaths.add(path);
    entities.add(path);
  }

  @override
  Future<void> deleteTree(String path) async {
    final error = _deleteError;
    if (error != null) {
      throw error;
    }
    deletedPaths.add(path);
    entities.removeWhere(
      (existing) => existing == path || existing.startsWith('$path/'),
    );
  }

  @override
  Future<void> renameDir(String from, String to) async {
    final error = _renameError;
    if (error != null) {
      throw error;
    }
    renamedFrom.add(from);
    final moved = <String>{
      for (final existing in entities)
        if (existing == from || existing.startsWith('$from/'))
          to + existing.substring(from.length)
        else
          existing,
    };
    entities
      ..clear()
      ..addAll(moved);
  }
}

void main() {
  const pluginIdValue = 'dev.example.echo';
  final pluginId = PluginId.parse(pluginIdValue);
  final scriptBytes = utf8.encode('print("echo")\n');

  Uint8List manifestBytes(String id) {
    return utf8.encode(
      jsonEncode(<String, Object?>{
        'id': id,
        'name': 'Echo',
        'version': '1.0.0',
        'apiVersion': 1,
        'kind': 'sidecar',
        'targets': ['windows'],
        'entrypoint': 'echo_sidecar.py',
        'provides': <Object?>[],
        'requires': <Object?>[],
        'surfaces': ['command'],
        'configSchemaVersion': 1,
        'dataSchemaVersion': 1,
      }),
    );
  }

  /// 两条目的合法好包（清单 + entrypoint 脚本）。
  Uint8List buildPackageBytes({String id = pluginIdValue}) {
    return PackageBuilder()
        .add('plugin.json', manifestBytes(id))
        .add('echo_sidecar.py', scriptBytes)
        .build();
  }

  SidecarPackage buildPackage() =>
      PackageReader.fromBytes(buildPackageBytes()).read();

  group('SidecarInstaller', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('sidecar_installer_test');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    SidecarInstaller realInstaller() =>
        SidecarInstaller(fs: IoPackageFileSystem(), rootDir: root.path);

    String finalDirPath([String id = pluginIdValue]) => '${root.path}/$id';

    test('install succeeds and materializes every entry', () async {
      final installer = realInstaller();

      final outcome = await installer.install(buildPackage());

      expect(outcome.succeeded, isTrue);
      expect(outcome.failure, isNull);
      expect(outcome.state, SidecarInstallState.installed);

      final finalDir = Directory(finalDirPath());
      expect(finalDir.existsSync(), isTrue);
      expect(
        File('${finalDir.path}/plugin.json').readAsBytesSync(),
        manifestBytes(pluginIdValue),
      );
      // 清单 entrypoint 文件确实存在且内容一致。
      expect(
        File('${finalDir.path}/echo_sidecar.py').readAsBytesSync(),
        scriptBytes,
      );
      expect(await installer.isInstalled(pluginId), isTrue);
    });

    test('installBytes accepts raw container bytes', () async {
      final installer = realInstaller();

      final outcome = await installer.installBytes(
        buildPackageBytes(id: 'dev.example.other'),
      );

      expect(outcome.succeeded, isTrue);
      expect(Directory(finalDirPath('dev.example.other')).existsSync(), isTrue);
    });

    test(
      'repeated install is rejected and leaves the original intact',
      () async {
        final installer = realInstaller();
        await installer.install(buildPackage());
        final entrypoint = File('${finalDirPath()}/echo_sidecar.py');
        final bytesBefore = entrypoint.readAsBytesSync();

        final outcome = await installer.install(buildPackage());

        expect(outcome.succeeded, isFalse);
        expect(outcome.failure?.code, 'sidecar.install_failed');
        expect(outcome.failure?.details['reason'], 'alreadyInstalled');
        expect(outcome.state, SidecarInstallState.installed);
        expect(entrypoint.readAsBytesSync(), bytesBefore);
        expect(Directory(finalDirPath()).listSync(), hasLength(2));
        expect(Directory('${finalDirPath()}.staging').existsSync(), isFalse);
      },
    );

    test('stale staging content is cleared before unpacking', () async {
      final staging = Directory('${finalDirPath()}.staging');
      staging.createSync(recursive: true);
      File('${staging.path}/leftover.txt').writeAsStringSync('stale');
      final installer = realInstaller();

      final outcome = await installer.install(buildPackage());

      expect(outcome.succeeded, isTrue);
      expect(staging.existsSync(), isFalse);
      expect(
        Directory(
          finalDirPath(),
        ).listSync().where((entity) => entity.path.endsWith('leftover.txt')),
        isEmpty,
      );
    });

    test('entry write failure yields stagingFailed and rolls back', () async {
      final fake = _FakeFileSystem(writeError: StateError('disk full'));
      final installer = SidecarInstaller(
        fs: fake,
        rootDir: '${root.path}/fake-root',
      );

      final outcome = await installer.install(buildPackage());

      expect(outcome.succeeded, isFalse);
      expect(outcome.failure?.code, 'sidecar.install_failed');
      expect(outcome.failure?.details['reason'], 'stagingFailed');
      expect(outcome.state, SidecarInstallState.notInstalled);
      final staging = '${root.path}/fake-root/$pluginIdValue.staging';
      expect(fake.deletedPaths, contains(staging));
      expect(
        fake.entities.where((entity) => entity.startsWith('$staging/')),
        isEmpty,
      );
    });

    test('rename failure yields commitFailed and cleans staging', () async {
      final fake = _FakeFileSystem(renameError: StateError('access denied'));
      final installer = SidecarInstaller(
        fs: fake,
        rootDir: '${root.path}/fake-root',
      );

      final outcome = await installer.install(buildPackage());

      expect(outcome.succeeded, isFalse);
      expect(outcome.failure?.code, 'sidecar.install_failed');
      expect(outcome.failure?.details['reason'], 'commitFailed');
      expect(outcome.state, SidecarInstallState.notInstalled);
      final staging = '${root.path}/fake-root/$pluginIdValue.staging';
      expect(fake.deletedPaths, contains(staging));
      expect(
        fake.entities.contains('${root.path}/fake-root/$pluginIdValue'),
        isFalse,
      );
    });

    test('uninstall removes the directory without trash leftovers', () async {
      final installer = realInstaller();
      await installer.install(buildPackage());

      final outcome = await installer.uninstall(pluginId);

      expect(outcome.succeeded, isTrue);
      expect(outcome.failure, isNull);
      expect(outcome.state, SidecarInstallState.notInstalled);
      expect(Directory(finalDirPath()).existsSync(), isFalse);
      expect(await installer.isInstalled(pluginId), isFalse);
      expect(root.listSync(), isEmpty); // 无 trash 残留
    });

    test('uninstall on a missing installation reports notInstalled', () async {
      final installer = realInstaller();

      final outcome = await installer.uninstall(pluginId);

      expect(outcome.succeeded, isFalse);
      expect(outcome.failure?.code, 'sidecar.uninstall_failed');
      expect(outcome.failure?.details['reason'], 'notInstalled');
      expect(outcome.state, SidecarInstallState.notInstalled);
    });

    test('uninstall rename failure keeps the installation', () async {
      final fakeRoot = '${root.path}/fake-root';
      final fake = _FakeFileSystem(renameError: StateError('locked'))
        ..seed('$fakeRoot/$pluginIdValue');
      final installer = SidecarInstaller(fs: fake, rootDir: fakeRoot);

      final outcome = await installer.uninstall(pluginId);

      expect(outcome.succeeded, isFalse);
      expect(outcome.failure?.code, 'sidecar.uninstall_failed');
      expect(outcome.failure?.details['reason'], 'renameFailed');
      expect(outcome.state, SidecarInstallState.installed);
      expect(fake.entities.contains('$fakeRoot/$pluginIdValue'), isTrue);
      expect(
        fake.entities.where((entity) => entity.contains('.trash-')),
        isEmpty,
      );
    });

    test(
      'trash deletion failure still counts as a successful uninstall',
      () async {
        final fakeRoot = '${root.path}/fake-root';
        final fake = _FakeFileSystem(deleteError: StateError('delete denied'))
          ..seed('$fakeRoot/$pluginIdValue');
        final installer = SidecarInstaller(fs: fake, rootDir: fakeRoot);

        final outcome = await installer.uninstall(pluginId);

        expect(outcome.succeeded, isTrue);
        expect(outcome.failure, isNull);
        expect(outcome.state, SidecarInstallState.notInstalled);
        expect(fake.entities.contains('$fakeRoot/$pluginIdValue'), isFalse);
      },
    );
  });
}
