# plugin_sidecar

`plugin_sidecar` 为桌面外部插件（sidecar）提供安装、进程监督与帧化 JSON-RPC 通信：

- `PackageBuilder` / `PackageReader`：SCP1 安装包的构建与严格解析（纯内存，不触碰文件系统）。
- `SidecarInstaller` + `IoPackageFileSystem`：把安装包原子落盘到插件根目录，支持卸载与重装。
- `SidecarSupervisor` + `IoProcessLauncher` + `SidecarSpawn`：启动 sidecar 子进程，以 stdout 首字节为就绪信号，报告意外退出。
- `StdioRpcTransport` + `RpcChannel`：在 stdio 上承载带超时的请求/响应 RPC。
- `RpcFrameCodec` / `RpcMessageCodec`：帧与 JSON-RPC 消息的编解码。

依赖方向为 `plugin_contracts <- plugin_sidecar`。本包只依赖契约包与 `crypto`（sha256 摘要），不依赖 `plugin_runtime` / `plugin_devkit`，也不依赖 Flutter。`dart:io` 仅出现在 `io_file_system.dart` 与 `io_process_launcher.dart` 两个适配器文件中，其余代码保持纯 Dart 可注入测试。

## SCP1 安装包格式

容器字节布局（大端序）：

| 偏移 | 长度 | 内容 |
|------|------|------|
| 0 | 4 字节 | 魔数 `SCP1` |
| 4 | 4 字节 | 索引长度 `indexLen`（u32 大端） |
| 8 | `indexLen` 字节 | 索引，UTF-8 JSON：`{"entries":[{"path","length","sha256"},...]}` |
| 8 + `indexLen` | 按索引 | 条目 payload，依索引顺序紧密排列 |

索引是唯一顶层键 `entries` 的对象；每条目固定三个字段：相对路径 `path`、字节长度 `length`、内容 sha256 十六进制摘要 `sha256`。解析时逐条校验路径安全（拒绝绝对路径、`..`、反斜杠、空段等）与摘要一致性；任何违规抛 `PackageException`（`package.bad_format`，details 带 `reason`，如 `badMagic`、`truncated`、`indexInvalid`、`digestMismatch`、`limitExceeded`），路径违规则带 `package.path_unsafe`。

默认限额（`PackageLimits`，可按宿主需要收紧或放宽）：

| 限额 | 默认值 |
|------|--------|
| 单条目字节 `maxEntryBytes` | 64 MiB |
| 全部条目总量 `maxTotalBytes` | 256 MiB |
| 索引 JSON 字节 `maxIndexBytes` | 1 MiB |
| 条目数量 `maxEntries` | 4096 |
| 单条路径长度 | 1024 字符 |

## 帧与消息格式

传输帧：4 字节大端长度前缀 + UTF-8 JSON payload。`RpcFrameDecoder` 增量解码，天然兼容半包与粘包；帧上限默认 `defaultMaxFrameBytes` = 8 MiB，超限帧立即失败（`rpc.frame_invalid`，details 带 `reason: tooLarge|empty|invalidUtf8`），解码器此后进入损坏态需 `reset()`。消息层遵循 JSON-RPC 2.0 请求/响应映射，`RpcChannel.call` 返回 `RpcCallResult`（value 或 `PluginFailure`）。

`StdioRpcTransport` 将 `SidecarProcess` 绑定为 `RpcTransport`：

- 发送：`send` 先同步编码（超限同步抛出），再异步写入子进程 stdin；写入失败转为 error 事件。
- 接收：订阅子进程 stdout，解出的 payload 依序投递到 `incoming`；stdout 错误、帧协议违规与 stdin 写入失败均以 error 事件投递，由 `RpcChannel` 统一映射为 `rpc.channel_closed(transportError)`；stdout 关闭后 `incoming` 完成。
- `dispose` 幂等，取消订阅并关闭 `incoming`。

注意：`SidecarProcess.stdout` 是单订阅流，而监督器的就绪探测（`stdout.first`）与传输层订阅会竞争同一流。真实宿主组合两者时需广播化 stdout（用 `asBroadcastStream` 包装或自定义 launcher 注入），e2e 测试中的 `_BroadcastingLauncher` 是参考实现。

## 安装目录布局与原子切换

安装根目录由宿主指定（`rootDir`），每个插件独占以其 ID 命名的子目录：

```text
<rootDir>/
└── <pluginId>/            # 最终安装目录，路径分隔符统一为正斜杠
    ├── plugin.json
    └── echo_sidecar.py
```

写入时序保证崩溃安全：

- 安装：先完整解包到 `<pluginId>.staging`，任何写入异常即清 staging 并返回 `stagingFailed`；提交点是「`<pluginId>.staging` → `<pluginId>` 单次 rename」，已安装时拒绝重复安装且不触碰既有目录。
- 卸载：先把 `<pluginId>` rename 到 `<pluginId>.trash-N`（N 递增探测防撞），再 best-effort 删除；rename 失败返回失败值，既有安装不受影响。

## 安全边界声明

本包提供的是**故障隔离**，不是恶意代码防护：

- 面向对象是**可信的自用插件**；sidecar 与宿主同为用户权限进程，本包不提供白名单、CA 验签、代码签名或沙箱能力。
- sha256 摘要仅用于**传输与落盘完整性校验**（防损坏、防半截包），不是签名：拿到包的攻击者可以重算摘要，篡改检测不能对抗蓄意构造的包。
- 崩溃隔离、超时与意外退出报告约束的是 sidecar **故障**的影响面（不挂死宿主），不约束恶意行为。

宿主如需运行不可信插件，必须在包层之外补充签名校验、最小权限与操作系统级沙箱。

## 验证命令

在本目录（或 workspace 根 `v2/`）执行：

```powershell
dart pub get --offline
dart test
dart format --output=none --set-exit-if-changed .
dart analyze
```

`test/e2e/python_sidecar_e2e_test.dart` 是真实 Python 子进程端到端测试：环境探测到 Python 3（依次尝试 `python`、`python3`、`py -3`）后运行完整安装-通信矩阵；无 Python 3 环境时相关用例自动跳过而非失败。
