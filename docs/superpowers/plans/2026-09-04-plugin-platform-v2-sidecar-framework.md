# Plugin Platform v2 Sidecar Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建桌面 Sidecar 插件的安装（含路径安全与原子切换）、JSON-RPC 帧通信、进程监督框架，并用 Windows Python 夹具完成端到端验证，最终通过 G2 独立安全验收。

**Architecture:** 在 `v2/packages/plugin_sidecar` 新建桌面专属 package：安装与 RPC 的纯逻辑（帧、消息、路径、容器）不依赖 `dart:io`；`dart:io` 只允许出现在两个薄适配文件（文件系统、进程启动）中并通过注入接口供测试替换。监督、通道与安装器全部通过注入的时钟（Delayer）与传输抽象保证确定性测试。

**Tech Stack:** Dart 3.10、Dart workspace、`package:test`、`package:crypto`（sha256）、`dart:io`（仅限两个适配文件）、Python 3 标准库（仅测试夹具）。不引入 Flutter SDK。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（重点 §6 生命周期、§8 Sidecar MVP 安全边界、§13 验收标准）

## Global Constraints

- 继承 Master Plan 全部约束：AI 不执行 Git 命令；同时最多一个子智能体；实现与验收分离；每个任务更新 progress.yaml。
- `plugin_contracts`、`plugin_runtime`、`plugin_devkit` 继续禁止 `dart:io`、Flutter、`dart:ffi`、win32；本阶段不修改这三个包的生产代码（新增 `plugin_sidecar` 对它们的依赖除外，即仅允许修改 `v2/pubspec.yaml` 与新增文件）。
- `plugin_sidecar` 是桌面专属包：其 `lib/` 中 `dart:io` 只允许出现在 `lib/src/process/io_process_launcher.dart` 与 `lib/src/package/io_file_system.dart`；其余文件必须保持纯 Dart。G2 验收执行边界扫描。
- 安全口径与设计规格 §8 一致：目标是可信自用插件的故障隔离，不宣称安全运行恶意代码；摘要不是数字签名；不建设白名单、证书中心或 OS 级沙箱。
- 所有公共错误使用 `PluginFailure` 值对象，错误码见本计划「错误码词汇表」；诊断信息不得包含宿主进程参数或用户主目录等敏感路径。
- 所有任务遵循测试先行：失败测试 → 验证失败 → 最小实现 → 验证通过 → format/analyze → 检查点。
- Python 夹具测试在无 Python 3 环境时必须 skip 并给出原因，不得失败；真实进程类测试用 Dart 子进程保证跨平台可跑。
- Sidecar 清单的 `entrypoint` 语义：安装包内相对路径（posix 风格）；解释器（如 `python.exe`）由宿主在启动时提供，不写入清单。

## 执行策略（用户于 2026-09-04 批准，覆盖默认 TDD 节奏）

1. **测试精简原则**：安全与协议核心场景（路径攻击矩阵、容器完整性、帧协议边界、监督故障注入、e2e）必须保留测试；功能过于简单的交付物（脚手架接线、纯转发）不单独写测试；同一交付物中语义相近的断言合并进少数 test 用例。不为合规而写测试。
2. **验证分层**：每个任务只运行自身的焦点测试（`dart test test/<焦点路径>`）作为快速反馈；workspace 全量 `dart test`、`dart format`、`dart analyze` 与依赖边界扫描**集中在 F2-09 统一执行一次**，不在每个任务后重复。
3. **验收合并**：中间任务不派逐任务独立评审智能体；G2 独立 Sol xhigh 验收一次性审查全部 F2 任务（实现与验收分离的底线不变，G2 硬门不变）。
4. **UI 与艺术风格**：M2 为纯 Dart 框架层，无任何 UI，不涉及视觉设计；M3 涉及 `plugin_flutter` 与宿主 UI 时，**必须先完成艺术风格设计（视觉方向、色彩、字体、布局语言）并经用户确认后才开始 UI 编码**——多端产品中「好看」是必要属性。
5. 派发批次（控制器按任务边界分批，子智能体串行）：批一 F2-01（控制器直接执行）；批二 F2-02～F2-05；批三 F2-06～F2-08；批四 F2-09；批五 G2。



| 错误码 | details.reason 取值 | 产生任务 |
|---|---|---|
| `rpc.frame_invalid` | `tooLarge` \| `empty` \| `invalidUtf8` | F2-02 |
| `rpc.message_invalid` | 无（message 含字段路径，不含 payload 原文） | F2-03 |
| `rpc.timeout` | 无（details 含 methodName、elapsedMs） | F2-07 |
| `rpc.channel_closed` | `closedByCaller` \| `transportError` \| `unexpectedResponse` | F2-07 |
| `rpc.remote_error` | 无（details 携带远端 code/message/data） | F2-07 |
| `package.path_unsafe` | `empty` \| `absolute` \| `traversal` \| `device` \| `backslash` \| `blankSegment` \| `trailingSeparator` \| `nulCharacter` \| `tooLong` \| `duplicate` | F2-04 |
| `package.bad_format` | `badMagic` \| `truncated` \| `indexInvalid` \| `digestMismatch` \| `limitExceeded` \| `manifestMissing` \| `entrypointMissing` | F2-05 |
| `sidecar.install_failed` | `alreadyInstalled` \| `stagingFailed` \| `commitFailed` | F2-06 |
| `sidecar.uninstall_failed` | `notInstalled` \| `renameFailed` | F2-06 |
| `process.start_failed` | `spawnError` \| `exited`（details 含 exitCode） | F2-08 |
| `process.start_timeout` | 无 | F2-08 |
| `process.stop_timeout` | 无 | F2-08 |
| `process.unexpected_exit` | 无（details 含 exitCode） | F2-08 |

---

## 已冻结的技术决策

