# 批三报告：F4-04 Windows ScreenCapture 真实现 + F4-05 截图插件

**日期**: 2026-09-05
**范围**: 前置小修（CLI entrypoint）、F4-04（platform_capabilities_windows 真实现）、F4-05（plugins/screenshot + toolbox_host 接线）
**约束遵守**: 未动 contracts/runtime/plugin_flutter/sidecar/platform_capabilities 接口包；FFI 与 dart:io 只出现在 platform_capabilities_windows 与宿主 app 层；截图插件包零平台依赖零 dart:io；新 UI 零样式字面量；错误码逐字对齐；未执行 git、未改 progress.yaml。

---

## 0. 前置小修：CLI entrypoint 模板修复

任务书指出 CLI 生成的 builtin entrypoint 使用 `builtin:<id>`，需修复为 `builtin://<id>`。

**偏差说明**：问题实际不在 `v2/packages/plugin_cli/lib/src/templates/builtin_template.dart`，而在 `v2/packages/plugin_cli/lib/src/commands/create.dart` 第 117 行——模板文件中的 entrypoint 本就正确，是 create 命令生成 `plugin.json` 时独立拼接了错误的 `builtin:<id>` 字面量。修复位置与任务书所列路径不同，但修改范围仍在白名单（plugin_cli）之内。

修复后同步了 create 命令测试的断言。验证：`dart run plugin_cli validate plugins/screenshot` → `OK tools.screenshot (builtin v1.0.0)`；plugin_cli 8 个测试全过。

---

## 1. Task F4-04：Windows ScreenCapture 真实现

### 1.1 文件清单（`v2/packages/platform_capabilities_windows/`）

| 文件 | 职责 |
|------|------|
| `lib/src/gdi_capture.dart`（406 行） | 全部 dart:ffi 声明收敛于此：GDI 捕获链路 + `GetDIBits` 像素读出 |
| `lib/src/png_encoder.dart` | BGRA → PNG 编码（`image` ^4.x，行序翻转在编码器内完成） |
| `lib/src/screen_capture_impl.dart` | 组装 `WindowsScreenCapture`，失败折算为 `capture.failed` |
| `lib/src/stub.dart` | 非 Windows 目标 stub（既有，未改） |
| `test/gdi_capture_test.dart` | 真机烟囱 + 零尺寸纯逻辑分支 |
| `test/stub_test.dart` | stub unsupported 失败（既有，未改） |

顶层符号 `windowsScreenCapture`（const `WindowsScreenCapture()`）供宿主组装根直接注入。

### 1.2 GDI 调用序列说明（gdi_capture.dart）

查询序列（`queryScreenInfo`）：

```
GetDC(0) → GetDeviceCaps(LOGPIXELSX=88 / LOGPIXELSY=90 / HORZRES=8 / VERTRES=10)
→ [校验正值并换算 scaleX/scaleY = dpi / 96] → finally: ReleaseDC(0, screenDc)
```

捕获序列（`capturePhysical`）：

```
GetDC(0)                                    —— 屏幕 DC
CreateCompatibleDC(screenDc)                —— 内存 DC
CreateCompatibleBitmap(screenDc, w, h)      —— 兼容位图
SelectObject(memoryDc, bitmap)              —— 选入位图（记录 previousObject）
BitBlt(memoryDc, 0, 0, w, h, screenDc, left, top,
      SRCCOPY=0x00CC0020 | CAPTUREBLT=0x40000000)
  └─ finally: SelectObject(memoryDc, previousObject)   ← 解除选中（GetDIBits 要求）
GetDIBits(screenDc, bitmap, 0, h, buffer, info, DIB_RGB_COLORS)
  —— BI_RGB 32bpp BGRA、正 biHeight 即自下而上行序（翻转交由 PNG 编码器）
  └─ finally: free(info)
→ 返回 GdiPixels
  └─ finally: free(pixelBuffer) → DeleteObject(bitmap) → DeleteDC(memoryDc) → ReleaseDC(0, screenDc)
```

组装层（screen_capture_impl.dart）语义：`Rect` 按虚拟屏幕坐标解释，仅支持主屏；先按 DPI 缩放为物理像素，再裁剪到主屏边界；全屏由调用方传超大矩形（0,0,100000,100000）配合边界裁剪达成。

### 1.3 资源释放路径表（泄漏零容忍证据）

