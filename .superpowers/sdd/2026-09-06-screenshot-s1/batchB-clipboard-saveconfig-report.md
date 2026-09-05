# Batch B Clipboard 能力 + 截图保存配置扩展报告

**日期**: 2026-09-06
**范围**: 任务一 Clipboard/KnownFolders 能力（接口 + Windows FFI + 宿主接线）；任务二 截图保存配置扩展 + 捕获落盘闭环
**约束遵守**: 未触及 contracts/runtime/plugin_flutter/plugin_sidecar/calculator；未执行 git；未改 progress.yaml；FFI/dart:io 仅存在于 windows 能力包与宿主 io 分支文件，插件包零平台依赖（image 纯 Dart 包除外）

---

## 一、文件清单

### 任务一：Clipboard + KnownFolders 能力

**接口包（platform_capabilities，纯 Dart 零 io/ffi）**
- `packages/platform_capabilities/lib/src/clipboard.dart`（新增）
  - `abstract interface class Clipboard`：`writeText(String)` / `writeImage(Uint8List pngBytes)`（PNG → CF_DIBV5）/ `writeFiles(List<String> paths)`（→ CF_HDROP），失败抛 `clipboard.locked` 结构化失败
  - `clipboardLockedFailure(String reason, String message, [details])`：错误码 `clipboard.locked`，`details.reason = openFailed|setDataFailed`
  - `final class UnsupportedClipboard implements Clipboard`：不支持平台的默认实现（恒抛 `clipboard.locked`/reason=unsupported）
- `packages/platform_capabilities/lib/src/known_folders.dart`（新增）：`abstract interface class KnownFolders`——**同步** `String? pictures()` / `String? documents()`，不可解析返回 null 由调用方回退
- `packages/platform_capabilities/lib/platform_capabilities.dart`：barrel 追加两导出
- `packages/platform_capabilities/test/clipboard_test.dart`（新增）：6 项（含接口包零 dart:io/ffi 边界扫描复检）

**Windows FFI 实现（platform_capabilities_windows）**
- `packages/platform_capabilities_windows/lib/src/clipboard_ff.dart`（新增）：`ClipboardFf` 底层绑定——`OpenClipboard` 瞬时失败重试（10 次 × 5ms）、`EmptyClipboard`/`SetClipboardData`/`CloseClipboard`；`GlobalAlloc(GMEM_MOVEABLE)` 分配并按目标格式落数据
- `packages/platform_capabilities_windows/lib/src/clipboard_impl.dart`（新增）
  - `final class WindowsClipboard implements Clipboard`：文本 → `CF_UNICODETEXT`；PNG → 内存 DIB（BITMAPV5HEADER，BGRA 自底向上行序）→ `CF_DIBV5`；文件路径 → `DROPFILES`（双 NUL 结尾宽字符列表）→ `CF_HDROP`；SetClipboardData 失败折算 `clipboard.locked`/reason=setDataFailed
  - `final class WindowsKnownFolders implements KnownFolders`：`SHGetKnownFolderPath`（FOLDERID_Pictures/Documents），失败/不可解析返回 null
- `packages/platform_capabilities_windows/lib/platform_capabilities_windows.dart`：barrel 追加导出
- `packages/platform_capabilities_windows/test/clipboard_test.dart`（新增）：7 项（1 项为真机剪贴板烟囱，按剪贴板可用性跳过）

**宿主条件导出（toolbox_host）**
- `apps/toolbox_host/lib/src/host_clipboard.dart`（新增）：`export 'host_clipboard_none.dart' if (dart.library.io) 'host_clipboard_io.dart';`
- `apps/toolbox_host/lib/src/host_clipboard_io.dart`（新增）：`createHostClipboard()` → `WindowsClipboard()`；`createHostKnownFolders()` → `WindowsKnownFolders()`
- `apps/toolbox_host/lib/src/host_clipboard_none.dart`（新增）：web → `UnsupportedClipboard` / KnownFolders 恒 null stub

### 任务二：截图保存配置扩展 + 捕获落盘闭环

