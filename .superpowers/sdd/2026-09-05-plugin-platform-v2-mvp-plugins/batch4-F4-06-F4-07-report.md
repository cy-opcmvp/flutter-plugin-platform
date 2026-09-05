# 批四报告：F4-06 Python hash_tool 样本与命令桥 + F4-07 开发文档走查与集中全量验证

**日期**: 2026-09-05
**范围**: F4-06（`v2/sidecars/python_sample`、`SidecarCommandBridge`、宿主接线与 e2e）、F4-07（开发走查文档、M4 集中全量验证、构建矩阵复跑、README、本报告）
**约束遵守**: 未动 contracts/runtime/plugin_flutter/plugin_sidecar/capabilities/plugin_cli 生产代码；Python 样本零 pip 依赖；e2e 无 Python 跳过不失败；错误码逐字对齐 M4 词汇表；未执行 git、未改 progress.yaml。

---

## 1. Task F4-06：Python hash_tool 样本与命令桥

### 1.1 样本目录（`v2/sidecars/python_sample/`）

| 文件 | 说明 |
|------|------|
| `plugin.json` | `tools.hashtool`，kind=sidecar，targets=[windows]，entrypoint=`hash_tool.py`，provides=[hash.compute v1]，surfaces=["command"]（经 `plugin_cli validate` 验证通过） |
| `hash_tool.py` | 纯标准库（hashlib/struct/json/sys），零 pip。三协议要点：4 字节大端长度前缀帧；启动先发纯字符串帧 `ready`；JSON-RPC 2.0（`hash.compute` params `{text}` → result `{md5, sha1, sha256}` hex 小写；未知方法 `-32601`，非法参数 `-32602`；日志一律 stderr，stdout 只写帧） |
| `hash-tool.scp` | `dart run plugin_cli pack ../../sidecars/python_sample -o ../../sidecars/python_sample/hash-tool.scp` 的现成产物，留在样本目录 |
| `README.md` | F4-07 补充的样本说明（见 §2.4） |

### 1.2 SidecarCommandBridge（`v2/apps/toolbox_host/lib/src/sidecar_command_bridge.dart`）

- 依赖注入：`SidecarInstaller`、`SidecarSessionFactory`（条件导出注入）；桥常量 `kHashToolCommandMethod='hash.compute'`、`kHashToolEntrypointFileName='hash_tool.py'`。
- `installFromBytes(Uint8List)` → `installer.installBytes`（坏包转 `package.bad_format` 结构化失败）。
- `isInstalled / start / stop`：桥持有当前会话句柄；重复 start 先 stop 旧会话；stop 幂等；未安装 start/run → `bridge.not_installed`。
- `run(formValues)` → channel.call('hash.compute', {text}) → 结果映射为声明式 `FieldsResultDescriptor`（MD5/SHA-1/SHA-256 三字段，非字符串值防御折空）；远端失败透传为 `bridge.command_failed`（details：`{pluginId, cause, causeDetails}`）。
- 声明式表单描述 `hashToolFormDescriptor(strings)`（text 字段）由桥提供；文案载体 `HashToolStrings` 由宿主 l10n 组装。
- Python 解释器探测：`sidecar_session_factory_io.dart` 的 `probePythonCommand()` 依次探测 `python` / `python3` / `py -3`（`--version` 实跑判定），全部失败 → `session.start_failed`（reason=pythonNotFound）；web 目标经条件导出取恒不支持 stub。

### 1.3 宿主接线

- 组装根（`host_composition_root.dart`）暴露 `sidecarBridge` 实例（复用 `sidecarInstaller` 根目录）；`hashToolManifest()` 进 manifests 列表（目录第 4 张卡，「可安装」状态）。
- 详情页（`plugin_detail_page.dart`）sidecar 面板：kind=sidecar 显示安装区（.scp 路径输入 + 安装按钮）/ 启动 / 停止 / 命令表单（FormRenderer）/ 结果区（ResultRenderer），busy 态与结构化状态消息；文案全部宿主 arb（zh/en，camelCase，hash 前缀语义分组）。
- **决策落实（MVP）**：静态清单常量注册（组装根 manifests 列表），动态发现留 M5。

### 1.4 e2e 结果（`v2/apps/toolbox_host/test/sidecar_hash_e2e_test.dart`）

**2/2 通过（真 Python 全链验证通过）**：