| 资源 | 获取点 | 正常释放点 | 异常释放点 | 备注 |
|------|--------|-----------|-----------|------|
| 屏幕 DC | `GetDC(0)` | `capturePhysical` 外层 finally `ReleaseDC(0, screenDc)` | 同左（try 覆盖全部后续步骤） | `GetDC(0)` 返回 0 时直接抛 `GdiCaptureException`，无句柄可泄 |
| 内存 DC | `CreateCompatibleDC` | 外层 finally `DeleteDC`（guard `!= 0`） | 同左；`CreateCompatibleDC` 失败时保持 0 不误删 | |
| 兼容位图 | `CreateCompatibleBitmap` | 外层 finally `DeleteObject`（guard `!= 0`） | 同左；`SelectObject`/`BitBlt`/`GetDIBits` 抛出时均经过 | |
| 原选中对象恢复 | `SelectObject(memoryDc, bitmap)` | `BitBlt` 的内层 finally 恢复 previousObject | `BitBlt` 抛出时同样恢复 | 满足 `GetDIBits` 对"位图未被选入 DC"的要求 |
| 像素缓冲 `Pointer<Uint8>` | `calloc<Uint8>(byteLength)` | `_readPixels` 外层 finally `calloc.free` | 同左 | |
| BITMAPINFO `Pointer` | `calloc<_BitmapInfo>()` | 内层 finally `calloc.free` | 同左 | |
| 屏幕 DC（查询路径） | `queryScreenInfo` 的 `GetDC(0)` | 该方法自身 finally `ReleaseDC` | 同左 | 返回 null 的全部路径均经 finally |

唯一 `calloc` 分配均在各自 try 的 finally 中释放；三处 GDI 句柄释放顺序固定为 bitmap → memoryDc → screenDc（先删从属资源再释放父 DC）。没有任何一条路径在异常时跳过释放。

### 1.4 失败折算（错误码逐字对齐）

`captureRegion` 的全部失败路径折算为 `capture.failed`，`details.reason` 词汇表三值（不扩张）：

| reason | 触发条件 |
|--------|---------|
| `noScreen` | 零宽/零高请求（不触碰 GDI）、`queryScreenInfo` 抛出或返回 null、经主屏边界裁剪后区域为空 |
| `gdiError` | `capturePhysical` 链路任一 GDI 步骤失败 |
| `encodeError` | `encodeBgraPng` 抛出或产出为空 |

### 1.5 真机烟囱证据（Windows 11 实机运行）

测试 `gdi_capture_test.dart` 以超大请求矩形（0,0,100000,100000）触发全屏捕获，断言 PNG 魔数 `\x89PNG\r\n\x1a\n`、IHDR 宽高、字节量后落盘临时文件。实机输出（stderr）：

```
烟囱捕获证据：width=2560 height=1440 bytes=1749704 path=%TEMP%\win_capture_smokeXXX\screen.png
```

- 分辨率与实机主屏物理分辨率一致（2560×1440）；
- 字节量 1,749,704 ≈ 期望下界（`2560×1440×4 = 14,745,600` 原始 BGRA 压缩为 PNG 后约 8.5%，合理）；
- 文件保留未删除，供人工查验。

---

## 2. Task F4-05：截图插件（Windows 平台变体）

### 2.1 包结构（`v2/plugins/screenshot/`，新建）

```
plugins/screenshot/
├── plugin.json                     # 手工维护：targets [windows]、provides [image.capture v1]、surfaces [page, settings]
├── pubspec.yaml                    # 依赖仅 plugin_contracts / plugin_flutter / platform_capabilities（接口包）；零 windows 包、零 dart:io
├── lib/screenshot.dart             # barrel
└── lib/src/
    ├── screenshot_manifest.dart    # screenshotManifest()：与 plugin.json 镜像（宿主一致性测试校验）
    ├── screenshot_model.dart       # ScreenshotModel（共享模型）+ ScreenshotSettings（filenamePrefix + quality 稳定键）
    ├── screenshot_strings.dart     # 13 字段文案载体 + ScreenshotStringsResolver typedef + 质量键/文案双向映射
    ├── capture_controller.dart     # CaptureController：注入 ScreenCapture 接口 + 写文件缝
    ├── screenshot_page.dart        # 页面提供方（捕获按钮 → ResultRenderer 结果区 → 保存提示/失败行）
    └── screenshot_settings.dart    # 设置提供方（FormRenderer：文件名前缀 TextField + 保存质量 Select）
```

### 2.2 CaptureController 设计（缝注入，零平台依赖）