1. **安装包格式为自定义容器 `SCP1`**（无第三方解压依赖，路径/摘要/上限完全显式可控；M4 CLI 打包器与本计划的 `PackageBuilder` 对称）。
2. **RPC 帧协议为 4 字节大端长度前缀 + UTF-8 JSON payload**，默认帧上限 8 MiB。
3. **进程抽象为注入接口** `SidecarProcessLauncher`，生产实现薄封装 `dart:io` `Process.start`；单测用 fake，真进程测试用 Dart 子进程。
4. **超时确定性**：所有超时通过注入 `typedef Delayer = Future<void> Function(Duration)` 实现，测试中受控推进。
5. **取消语义**：Dart Future 不可取消；「取消」= 关闭通道/停止进程，使所有未完成请求以 `rpc.channel_closed` 或进程失败结果收敛，可预测且无需协议支持。
6. **请求超时后通道关闭**：超时后响应无法再可靠匹配，通道进入 closed，防止响应错配。
7. **原子切换用目录 rename**：`staging → final` 单次 rename 为安装提交点；Windows 无需 symlink 特权。MVP 不做多版本共存，升级 = 卸载 + 安装。
8. **就绪信号协议无关**：supervisor 以「stdout 首字节到达」为启动就绪的弱信号，不内置业务握手。
9. **路径重复检测按大小写折叠**：包内路径在规范化后以 `toLowerCase()` 去重，覆盖 Windows 文件系统大小写不敏感语义。

## 文件结构

```text
v2/
  pubspec.yaml                                  # workspace 增加 plugin_sidecar
  packages/plugin_sidecar/
    pubspec.yaml
    lib/plugin_sidecar.dart                     # 公共导出
    lib/src/rpc/
      rpc_frame_codec.dart                      # F2-02 帧编码 + 增量解码
      rpc_message_codec.dart                    # F2-03 JSON-RPC 消息模型与编解码
      rpc_channel.dart                          # F2-07 关联/超时/关闭
    lib/src/package/
      package_paths.dart                        # F2-04 路径安全验证
      package_builder.dart                      # F2-05 内存打包器
      package_reader.dart                       # F2-05 容器读取与完整性校验
      install_state_machine.dart                # F2-06 安装生命周期状态机
      sidecar_installer.dart                    # F2-06 原子安装/卸载编排
      io_file_system.dart                       # F2-06 dart:io 文件系统适配（唯一 IO 点之一）
    lib/src/process/
      sidecar_process.dart                      # F2-08 进程抽象与 spawn 描述
      sidecar_supervisor.dart                   # F2-08 监督/超时/回收
      io_process_launcher.dart                  # F2-08 dart:io 进程适配（唯一 IO 点之一）
      stdio_rpc_transport.dart                  # F2-09 进程 stdio ↔ 帧通道适配
    test/rpc/rpc_frame_codec_test.dart
    test/rpc/rpc_message_codec_test.dart
    test/rpc/rpc_channel_test.dart
    test/package/package_paths_test.dart
    test/package/package_builder_test.dart
    test/package/package_reader_test.dart
    test/package/install_state_machine_test.dart
    test/package/sidecar_installer_test.dart
    test/process/sidecar_supervisor_test.dart
    test/process/io_process_launcher_test.dart
    test/process/stdio_rpc_transport_test.dart
    test/e2e/python_sidecar_e2e_test.dart
    test/fixtures/dart/echo_child.dart          # F2-08 真进程夹具（Dart 子进程）
    test/fixtures/python/echo_sidecar.py        # F2-09 Windows 端到端夹具
    README.md                                   # F2-09
```

安装目录布局（`root` 由宿主传入）：

```text
<root>/<pluginId>/            # 最终安装目录（staging 整体 rename 而来）
<root>/<pluginId>.staging/    # 解包暂存
<root>/<pluginId>.trash-N/    # 卸载 rename 落点，删除为 best-effort
```

`SCP1` 容器字节布局：

```text
offset 0            magic，固定 ASCII "SCP1"（4 字节）
offset 4            u32 大端：索引 JSON 字节长度
offset 8            索引 JSON（UTF-8，严格解码，未知字段拒绝）
offset 8+indexLen   条目字节按索引顺序连续存放

索引 JSON 形状：
{
  "entries": [
    {"path": "plugin.json", "length": 123, "sha256": "<64 位小写 hex>"}
  ]
}
限制：entries 数量 1..4096；单条目 ≤ 64 MiB；总条目字节 ≤ 256 MiB；
索引长度 ≤ 1 MiB；path=="plugin.json" 的条目必须存在（manifestMissing）。
```

JSON-RPC 消息（严格子集）：

```text
所有消息必须是 JSON object，未知字段拒绝，jsonrpc 必须恰好为 "2.0"。
request      : method 非空 string；params 若出现必须是 object；id 为非负 int 或非空 string
notification : 同 request 但不得含 id 字段
success      : 必须含 id（同上限制）与 result（可为 null），不得含 error
error        : 必须含 id（可为 null，表示无法定位请求）；error 为
               {code:int, message:string, data?:任意}
标准错误码保留：-32700 -32600 -32601 -32602 -32603；应用错误码 ≥ 1
```

帧格式：

```text
u32 大端 payloadLength（必须 1..maxFrameBytes，默认 8 MiB）
payloadLength 字节 UTF-8 JSON
```

---

## Task F2-01：创建 plugin_sidecar package 骨架

**Files:**

- Modify: `v2/pubspec.yaml`
- Create: `v2/packages/plugin_sidecar/pubspec.yaml`
- Create: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`
- Create: `v2/packages/plugin_sidecar/analysis_options.yaml`（若 workspace 根已覆盖则不建，沿用根配置）

**Interfaces:**

- Consumes: `v2/pubspec.yaml` 的 workspace 机制；`plugin_contracts` 公共 API。
- Produces: 可被 workspace 解析的 `plugin_sidecar` package，运行时依赖 `plugin_contracts` 与 `crypto`，开发依赖 `lints`、`test`。

- [ ] **Step 1：写入任务卡**

在 progress.yaml 增加 `F2-01` 条目，状态 `in_progress`，记录文件范围、实现者（Sol xhigh）和验证命令。

- [ ] **Step 2：注册 workspace 成员**

`v2/pubspec.yaml` 的 `workspace` 列表追加 `- packages/plugin_sidecar`。

- [ ] **Step 3：创建 pubspec**

```yaml
name: plugin_sidecar
publish_to: none
resolution: workspace
environment:
  sdk: ^3.10.0
dependencies:
  crypto: ^3.0.0
  plugin_contracts:
    path: ../plugin_contracts  # workspace resolution 生效时此段可省，保持与现有包一致写法
dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
```

实际依赖声明方式必须与 `plugin_runtime` 现有 pubspec 的 workspace 写法完全一致（先读该文件再照抄模式）。

- [ ] **Step 4：创建空导出**

`lib/plugin_sidecar.dart` 初始内容为带 library 注释的空导出文件。骨架不写测试（执行策略第 1 条）。

- [ ] **Step 5：运行解析与验证**

Working directory: `v2`

Run: `dart pub get`
Expected: 解析成功。

Run: `dart pub workspace list`
Expected: 列出四个 package。

Run: `dart analyze`
Expected: 0 errors。

- [ ] **Step 6：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(sidecar): scaffold sidecar package`。

## Task F2-02：实现 RPC 帧编解码

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/rpc/rpc_frame_codec.dart`
- Create: `v2/packages/plugin_sidecar/test/rpc/rpc_frame_codec_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `PluginFailure`。
- Produces:

```dart
const int defaultMaxFrameBytes = 8 * 1024 * 1024;

Uint8List encodeFrame(String payload, {int maxFrameBytes = defaultMaxFrameBytes});

final class RpcFrameDecoder {
  RpcFrameDecoder({this.maxFrameBytes = defaultMaxFrameBytes});
  final int maxFrameBytes;
  void addBytes(List<int> chunk);
  List<String> drainFrames(); // 取出已完整帧的 payload，无完整帧返回空表
  void reset();
}

final class RpcFrameException implements Exception {
  RpcFrameException(this.failure);
  final PluginFailure failure; // code: rpc.frame_invalid
}
```

- [ ] **Step 1：写入任务卡**

F2-02 标记 `in_progress`；注明解码器为增量式、可跨多次 `addBytes` 拼帧。

- [ ] **Step 2：编写失败测试**

覆盖矩阵（全部写入 `rpc_frame_codec_test.dart`）：

```dart
test('encode/decode round trip', () {
  final bytes = encodeFrame('{"jsonrpc":"2.0"}');
  final decoder = RpcFrameDecoder();
  decoder.addBytes(bytes);
  expect(decoder.drainFrames(), ['{"jsonrpc":"2.0"}']);
});

test('half frames delivered one byte at a time', () {
  final bytes = encodeFrame('ok');
  final decoder = RpcFrameDecoder();
  for (final b in bytes) {
    decoder.addBytes([b]);
    expect(decoder.drainFrames(), isEmpty); // 未完整前不产出
  }
  expect(decoder.drainFrames(), ['ok']);
});

test('multiple frames coalesced in one chunk', () {
  final decoder = RpcFrameDecoder();
  decoder.addBytes([...encodeFrame('a'), ...encodeFrame('bb')]);
  expect(decoder.drainFrames(), ['a', 'bb']);
});

test('declared length above limit fails before payload arrives', () {
  final decoder = RpcFrameDecoder(maxFrameBytes: 16);
  final header = ByteData(4)..setUint32(0, 17);
  expect(
    () => decoder.addBytes(header.buffer.asUint8List()),
    throwsA(isA<RpcFrameException>()),
  );
});

test('zero length frame is rejected', () {
  final decoder = RpcFrameDecoder();
  final header = ByteData(4)..setUint32(0, 0);
  expect(
    () => decoder.addBytes(header.buffer.asUint8List()),
    throwsA(isA<RpcFrameException>()),
  );
});

test('non utf-8 payload is rejected', () {
  final header = ByteData(4)..setUint32(0, 1);
  final decoder = RpcFrameDecoder();
  decoder.addBytes(header.buffer.asUint8List());
  expect(() => decoder.addBytes([0xFF]), throwsA(isA<RpcFrameException>()));
});

test('reset discards partial state', () {
  final decoder = RpcFrameDecoder();
  decoder.addBytes(encodeFrame('abc').take(3).toList());
  decoder.reset();
  decoder.addBytes(encodeFrame('z'));
  expect(decoder.drainFrames(), ['z']);
});

test('exception carries structured failure', () {
  PluginFailure? captured;
  try {
    final decoder = RpcFrameDecoder(maxFrameBytes: 4);
    final header = ByteData(4)..setUint32(0, 5);
    decoder.addBytes(header.buffer.asUint8List());
  } on RpcFrameException catch (e) {
    captured = e.failure;
  }
  expect(captured?.code, 'rpc.frame_invalid');
  expect(captured?.details['reason'], 'tooLarge');
});
```

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_sidecar`
Run: `dart test test/rpc/rpc_frame_codec_test.dart`
Expected: 因符号不存在而编译失败。

- [ ] **Step 4：最小实现**

`encodeFrame` 断言 UTF-8 字节数 ≤ maxFrameBytes（超限抛 `RpcFrameException`，reason `tooLarge`）。解码器内部维护 `BytesBuilder` 缓冲：不足 4 字节头等待；长度为 0 → `empty`；长度超限 → `tooLarge`（立即抛，不等 payload）；凑满 payload 后以严格 `utf8.decode`（`allowMalformed: false`）解码，失败 → `invalidUtf8`。`PluginFailure.details` 携带 `reason` 与已接收字节数。

- [ ] **Step 5：运行测试与分析**

Run: `dart test test/rpc/rpc_frame_codec_test.dart` → PASS
Run: `dart test` → PASS
Run: `dart analyze` → 0 errors

- [ ] **Step 6：记录检查点**

状态 `verified_pending_acceptance`，建议提交信息 `feat(sidecar): add length-prefixed rpc frame codec`。

## Task F2-03：实现 JSON-RPC 消息模型与严格编解码

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/rpc/rpc_message_codec.dart`
- Create: `v2/packages/plugin_sidecar/test/rpc/rpc_message_codec_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: 无项目内部依赖（纯 Dart + `dart:convert`）。
- Produces:

```dart
sealed class RpcMessage { const RpcMessage(); }
final class RpcRequest extends RpcMessage {
  const RpcRequest({required this.id, required this.method, this.params});
  final Object id; // int >= 0 或非空 String
  final String method;
  final Map<String, Object?>? params;
}
final class RpcNotification extends RpcMessage {
  const RpcNotification({required this.method, this.params});
  final String method;
  final Map<String, Object?>? params;
}
final class RpcSuccess extends RpcMessage {
  const RpcSuccess({required this.id, required this.result});
  final Object id;
  final Object? result;
}
final class RpcError extends RpcMessage {
  const RpcError({required this.id, required this.code, required this.message, this.data});
  final Object? id; // 可为 null（无法定位请求）
  final int code;
  final String message;
  final Object? data;
}

