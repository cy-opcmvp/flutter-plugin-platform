# G2 验收报告：M2 Sidecar 框架（F2-01 ～ F2-09）

**验收日期**: 2026-09-04
**验收者**: G2 独立验收智能体（与实现者无共享上下文，全新上下文只读验收）
**验收范围**: `v2/packages/plugin_sidecar` 全部实现与测试、`v2/README.md` M2 边界段、三包（contracts/runtime/devkit）M2 约束符合性
**对照输入**: 设计规格 `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（§6/§8/§13）、冻结计划 `docs/superpowers/plans/2026-09-04-plugin-platform-v2-sidecar-framework.md`、实现报告 `.superpowers/sdd/2026-09-04-plugin-platform-v2-sidecar-framework/`（batch1-4）、G1 报告结构模板

---

## 结论：Approved

- Critical：0
- Important：0
- Minor / 观察项：8（均不阻塞，见第三节）

全部验收项（A-I）通过。安全边界真实且与规格 §8 声明一致：无伪签名、无伪沙箱、无模拟 IPC（stdio RPC 为真实 Python 子进程通信，e2e 0 跳过实证）。M2 可标记 `accepted`。

---

## 一、分项核查表

### A. 复跑验证 — 通过

| 验证 | 结果 | 证据 |
|---|---|---|
| `dart test packages/plugin_contracts` | `00:00 +48: All tests passed!`，exit 0 | 验收命令记录 #1 |
| `dart test packages/plugin_runtime` | `00:00 +26: All tests passed!`，exit 0 | #2 |
| `dart test packages/plugin_devkit` | `00:00 +8: All tests passed!`，exit 0 | #3 |
| `dart test packages/plugin_sidecar` | `00:06 +85: All tests passed!`，exit 0；e2e 场景 7-10 可见真实执行，0 跳过（Python 3.13.7 经 `py -3` 命中） | #4 |
| `dart format --output=none --set-exit-if-changed .` | `Formatted 52 files (0 changed)`，exit 0 | #5 |
| `dart analyze` | `No issues found!`，exit 0 | #6 |
| 边界扫描：contracts/runtime/devkit 的 `lib/` 中 `dart:io\|dart:ffi\|package:flutter\|win32` | 0 命中 | #7 |
| 边界扫描：plugin_sidecar 的 `lib/` 中 `dart:io` | 仅 `io_file_system.dart` 与 `io_process_launcher.dart` 命中，符合计划的两个允许点 | #7 |
| M2 约束「不修改三包生产代码」 | `git status --porcelain v2/packages`（排除 plugin_sidecar）为空；三包相对 HEAD（M1 提交 632868b）零改动 | #8 |

### B. 路径安全攻击矩阵 — 通过

`test/package/package_paths_test.dart` 与实现 `lib/src/package/package_paths.dart` 逐条对应计划 F2-04 矩阵：

- 拒绝：`''`→empty；`C:/x`、`c:\x`、`/abs`→absolute；`../x`、`a/../../x`、`..`→traversal；`\\.\x`、`\\?\C:\x`、`CON`、`NUL`、`COM1`、`LPT9`、`con.txt`→device（段名去扩展名后与保留名集合大小写不敏感比对）；`a\b`→backslash；`a//b`→blankSegment；`a/`→trailingSeparator；`a\x00b`→nulCharacter；路径 >1024、段名 >255→tooLong。
- `detectDuplicatePaths`：`['a/B.json','A/b.JSON']` 冲突（toLowerCase 大小写折叠，冻结决策 9）；`['a/b','c/b']` 无冲突。
- 全部断言 code=`package.path_unsafe` + 对应 reason，与错误码词汇表一致。

### C. 容器攻击矩阵 — 通过

`test/package/package_reader_test.dart` 覆盖计划 F2-05 全部 13 条：好包往返；`SCP2`→badMagic；截断（去尾 10 字节 / 仅 6 字节）→truncated；索引长度超出实际→truncated；索引非严格 JSON / 未知字段 / 条目缺字段→indexInvalid；sha256 改一位→digestMismatch；length 不符→digestMismatch|truncated；entries>maxEntries、单条>maxEntryBytes、总量>maxTotalBytes、索引>maxIndexBytes（四类限额均以小 limits 构造）→limitExceeded；缺 `plugin.json`→manifestMissing；kind 非 sidecar / entrypoint 无条目→entrypointMissing；含 `../x` 条目→内嵌 package.path_unsafe(traversal)；大小写重复条目→duplicate。