**插件包（screenshot，零平台依赖）**
- `plugins/screenshot/lib/src/screenshot_model.dart`：设置扩展 5 字段——保存目录 `saveDir`（`{pictures}`/`{documents}`/`{pluginData}`，默认 `{pictures}`）、文件名模板 `filenameTemplate`（默认 `screenshot-{date}{time}`）、格式 `format`（png/jpeg，默认 png）、JPEG 质量 `jpegQuality`（int 1-100，默认 90）、自动复制 `autoCopy`（none/image/path，默认 image）；`copyWith`/`==`/`hashCode` 全字段；loadFromStorage 恢复 5 键（稳定键白名单校验、非法回退默认值）、updateSettings 即时写回
- `plugins/screenshot/lib/src/filename_template.dart`（新增）：模板纯逻辑——token `{date}`(yyyyMMdd)/`{time}`(HHmmss)/`{seq}`(同秒序号) 展开；`sanitizeFilenameBase`（非法字符与控制字符替换下划线、结尾点号与尾部空白剔除、空或仅剩下划线回退 `screenshot`）；`FilenameSequencer` 同秒递增/跨秒重置
- `plugins/screenshot/lib/src/screenshot_codec.dart`（新增）：`encodeScreenshotBytes`（png 原样透传 / jpeg 经 image 包重编码）+ 新错误码 `capture.encode_failed`（reason=decode|encode）+ `screenshotExtensionForFormat`（jpeg→jpg）
- `plugins/screenshot/lib/src/capture_controller.dart`：落盘闭环编排——模板展开（注入缝 `DateTime Function()?`，默认系统时钟）→ `encodeScreenshotBytes` 编码分派 → `_resolveSaveDir` 目录解析（`{pictures}`/`{documents}` 走 KnownFolders、不可解析回退 pluginDataDir、`{pluginData}` 直取）→ 写文件缝 `ScreenshotFileSaver`（宿主注入）→ 按 autoCopy 调剪贴板（image 始终写原始 PNG 字节；path 写完整路径；失败仅明细标记 failed）；结果为 `ImageResultDescriptor` + `ScreenshotSaveDetails`（path/width/height/copyKey，宽高解析 PNG IHDR）供页面构建；防重入 `capturing`；捕获/编码失败结构化透传，写文件异常折算 `capture.failed`/reason=saveError
- `plugins/screenshot/lib/src/screenshot_strings.dart`（新增）：28 字段全必填文案载体（6 核心 + 22 新增），含 `screenshotSaveDirLabel/Key`、`screenshotFormatLabel/Key`、`screenshotAutoCopyLabel/Key`、`screenshotCopyStatusLabel` 折算辅助
- `plugins/screenshot/lib/src/screenshot_settings.dart`：设置 surface 改为 5 字段声明式表单（目录/格式/自动复制为 Select，模板为必填 Text，质量为 NumberFieldSpec 1-100 提交钳制）；下拉以展示文案为值、提交经 `screenshot*Key` 折算回稳定键；表单下方 `formatNote` 说明文案
- `plugins/screenshot/lib/src/screenshot_page.dart`：页面以 `FieldsResultDescriptor` 呈现落盘明细（路径/尺寸/复制状态），保存成功提示带完整路径
- `plugins/screenshot/pubspec.yaml`：dependencies 追加 `image`（纯 Dart，JPEG 编解码用）
- 测试：`test/filename_template_test.dart`（新增 10 项）、`test/capture_controller_test.dart`（重写 10 项）、`test/ui/screenshot_model_storage_test.dart`（重写 4 项）、`test/ui/screenshot_page_test.dart`（重写 4 项）、`test/ui/surface_contract_test.dart`（文件缝签名跟进）、`test/ui/test_harness.dart`（kTestStrings 升级为 28 字段载体）

**宿主（toolbox_host）**
- `apps/toolbox_host/lib/src/host_file_saver.dart` / `host_file_saver_io.dart` / `host_file_saver_none.dart`：写文件缝改签名 `{required dir, required bytes, required filename}`（io 目标按目录创建并写文件，返回完整路径；web 恒返回空串）
- `apps/toolbox_host/lib/src/host_composition_root.dart`：`CaptureController` 注入 `clipboard`（createHostClipboard）、`knownFolders`（createHostKnownFolders）、`pluginDataDir`（`systemPaths.pluginDataDir(截图 ID)`）、`saveFile` lambda 桥接 `saveHostScreenshotFile`
- `apps/toolbox_host/lib/src/plugins/screenshot_plugin.dart`：`screenshotStrings` 映射扩至 28 字段
- `apps/toolbox_host/lib/l10n/app_zh.arb` / `app_en.arb`：新增 22 个 `shot*` 键（目录/模板/格式/质量/自动复制/明细/复制状态/formatNote），中英齐全；清理陈旧键 `shotSettingsFilenamePrefix`/`shotSettingsFilenamePrefixPlaceholder` 并重跑 gen-l10n

---

## 二、焦点测试结果

