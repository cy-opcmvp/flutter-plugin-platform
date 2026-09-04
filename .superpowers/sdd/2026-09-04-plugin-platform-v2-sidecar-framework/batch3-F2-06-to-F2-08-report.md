# 批次 3 报告：F2-06 / F2-07 / F2-08

- **日期**: 2026-09-04
- **范围**: `v2/packages/plugin_sidecar/` 包内三个串行任务（安装状态机 → RPC 通道 → 进程监督器）
- **验证方式**: 每任务仅跑焦点测试（未跑 workspace 全量），每任务后 `dart analyze` 0 issues
- **dart:io 边界自检**: `grep -rl "dart:io" lib/` 仅命中
  `lib/src/package/io_file_system.dart` 与 `lib/src/process/io_process_launcher.dart`，符合 G2 约束

---

## F2-06 安装状态机与安装器

### 文件清单

| 文件 | 说明 |
|------|------|
| `lib/src/package/install_state_machine.dart` | 纯状态机：合法转换表 + 状态历史，无 IO |
| `lib/src/package/sidecar_installer.dart` | 安装/卸载编排：下载载荷落盘 → trash-N 暂存 → rename 原子切换 |
| `lib/src/package/io_file_system.dart` | `PackageFileSystem` 的 IO 适配（dart:io 允许点之一） |
| `test/package/install_state_machine_test.dart` | 4 测试 |
| `test/package/sidecar_installer_test.dart` | 10 测试（内存 fake fs） |
| `lib/plugin_sidecar.dart` | 追加 `install_state_machine` / `io_file_system` / `sidecar_installer` 三个 export（字母序） |

### 焦点验证

```
dart test test/package/install_state_machine_test.dart test/package/sidecar_installer_test.dart
→ 00:00 +14: All tests passed!   (4 + 10 = 14)
dart analyze → No issues found!
```

### 实现要点

- 状态机持有合法转换白名单，非法转换返回失败结果而非抛异常；历史记录可审计。
- 安装入口先做 `exists(finalDir)` 预检，命中则跳过状态转换直接幂等返回，
  避免持久化状态机对重复 install 报非法转换。
- `_syncMachineDown`：状态机状态以磁盘真值（final 目录是否存在）反向同步，
  保证进程重启后状态机与磁盘一致。
- trash-N 暂存目录用递增探测防撞名；rename 前显式 `fs.createDir(rootDir)`
  保证 Windows 上 rename 目标父目录存在。

### 偏差及理由

1. **install 入口增加 finalDir 预检**（计划未显式要求）——重复 install 是正常
   运维路径，持久化状态机白名单不含 `installed → installing`，无预检会拒绝
   合法重复安装。
2. **uninstall 语义补齐**：目标不存在时视为幂等成功，与 deleteTree 的
   no-op 语义对齐。

---

## F2-07 RPC 客户端通道

### 文件清单

| 文件 | 说明 |
|------|------|
| `lib/src/rpc/rpc_channel.dart` | `RpcTransport` 抽象、`RpcCallResult`、`RpcChannel`、`typedef Delayer` |
| `test/rpc/rpc_channel_test.dart` | 11 测试（fake transport + 受控 delayer） |
| `lib/plugin_sidecar.dart` | 追加 `rpc_channel` export（字母序） |

### 焦点验证

```
dart test test/rpc/rpc_channel_test.dart
→ 00:00 +11: All tests passed!   (11)
dart analyze → No issues found!
```

### 实现要点

- **RpcTransport 是纯 String 抽象**：`send(String payload)` /
  `incoming: Stream<String>`；帧编解码（4 字节大端长度前缀）由传输实现
  负责（F2-09 StdioRpcTransport 落地），通道只做
  `encodeRpcMessage` / `decodeRpcMessage`。
- **id 从 0 自增**（`final id = _nextId; _nextId += 1;`），pending 表按 id
  精确匹配，支持并发乱序响应。
- **超时语义**：每个 call 持有自己的 delayer 竞速回调；到期后该请求以
  `rpc.timeout`（details: methodName/elapsedMs）收敛 → `_pending.remove` →
  关闭通道。**其余 pending 各自的 delayer 到期后各自以 rpc.timeout 收敛**
  （"pending 已按各自结果完成"），超时引发的关闭**不补发
  `rpc.channel_closed`**——词汇表的 reason（closedByCaller/transportError/
  unexpectedResponse）无 timeout 项。
- **错误路径**：send 抛异常 → 全部 pending 以
  `rpc.channel_closed(transportError)` 收敛并关闭；响应 id 无对应 pending →
  `unexpectedResponse`；非法 JSON（FormatException.message 透传）与响应流上
  的非响应消息 → `rpc.message_invalid`（后者文案固定
  'received a non-response message'）。
- `close()` 幂等；关闭后 call/notify 静默或立即以 `closedByCaller` 失败。

### 偏差及理由

