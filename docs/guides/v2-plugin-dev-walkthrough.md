# v2 插件开发走查（M4 MVP）

> 面向 v2 插件平台新开发者的端到端走查：从环境准备到内置插件、Sidecar
> 插件、契约检查与常见错误码。全部示例取自仓库真实产物：
> `v2/plugins/calculator`（builtin）、`v2/plugins/screenshot`（builtin）、
> `v2/sidecars/python_sample`（sidecar）。

## 1. 前置条件

| 依赖 | 用途 | 说明 |
|------|------|------|
| Flutter SDK（stable） | 宿主与全部 Flutter 包的构建/测试 | 版本以 `v2/pubspec.lock` 解析为准 |
| Python 3（可选） | 运行 Sidecar Python 样本 | 样本仅用标准库（hashlib），零 pip 依赖；无 Python 时相关测试自动跳过 |

确认解释器可用（任一即可，CLI 依次探测 `python`、`python3`、`py -3`）：

```bash
python --version   # 或 python3 --version / py -3 --version
```

## 2. 仓库布局速览

```
v2/
├── packages/                 # 框架包
│   ├── plugin_contracts/     # 契约：清单/能力/失败/表单/结果描述符（零 IO、零 Flutter）
│   ├── plugin_runtime/       # 会话与 RPC（SidecarSession/RpcChannel）
│   ├── plugin_sidecar/       # 包格式/安装器/进程启动器（唯一 dart:io 边界之一）
│   ├── platform_capabilities/         # 能力接口（零实现依赖）
│   ├── platform_capabilities_windows/ # Windows 能力实现（含 GDI 截图）
│   ├── plugin_cli/           # 脚手架与包工具：create / validate / pack
│   ├── plugin_flutter/       # 声明式 UI：表单/结果渲染、目录/解析、提供方接口
│   └── plugin_devkit/        # 开发套件：SurfaceContractChecks、fakes、matchers
├── plugins/                  # 内置（builtin）插件包：calculator、screenshot
├── sidecars/python_sample/   # Sidecar 样本：plugin.json + hash_tool.py + hash-tool.scp
└── apps/toolbox_host/        # 宿主应用（组装根 + 目录/详情页 + 桥）
```

最小验证命令（在 `v2/` 下）：

```bash
cd v2/packages/plugin_contracts && dart test          # 纯 Dart 包示例
cd v2/apps/toolbox_host && flutter test               # Flutter 包示例
dart format --output=none --set-exit-if-changed .     # 格式检查（v2/ 下）
```

## 3. 内置（builtin）插件路径

以 `v2/plugins/calculator` 为实例。

### 3.1 包结构

```
plugins/calculator/
├── plugin.json        # 插件清单（声明式元数据）
├── pubspec.yaml       # 纯 Dart 共享模型包（依赖 plugin_contracts）
├── lib/calculator.dart
└── test/              # 模型与文案解析测试
```

### 3.2 清单要点

```json
{
  "id": "tools.calculator",
  "name": "计算器",
  "version": "1.0.0",
  "apiVersion": 1,
  "kind": "builtin",
  "targets": ["windows", "macos", "linux", "android", "ios", "web"],
  "entrypoint": "builtin://tools.calculator",
  "provides": [{ "id": "calc.evaluate", "version": 1 }],
  "requires": [],
  "surfaces": ["page", "settings"],
  "configSchemaVersion": 1,
  "dataSchemaVersion": 1
}
```

- `id` 必须是反向域（`{tld}.{org}.{name}`），`PluginId.parse` 校验。
- `kind: builtin` 的 `entrypoint` 用 `builtin://<id>` 占位；真实实现由宿主
  在组装根以 `PluginPageProvider` / `PluginSettingsProvider` 注入。
- `surfaces` 决定宿主呈现面：`page`（页面）、`settings`（设置）、
  `actions`（动作）、`command`（Sidecar 命令面）。

### 3.3 实现模式

1. **共享模型包**（纯 Dart）：表达式求值、历史记录等业务逻辑不依赖
   Flutter，独立 `dart test` 可测。
2. **宿主接线**（`apps/toolbox_host/lib/src/plugins/calculator_plugin.dart`）：
   - `calculatorManifest()` 在宿主内存中镜像 `plugin.json`（字段必须逐一致）；
   - `CalculatorPageProvider` / `CalculatorSettingsProvider` 把模型与宿主
     文案解析器（`HostL10n`）组合为声明式 UI；
   - 组装根（`host_composition_root.dart`）把清单注册进 `PluginRegistry`、
     提供方注册进 `pageProviders` / `settingsProviders`。

### 3.4 验证

```bash
cd v2/plugins/calculator && flutter test        # 插件包自测
cd v2/packages/plugin_cli && dart run plugin_cli validate ../../plugins/calculator
```

`validate` 校验清单结构、ID 格式、语义版本、surface 合法值等；退出码
0 成功、1 结构化失败（见第 6 节错误码）、2 用法错误。

## 4. Sidecar 插件路径

以 `v2/sidecars/python_sample` 为实例。

### 4.1 清单要点

```json
{
  "id": "tools.hashtool",
  "kind": "sidecar",
  "targets": ["windows"],
  "entrypoint": "hash_tool.py",
  "provides": [{ "id": "hash.compute", "version": 1 }],
  "surfaces": ["command"]
}
```

- `kind: sidecar` 的 `entrypoint` 是**包内脚本文件相对路径**。
- `provides` 的能力 ID 即命令面的 RPC 方法名（`hash.compute`）。

### 4.2 脚本协议（零依赖实现）

`hash_tool.py` 实现三件事：

1. **帧协议**：每条消息为 4 字节大端长度前缀（`struct ">I"`）+ UTF-8 JSON；
   stdout 只写帧、日志走 stderr。