RpcMessage decodeRpcMessage(String payload); // 非法抛 FormatException（消息含字段路径）
String encodeRpcMessage(RpcMessage message);
```

- [ ] **Step 1：写入任务卡**

F2-03 标记 `in_progress`；注明严格解码语义与 F1-03 清单解码一致：未知字段拒绝、错误消息不包含 payload 原文。

- [ ] **Step 2：编写失败测试**

覆盖矩阵：

```text
decode:
  合法 request/notification/success/error 各往返 encode 后字节一致
  jsonrpc 缺失 / 非 "2.0" → FormatException
  未知字段（如 "foo"）→ FormatException，消息含字段名
  method 空串 / params 为数组 → FormatException
  request id 为负数 / 空串 / null → FormatException
  notification 含 id → FormatException
  success 与 error 同时出现 / 同时缺失 → FormatException
  error.code 非 int / error.message 空 → FormatException
  顶层非 object（数组/字符串/数字）→ FormatException
  payload 非 JSON → FormatException
encode:
  构造参数非法（负 id、空 method）→ ArgumentError
脱敏：
  所有 FormatException 消息不包含 payload 中的值原文，只含字段路径
```

- [ ] **Step 3：验证测试先失败**

Run: `dart test test/rpc/rpc_message_codec_test.dart`
Expected: 编译失败（类型不存在）。

- [ ] **Step 4：最小实现**

解码按「顶层形状 → 必备字段 → 字段集合严格匹配 → 逐字段类型」顺序；id 校验封装为私有函数 `_validateId(Object? value, {bool allowNull})`；encode 前对构造约束做 ArgumentError 防御。

- [ ] **Step 5：运行测试与分析**

Run: `dart test` → PASS；`dart analyze` → 0 errors。

- [ ] **Step 6：记录检查点**

建议提交信息 `feat(sidecar): add strict json-rpc message codec`。

## Task F2-04：实现安装包路径安全验证

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/package/package_paths.dart`
- Create: `v2/packages/plugin_sidecar/test/package/package_paths_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `PluginFailure`。
- Produces:

```dart
const int maxEntryPathLength = 1024;

/// 校验安装包内单条相对路径；合法返回规范化 posix 相对路径，非法返回 PluginFailure。
Object validatePackagePath(String rawPath);
// 返回值使用 record：({String normalized, PluginFailure? failure})
// 合法时 failure == null；非法时 normalized 为空且 failure.code == 'package.path_unsafe'

/// 对整包路径集合做重复检测（大小写折叠）。返回首个冲突或 null。
PluginFailure? detectDuplicatePaths(Iterable<String> normalizedPaths);
```

- [ ] **Step 1：写入任务卡**

F2-04 标记 `in_progress`；注明这是 G2 安全验收的核心攻击面之一。

- [ ] **Step 2：编写失败测试（攻击矩阵）**

```text
合法：'plugin.json'、'a/b.py'、'assets/data/x.json'、含 '.' 文件名 'main.py'（点号在段内合法）
拒绝（断言 code == 'package.path_unsafe' 与对应 reason）：
  ''                                              → empty
  'C:/x'、'c:\\x'、'/abs'                         → absolute
  '../x'、'a/../../x'、'..'                       → traversal
  '\\\\.\\x'、'\\\\?\\C:\\x'、'CON'、'NUL'、'COM1'、'LPT9'、'con.txt'  → device
  'a\\b'                                          → backslash
  'a//b'                                            → blankSegment（以 `/` 开头的路径统一归 absolute，F2-04 实现时澄清）
  'a/'                                            → trailingSeparator
  'a\x00b'                                        → nulCharacter
  长度 > 1024                                     → tooLong
  段名 > 255 字符                                 → tooLong
detectDuplicatePaths：
  ['a/B.json', 'A/b.JSON']                        → 冲突（大小写折叠）
  ['a/b', 'c/b']                                  → 无冲突
```

- [ ] **Step 3：验证测试先失败**

Run: `dart test test/package/package_paths_test.dart`
Expected: 编译失败。

- [ ] **Step 4：最小实现**

按「空检查 → 反斜杠 → NUL → 绝对路径（`/` 开头、盘符正则 `^[a-zA-Z]:`、`\\\\` 开头）→ 长度 → `/` 分段 → 逐段：空段 / `.` / `..` → Windows 保留名集合 `{CON,PRN,AUX,NUL,COM1..9,LPT1..9}` 与段名去扩展名后比对（大小写不敏感）」的顺序校验；规范化 = 原样返回（输入已是 posix 相对路径，不做多余改写）。`details` 携带 `reason` 与脱敏后的段位置，不携带宿主路径。

- [ ] **Step 5：运行测试与分析**

Run: `dart test` → PASS；`dart analyze` → 0 errors。

- [ ] **Step 6：记录检查点**

建议提交信息 `feat(sidecar): add package path safety validation`。

## Task F2-05：实现 SCP1 容器读取、完整性与打包器

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/package/package_builder.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/package/package_reader.dart`
- Create: `v2/packages/plugin_sidecar/test/package/package_builder_test.dart`
- Create: `v2/packages/plugin_sidecar/test/package/package_reader_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `PluginFailure`、`PluginManifestCodec.decode`、`validatePackagePath`、`detectDuplicatePaths`、`crypto` 的 `sha256`。
- Produces:

```dart
final class PackageEntry {
  const PackageEntry({required this.path, required this.bytes});
  final String path;        // 已验证的规范化相对路径
  final List<int> bytes;
}

final class SidecarPackage {
  const SidecarPackage({required this.manifest, required this.entries});
  final PluginManifest manifest;        // kind 必须为 PluginKind.sidecar
  final List<PackageEntry> entries;     // 含 manifest 条目
  PackageEntry? entryByPath(String path);
}

final class PackageBuilder {
  PackageBuilder add(String path, List<int> bytes);
  Uint8List build(); // 至少包含 plugin.json；条目按加入顺序写入
}