- `ScreenCapture` 为构造注入的接口（来自 platform_capabilities 接口包），包内不出现任何 windows 实现类型；
- `typedef ScreenshotFileSaver = Future<String> Function(Uint8List bytes, String filename)` 为写文件缝——宿主接线 dart:io 落盘，插件包内无 IO；
- `capture()`：防重入 gate（`_inFlight` 完成前拒绝并发捕获）→ `screenCapture.captureRegion(kFullscreenRegion)`（超大矩形 + 实现侧边界裁剪）→ 成功折算 `ResultDescriptor`（image 类型，路径 `{dataDir}/{filename}`）→ `_saveAndRecord` 调用注入的写文件缝并记录 savedPath；
- 失败透传：能力层 `capture.failed` 结构化失败原样进入结果描述符；写文件缝抛 `Exception` 时折算为 `PluginFailure('capture.failed', '截图保存失败：$error', {'reason': 'saveError'})`（见偏差 5）；
- 文件名：`{prefix}-{yyyyMMdd-HHmmss}.png`（手写时间戳格式化，避免 ISO 8601 的冒号进入文件名）。

### 2.3 UI（零样式字面量）

- 页面：`FilledButton.icon` 捕获按钮（捕获中禁用 + capturing 文案）→ `ResultRenderer`（image 结果经注入的 `bytesLoader` + FutureBuilder `Image.memory` 呈现）→ 保存成功提示（含路径，primary 色 bodyMedium）或失败行（`'{failureTitle}：{message}'`，error 色）；
- 设置：`FormRenderer` 提交式表单——文件名前缀 `TextFieldSpec`（required，占位符 'shot'）+ 保存质量 `SelectFieldSpec`（显示文案 ↔ 稳定键 'lossless'/'high'/'standard' 双向映射，onSubmit 折算回稳定键写回模型）+ qualityNote 说明行（bodySmall）；
- 全部文案经 13 字段 `ScreenshotStrings` 载体注入，包内零硬编码用户可见文本；提示行样式用 `Theme.of(context).textTheme`（plugin_flutter barrel 未导出 token_text_style，见偏差说明节）。

### 2.4 宿主接线（`v2/apps/toolbox_host/`）

| 变更 | 内容 |
|------|------|
| `pubspec.yaml` | 新增 `screenshot: path: ../../plugins/screenshot` |
| `lib/src/host_file_saver.dart` / `_io.dart` / `_none.dart` | 条件导出写文件缝（镜像 host_bytes_loader 模式）：io 目标 `Directory.create(recursive:) + File.writeAsBytes(flush: true)` 返回落盘路径；web 目标恒返回 `''`（截图清单仅 windows 目标，该分支不调用） |
| `lib/l10n/app_zh.arb` / `app_en.arb` | 追加 13 个 `shot*` 键（camelCase、shot 前缀）；`shotSavedHint` 带 `{path}` 占位符（含 `@shotSavedHint` placeholders 元数据） |
| `lib/src/generated/host_l10n.dart` | `flutter gen-l10n` 产出（HostL10n.of(context)） |
| `lib/src/plugins/screenshot_plugin.dart` | `screenshotStrings(HostL10n)` 13 字段一一映射 + `hostScreenshotStringsResolver()`（复制 calculator 接线模式） |
| `lib/src/host_composition_root.dart` | ① manifests 列表加入 `screenshotManifest()`；② `bytesLoader = loadHostImageBytes` 赋值先于 pageProviders 构造（截图页面构造注入该函数引用，顺序敏感）；③ 构造 `CaptureController(screenCapture: screenCapture, saveFile: 写入 systemPaths.pluginDataDir(tools.screenshot), model:)`——`screenCapture` 即 F4-04 的 `windowsScreenCapture` 真实现；④ pageProviders 加入 `ScreenshotPageProvider`、settingsProviders 加入 `kScreenshotPluginId: ScreenshotSettingsProvider` |

宿主层 dart:io 仅存在于 `host_file_saver_io.dart` 与 `host_bytes_loader_io.dart`（条件导出 io 变体），符合约束。

### 2.5 测试

**screenshot 包（13 个）**：
- `test/capture_controller_test.dart`（5）：fake ScreenCapture 注入——成功路径产出 image 描述符并落盘返回路径；能力失败 `capture.failed` 透传；写文件缝抛异常折算 `reason: saveError`；防重入 gate（gate.complete 前重入调用被拒）；文件名含前缀。
- `test/surface_contract_test.dart`（4）：清单与 `screenshotManifest()` 一致、provides image.capture v1、surfaces 声明、page/settings 提供方 id 匹配。
- `test/ui/screenshot_page_test.dart` + `test_harness.dart`（4）：初始态、捕获成功（`find.byType(Image)` + 已保存提示）、失败文案、设置表单提交（前缀回写 + 质量折算）。harness 注册 PluginFlutterL10n delegates + 固定中文文案。

