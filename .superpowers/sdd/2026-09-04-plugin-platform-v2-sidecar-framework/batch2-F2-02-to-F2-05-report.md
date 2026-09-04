# Batch2 实现报告：F2-02 ~ F2-05（plugin_sidecar 包）

- 日期：2026-09-04
- 工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_sidecar`
- 权威计划：`docs/superpowers/plans/2026-09-04-plugin-platform-v2-sidecar-framework.md`
- 执行方式：串行（F2-02 → F2-03 → F2-04 → F2-05），每任务独立完成焦点验证。
- 全局约束确认：所有新建文件均未 import `dart:io` / `dart:ffi` / `package:flutter` / `win32`；`crypto` 仅 F2-05 使用；`lib/plugin_sidecar.dart` 逐任务追加 export；未执行任何 git 命令；未修改 progress.yaml。

## 最终验证汇总

| 命令（包目录下执行） | 结果 |
| --- | --- |
| `dart test`（全包） | 38/38 通过（8 + 10 + 5 + 5 + 10） |
| `dart analyze` | No issues found! |
| `dart format`（全部新建文件） | 0 changed（已格式化，80 列） |

---

## F2-02：RPC 帧编解码

### 文件清单
- `lib/src/rpc/rpc_frame_codec.dart`（新增）
- `test/rpc/rpc_frame_codec_test.dart`（新增）
- `lib/plugin_sidecar.dart`（追加 export）

### 焦点验证
- 命令：`dart test test/rpc/rpc_frame_codec_test.dart`
- 结果：**8/8 通过**

### 实现要点
- `defaultMaxFrameBytes = 8MiB`，与计划一致。
- `encodeFrame(Uint8List payload)`：4 字节大端长度头 + payload，超限抛异常。
- `RpcFrameDecoder`：支持增量输入（`addBytes` / `addByte`），严格长度头校验，帧边界逐字节切分。
- `RpcFrameException`：携带违规细节（长度超限 / 非法声明等）。

### 与计划的偏差
1. **半包测试循环修正**：计划描述对每次追加 1 字节后断言产出为空，但追加至最后一字节时帧已完整、必须产出，逐字节断言空必然失败。修正为仅对前 n-1 字节断言无产出，最后 1 字节断言完整帧产出。属测试构造缺陷修正，不改变被测语义。
2. **encode 超限断言补充**：计划矩阵未显式列出 encode 超限场景，测试补充断言（属覆盖增强，非行为偏差）。

---

## F2-03：RPC 消息编解码

### 文件清单
- `lib/src/rpc/rpc_message_codec.dart`（新增）
- `test/rpc/rpc_message_codec_test.dart`（新增）
- `lib/plugin_sidecar.dart`（追加 export）

### 焦点验证
- 命令：`dart test test/rpc/rpc_message_codec_test.dart`
- 结果：**10/10 通过**

### 实现要点
- `sealed RpcMessage` + 四个消息子类，与计划类型签名一致。
- `decodeRpcMessage`：严格 JSON 解码；未知字段拒绝；`FormatException` 消息脱敏——不包含 payload 原文，仅含字段路径。
- `encodeRpcMessage`：入口防御（ArgumentError），序列化输出稳定。
- 消息严格性场景全覆盖（未知字段 / 类型错 / 缺字段）。

### 与计划的偏差
1. **测试 helper 增加 `allowSecretInField` 豁免参数**：未知字段用例中，异常消息必须包含字段名本身（属字段路径而非 payload 值原文），helper 原先无条件断言「消息不含 SECRET 串」会误伤该用例。仅为测试辅助参数，实现行为与计划一致（脱敏规则：值原文绝不外泄）。

---

## F2-04：包路径安全校验

### 文件清单
- `lib/src/package/package_paths.dart`（新增）
- `test/package/package_paths_test.dart`（新增）
- `lib/plugin_sidecar.dart`（追加 export）

### 焦点验证
- 命令：`dart test test/package/package_paths_test.dart`
- 结果：**5/5 通过**

### 实现要点
- `validatePackagePath(String)` 返回 record `({String normalized, PluginFailure? failure})`，与计划 Interfaces: Produces 签名逐字一致。
- 常量：总路径长上限 `1024`、单段上限 `255`，与计划一致。
- 校验顺序：empty → nulCharacter → 设备前缀（`\\.\` / `\\?\`）→ absolute（`/` 开头、`\\` UNC、盘符）→ backslash → 总长 → trailingSeparator → 分段（blankSegment、`.`/`..`→traversal、段长→tooLong、DOS 保留名→device）。
- `detectDuplicatePaths`：按 `toLowerCase()` 折叠后检测重复，命中返回 `PluginFailure('package.path_unsafe', ..., {'reason': 'duplicate', 'path': ...})`。
- 所有违规 reason 与计划取值一一对应；错误码统一 `package.path_unsafe`。
- 纯逻辑实现，无任何 IO 依赖。

### 与计划的偏差
1. **`/a` 归为 absolute**：计划攻击矩阵内部矛盾——`/abs`→absolute 与 `/a`→blankSegment 不可能同时成立（两者均以 `/` 开头，若先判 absolute 则 `/a` 不会走到分段检查）。决策：统一「`/` 开头 → absolute」（更安全的语义，绝对路径一律拒绝）；另补充 `a//b`→blankSegment 用例保证空段场景仍有覆盖。