1. **真 Python 全链**：读样本 `hash-tool.scp` → `installFromBytes`（真实磁盘 fs）→ `isInstalled=true` → `start`（探测到解释器并启动脚本，等待 ready 帧）→ `run({'text':'abc'})` → `FieldsResultDescriptor` 三字段与 hashlib 参考值硬编码断言：
   - MD5 `900150983cd24fb0d6963f7d28e17f72`
   - SHA-1 `a9993e364706816aba3e25717850c26c9cd0d89d`
   - SHA-256 `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`
   → `stop` → `isSessionLive=false` → `uninstall` → `isInstalled=false`。`@Timeout(90s)`（library 级）；无解释器时 `markTestSkipped` 跳过不失败。
2. **未安装 run → `bridge.not_installed`**（无需 Python，fake 会话工厂断言不可达）：结构化断言 `failure.code` 与 `details.pluginId`。

---

## 2. Task F4-07：开发文档走查与集中全量验证

### 2.1 走查文档（`docs/guides/v2-plugin-dev-walkthrough.md`，新建）

中文七节：前置条件（Flutter/Python 可选与探测候选）→ 仓库布局与最小验证命令 → builtin 路径（calculator 实例：包结构/清单要点/宿主镜像模式/validate 验证）→ sidecar 路径（python_sample 实例：脚本协议三件事/打包命令/宿主命令桥/e2e 命令）→ 契约检查（devkit `SurfaceContractChecks` 四个 check 方法代码示例）→ 常见错误码表（13 码）→ 常见坑（清单镜像漂移/surfaces 拼写/stdout 污染/重复安装/级联表达式取值）。文档中全部命令均实测（`validate` 三包 exit=0）。

**CLI 走查结论：未发现 CLI bug**（`validate`/`pack`/退出码约定均正常），无需修复。

### 2.2 集中全量验证（v2/ 下，M4 唯一一次）

**逐包测试全绿，总计 306 测试**：

| 纯 Dart（dart test ×11） | 数 | | Flutter（flutter test ×5） | 数 |
|---|---|---|---|---|
| plugin_contracts | 48 | | plugin_flutter | 37 |
| plugin_runtime | 26 | | plugin_devkit | 14 |
| platform_capabilities | 5 | | toolbox_host | 26 |
| platform_capabilities_windows | 3 | | plugins/calculator | 23 |
| platform_capabilities_android/ios/linux/macos/web | 各 2（共 10） | | plugins/screenshot | 13 |
| plugin_cli | 8 | | | |
| plugin_sidecar | 93 | | | |
| **小计** | **193** | | **小计** | **113** |

**dart format 全量**：`dart format --output=none --set-exit-if-changed .`（独立运行取真实退出码，规避管道 `$?` 取到 tail 退出码的假象）→ **exit 0**。

**analyze 全量**：16 包（11 个 `dart analyze` + 5 个 `flutter analyze`）全部 **No issues found**。

**依赖边界扫描（五项全过）**：

| 检查项 | 结果 |
|--------|------|
| contracts/runtime 零 `dart:io`/`dart:ffi`/`package:flutter` | ✅ 无匹配 |
| sidecar `dart:io` 限定两文件 | ✅ 恰好 `io_file_system.dart` + `io_process_launcher.dart` |
| capability 七包零相互导入 | ✅ 实现包仅导入接口包 `platform_capabilities`；接口包仅依赖 contracts |
| 插件三包零平台通道依赖 | ✅ calculator/screenshot 仅依赖 flutter sdk + plugin_contracts + plugin_flutter（+ capabilities 接口）+ devkit(dev)；python_sample 零 pip |
| `dart:ffi` 仅 gdi_capture | ✅ 仅 `platform_capabilities_windows/lib/src/gdi_capture.dart` |

### 2.3 构建矩阵复跑

`powershell -ExecutionPolicy Bypass -File scripts/v2/build-matrix.ps1`（仓库根，输出重定向临时文件，退出码 0）。首轮复跑暴露两处上批次遗留合规问题（见 §3 偏差 2/3），修复后最终结果（matrix summary 原文）：

```
compile-graph OK                           12 packages scanned, 0 platform-only imports
windows    OK                           E:\my\flutter-plugin-platform\v2\apps\toolbox_host\build\windows\x64\runner\Debug\toolbox_host.exe
web        OK                           E:\my\flutter-plugin-platform\v2\apps\toolbox_host\build\web\index.html
android    OK                           E:\my\flutter-plugin-platform\v2\apps\toolbox_host\build\app\outputs\flutter-apk\app-debug.apk
macos      SKIPPED-LOCAL-UNAVAILABLE    not a macOS host; compile-graph static check is the substitute evidence
linux      SKIPPED-LOCAL-UNAVAILABLE    not a Linux host; compile-graph static check is the substitute evidence
ios        SKIPPED-LOCAL-UNAVAILABLE    not a macOS host; compile-graph static check is the substitute evidence

RESULT: SUCCESS
```