| 包 | 命令 | 结果 |
|---|---|---|
| platform_capabilities | `dart test` | 15/15 通过（本批新增 clipboard_test 6 项；含接口包零 dart:io/ffi 边界扫描） |
| platform_capabilities_windows | `dart test` | 14 过 + 1 跳过（本批新增 clipboard_test 7 项，1 项真机烟囱按剪贴板可用性跳过；既有 gdi/storage/stub 全回归） |
| plugins/screenshot | `flutter test` | 32/32 通过（模板纯逻辑 10 项 + 控制器 fake 注入 10 项 + 模型存储 4 项 + 页面/契约 8 项） |
| apps/toolbox_host | `flutter test` | 31/31 通过（全量回归，含截图页/设置/组装根接线） |

静态检查：`plugins/screenshot` 与 `apps/toolbox_host` `flutter analyze` 均 No issues；触及源码已 `dart format`（80 列）。

**真机剪贴板烟囱证据**（Windows 宿主，任务一阶段实跑记录）：
- `writeText` → peekText 往返一致（含中文字符串），二次写入正确覆盖；
- `writeImage`（7×3 PNG）→ peekHeader：headerSize=124（BITMAPV5HEADER）、width=7、height=3、bitCount=32、compression=3（BI_BITFIELDS），证实 CF_DIBV5 落入剪贴板；
- `writeFiles` → peekPaths 往返一致（CF_HDROP 路径列表）；
- `WindowsKnownFolders` 返回真实图片/文档目录路径。

---

## 三、接线说明

1. **能力注入**：组装根构造 `CaptureController` 时注入 `clipboard`/`knownFolders`（条件导出：io 目标 Windows FFI 真实现、web 目标 stub）、`pluginDataDir` 与 `saveFile` 缝；截图插件包对以上全部零 import（仅经构造参数耦合接口），编译图内 ffi/dart:io 只出现在 windows 能力包与宿主 io 分支文件。
2. **落盘闭环**：`capture()` → ScreenCapture 全屏捕获 → 模板展开 + 同秒序号 + 扩展名折算得文件名 → png 透传 / jpeg 重编码（`capture.encode_failed` 兜底）→ 目录解析（系统目录不可用回退插件数据目录）→ 宿主写文件 → autoCopy none 跳过 / image 写原始 PNG / path 写完整路径（复制失败不影响落盘结果，明细标记 failed）→ `ImageResultDescriptor` + 明细 descriptor 交页面渲染。
3. **设置流**：设置表单（宿主 arb `shot*` 文案 → `screenshotStrings` 映射 → 28 字段载体）提交时文案折算回稳定键、质量钳制 1-100 → `model.updateSettings` 即时经 PluginStorage 写回单一 `settings` 键；启动时组装根 `unawaited(loadFromStorage())` 异步恢复，非法键回退默认值。
4. **web 目标**：剪贴板恒不支持、已知目录恒 null、写文件恒空串——落盘闭环在 web 上产出结构化失败（capture.failed/saveError），不触碰 dart:io。

---

## 四、偏差列表

1. **JPEG 质量控件形态**：声明式表单（FormRenderer）无 slider 规格，质量以 `NumberFieldSpec(min:1,max:100,defaultValue:90)` 文本数值字段承载，提交时钳制 1-100。
2. **arb 文案规避字面 token**：ICU MessageFormat 中字面 `{date}`/`{time}` 与占位符语法冲突，formatNote 文案以文字描述 token、placeholder 用示例输出 `screenshot-20260101-120000`。
3. **落盘明细 descriptor 由页面构建**：`ScreenshotSaveDetails`（控制器持有，稳定键）→ 页面 `_buildDetailsDescriptor` 折算为 `FieldsResultDescriptor`（l10n 文案）——维持插件包零 l10n 架构。
4. **autoCopy=image 始终复制原始 PNG**：即使 format=jpeg（落盘为 JPEG），剪贴板仍写入捕获原始 PNG 字节——保真优先，避免 JPEG 二次损失；偏差如需「复制与落盘同格式」需后续迭代确认。
5. **sanitizeFilenameBase 增强两处**：① 结尾点号与尾部空白改为循环剔除（`' name. .. '` 修复为 `name`，原单次 trim 会残留尾部空格）；② 清理后为空**或仅剩替换下划线**（如 `'???'` → `'___'`）时回退 `screenshot`，避免全非法输入产出无意义文件名。
6. **windows 剪贴板烟囱测试在套件内跳过**：真机烟囱依赖剪贴板可用性（CI 无交互会话会失败），套件内按环境跳过；证据以开发机实跑记录留存于本报告第二节。