实现 `package_reader.dart` 全程内存字节操作，无 dart:io，顺序为魔数→限制→索引严格解码→路径安全→摘要比对→清单解码→sidecar kind 与 entrypoint 校验，与计划 Step 4 一致。

### D. 帧与消息 — 通过

帧（`rpc_frame_codec_test.dart` 与计划矩阵逐条对应）：往返；逐字节半包；多帧粘包；声明超限在 payload 到达前即抛 tooLarge；零长帧 empty；非 UTF-8 invalidUtf8（`allowMalformed: false`）；reset 丢弃半包状态；异常携带结构化 `rpc.frame_invalid` failure。默认上限 `defaultMaxFrameBytes = 8MiB`（冻结决策 2）。

消息（`rpc_message_codec_test.dart`）：四类消息往返字节一致；jsonrpc 缺失/非 "2.0"、未知字段（消息含字段名）、method 空串、params 数组、负 id/空串 id/null id、notification 含 id、success 与 error 同时出现/同时缺失、error.code 非 int、error.message 空、顶层非 object、非法 JSON——全部 FormatException 且消息不含 payload 值原文（脱敏核对通过）；encode 侧负 id/空 method 抛 ArgumentError。

通道（`rpc_channel_test.dart`）：按 id 关联、3 并发乱序、remote_error 携带远端 code/message、超时 `rpc.timeout`(methodName/elapsedMs) 后通道关闭、超时后迟到响应被静默忽略且其余 pending 以各自超时收敛、未知 id 响应→channel_closed(unexpectedResponse)、send 异常→transportError、incoming 非法 payload→message_invalid 并关闭、close 后 call 立即 closedByCaller、notify 无 pending、id 从 0 递增。与冻结决策 5/6 自洽（见 M7/M8 观察项）。

### E. 安装原子性 — 通过

状态机（`install_state_machine_test.dart` 对应计划 Step 2 全矩阵）：主链 notInstalled→installing→installed→uninstalling→notInstalled；失败回退 installing→notInstalled、uninstalling→installed；三条非法转换断言 code=`sidecar.install_state.invalid_transition`、details 含 pluginId/from/to、状态不变；无终态（重装可行）。

安装器（`sidecar_installer_test.dart` 10 条对应计划 Step 3 全矩阵，真实 systemTemp 目录 + 可注入 fake fs）：

- install 成功：`<root>/<id>/` 出现全部条目、entrypoint 内容一致、isInstalled==true、状态 installed。
- alreadyInstalled：原目录未被触碰（仍 2 文件）、staging 无残留、状态机不进入 installing（见 M2 观察项）。
- staging 残留先清理；writeError→stagingFailed+staging 清理+回退 notInstalled；renameError→commitFailed+staging 清理+final 不存在。
- uninstall 成功无 trash 残留；不存在→notInstalled 失败；renameError→renameFailed+回退 installed+原目录保留；trash deleteError→仍成功（best-effort，failure==null）。
- 提交点为单次 `renameDir(staging, final)`；目录名仅来自已验证 `pluginId.value`（`sidecar_installer.dart` 62-64 行），无其他字符串拼接。
- 宿主重启后磁盘真值补齐（installed 但磁盘缺失→回 notInstalled；notInstalled 但磁盘存在→快进 installed）均只走合法转换链（见 I-4）。

### F. 监督故障注入 — 通过

`sidecar_supervisor_test.dart` 9 测试对应计划 F2-08 矩阵 9 条，全部经注入 Delayer（`_ControlledDelayer` 受控推进，无真实等待）：

1. stdout 首字节就绪+hasAlive；2. 启动超时→kill 被调用+start_timeout+hasAlive false；3. 启动即退出→start_failed(exited, exitCode=3) 且不触发 unexpected；4. launcher.start 抛异常→start_failed(spawnError) 且 process==null；5. stop 正常 success 且不报意外退出；6. stop 宽限超时→stop_timeout 且进程仍存活；7. 意外退出→unexpected_exit(exitCode=9)；8. disposeAll 两进程回收+hasAlive false；9. disposeAll 幂等。