final class PackageReader {
  PackageReader.fromBytes(Uint8List bytes, {this.limits = const PackageLimits()});
  SidecarPackage read(); // 任何违规抛 PackageException(failure: package.bad_format)
}
// 决策：不提供 fromFile。字节读取由调用方（F2-06 installer 经 PackageFileSystem）
// 完成，保持 package_reader.dart 纯 Dart、无 dart:io。

final class PackageLimits {
  const PackageLimits({
    this.maxEntries = 4096,
    this.maxEntryBytes = 64 * 1024 * 1024,
    this.maxTotalBytes = 256 * 1024 * 1024,
    this.maxIndexBytes = 1024 * 1024,
  });
}

final class PackageException implements Exception {
  PackageException(this.failure);
  final PluginFailure failure;
}
```

- [ ] **Step 1：写入任务卡**

F2-05 标记 `in_progress`；注明格式常量（magic、限制值）为公共契约，G2 按此表核查。

- [ ] **Step 2：编写失败测试**

builder 测试：往返（build → reader.read → manifest 与条目一致）、摘要为 64 位小写 hex、至少两条目索引顺序稳定、缺 plugin.json 抛错。

reader 测试（全部用 builder 产物或对其字节做篡改构造）：

```text
好包往返                                       → manifest 字段与源一致
篡改魔数 'SCP2'                                 → badMagic
截断（去掉最后 10 字节 / 只留 6 字节）           → truncated
索引长度字段超出实际字节                         → truncated
索引非严格 JSON / 含未知字段 / 条目缺字段        → indexInvalid
某条目 sha256 改一位                            → digestMismatch
某条目 length 与实际不符                         → digestMismatch 或 truncated
条目数 > maxEntries / 单条 > maxEntryBytes /
总字节 > maxTotalBytes / 索引 > maxIndexBytes   → limitExceeded（用小 limits 构造）
缺 'plugin.json' 条目                           → manifestMissing
manifest 内容不是合法 sidecar 清单（kind=builtin / entrypoint 条目不存在）→ entrypointMissing 或 indexInvalid
manifest.json 合法但 entrypoint 'run.py' 无对应条目 → entrypointMissing
含路径攻击条目（'../x'）                         → PackageException 内嵌 package.path_unsafe
含大小写重复条目                                 → package.path_unsafe duplicate
```

- [ ] **Step 3：验证测试先失败**

Run: `dart test test/package`
Expected: 编译失败。

- [ ] **Step 4：最小实现**

builder：对每条 path 先 `validatePackagePath`，逐条目算 sha256，索引 JSON 用稳定字段顺序序列化。reader：校验魔数与版本 → 长度限制 → 索引严格解码（逐条目字段与形状，错误归入 `indexInvalid`）→ 路径安全与重复检测 → 逐条目切分字节并算摘要比对 → 取 `plugin.json` 用 `PluginManifestCodec.decode` → 校验 `kind == PluginKind.sidecar` 且 `manifest.entrypoint` 有对应条目。reader 全程操作内存字节，不触碰 `dart:io`。

- [ ] **Step 5：运行测试与分析**

Run: `dart test` → PASS；`dart analyze` → 0 errors。

- [ ] **Step 6：记录检查点**

建议提交信息 `feat(sidecar): add scp1 package format reader and builder`。

## Task F2-06：实现安装状态机与原子安装/卸载

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/package/install_state_machine.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/package/sidecar_installer.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/package/io_file_system.dart`
- Create: `v2/packages/plugin_sidecar/test/package/install_state_machine_test.dart`
- Create: `v2/packages/plugin_sidecar/test/package/sidecar_installer_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `SidecarPackage`、`PluginId`、`PluginFailure`、`dart:io`（仅 `io_file_system.dart`）。
- Produces:

```dart
enum SidecarInstallState { notInstalled, installing, installed, uninstalling }

final class InstallStateMachine {
  InstallStateMachine(this.pluginId);
  final PluginId pluginId;
  SidecarInstallState get state;
  InstallTransitionResult transitionTo(SidecarInstallState requested);
  // 合法转换：notInstalled→installing→installed→uninstalling→notInstalled
  // installing→notInstalled（失败回退）、uninstalling→installed（卸载失败回退）合法
  // 其余非法，返回 PluginFailure('sidecar.install_state.invalid_transition')
}

abstract interface class PackageFileSystem {
  Future<void> createDir(String path, {bool recursive = true});
  Future<bool> exists(String path);
  Future<void> writeFile(String path, List<int> bytes);
  Future<void> deleteTree(String path);          // 不存在时为 no-op
  Future<void> renameDir(String from, String to);
}

final class IoPackageFileSystem implements PackageFileSystem; // dart:io 适配

