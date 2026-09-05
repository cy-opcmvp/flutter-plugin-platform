# v2 验收报告 - B 门：构建证据（M3）

- **验收日期**: 2026-09-04
- **验收人**: 独立验收工程师（B 门）
- **工作根**: `E:\my\flutter-plugin-platform\v2`
- **验收方式**: 只读复跑（除本报告外不创建/修改任何文件；命令输出重定向至系统临时目录）
- **门结论**: （见文末）

## 工作区实际包清单

- 纯 Dart 11 包: `plugin_contracts`, `plugin_runtime`, `plugin_sidecar`, `platform_capabilities`, `platform_capabilities_windows/macos/linux/android/ios/web`, `plugin_cli`
- Flutter 3 包: `plugin_flutter`, `plugin_devkit`, `apps/toolbox_host`

---

## 1. 逐包测试复跑

命令: 每包 `dart test` / `flutter test`，输出 `2>&1 | tail -1`。

| # | 包 | 命令 | 摘要 | 结果 |
|---|----|------|------|------|
| 1 | plugin_contracts | `dart test` | `00:00 +48: All tests passed!` | PASS |
| 2 | plugin_runtime | `dart test` | `00:00 +26: All tests passed!` | PASS |
| 3 | plugin_sidecar | `dart test` | `00:06 +93: All tests passed!` | PASS |
| 4 | platform_capabilities | `dart test` | `00:00 +5: All tests passed!` | PASS |
| 5 | platform_capabilities_windows | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 6 | platform_capabilities_macos | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 7 | platform_capabilities_linux | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 8 | platform_capabilities_android | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 9 | platform_capabilities_ios | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 10 | platform_capabilities_web | `dart test` | `00:00 +2: All tests passed!` | PASS |
| 11 | plugin_cli | `dart test` | `00:00 +8: All tests passed!` | PASS |
| 12 | plugin_flutter | `flutter test` | `00:01 +35: All tests passed!` | PASS |
| 13 | plugin_devkit | `flutter test` | `00:00 +14: All tests passed!` | PASS |
| 14 | apps/toolbox_host | `flutter test` | `00:01 +9: All tests passed!` | PASS |

**汇总**: 14/14 包全绿，**250 测试 0 失败**（192 纯 Dart + 35 + 14 + 9 Flutter），与预期 250 一致。✅

## 2. 格式与静态分析

| 检查 | 命令 | 结果 |
|------|------|------|
| 格式 | `dart format --output=none --set-exit-if-changed .`（v2 根） | EXIT=0，`Formatted 131 files (0 changed)` ✅ |
| 静态分析 | `flutter analyze`（v2 根，覆盖 workspace） | EXIT=0，`No issues found! (ran in 0.9s)` ✅ |

## 3. 构建矩阵复跑

命令: `powershell -ExecutionPolicy Bypass -File E:\my\flutter-plugin-platform\scripts\v2\build-matrix.ps1 > $TEMP/g3b-matrix.log 2>&1`

- **退出码**: `MATRIX_EXIT=0`；log 尾部 `RESULT: SUCCESS`
- **log tail -15 关键行**:

```
compile-graph OK      12 packages scanned, 0 platform-only imports
windows    OK         ...\toolbox_host\build\windows\x64\runner\Debug\toolbox_host.exe
web        OK         ...\toolbox_host\build\web\index.html
android    OK         ...\toolbox_host\build\app\outputs\flutter-apk\app-debug.apk
macos      SKIPPED-LOCAL-UNAVAILABLE  not a macOS host; compile-graph static check is the substitute evidence
linux      SKIPPED-LOCAL-UNAVAILABLE  not a Linux host; compile-graph static check is the substitute evidence
ios        SKIPPED-LOCAL-UNAVAILABLE  not a macOS host; compile-graph static check is the substitute evidence
RESULT: SUCCESS
```

**三产物 Test-Path 复核**（本门独立验证，非仅采信脚本声明）:

| 产物 | 存在 | 大小 |
|------|------|------|
| `apps/toolbox_host/build/windows/x64/runner/Debug/toolbox_host.exe` | ✅ | 577,536 B |
| `apps/toolbox_host/build/web/index.html` | ✅ | 1,243 B |
| `apps/toolbox_host/build/app/outputs/flutter-apk/app-debug.apk` | ✅ | 144,937,756 B |