真进程链路：`io_process_launcher_test.dart`（@Timeout 30s）以 `Platform.resolvedExecutable` 启动 `echo_child.dart`（与计划夹具源码逐字一致：ready 帧 + Completer 常驻）→ 收到 ready 帧→kill→exitCode 非零→closeStdin。`io_process_launcher.dart`/`io_file_system.dart` 是 `dart:io` 仅有的两个生产使用点，均薄适配。

### G. 端到端证据 — 通过（真实运行，0 跳过）

`test/e2e/python_sidecar_e2e_test.dart`（@Timeout 3min，6 用例合并覆盖 10 场景，符合执行策略第 1 条）：

| 场景 | 证据（行号） | 结果 |
|---|---|---|
| 1 install 落盘 | 232-236：installed + plugin.json/echo_sidecar.py 存在 | 通过 |
| 2 start 就绪 | 207-216 + 239：supervisor stdout 首字节就绪 | 通过 |
| 3 ping→pong | 246-248 | 通过 |
| 4 echo 原样回显（含嵌套+中文） | 250-257 | 通过 |
| 5 stderrNoise 不干扰 | 259-262（夹具 29-32 行先写 stderr 再回 ok） | 通过 |
| 6 hang→rpc.timeout+通道关闭 | 265-282：code/details(methodName=hang, elapsedMs=3000)/isClosed | 通过 |
| 7 crash→unexpected_exit | 284-312：先 ping 确认通道可用，crash 后 unexpected_exit(exitCode=1) | 通过 |
| 8 stop 优雅退出+卸载重装 | 314-337 | 通过 |
| 9 篡改包 digestMismatch+原安装完好 | 339-373：篡改索引后首 payload 字节，原安装 isInstalled 仍 true、脚本内容未变 | 通过 |
| 10 uninstall 目录消失 | 375-387 | 通过 |

超时→通道关闭→进程回收链路完整（场景 6/7/8 + tearDown disposeAll）。stderr 噪声不干扰协议（场景 5）。实现者披露的运行环境：Windows 11、Python 3.13.7（`py -3`；`python` 命中 Microsoft Store 存根退出码 9009 被探测正确排除）。验收复跑与本机运行一致（A-4）。

夹具 `echo_sidecar.py` 处理 5 方法 + 默认 -32601，与计划语义一致；就绪帧形式差异见 I-5a。

### H. 一致性核查 — 通过

