# F2-09 任务报告：Windows Python 端到端夹具、StdioRpcTransport、包文档与 workspace 全量验证

**日期**: 2026-09-04
**任务**: F2-09（M2 收尾）
**结论**: 完成。e2e 场景 1-10 全部通过（0 跳过）；四项全量验证（逐包 dart test / dart format / dart analyze / 依赖边界扫描）全部通过。

## 一、交付文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `v2/packages/plugin_sidecar/lib/src/process/stdio_rpc_transport.dart` | 新建 | StdioRpcTransport：`SidecarProcess` 绑定为 `RpcTransport`；send → encodeFrame → writeStdin；stdout 经 RpcFrameDecoder 增量解码投递 incoming；不依赖平台进程 API |
| `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart` | 修改 | 追加 `export 'src/process/stdio_rpc_transport.dart';`（按字母序，现 13 个 export） |
| `v2/packages/plugin_sidecar/test/process/stdio_rpc_transport_test.dart` | 新建 | 6 个单元测试（写入转发/半包粘包/超限同步抛/协议违规 error 事件/stdin 写失败投递/dispose 幂等） |
| `v2/packages/plugin_sidecar/test/fixtures/python/echo_sidecar.py` | 新建 | 计划源码逐字 + main() 中新增一行就绪帧 `write_frame("ready")`（见偏差 1） |
| `v2/packages/plugin_sidecar/test/e2e/python_sidecar_e2e_test.dart` | 新建 | 6 个用例覆盖场景矩阵 1-10；`@Timeout(Duration(minutes: 3))`；每处 await 有 20s `_guard` 保护；无 Python 3 时 skip |
| `v2/packages/plugin_sidecar/test/process/io_process_launcher_test.dart` | 修改 | 夹具路径改为经 package: URI 解析（见偏差 6），其余未动 |
| `v2/packages/plugin_sidecar/README.md` | 新建 | 包职责与依赖方向 / SCP1 字节布局与限额表 / 帧与消息格式 / 安装目录布局与原子切换 / 安全边界声明 / 验证命令 |
| `v2/README.md` | 修改 | 「包职责与依赖」追加 plugin_sidecar 条目与依赖方向；新增「M2 边界」章节；「最小验证命令」追加 `dart test packages/plugin_sidecar` |

## 二、e2e 场景矩阵结果（10/10 通过，0 跳过）

运行环境：Windows 11，`py -3`（Python 3.13.7）经候选探测命中（`python` 命中的是 Microsoft Store 存根，退出码 9009，被探测排除）。

| 场景 | 用例 | 结果 |
|------|------|------|
| 1. install 落盘 | state=installed，plugin.json 与 echo_sidecar.py 均存在 | 通过 |
| 2. start 就绪 | supervisor 以 stdout 首字节就绪 | 通过 |
| 3. ping | `call('ping')` → `'pong'` | 通过 |
| 4. echo | 含中文与嵌套结构的 params 原样回显 | 通过 |
| 5. stderrNoise | stderr 噪声不影响 RPC，返回 `'ok'` | 通过 |
| 6. hang-timeout | `rpc.timeout`，details methodName='hang'、elapsedMs=3000，通道 isClosed=true | 通过 |
| 7. crash-unexpectedExit | 先 ping 成功，crash 后 `process.unexpected_exit`、exitCode=1 | 通过 |
| 8. stop + 重装 | stop succeeded → uninstall succeeded → isInstalled=false → 重装 installed | 通过 |
| 9. tampered-digest | 篡改索引后首个 payload 字节 → `package.bad_format`，reason=`digestMismatch`；原安装完好 | 通过 |
| 10. uninstall | 目录消失、isInstalled=false | 通过 |

Skip 机制说明：setUp 与每个用例体首行调用 `_requirePython()`，探测 `python`/`python3`/`py -3` 全部失败时 `markTestSkipped('python 3 not available')`，用例立即中止，不产生失败。本环境探测命中故 0 跳过。

## 三、workspace 全量验证证据（均从 `v2/` 执行）