1. **构造参数 `RpcFrameDecoder? decoder` 保留为接口契约字段**——计划接口
   签名冻结要求保留，但 transport.incoming 已是解码后的 payload 流，通道不
   重复做帧解码；故存为 public final 字段（默认 `RpcFrameDecoder()`）并
   文档注明用途，避免未使用私有字段 lint。
2. **`_resolvePending(Object? id)`**：`RpcError.id` 类型为 `Object?`（JSON-RPC
   允许 error 响应 id 为 null），参数必须收宽；null id 查不到 pending 自然走
   `unexpectedResponse` 路径。

---

## F2-08 进程监督器与 IO 启动器

### 文件清单

| 文件 | 说明 |
|------|------|
| `lib/src/process/sidecar_process.dart` | `SidecarSpawn`、`SidecarProcess`、`SidecarProcessLauncher` 接口 |
| `lib/src/process/sidecar_supervisor.dart` | `SidecarSupervisor`、`SupervisedStartResult`、`StopResult` |
| `lib/src/process/io_process_launcher.dart` | IO 适配（dart:io 允许点之二）：`Process.start` → 最小句柄映射 |
| `test/fixtures/dart/echo_child.dart` | 真实子进程夹具：立即写 'ready' 帧，常驻至被 kill |
| `test/process/sidecar_supervisor_test.dart` | 9 测试（fake launcher + fake process + 受控 delayer） |
| `test/process/io_process_launcher_test.dart` | 1 测试（真实子进程，`@Timeout(30s)` 库级注解） |
| `lib/plugin_sidecar.dart` | 追加 `io_process_launcher` / `sidecar_process` / `sidecar_supervisor` 三个 export（字母序） |

### 焦点验证

```
dart test test/process/sidecar_supervisor_test.dart test/process/io_process_launcher_test.dart
→ 00:00 +10: All tests passed!   (9 + 1 = 10)
dart analyze → No issues found!
```

### 实现要点

- **就绪信号 = stdout 首字节**（协议无关弱信号）：`start` 以 `Future.any`
  竞速 `stdout.first` / `exitCode` / `delayer(startupTimeout)`。
- 启动窗口三路收敛：就绪 → 加入存活表并挂退出监听；exitCode 先到 →
  `process.start_failed(exited, exitCode)`（不触发 onUnexpectedExit）；
  超时先到 → kill + `process.start_timeout`。`launcher.start` 抛异常 →
  `process.start_failed(spawnError)`，process 为 null。
- **意外退出 vs 主动停止**：`_stopping` 集合区分——`stop()` 先登记；退出
  监听发现进程不在 `_stopping` 时才回调
  `process.unexpected_exit(exitCode)`。stop 正常不触发回调。
- **stop** = kill → `Future.any(exitCode, delayer(stopGracePeriod))`；
  超时分支报 `process.stop_timeout` 且进程仍留在存活表（hasAlive 保持
  true）。`stopGracePeriod` 默认 `Duration(seconds: 5)`，与计划一致。
- **disposeAll** 逆序遍历存活表逐个 stop，幂等（空表 no-op）。
- 所有超时经注入 `Delayer`，测试 `fireAll` 受控推进，零真实等待。
- IO 适配：`_IoSidecarProcess.kill()` 用 dart:io 默认信号（Windows 等价
  TerminateProcess）；`writeStdin` 写后 flush；`closeStdin` 关闭写端。

### 偏差及理由

1. **echo_child.dart 补 `import 'dart:typed_data';`**——计划给定代码使用
   `ByteData`/`Endian` 但未导入（编译报 `Method not found: 'ByteData'`），
   属计划代码笔误，其余内容逐字保留。
2. **测试文件显式 `import 'package:plugin_contracts/plugin_contracts.dart';`**
   ——supervisor 测试声明 `PluginFailure` 局部变量需要类型导入；
   `plugin_sidecar.dart` 不 re-export contracts（保持包导出面最小）。
3. **`_FakeProcess.exitCodeOnKill` 为事后赋值的字段而非构造参数**——
   "kill 后退出"（disposeAll 场景）与"kill 后不退出"（start/stop 超时场景）
   两种 fake 行为需共存；构造可选参数永不传值会触发 unused_element_parameter
   警告，字段赋值方案两者兼得。
4. **`@Timeout` 用库级注解**（`@Timeout(...) library;`）——Dart 规定该注解
   不能标注在 `main` 函数上（invalid_annotation_target）。

---

## 汇总

| 任务 | 焦点测试 | 结果 |
|------|---------|------|
| F2-06 | `dart test test/package/install_state_machine_test.dart test/package/sidecar_installer_test.dart` | 14/14 通过 |
| F2-07 | `dart test test/rpc/rpc_channel_test.dart` | 11/11 通过 |
| F2-08 | `dart test test/process/sidecar_supervisor_test.dart test/process/io_process_launcher_test.dart` | 10/10 通过 |

包级 `dart analyze`：No issues found（每任务后各验一次）。
未执行任何 git 命令；未修改 progress.yaml。