2. **就绪信号**：进程启动后先发送一个纯字符串帧 `ready`，宿主据此判定
   会话就绪（15 秒启动超时）。
3. **JSON-RPC 2.0**：请求 `{"jsonrpc":"2.0","id":1,"method":"hash.compute",
   "params":{"text":"abc"}}`；成功回 `result`（`{md5, sha1, sha256}`，
   hex 小写）；未知方法回错误码 `-32601`，非法参数回 `-32602`。

### 4.3 打包与分发

```bash
cd v2/packages/plugin_cli
dart run plugin_cli validate ../../sidecars/python_sample
dart run plugin_cli pack ../../sidecars/python_sample -o ../../sidecars/python_sample/hash-tool.scp
```

`.scp` 是自包含包（清单 + 入口脚本），交宿主「安装」到数据目录
`<hostDataRoot>/sidecar-packages/<pluginId>/` 后运行。样本目录内
`hash-tool.scp` 是 pack 的现成产物。

### 4.4 宿主命令桥

宿主侧 `SidecarCommandBridge`（`apps/toolbox_host/lib/src/sidecar_command_bridge.dart`）
把「安装 → 启动 → 命令 → 停止 → 卸载」收敛为一个 API：

- `installFromBytes(Uint8List)`：包字节 → 安装器落盘（坏包转
  `package.bad_format` 结构化失败）；
- `start()` / `stop()`：会话管理（重复 start 先停旧；stop 幂等）；
- `run(formValues)`：表单值 → `hash.compute` RPC → 声明式
  `FieldsResultDescriptor`（MD5 / SHA-1 / SHA-256 三字段）；
- Python 解释器探测与进程启动在 `sidecar_session_factory_io.dart`
  （web 目标编译到恒不支持的 stub）。

e2e 测试（真实 Python 全链）：

```bash
cd v2/apps/toolbox_host && flutter test test/sidecar_hash_e2e_test.dart
```

无 Python 环境时该测试自动跳过（不失败）；未安装分支无需 Python，
恒常运行。

### 4.5 验证

```bash
cd v2/sidecars/python_sample && python hash_tool.py   # 手动帧调试可选
cd v2/packages/plugin_cli && dart run plugin_cli validate ../../sidecars/python_sample
```

## 5. 契约检查（plugin_devkit）

`SurfaceContractChecks`（`packages/plugin_devkit`）覆盖「清单声明与实现族
一致」这一最易出错的契约：

```dart
import 'package:plugin_devkit/plugin_devkit.dart';

// 页面提供方构建不抛异常且返回 Widget。
SurfaceContractChecks.checkPageProviderBuilds(context, provider);

// 设置提供方构建不抛异常且返回 Widget。
SurfaceContractChecks.checkSettingsProviderBuilds(context, settingsProvider);

// 清单 surfaces 与实现族一一对应（声明了 page 却未实现即抛 StateError）。
SurfaceContractChecks.checkManifestSurfaceDeclared(
  manifest,
  page: true,
  settings: true,
);

// 动作提供方至少返回一个动作。
SurfaceContractChecks.checkActionsNonEmpty(actionProvider, context);
```

devkit 还提供测试用 fakes 与 matchers；插件包的 `flutter test` 中把上述
检查纳入常规断言即可在 CI 前拦截清单漂移。

## 6. 常见错误码表（M4 词汇表）

| 错误码 | 来源 | 触发场景 |
|--------|------|----------|
| `calc.invalid_expression` | calculator | 表达式为空/无法识别符号/括号未闭合/除零等（details 带位置与种类） |
| `capture.failed` | screenshot | 屏幕捕获能力调用失败 |
| `bridge.not_installed` | 宿主命令桥 | Sidecar 未安装即 start/run |
| `bridge.command_failed` | 宿主命令桥 | 命令链路失败（details.cause 为原码：`rpc.remote_error`、`session.start_failed` 等） |
| `package.bad_format` | plugin_sidecar | `.scp` 字节解析失败（魔数/清单缺失等） |
| `sidecar.install_failed` | plugin_sidecar | 安装失败（details.reason：`alreadyInstalled` / `stagingFailed` / `commitFailed`） |
| `sidecar.uninstall_failed` | plugin_sidecar | 卸载失败（details.reason：`notInstalled` 等） |
| `session.start_failed` | plugin_runtime | 会话启动失败（解释器缺失/进程退出/就绪超时） |
| `rpc.timeout` / `rpc.remote_error` / `rpc.channel_closed` | plugin_runtime | RPC 请求超时 / 远端返回 JSON-RPC 错误 / 通道已关闭 |
| `cli.pack_failed` | plugin_cli | pack 阶段失败 |
| `surface.unsupported` | plugin_flutter | 宿主未实现清单声明的呈现面 |

排查顺序建议：先看 `details.reason` / `details.cause` 定位层（安装器 →
会话 → RPC），再对照本表回到对应包的测试复现。

## 7. 常见坑

- **清单与宿主镜像漂移**：builtin 插件清单在宿主内有内存镜像（如
  `calculatorManifest()`），改 `plugin.json` 必须同步镜像，devkit 的
  `checkManifestSurfaceDeclared` 可在测试中拦截。
- **surfaces 拼写**：合法值只有 `page` / `settings` / `actions` /
  `command`，其他值会被 `validate` 拒绝。
- **stdout 污染**：Sidecar 脚本往 stdout 打日志会破坏帧协议，日志一律
  走 stderr。
- **重复安装**：安装器遇 `alreadyInstalled` 返回结构化失败，先
  `uninstall` 再装，或安装前用 `isInstalled` 判定。
- **级联表达式取值**：`PackageBuilder()..add(..)..add(..).build()` 的值是
  builder 本身而非 build 结果，需拆成两条语句。