| 命令 | 结果 | 退出码 |
|------|------|--------|
| `dart test packages/plugin_contracts` | `00:00 +48: All tests passed!` | 0 |
| `dart test packages/plugin_runtime` | `00:00 +26: All tests passed!` | 0 |
| `dart test packages/plugin_devkit` | `00:00 +8: All tests passed!` | 0 |
| `dart test packages/plugin_sidecar` | `00:06 +85: All tests passed!` | 0 |
| `dart format --output=none --set-exit-if-changed .` | `Formatted 52 files (0 changed)` | 0 |
| `dart analyze` | `No issues found!` | 0 |

注：此版本 Dart 不支持在 workspace 根直接 `dart test`（打印用法帮助），故按 `v2/README.md` 既有约定的逐包命令执行；plugin_sidecar 85 个测试从 workspace 根与包目录内运行均通过（路径已 cwd 无关化，见偏差 6）。

依赖边界扫描（grep -rEn）：

- `plugin_contracts/lib`、`plugin_runtime/lib`、`plugin_devkit/lib` 中 `dart:io|dart:ffi|package:flutter|win32`：**0 命中**。
- `plugin_sidecar/lib` 中 `dart:ffi|package:flutter|win32`：**0 命中**。
- `plugin_sidecar/lib` 中 `dart:io` 仅出现在 2 个允许的适配器文件：`lib/src/package/io_file_system.dart`、`lib/src/process/io_process_launcher.dart`。（已将 stdio_rpc_transport.dart 文档注释中提及 "dart:io" 的措辞改为"平台进程 API"，避免字符串扫描误命中。）

## 四、偏差清单

1. **Python 夹具新增就绪帧**：计划的 echo_sidecar.py 源码逐字缺少就绪信号，supervisor 以 stdout 首字节判定就绪，不加则每次启动必然 startup-timeout。在 `main()` 开头新增 `write_frame("ready")`，与 dart 夹具 echo_child.dart 的约定一致。
2. **e2e 广播化 stdout**：`SidecarProcess.stdout` 为单订阅流，supervisor 的 `stdout.first` 就绪探测与 StdioRpcTransport 订阅冲突。e2e 以 `_SharedStdoutProcess`（`asBroadcastStream` 包装）+ `_BroadcastingLauncher` 注入解决；属组合层指导，未改动 F2-01～08 任何文件，README 已将此作为 M3 宿主组合注意事项记录。
3. **Python 探测改为候选列表**：计划为单一 `python --version` 探测；Windows 下 pyenv-win shim（无扩展名）与 Microsoft Store 存根 python.exe（退出码 9009 且写 stdout，会造成假就绪）使单一探测不可靠。改为依次探测 `python`/`python3`/`py -3`，命中即用并记录可执行文件与前置参数。
4. **`_requirePython()` 同时在用例体首行调用**：本版本 test 包中 setUp 里的 `markTestSkipped` 不会中止用例体，仅 setUp 调用会导致无 Python 环境下用例体继续执行而失败。
5. **`_guard` 20 秒超时保护**：按协调者指示，e2e 中所有进程类 await 统一加 `.timeout(Duration(seconds: 20))`，防止任一步骤无限挂起。
6. **夹具路径 cwd 无关化**：从 workspace 根运行 `dart test packages/plugin_sidecar` 时 cwd 是 `v2/` 而非包根，相对路径 `test/fixtures/...` 失效（本任务运行中发现）。e2e 与既有 `io_process_launcher_test.dart` 均改为 `Isolate.resolvePackageUri(Uri.parse('package:plugin_sidecar/'))` 再 `resolve('..')` 定位包根（workspace 下 package: URI 指向 `lib/`，需上一级）。io_process_launcher_test.dart 属 F2-07 交付物，为满足"从 v2/ 全量验证通过"的验收要求做了最小修改（仅路径解析，5 行）。

## 五、约束符合性自检

- 只新建/修改了 `v2/packages/plugin_sidecar/` 下文件与 `v2/README.md`：符合。
- e2e 有 `@Timeout(Duration(minutes: 3))`：符合。
- 无 Python 探测失败即 skip 不 fail：符合（本环境命中，0 跳过）。
- 错误码断言逐条对齐词汇表：`rpc.timeout`（methodName/elapsedMs）、`process.unexpected_exit`（exitCode）、`package.bad_format`（digestMismatch）、`rpc.frame_invalid`：符合。
- 中文文档注释/README：符合。禁止 var/dynamic：符合（全文件 final/显式类型）。80 列：`dart format` 零变更通过。
- 未执行 git 命令、未修改 progress.yaml：符合。
