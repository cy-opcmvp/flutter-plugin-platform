// 覆盖场景清单：
// 1. 启动真实子进程（dart VM 运行 echo_child.dart）：stdout 首个完整帧
//    经帧解码为 'ready'。
// 2. kill() 后 exitCode 完成且非零；closeStdin 可安全调用。
@Timeout(Duration(seconds: 30))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 定位包内夹具：workspace 根启动测试时 cwd 不是包根，
/// 必须经 package: URI 解析到插件包目录。
Future<String> _fixture(String relative) async {
  final libUri = await Isolate.resolvePackageUri(
    Uri.parse('package:plugin_sidecar/'),
  );
  final rootUri = libUri!.resolve('..');
  return rootUri.resolve(relative).toFilePath();
}

void main() async {
  final echoChildPath = await _fixture('test/fixtures/dart/echo_child.dart');

  test('starts a real child process and reads the ready frame', () async {
    final launcher = IoProcessLauncher();
    final process = await launcher.start(
      SidecarSpawn(
        executable: Platform.resolvedExecutable,
        arguments: <String>[echoChildPath],
      ),
    );

    final decoder = RpcFrameDecoder();
    var readyPayload = '';
    await for (final chunk in process.stdout) {
      decoder.addBytes(chunk);
      final frames = decoder.drainFrames();
      if (frames.isNotEmpty) {
        readyPayload = frames.first;
        break;
      }
    }
    expect(readyPayload, 'ready');

    await process.kill();
    final exitCode = await process.exitCode;
    expect(exitCode, isNot(0));
    await process.closeStdin();
  });
}