（前两跑：第 1 跑 compile-graph VIOLATION——path_provider in host_composition_root.dart——且 web FAILED；第 2 跑 compile-graph VIOLATION——path_provider in host_data_root_io.dart——且 web FAILED（dart:ffi 根因）。修复动作：§3 偏差 2/3/4。）

### 2.4 文档交付

- `v2/README.md`：新增 M4 边界段（插件/样本/宿主桥/静态注册决策/词汇表）与「六端编译图的 M4 规则演进」小节；最小验证命令补齐 M4 包（capabilities_windows dart test、calculator/screenshot flutter test、sidecar e2e 命令）。
- `v2/plugins/calculator/README.md`、`v2/plugins/screenshot/README.md`、`v2/sidecars/python_sample/README.md`：新建三份包级 README（结构/接线/验证命令/错误码）。

---

## 3. 偏差列表（如实记录）

1. **前批次遗留 4 文件未格式化，经 `dart format` 规范化**：`platform_capabilities_windows/lib/src/gdi_capture.dart`（untracked 新文件）、`.../screen_capture_impl.dart`、`.../test/gdi_capture_test.dart`、`plugin_flutter/lib/src/widgets/result_renderer.dart`。均为 F4-02/F4-04 批次工作区遗留改动，纯空白/换行调整无语义变更；format 后复跑 plugin_flutter（37）与 capabilities_windows（3）测试全绿。集中验证要求 format 全绿，此为必要动作。
2. **F4-02 遗留：组装根直接 import path_provider**（`host_composition_root.dart`），导致 compile-graph VIOLATION 且属 web 编译隐患。修复：新建条件导出三件套 `host_data_root.dart` / `host_data_root_io.dart`（path_provider 唯一落点）/ `host_data_root_none.dart`（web 占位），组装根经条件入口取 `resolveApplicationSupportRoot`；`kWebHostDataRoot` 常量迁移至 `host_data_root.dart`（grep 确认无外部引用受影响）。行为语义不变。理由：toolbox_host 不在本批禁改清单，且为构建矩阵合规必要修复。
3. **F4-04 遗留：组装根直接 import platform_capabilities_windows**，其 `gdi_capture.dart` 的 `dart:ffi` 进入 web 编译图，`flutter build web` 实际失败（M3 时包内全 stub 故 web 可编）。修复（不动被禁包）：宿主新建 `host_screen_capture.dart` / `host_screen_capture_io.dart`（转发 `windowsScreenCapture`）/ `host_screen_capture_stub.dart`（web 取接口包 `UnsupportedScreenCapture('web')`），组装根 `screenCapture = hostScreenCapture`。截图清单 targets=[windows]，web 上该插件本就不可用，行为无回归；修复后 web 实构建通过。
4. **build-matrix.ps1 规则演进（工具脚本最小修改，非生产代码）**：compile-graph 对宿主 `*_io.dart` 条件导出分支文件豁免平台专属插件 import 检查。理由：宿主接入真实系统能力必然需要平台插件引用点，条件导出已把平台依赖隔离在 io 分支、web 编译图零混入；规则与 F4-02 确立的 `*_io.dart` 接线模式对齐。演进理由已写入脚本头注释与 v2/README「六端编译图的 M4 规则演进」小节。纯 Dart 包 dart:io/flutter 检查不变。
5. **测试计数更新（非缺陷）**：组装根注册 hash_tool 清单后目录第 4 张卡解析为「可用」，`app_test.dart` 两处「可用」徽章计数断言由 3/2 更新为 4/3，并补 Hash 工具卡存在断言。

---

## 4. 四项结论

- **e2e 结果**：真 Python 全链 2/2 通过（安装→启动→hash.compute('abc') 三摘要与 hashlib 参考值一致→停止→卸载；未安装分支结构化断言 `bridge.not_installed`）。无 Python 环境时测试自动跳过不失败。
- **全量验证测试总数**：306（dart test 193 + flutter test 113），全部通过；format 全量 exit 0；16 包 analyze 零问题；依赖边界五项扫描全过。
- **构建矩阵结果**：修复两处上批次遗留后第三次复跑——退出码 0，RESULT: SUCCESS；windows/web/android 实构建 OK（产物齐备），macos/linux/ios SKIPPED-LOCAL-UNAVAILABLE（compile-graph 静态检查替代证据，12 包扫描 0 violation）。
- **偏差列表**：见 §3（5 项，全部如实标注理由；未触碰任何禁改生产代码）。