final class SidecarInstaller {
  SidecarInstaller({required this.fs, required this.rootDir});
  final PackageFileSystem fs;
  final String rootDir;
  Future<InstallOutcome> install(SidecarPackage package);
  Future<InstallOutcome> uninstall(PluginId id);
  Future<bool> isInstalled(PluginId id);
}
// InstallOutcome: succeeded 标志 + PluginFailure? failure + SidecarInstallState state
```

installer 读包的路径：宿主经 `fs` 接口读入包文件字节，再 `PackageReader.fromBytes` 解析（F2-05 已冻结该决策，无 `fromFile` API）。install 接口因此增加可选入口：

```dart
Future<InstallOutcome> install(SidecarPackage package);   // 已解析的包
Future<InstallOutcome> installBytes(Uint8List packageBytes); // 便捷入口：内部 fromBytes + install
```

- [ ] **Step 1：写入任务卡**

F2-06 标记 `in_progress`；注明目录名只来自已验证 `PluginId.value`，无其他字符串拼接。

- [ ] **Step 2：编写状态机失败测试**

覆盖：合法链 `notInstalled→installing→installed→uninstalling→notInstalled`；失败回退 `installing→notInstalled`、`uninstalling→installed`；非法 `notInstalled→installed`、`installed→installing`、`notInstalled→uninstalling`；终态保护无（安装状态机无终态，与运行状态机不同）；非法转换返回结构化 failure 且状态不变。

- [ ] **Step 3：编写安装器失败测试**

测试用 `Directory.systemTemp.createTemp` 建真实根目录 + `IoPackageFileSystem`（真实文件系统更可信；跨平台在 Windows 开发机运行）：

```text
install 成功：目录 <root>/<id>/ 出现全部条目；isInstalled == true；状态机到 installed
重复 install                                  → alreadyInstalled，原目录未被触碰
解包前 staging 残留                           → 先清理 staging 再写
写入条目时 fs 抛异常（注入 fake fs）           → stagingFailed，staging 被清理，状态回 notInstalled
rename 抛异常（注入 fake fs）                  → commitFailed，staging 被清理
uninstall 成功                                → 目录消失，trash 已清，状态 notInstalled
uninstall 不存在                              → notInstalled
uninstall 时 rename 失败（注入 fake fs）       → renameFailed，状态回 installed
trash 删除失败（注入 fake fs）                 → 仍算成功，failure == null（best-effort）
install 后清单 entrypoint 文件确实存在
```

- [ ] **Step 4：验证测试先失败**

Run: `dart test test/package/install_state_machine_test.dart test/package/sidecar_installer_test.dart`
Expected: 编译失败。

- [ ] **Step 5：最小实现**

install 流程：`transitionTo(installing)` → 清 `<id>.staging` → 逐条目写 staging（任何异常 → 清 staging → `stagingFailed` → 回退 notInstalled）→ 存在 `<id>` 则 `alreadyInstalled`（先清 staging）→ `renameDir(staging, <id>)` 为提交点（失败 → `commitFailed`）→ `installed`。uninstall：`transitionTo(uninstalling)` → `renameDir(<id>, <id>.trash-N)`（N 递增防撞；失败 → `renameFailed` 回 installed）→ `deleteTree(trash)` best-effort → `notInstalled`。`IoPackageFileSystem` 用 `Directory`/`File` API；`renameDir` 直接映射 `Directory.rename`。

- [ ] **Step 6：运行测试、格式化与分析**

Run: `dart test` → PASS；`dart format --output=none --set-exit-if-changed .` → 0；`dart analyze` → 0 errors。

- [ ] **Step 7：记录检查点**

建议提交信息 `feat(sidecar): add atomic installer with install lifecycle`。

## Task F2-07：实现 RPC 通道（关联、超时、关闭）

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/rpc/rpc_channel.dart`
- Create: `v2/packages/plugin_sidecar/test/rpc/rpc_channel_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `encodeFrame`、`RpcFrameDecoder`、`encodeRpcMessage`、`decodeRpcMessage`、`PluginFailure`。
- Produces:

```dart
typedef Delayer = Future<void> Function(Duration duration);

abstract interface class RpcTransport {
  void send(String payload);       // 上层负责帧编码后的写出；抛异常视为传输错误
  Stream<String> get incoming;     // 已解码的帧 payload 流
}

final class RpcCallResult {
  const RpcCallResult({this.value, this.failure});
  final Object? value;             // 远端 result
  final PluginFailure? failure;    // rpc.timeout / rpc.remote_error / rpc.channel_closed
}

final class RpcChannel {
  RpcChannel({
    required RpcTransport transport,
    required Delayer delayer,
    required Duration requestTimeout,
    RpcFrameDecoder? decoder,       // 注入便于测试；默认新建
  });
  bool get isClosed;
  Future<RpcCallResult> call(String method, [Map<String, Object?>? params]);
  void notify(String method, [Map<String, Object?>? params]);
  void close();                     // 所有 pending 以 rpc.channel_closed(closedByCaller) 完成
}
```

- [ ] **Step 1：写入任务卡**

F2-07 标记 `in_progress`；注明「请求超时后通道关闭」与「取消 = close」两项已冻结决策。

- [ ] **Step 2：编写失败测试（用内存 fake transport + 受控 delayer）**

```text
call 收到匹配 id 的 success       → value 正确
并发 3 个 call 乱序响应           → 各自按 id 匹配
call 收到 error response          → failure.code == rpc.remote_error，details 带远端 code/message
delayer 到期无响应                → rpc.timeout（details methodName/elapsedMs），通道关闭
超时后迟到的响应                   → 通道已 closed；pending 均已 rpc.channel_closed 完成
响应 id 无对应 pending            → 通道关闭，pending 以 rpc.channel_closed(unexpectedResponse) 完成
transport.send 抛异常             → transportError，通道关闭
incoming 喂非法 JSON payload      → rpc.message_invalid 以 failure 完成当前/后续 call 并关闭通道
close 后再 call                   → 立即 rpc.channel_closed(closedByCaller)
notify 不产生 pending             → 只发送
id 分配从 0 递增 int，不与远端 id 冲突
```

- [ ] **Step 3：验证测试先失败**

Run: `dart test test/rpc/rpc_channel_test.dart`
Expected: 编译失败。

- [ ] **Step 4：最小实现**

通道持有 `Map<int, Completer<RpcCallResult>>`；`call` 注册 completer、`encodeRpcMessage(RpcRequest(...))` 经 `encodeFrame` 后 `transport.send`、`delayer(requestTimeout)` 竞速（`Future.any` 语义，首个完成胜出；delayer 分支先触发 pending 清理 + `rpc.timeout` + `_closeTransport(reason: timeout 引发的关闭不额外发 failure 码，pending 已按各自结果完成)`）。incoming 流订阅：`decodeRpcMessage` 失败或非 response（收到 request/notification）视为协议违规 → 关闭并使 pending 以 `rpc.message_invalid` 失败。关闭实现统一 `_close(reason)`：置位、取消订阅、`transport.send` 不再调用。

- [ ] **Step 5：运行测试与分析**

Run: `dart test` → PASS；`dart analyze` → 0 errors。

- [ ] **Step 6：记录检查点**

建议提交信息 `feat(sidecar): add rpc channel with timeout and cancellation`。

## Task F2-08：实现进程抽象、IO 启动器与监督器

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/process/sidecar_process.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/process/sidecar_supervisor.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/process/io_process_launcher.dart`
- Create: `v2/packages/plugin_sidecar/test/process/sidecar_supervisor_test.dart`
- Create: `v2/packages/plugin_sidecar/test/process/io_process_launcher_test.dart`
- Create: `v2/packages/plugin_sidecar/test/fixtures/dart/echo_child.dart`
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`

**Interfaces:**

- Consumes: `PluginFailure`、`Delayer`。
- Produces:

```dart
final class SidecarSpawn {
  const SidecarSpawn({required this.executable, this.arguments = const [], this.workingDirectory});
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}

