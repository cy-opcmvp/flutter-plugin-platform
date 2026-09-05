/// F4-06 e2e：真 Python 进程起停 hash_tool sidecar 并运行 hash.compute。
///
/// 链路：读样本 .scp → installFromBytes（真实磁盘 fs）→ start（探测
/// python/python3/py -3 并启动脚本）→ run('abc') → 三摘要与 hashlib
/// 参考值断言 → stop → uninstall。无可用 Python 解释器时跳过不失败。
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';

import 'package:toolbox_host/src/plugins/hash_tool_plugin.dart';
import 'package:toolbox_host/src/sidecar_command_bridge.dart';
import 'package:toolbox_host/src/sidecar_session_factory_io.dart';

/// e2e 文案载体：无需宿主 l10n，标签仅供结果字段呈现。
const HashToolStrings kE2eStrings = HashToolStrings(
  formTitle: 'Hash',
  textLabel: 'Text',
  textPlaceholder: 'text to hash',
  md5Label: 'MD5',
  sha1Label: 'SHA-1',
  sha256Label: 'SHA-256',
);

void main() {
  test('真 Python 环境：安装→启动→hash.compute→停止→卸载全链', () async {
    final (String, List<String>)? command = probePythonCommand();
    if (command == null) {
      markTestSkipped('未检测到可用的 Python 3 解释器，e2e 跳过');
      return;
    }
    final Directory temp = await Directory.systemTemp.createTemp('hash_e2e_');
    addTearDown(() => temp.delete(recursive: true));
    // CWD 无关的样本包路径：向上寻找 workspace 根标记（G5 Important 修复，
    // 不使用 Isolate.resolvePackageUri——根 CWD 的 flutter test 下不受支持）。
    String repoRoot = '';
    for (
      Directory d = Directory.current;
      d.parent.path != d.path;
      d = d.parent
    ) {
      if (File('${d.path}/pubspec.yaml').existsSync() &&
          Directory('${d.path}/apps/toolbox_host').existsSync()) {
        repoRoot = d.path;
        break;
      }
    }
    expect(repoRoot, isNotEmpty, reason: '未能在 CWD 祖先中定位仓库根');
    final Uint8List bytes = await File(
      '$repoRoot/sidecars/python_sample/hash-tool.scp',
    ).readAsBytes();

    final SidecarCommandBridge bridge = SidecarCommandBridge(
      installer: SidecarInstaller(
        fs: const IoPackageFileSystem(),
        rootDir: '${temp.path}/packages',
      ),
      pluginId: PluginId.parse(kHashToolPluginId),
      entrypointFileName: kHashToolEntrypointFileName,
      sessionFactory: createHashToolSessionFactory(),
    );

    // 安装：.scp 字节经真实 fs 落盘。
    final BridgeInstallResult install = await bridge.installFromBytes(bytes);
    expect(install.succeeded, isTrue, reason: '${install.failure?.code}');
    expect(await bridge.isInstalled(), isTrue);

    // 启动：探测解释器并启动 hash_tool.py，等待 ready 帧。
    final BridgeStartOutcome start = await bridge.start();
    expect(start.succeeded, isTrue, reason: '${start.failure?.code}');
    expect(bridge.isSessionLive, isTrue);

    // 运行 hash.compute('abc')，映射为声明式三字段结果。
    final BridgeRunResult run = await bridge.run(<String, Object?>{
      'text': 'abc',
    }, strings: kE2eStrings);
    expect(run.succeeded, isTrue, reason: '${run.failure?.code}');
    final FieldsResultDescriptor descriptor =
        run.result! as FieldsResultDescriptor;
    expect(descriptor.fields, hasLength(3));
    // hashlib 参考值（硬编码，样本脚本零 pip 依赖）。
    expect(descriptor.fields[0].value, '900150983cd24fb0d6963f7d28e17f72');
    expect(
      descriptor.fields[1].value,
      'a9993e364706816aba3e25717850c26c9cd0d89d',
    );
    expect(
      descriptor.fields[2].value,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );

    // 停止 + 卸载：状态回落为未安装。
    final PluginFailure? stopFailure = await bridge.stop();
    expect(stopFailure, isNull);
    expect(bridge.isSessionLive, isFalse);
    final PluginFailure? uninstallFailure = await bridge.uninstall();
    expect(uninstallFailure, isNull);
    expect(await bridge.isInstalled(), isFalse);
  });

  test('未安装运行命令返回 bridge.not_installed（无需 Python）', () async {
    // run 的未安装分支先于会话工厂调用，无需解释器；工厂断言不可达。
    final Directory temp = await Directory.systemTemp.createTemp(
      'hash_e2e_ng_',
    );
    addTearDown(() => temp.delete(recursive: true));
    final SidecarCommandBridge bridge = SidecarCommandBridge(
      installer: SidecarInstaller(
        fs: const IoPackageFileSystem(),
        rootDir: '${temp.path}/packages',
      ),
      pluginId: PluginId.parse(kHashToolPluginId),
      entrypointFileName: kHashToolEntrypointFileName,
      sessionFactory: (String scriptPath) async {
        fail('未安装时不应调用会话工厂：$scriptPath');
      },
    );

    final BridgeRunResult run = await bridge.run(<String, Object?>{
      'text': 'abc',
    }, strings: kE2eStrings);
    expect(run.succeeded, isFalse);
    expect(run.result, isNull);
    expect(run.failure?.code, 'bridge.not_installed');
    expect(run.failure?.details['pluginId'], kHashToolPluginId);
  });
}