- **错误码词汇表**：`rpc.frame_invalid`/`rpc.message_invalid`/`rpc.timeout`/`rpc.channel_closed`/`rpc.remote_error`/`package.path_unsafe`/`package.bad_format`/`sidecar.install_failed`/`sidecar.uninstall_failed`/`process.start_failed`/`process.start_timeout`/`process.stop_timeout`/`process.unexpected_exit` 及全部 reason 取值、details 约定（methodName+elapsedMs、exitCode、脱敏），逐条与计划词汇表一致；状态机错误码 `sidecar.install_state.invalid_transition` 与计划 F2-06 Interfaces 一致。
- **接口签名**：F2-02～F2-09 各 Produces 代码块（encodeFrame/RpcFrameDecoder/RpcMessage 四类/validatePackagePath/PackageBuilder/PackageReader/PackageLimits/PackageException/InstallStateMachine/PackageFileSystem/SidecarInstaller/SidecarProcess/SidecarProcessLauncher/SidecarSupervisor/RpcTransport/RpcCallResult/RpcChannel/Delayer）与实现一致；`plugin_sidecar.dart` 13 个 export 字母序完整。9 项冻结技术决策全部落地（SCP1、4B 大端+UTF-8 帧 8MiB、注入 launcher、Delayer 确定性超时、取消=关闭、超时后通道关闭、单次 rename 提交、stdout 首字节弱信号、大小写折叠重复检测）。
- **contracts 消费**：`PluginId.parse` 正则、`PluginFailure(code,message,[details])` 不可变快照、`PluginManifest` sidecar 桌面 target 约束、`PluginManifestCodec.decode` 均与 sidecar 用法一致；e2e 清单字段与 PluginManifest 构造参数一一对应。
- **README 一致性**：`plugin_sidecar/README.md` 含包职责/SCP1 布局与限额表/帧消息格式/安装布局与原子切换/**安全边界声明**（「故障隔离，不是恶意代码防护」「sha256 不是签名」「不提供白名单、CA 验签、代码签名或沙箱能力」）/验证命令/广播化 M3 注意事项——均与实际行为一致。`v2/README.md` M2 边界段（桌面专属、dart:io 收敛两文件、M3 才有 Flutter 宿主）与实现一致。
- **误导性声明扫描**：`signature|sandbox` 在全部 `*.dart` 0 命中（无伪实现）；`*.md` 仅 README 否定式安全声明命中（#9）。无伪签名/伪沙箱/模拟 IPC。

---

## 二、验收命令记录（G2 独立复跑）

```text
# 1-4 逐包测试（从 v2/ 执行；此版本 Dart 不支持 workspace 根直接 dart test）
dart test packages/plugin_contracts   → 00:00 +48: All tests passed! (exit 0)
dart test packages/plugin_runtime     → 00:00 +26: All tests passed! (exit 0)
dart test packages/plugin_devkit      → 00:00 +8:  All tests passed! (exit 0)
dart test packages/plugin_sidecar     → 00:06 +85: All tests passed! (exit 0, e2e 0 跳过)

# 5-6 格式化与静态分析
dart format --output=none --set-exit-if-changed .  → Formatted 52 files (0 changed) (exit 0)
dart analyze                                        → No issues found! (exit 0)

# 7 依赖边界扫描（grep -rEn）
contracts/runtime/devkit lib/: dart:io|dart:ffi|package:flutter|win32 → 0 命中
plugin_sidecar lib/: dart:io → 仅 lib/src/package/io_file_system.dart、lib/src/process/io_process_launcher.dart

# 8 M2 修改范围核查
git status --porcelain v2/packages（排除 plugin_sidecar 路径）→ 空（M2 未改三包生产代码）

# 9 误导性声明扫描
grep -rniE 'signature|sandbox' --include='*.dart' --include='*.md' packages README.md
→ dart 0 命中；md 仅 plugin_sidecar/README.md 68-72 行否定式安全声明
```

---

## 三、发现分级

### Critical（0 项）

无。

### Important（0 项）

无。安全边界（路径校验、容器完整性、帧/消息严格性、安装原子提交、监督回收）全部有真实测试实证，未发现可绕过点或夸大声明。

### Minor / 观察项（8 项，均不阻塞）

| # | 发现 | 证据 | 建议 |
|---|---|---|---|
| M1 | batch4 报告偏差 1 披露措辞失准：计划 973-980 行的夹具 main() **并非缺少就绪帧**（原文为 `write_frame({"jsonrpc":"2.0","method":"ready"})`），实际差异是就绪帧形式改为纯字符串 `write_frame("ready")`（`test/fixtures/python/echo_sidecar.py:47`）。对 supervisor 等效（仅取 stdout 首字节事件）；广播流语义下 ready 帧已被 supervisor 消费、不会泄漏进 RpcChannel，无协议影响 | 计划 973-980 行 vs echo_sidecar.py:45-47 vs batch4 报告偏差 1 | 修正报告措辞；无需改代码 |
| M2 | alreadyInstalled 的 finalDir 预检发生在 `transitionTo(installing)` 之前，计划 F2-06 Step 5 文字顺序为先转换后检查。实现的顺序更安全：重复安装不污染状态机（保持 notInstalled），且预检失败时 staging 先行清理。良性重排，与状态机语义自洽 | sidecar_installer.dart install 流程；sidecar_installer_test.dart 185-203 | 无需修改；记录差异即可 |
| M3 | `RpcChannel` 保留 `decoder` 构造参数但帧解码职责已归属 `StdioRpcTransport`（与计划 RpcTransport 接口注释「已解码的帧 payload 流」自洽），该参数当前无实效 | rpc_channel.dart 构造参数 vs stdio_rpc_transport.dart | M3 前移除或文档明确其兼容语义 |
| M4 | 宿主重启后的磁盘真值补齐转换（installed-无目录→notInstalled；notInstalled-有目录→快进 installed）无直接单测固化 | sidecar_installer.dart 两处 sync 逻辑；install_state_machine_test 未覆盖 | 补 2 条单测固化该防御行为 |
| M5 | `SidecarProcess.stdout` 单订阅接口与「supervisor 就绪探测 + transport 订阅」双消费者存在结构性摩擦，e2e 以 `_BroadcastingLauncher` 组合层补丁解决（未改 F2-01~08 文件，README 已记录 M3 注意事项）。M3 宿主将复遇同样问题 | python_sidecar_e2e_test.dart 75-109；plugin_sidecar/README.md | M3 将广播化下沉为框架设施，或调整 stdout 流契约 |
| M6 | 计划 D 项矩阵「notification 含 id → FormatException」的措辞与实现不符：实现按 JSON-RPC 标准，`method+id` 归类为 request（合法）。计划的消息格式定义（notification=无 id 的 request）本身使两类重叠，实现归类合理，纯说明性差异 | rpc_message_codec.dart 判序 vs 计划 F2-03 矩阵 | 无需修改 |
| M7 | RpcChannel 请求超时只完成引发超时的请求并移除其 pending，其余 pending 以各自 `rpc.timeout` 收敛；迟到响应因通道关闭被静默忽略。与冻结决策 6「超时后通道关闭」自洽，但「其余 pending 收敛语义」计划未明示 | rpc_channel.dart 超时路径；rpc_channel_test.dart | 在 README/接口注释中明确该收敛语义 |
| M8 | `RpcError` data==null 时编码省略 `data` 键（JSON-RPC 允许）；round-trip 一致，非缺陷 | rpc_message_codec.dart | 无需修改 |

---

## 四、已知偏差裁定表

| # | 偏差 | 裁定 | 理由 |
|---|---|---|---|
| I-1 | `/` 开头路径统一归 absolute（计划测试矩阵行内预留「F2-04 实现时澄清」） | **接受** | POSIX 语义 `/a` 本为绝对路径；若按相对处理在 Windows 会落到当前盘根，同样危险。归类 absolute 更保守、拒绝面更大，有测试覆盖（package_paths_test） |
| I-2 | `SidecarPackage` 非 const 构造（计划 Interfaces 写 const） | **接受** | 字段含运行时对象（manifest、entries、bytes），const 实例化在实践中不可达；字段仍 final，不可变性语义不变。纯语法层面，无行为差异 |
| I-3 | RpcChannel 保留 decoder 构造参数但通道不重复解帧 | **接受** | 帧职责归 transport 与计划 RpcTransport 接口注释自洽、职责更单一；参数保留仅为签名兼容，无重复解帧风险。遗留项记 M3（M3 观察项） |
| I-4 | 安装器对宿主重启后落后于磁盘真值做补齐转换 | **接受** | 计划未覆盖的现实防御场景；两处补齐均严格走 6 条合法转换链，不引入新状态或非法跳转。建议补测固化（M4） |
| I-5 | 四项夹具/测试修复：(a) Python 夹具补 ready 帧；(b) Python 探测候选列表 python/python3/py -3；(c) e2e stdout 广播化（组合层）；(d) `_requirePython` 同时在用例体首行 + `_guard` 20s + 夹具路径 cwd 无关化（含 io_process_launcher_test 5 行最小修复） | **全部接受** | (a) 必要——无就绪帧 supervisor 必启动超时；形式差异披露措辞见 M1。(b) 必要且更稳健——Windows Store 存根（9009）与 pyenv shim 使单一探测不可靠。(c) 必要的组合层方案，未改 F2-01~08 交付物，框架级解决留 M3（M5）。(d) 均为测试框架行为规避/防御保护/cwd 无关化最小修改，披露透明。io_process_launcher_test 的 5 行修复属「workspace 全量验证通过」验收要求的必要前提，修改范围最小且未触碰被测逻辑 |

---

## 五、验收小结

- A-I 十项验收全部通过，无 Critical/Important 发现。
- 安全三声明成立：无伪签名（摘要仅完整性校验且 README 明示）、无伪沙箱（README 明示不提供且宿主需自建）、无模拟 IPC（真实 Python 子进程 stdio 帧通信，e2e 0 跳过）。
- 8 项 Minor/观察项均已列出并给出建议，不阻塞 M2 标记 `accepted`；其中 M3/M5 应纳入 M3 计划输入。
- 建议提交信息（F2-09 Step 8 预留）：`feat(sidecar): complete sidecar runtime`。