abstract interface class SidecarProcess {
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;
  Future<void> kill();
  Future<void> writeStdin(List<int> bytes); // RpcTransport 写帧用
  Future<void> closeStdin();                // 关闭时回收 stdin
}

abstract interface class SidecarProcessLauncher {
  Future<SidecarProcess> start(SidecarSpawn spawn);
}

final class IoProcessLauncher implements SidecarProcessLauncher; // dart:io Process.start

final class SidecarSupervisor {
  SidecarSupervisor({
    required SidecarProcessLauncher launcher,
    required Delayer delayer,
    required this.startupTimeout,
    this.stopGracePeriod = const Duration(seconds: 5),
  });
  final Duration startupTimeout;
  final Duration stopGracePeriod;

  /// spawn + 等待 stdout 首字节作为就绪弱信号；
  /// 进程先退出 → process.start_failed(details: exitCode)
  /// 超时无首字节 → kill + process.start_timeout
  Future<SupervisedStartResult> start(
    SidecarSpawn spawn, {
    void Function(PluginFailure failure)? onUnexpectedExit,
  });

  Future<StopResult> stop(SidecarProcess process); // kill → 等 exitCode ≤ grace；超时 → process.stop_timeout
  Future<void> disposeAll();                       // 逆序 stop 所有存活进程（宿主关闭回收）
  bool get hasAlive;
}

// SupervisedStartResult: process + failure?；StopResult: failure?
```

- [ ] **Step 1：写入任务卡**

F2-08 标记 `in_progress`；注明监督逻辑只依赖注入接口，`dart:io` 仅存在于 `io_process_launcher.dart`。

- [ ] **Step 2：编写监督器失败测试（fake launcher + 受控 delayer）**

```text
start 成功：fake process stdout 广播首字节           → 就绪
start 超时：stdout 永不出字节，delayer 先完成          → start_timeout，kill 被调用
启动即退出：exitCode 先完成                           → start_failed(details exitCode)
launcher.start 抛异常                                 → start_failed(spawnError)
stop 正常：kill 后 exitCode 完成                      → success
stop 超时：kill 后 exitCode 永不完成，delayer 先完成    → stop_timeout
意外退出回调：就绪后 exitCode 完成                     → onUnexpectedExit 收到 process.unexpected_exit(details exitCode)
disposeAll：两个存活进程都被 stop，且 hasAlive == false
disposeAll 幂等：二次调用 no-op
```

- [ ] **Step 3：编写 IO 启动器真进程测试**

夹具 `test/fixtures/dart/echo_child.dart`（完整内容）：

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  // 就绪信号：立即写一个最小帧
  void writeFrame(String payload) {
    final data = utf8.encode(payload);
    final header = ByteData(4)..setUint32(0, data.length, Endian.big);
    stdout.add(header.buffer.asUint8List());
    stdout.add(data);
  }

  writeFrame('ready');
  await stdout.flush();
  // 常驻直到被 kill；被 kill 后以非零码退出属预期
  await Completer<void>().future;
}
```

测试：`IoProcessLauncher.start(SidecarSpawn(executable: Platform.resolvedExecutable, arguments: [<echo_child.dart 绝对路径>]))` → stdout 收到 `ready` 帧 → `kill()` → `exitCode` 完成且非零。标注 `@Timeout(Duration(seconds: 30))`。

- [ ] **Step 4：验证测试先失败**

Run: `dart test test/process`
Expected: 编译失败。

- [ ] **Step 5：最小实现**

监督器 `start`：`launcher.start` 异常 → `start_failed(spawnError)`；随后 `Future.any` 竞速 `process.stdout.first`（丢弃字节内容仅取事件）、`process.exitCode`（→ `start_failed`）、`delayer(startupTimeout)`（→ kill + `start_timeout`）。就绪后把 `process.exitCode` 挂到 `onUnexpectedExit`。`stop`：`kill()` → `Future.any(exitCode, delayer(stopGracePeriod))`。`disposeAll` 逆序遍历内部存活表。`IoProcessLauncher` 直接映射 `Process.start(executable, arguments, workingDirectory: ...)`，stdout/stderr/exitCode/kill 透传（`kill()` 用默认 `ProcessSignal.sigterm`，Windows 上等价 TerminateProcess）。

- [ ] **Step 6：运行测试与分析**

Run: `dart test` → PASS；`dart analyze` → 0 errors。

- [ ] **Step 7：记录检查点**

建议提交信息 `feat(sidecar): add process supervision with timeouts and cleanup`。

## Task F2-09：Windows Python 端到端夹具、文档与 G2 验收

**Files:**

- Create: `v2/packages/plugin_sidecar/test/fixtures/python/echo_sidecar.py`
- Create: `v2/packages/plugin_sidecar/test/e2e/python_sidecar_e2e_test.dart`
- Create: `v2/packages/plugin_sidecar/lib/src/process/stdio_rpc_transport.dart`
- Create: `v2/packages/plugin_sidecar/test/process/stdio_rpc_transport_test.dart`
- Create: `v2/packages/plugin_sidecar/README.md`
- Modify: `v2/README.md`（追加 M2 边界段）
- Create: `docs/superpowers/acceptance/v2-sidecar-framework-acceptance.md`（G2 报告，由验收智能体产出）

**Interfaces:**

- Consumes: F2-02～F2-08 全部公共 API：`PackageBuilder`、`PackageReader.fromBytes`、`SidecarInstaller`、`IoPackageFileSystem`、`IoProcessLauncher`、`SidecarSupervisor`、`RpcChannel`、帧与消息编解码。
- Produces: `StdioRpcTransport`（`implements RpcTransport`，绑定 `SidecarProcess` 的 stdio）；端到端证据、包文档、G2 验收报告。

- [ ] **Step 1：写入任务卡**

F2-09 标记 `in_progress`；注明 Python 缺失时全部 e2e skip 且测试名含原因。

- [ ] **Step 2：编写 Python 夹具（完整内容）**

`test/fixtures/python/echo_sidecar.py`：