macos/linux/ios 如实标注 `SKIPPED-LOCAL-UNAVAILABLE`，未伪造。compile-graph 检查 OK（12 包扫描，0 平台专属导入混入）。✅

## 4. 诚实证据模型

- `grep -n "SKIPPED\|six\|六端" scripts/v2/build-matrix.ps1`（命中 8 行，无 "six" 独立命中）:
  - 脚本头注释明确 android 为条件构建、macos/linux/ios 输出 `SKIPPED-LOCAL-UNAVAILABLE` 并以「六端编译图静态检查 + flutter analyze」为替代证据（行 8-10）；
  - 行 169/173/174/175 实现了 `Add-Row ... 'SKIPPED-LOCAL-UNAVAILABLE'` 及替代证据说明文字。
- v2/README.md「M3 边界 → 六端构建证据模型」（行 41-48）明确声明「**不伪造跳过端**」：windows/web 实构建记录退出码与产物路径；android 条件构建；跳过端如实输出并给出替代证据（编译图静态检查：平台专属插件依赖零混入 + 纯 Dart 包零 dart:io/Flutter 导入）；脚本对本机状态无写死假设，CI 可直接引用。
- **判定**: 无任何"六端全绿/六端全部实构建"的伪造声明；跳过项均有替代证据说明且与本门第 5 节实测一致。✅

## 5. 依赖边界复扫

| 边界 | 扫描方式 | 结果 |
|------|---------|------|
| plugin_contracts lib 无 `dart:io\|dart:ffi\|package:flutter\|package:win32` | `grep -rlE` 全 lib | **0 文件命中** ✅ |
| plugin_runtime lib 同上 | `grep -rlE` 全 lib | **0 文件命中** ✅ |
| plugin_sidecar lib 的 dart:io 限定 | `grep -rln "dart:io"` | 仅 2 文件：`lib/src/package/io_file_system.dart`、`lib/src/process/io_process_launcher.dart` ✅（与 README M2 边界声明逐字一致） |
| capability 七包 lib 无 dart:io 导入语句 | `grep -rn "import ['\"]dart:io"` 逐包 | 七包（capabilities + windows/macos/linux/android/ios/web）**均 0 条导入** ✅ |
| plugin_flutter lib 无平台专属包 | 全 lib import/export 清单去重 | 第三方仅 `package:intl`（纯 Dart 跨平台）+ flutter/flutter_localizations，其余为包内相对导入，**零平台专属包** ✅ |
| toolbox_host lib 无平台专属包 | 全 lib `package:` import 清单去重 | 见下方说明 ✅（记录内组合根架构） |

**toolbox_host 说明**: lib 中存在 `package:platform_capabilities_windows` 导入。核对 README（行 16、33、M3 边界段）：宿主被明确记录为"依赖 platform_capabilities（**+ 对应平台包**）"、"平台实现经接口注入，**宿主按需依赖对应平台包**"、"`HostCompositionRoot` 是全应用唯一组装点"。平台实现包仅出现在 host 组合根、且未混入任何插件/运行时/devkit/capabilities 抽象层——属**记录内的依赖倒置架构**，不构成边界违规。lib 中另无 win32、window_manager、shared_preferences 等其他平台专属直接依赖。

**总判定**: 5/5 项边界全部通过。✅

## 发现分级

- **Critical**: 0
- **Important**: 0
- **Minor**: 1
  - 观察项：`toolbox_host/lib` 导入 `platform_capabilities_windows`（组合根唯一注入点，README 有明确记录，判定合规；仅作留档，供后续里程碑复核多平台注入演化时追踪）。

## B 门结论

**✅ Approved**

| 维度 | 结果 |
|------|------|
| 测试 | 14/14 包全绿，**250 测试 0 失败** |
| 格式/分析 | 0 changed；No issues found |
| 构建矩阵 | windows/web/android 实构建 OK + 三产物实证存在；macos/linux/ios 如实 SKIPPED；compile-graph OK |
| 诚实模型 | 通过——无伪造六端声明，跳过项有替代证据 |
| 依赖边界 | 5/5 项通过 |

验收证据均来自本门独立复跑（非转引历史记录）；所有长输出重定向至系统临时目录（`$TEMP/g3b-*.log`）。