---

## F2-05：SCP1 容器打包与读取

### 文件清单
- `lib/src/package/package_builder.dart`（新增：`PackageEntry` / `PackageException` / `PackageBuilder`）
- `lib/src/package/package_reader.dart`（新增：`PackageLimits` / `SidecarPackage` / `PackageReader`）
- `test/package/package_builder_test.dart`（新增）
- `test/package/package_reader_test.dart`（新增）
- `lib/plugin_sidecar.dart`（追加 export，五个 export 全部就位）

### 焦点验证
- 命令：`dart test test/package`（含 F2-04 的 5 个路径测试）
- 结果：**20/20 通过**（paths 5 + builder 5 + reader 10）

### 实现要点
- 容器格式：8 字节头（魔数 `SCP1` = `[0x53,0x43,0x50,0x31]` + u32 大端索引长度）+ 索引 JSON（`{"entries":[{path,length,sha256}]}` 严格解码）+ 条目字节连续存放。
- `PackageBuilder`：`add` 时立即做路径校验（复用 F2-04），`build` 强制要求 `plugin.json` 条目（缺失 → `manifestMissing`）；sha256 使用 `crypto.sha256.convert(bytes).toString()`（64 位小写 hex）。
- `PackageReader.fromBytes(Uint8List, {limits})`：仅内存字节，无文件系统访问。
- `PackageLimits` 默认值与计划一致：条目数 4096、单条目 64MiB、总量 256MiB、索引 1MiB。
- 解码顺序固定：truncated（头不全 / 声明索引长超容器 / 条目越界）→ badMagic → 索引 limit → 索引严格解码（形状错一律 `indexInvalid`）→ 条目数 limit → 路径安全 / 大小写折叠重复 → 切分（单条 limit → 总量 limit → truncated → `digestMismatch`）→ `manifestMissing` → 清单严格解码（`PluginManifestCodec.decode`，失败归 `indexInvalid`）→ kind 必须为 sidecar → `entrypointMissing`。
- 错误码统一 `package.bad_format`（reason 放 details）；路径违规模块抛 `PackageException` 内嵌 `package.path_unsafe`。
- 诊断消息不含宿主参数或用户主目录；`FormatException` 不携带 payload 原文。
- `PackageException` 定义放在 builder 文件中供 reader 复用，避免循环依赖。

### 与计划的偏差
1. **`SidecarPackage` 为非 const 构造**：const 构造函数的初始化列表不能调用非 const 工厂（`List.unmodifiable`），编译报错。计划 Interfaces: Produces 块未要求 const，改为普通构造，字段仍为不可变 `List.unmodifiable`，语义不变。
2. **「索引长度字段超出实际字节 → truncated」的测试构造调整**：计划矩阵该行按字面（声明长度 +16）无法稳定触发 truncated——当容器 payload 足够大时，+16 仍在容器内，索引切片混入 payload 字节后 JSON 解码失败，按解码顺序正确归为 `indexInvalid`（索引内容非法先于结构截断命中，语义正确）。实现保留 `8 + indexLength > container length → truncated` 检查；测试改为声明 `good.length - 8 + 16`（声明长度超出容器实际可容纳字节数），忠实还原矩阵「声明超出实际 → truncated」的意图。实现行为未偏离计划矩阵定义的两类触发条件。

---

## 交付自检

- [x] 四个任务代码 + 测试全部完成，焦点验证通过。
- [x] 错误码 / reason 取值 / 类型签名 / 常量值与计划一致（逐条核对：8MiB、4096、64MiB、256MiB、1MiB、1024、255、"SCP1"）。
- [x] 接口签名与计划 Interfaces: Produces 一致：`PackageReader.fromBytes`（无 fromFile）、`validatePackagePath` 返回 record。
- [x] 禁止依赖约束满足（dart:io / dart:ffi / flutter / win32 均未引入；crypto 仅 F2-05）。
- [x] 中文文档注释、无 var / dynamic、每文件单一职责、dart format 80 列。
- [x] 测试文件顶部均有中文覆盖场景清单；安全与协议核心场景全覆盖。
- [x] 未执行 git 命令；未修改 progress.yaml。