**toolbox_host（17 个，回归）**：
- 原有 11 个全过；新增 2 个：截图插件注册/页面/设置提供方/无 surface 失败/数据目录 `$hostDataRoot/tools.screenshot`；`screenshotManifest()` 与 plugin.json 逐字段一致（镜像 calculator 一致性测试）。
- `app_test.dart` 调整（4 个全过）：目录页补 `find.text('截图')` 断言；可用徽章 2→3；停用 Welcome 后 1→2（计算器与截图保持可用）。

---

## 3. 验证记录

| 验证项 | 结果 |
|--------|------|
| `dart analyze`（plugin_cli / platform_capabilities_windows / screenshot / toolbox_host） | 全部 No issues found |
| `dart format`（新增/修改文件均 80 列格式化） | 通过 |
| plugin_cli 测试 | 8 个全过 |
| platform_capabilities_windows 测试（F4-04 焦点） | 3 个全过（含真机烟囱） |
| screenshot 包测试（F4-05 焦点） | 13 个全过 |
| toolbox_host 测试（回归） | 17 个全过 |
| `dart run plugin_cli validate plugins/screenshot` | `OK tools.screenshot (builtin v1.0.0)` |

未跑全量 workspace 测试（按任务约束，每任务焦点测试 + 包级 analyze）。

---

## 4. 偏差列表

1. **前置小修位置**：entrypoint bug 实际在 `v2/packages/plugin_cli/lib/src/commands/create.dart`（第 117 行），而非任务书所称 `templates/builtin_template.dart`——模板文件本身正确，是 create 命令生成 plugin.json 时拼接了错误字面量。修改仍在 plugin_cli 白名单内。
2. **零尺寸区域 reason 归 `noScreen`**：请求宽/高 ≤ 0 时不触碰 GDI 直接失败，reason 取既有三值词汇表中的 `noScreen` 而非新增第四值（如 invalidRegion），保持词汇表不扩张；details 携带 regionWidth/regionHeight 供诊断。
3. **quality 'high'/'standard' 为预留稳定键**：设置下拉提供三档选项，但 MVP 阶段编码器一律 PNG 原图保存（'lossless' 语义），'high'/'standard' 仅作为稳定键与文案预留，界面以 qualityNote 说明。后续接入 JPEG/WebP 时无需迁移配置。
4. **烟囱证据输出走 stderr**：真机烟囱测试的路径与尺寸证据用 `stderr.writeln` 输出（flutter_test 对 stdout 的 print 有缓冲干扰），文件保留不删除供人工查验。
5. **saveError 为插件层新增 reason**：`capture.failed` 的能力层词汇表仍为三值（noScreen/gdiError/encodeError）；插件控制器在写文件缝异常时折算的 `PluginFailure` 携带 `reason: saveError`。该 reason 由插件层引入（不在能力层词汇表内），语义为"能力成功但落盘失败"，无法归入能力层三值——选择新增而非误标。
6. **删除 CLI 生成的根级骨架文件**：CLI 起步工具在包根生成了 `tools_screenshot_plugin.dart` 骨架（与 lib/src 内手工实现重复的死代码），已删除；plugin.json 按任务要求手工维护。
7. **FormRenderer 为提交式保存**：设置表单沿用 plugin_flutter 现有 FormRenderer 语义（onSubmit 一次性回填），非逐字段实时保存；与 calculator 设置接线一致。若后续要求实时保存需扩展 FormRenderer（属 plugin_flutter 包，本批禁止修改）。
8. **提示行样式不依赖 token_text_style**：plugin_flutter barrel 未导出 `token_text_style.dart`（接口包禁止修改），页面提示行改用 `Theme.of(context).textTheme.bodyMedium?.copyWith(...)` 达成同等语义。

---

## 5. 修改文件总表

**前置小修**：`v2/packages/plugin_cli/lib/src/commands/create.dart`、对应测试。

**F4-04**（`v2/packages/platform_capabilities_windows/`）：`lib/src/gdi_capture.dart`、`lib/src/png_encoder.dart`、`lib/src/screen_capture_impl.dart`、`lib/platform_capabilities_windows.dart`（barrel 导出）、`test/gdi_capture_test.dart`、`pubspec.yaml`（image 依赖）。

**F4-05**：新建 `v2/plugins/screenshot/` 全包；`v2/apps/toolbox_host/` 的 `pubspec.yaml`、`lib/src/host_file_saver*.dart`（3 文件）、`lib/src/plugins/screenshot_plugin.dart`、`lib/src/host_composition_root.dart`、`lib/l10n/app_zh.arb`、`lib/l10n/app_en.arb`、`lib/src/generated/host_l10n.dart`（gen-l10n 产出）、`test/composition_root_test.dart`、`test/app_test.dart`；`v2/pubspec.yaml`（workspace 登记）。