```python
"""Echo sidecar fixture: length-prefixed JSON-RPC over stdio."""
import json
import struct
import sys


def read_frame():
    header = sys.stdin.buffer.read(4)
    if len(header) < 4:
        return None
    (length,) = struct.unpack(">I", header)
    body = sys.stdin.buffer.read(length)
    return json.loads(body.decode("utf-8"))


def write_frame(obj):
    data = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    sys.stdout.buffer.write(struct.pack(">I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def handle(msg):
    method = msg.get("method")
    if method == "ping":
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": "pong"})
    elif method == "echo":
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": msg.get("params")})
    elif method == "stderrNoise":
        sys.stderr.write("noise\n")
        sys.stderr.flush()
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": "ok"})
    elif method == "hang":
        pass  # intentional no-reply for timeout testing
    elif method == "crash":
        sys.exit(1)
    else:
        write_frame({
            "jsonrpc": "2.0",
            "id": msg.get("id"),
            "error": {"code": -32601, "message": "Method not found"},
        })


def main():
    # 就绪信号：supervisor 以 stdout 首字节为启动就绪。纯字符串帧（非 JSON-RPC），
    # 且必须先于通道订阅广播流发出——通道不得消费此帧（G2 裁定的实际实现形态）
    write_frame("ready")
    while True:
        msg = read_frame()
        if msg is None:
            break
        handle(msg)


if __name__ == "__main__":
    main()
```

- [ ] **Step 3：编写端到端测试**

Python 探测：测试 setUp 用 `Process.runSync('python', ['--version'])`，失败则 `markTestSkipped('python 3 not available')`。场景矩阵（每场景独立临时 root，串行）：

```text
1  PackageBuilder 构造含 plugin.json（sidecar 清单，entrypoint=echo_sidecar.py）
   + echo_sidecar.py → 安装 → installed，目录含两文件
2  supervisor 启动（executable=python, arguments=[<installDir>/echo_sidecar.py]）→ 就绪
3  RpcChannel call('ping') → 'pong'
4  call('echo', {...}) → 参数原样返回
5  call('stderrNoise') → 'ok'，通信不受 stderr 干扰
6  call('hang') → rpc.timeout，通道关闭
7  新通道 call('crash') → onUnexpectedExit 收到 process.unexpected_exit
8  stop → exitCode 回收；再次 install（先 uninstall）成功
9  篡改摘要的坏包 → 安装拒绝 package.bad_format(digestMismatch)，原安装不受影响
10 uninstall → 目录消失 → isInstalled == false
```

通道与进程的接线由 `StdioRpcTransport`（公共 API，M3 宿主复用）完成：`send(payload)` → `encodeFrame` → `SidecarProcess.writeStdin`；`incoming` = `process.stdout` 经 `RpcFrameDecoder` 解码成的 payload 流。该文件只依赖 `SidecarProcess` 抽象，不 import `dart:io`。本任务创建 `stdio_rpc_transport.dart` 并附最小单测（fake process 验证写入转发与流式解码）。

- [ ] **Step 4：运行全部验证**

Working directory: `v2`

Run: `dart test` → 全 PASS（含 e2e，或明确 skip 记录）
Run: `dart format --output=none --set-exit-if-changed .` → 0
Run: `dart analyze` → 0 errors

依赖边界扫描（G2 前置自检）：在 `plugin_contracts`、`plugin_runtime`、`plugin_devkit` 的 `lib/` 中 grep `dart:io|dart:ffi|package:flutter|win32` → 0 命中；在 `plugin_sidecar/lib/` 中 grep `dart:io` → 仅 `io_process_launcher.dart` 与 `io_file_system.dart` 命中。

- [ ] **Step 5：编写包文档**

`plugin_sidecar/README.md` 必须包含：包职责与依赖方向；SCP1 格式字节布局与限制表；帧与消息格式；安装目录布局与原子切换说明；**安全边界声明（故障隔离，非恶意代码防护；摘要非签名）**；完整验证命令。`v2/README.md` 追加「M2 边界」：plugin_sidecar 桌面专属、dart:io 收敛于两个适配文件、M3 才有 Flutter 宿主。

- [ ] **Step 6：启动 G2 独立验收智能体**

全新上下文 Sol xhigh，只读。输入：设计规格（§6/§8/§13）、本计划、v2 代码与测试、G1 报告。验收清单：

```text
路径攻击矩阵逐一核对 package_paths 测试与实现一致
容器攻击（魔数/截断/摘要/超限/重复/manifest）覆盖核对
帧攻击（超长/零长/坏 UTF-8/半包）覆盖核对
消息严格性与诊断脱敏核对
安装原子性：rename 提交点、失败回退、alreadyInstalled 不可破坏既有安装
监督故障注入：启动超时 kill、stop 超时、意外退出上报、disposeAll 回收
e2e 证据真实（Python skip 时给出明确降级结论而非宣称通过）
dart:io 边界扫描复跑
错误码与词汇表逐条一致
无伪签名/伪沙箱/模拟 IPC 误导性声明
```

- [ ] **Step 7：写入验收结论**

报告写入 `docs/superpowers/acceptance/v2-sidecar-framework-acceptance.md`。通过 → controller 将 F2-01～F2-09 与 M2 标记 `accepted`，M3 状态 `in_progress` 待计划冻结；不通过 → 退回对应任务原实现等级修复。

- [ ] **Step 8：用户检查点**

建议提交信息：`feat(sidecar): complete sidecar runtime`（对应 Master Plan 预留文案）。AI 不执行 Git 命令。

---

## 与规格条款的覆盖对照（自审）

| 规格条款 | 任务 |
|---|---|
| §6 安装生命周期与转换 | F2-06 状态机 |
| §8 安装包含清单/入口/资源/摘要 | F2-05 |
| §8 暂存解包 + 规范化路径验证 | F2-04 + F2-06 |
| §8 禁止绝对/穿越/设备/重复路径 | F2-04 |
| §8 原子目录切换 | F2-06 |
| §8 启动超时/请求超时/取消/退出回收/宿主关闭回收 | F2-08（启动、退出、关闭）/ F2-07（请求、取消） |
| §8 不建白名单/证书/沙箱（负向声明） | F2-09 README + G2 |
| §2.2 帧边界 JSON-RPC/stdio | F2-02 + F2-03 + F2-09 StdioRpcTransport |
| §13 Windows Python Sidecar 安装/启动/通信/停止/超时/卸载 | F2-09 场景 1-10 |
| Master Plan M2 五项 + G2 | 全任务 + F2-09 Step 6-7 |
