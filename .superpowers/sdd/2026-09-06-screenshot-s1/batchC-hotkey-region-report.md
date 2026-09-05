# S1 批C 收官报告：全局热键 + 区域选择闭环

**日期**: 2026-09-06
**范围**: platform_capabilities（GlobalHotkeys 接口）、platform_capabilities_windows（FFI 实现）、apps/toolbox_host（overlay + 窗口形态 + 组装）、plugins/screenshot（接缝 + S1 接线）

---

## 一、交付内容

### Task 1：GlobalHotkeys 能力（platform_capabilities + windows 实现）

- `packages/platform_capabilities`：纯 Dart `GlobalHotkeys` 接口
  （`register(id, combo)` / `unregister(id)` / `hotkeyFired` 事件流），
  错误码 `hotkey.register_failed`（reason: conflict / invalid / unsupported）。
- `packages/platform_capabilities_windows`：FFI 实现 `hotkey_ff`
  （Win32 `RegisterHotKey` + `PeekMessage` 消息轮询转发事件流），
  组装根导出 `globalHotkeys`。
- `apps/toolbox_host`：`host_hotkeys` 条件导出三件套（io/none），组装根
  装配 `globalHotkeys` 并注入截图页。

### Task 2：区域选择 overlay + S1 闭环

- **插件侧接缝**（`plugins/screenshot/lib/src/region_selection.dart`，
  零平台依赖）：
  - typedef `RegionSelector` / `HotkeyBinder` / `HotkeyUnbinder`；
  - `ScreenRegion`（logicalRect / physicalRect / action）；
  - 纯函数 `screenshotPhysicalRegionFromLogical`（先钳制四边再推导宽高）、
    `screenshotIsValidHotkeyCombo`、`screenshotRegionDragModeFor`、
    `screenshotRegionRectForDrag`（new/move/resize 三模式 + 最小边长
    `kMinRegionLogicalSize = 8`）。
- **宿主 overlay**（`apps/toolbox_host/lib/src/region_selection/`）：
  - `region_selection_overlay.dart`：全屏路由内容——冻结帧底图铺满 +
    半透明四段遮罩 + 红框与四角控制点 + 尺寸标签 + 工具条（保存/复制/
    放弃）；拖拽新建/框内移动/角点缩放；Enter 确认、Esc 取消；
  - `region_selection_coordinator.dart`：`HostRegionSelectionCoordinator`
    （窗口形态切换 → overlay 路由 → 恢复窗口）+ `RegionHotkeyBinding`
    （bind 幂等反绑、失败清理、按固定能力 id `screenshot.region` 过滤）；
  - `host_window` 条件导出：io 分支 `WindowsHostWindowOps`
    （window_manager 全屏 + 置顶 + 跳任务栏，退出按快照恢复），web 分支
    `NoopHostWindowOps`（window_manager 零依赖，条件导出保证零调用）。
- **S1 接线**（插件截图页）：设置热键字段默认 `Ctrl+Shift+A`；页面
  `initialize` 注册热键 → 触发 → 全屏捕获 → `regionSelector` overlay →
  用户框选确认 → 二次捕获物理区域 → 批B 保存 + 剪贴板复制闭环；
  热键注册失败按 reason 提示（冲突/无效/不支持）。

---

## 二、测试计数

| 包 | 结果 | 说明 |
|---|---|---|
| platform_capabilities | **18 pass** | 接口契约、barrel 边界扫描（零 dart:io/ffi） |
| platform_capabilities_windows | **30 pass + 1 skip** | FFI 结构编解码、stub 路径、hotkey 解析 |
| plugins/screenshot | **53 pass** | region_selection 14 + capture_controller 17（区域闭环 7 场景）+ 既有 |
| apps/toolbox_host | **43 pass** | region_selection_coordinator 6 + region_selection_overlay 6 + 既有 |

静态检查：宿主 `flutter analyze` No issues；触及文件全部 `dart format`（80 列）。
烟囱：`flutter build windows --debug` 成功（`build\windows\x64\runner\Debug\toolbox_host.exe`）。

---

## 三、真机热键证据

- Windows 真机（Debug 构建）运行宿主，`GlobalHotkeys.register`
  （`screenshot.region`，`Ctrl+Shift+A`）返回 `true`；
- 宿主不在前台时按下 `Ctrl+Shift+A`，`hotkeyFired` 事件流收到
  `screenshot.region`，回调触发全屏捕获 + overlay；
- `unregister` 后重注册成功；重复注册同 combo 返回失败，
  reason 归类为 conflict（错误码 `hotkey.register_failed`）。

---

## 四、S1 闭环自测步骤清单（真机走查）

1. 启动 `toolbox_host.exe`，进入截图插件页面；
2. 设置页确认区域热键字段默认 `Ctrl+Shift+A`（可改，保存后生效）；
3. 页面加载后热键自动注册；若被其他程序占用应提示注册失败（冲突）；
4. 切到任意其他应用前台，按 `Ctrl+Shift+A` → 宿主进入全屏置顶
   overlay（冻结帧底图 + 遮罩，任务栏不显示）；
5. 空白处拖拽框选 → 红框、四角控制点、尺寸标签、工具条出现；
6. Enter（或工具条"保存"）→ overlay 退出、窗口恢复正常形态 →
   自动二次捕获所选物理区域 → 保存到截图历史 + 剪贴板复制；
7. 再次热键 → 框选 → 点"复制" → 仅复制不新增保存；
8. 再次热键 → 框选 → 点"放弃"或按 Esc → 无捕获，窗口恢复；
9. 框选后拖动框内平移、拖四角缩放，确认最小边长 8 生效、不越视口；
10. 取消后检查窗口尺寸/置顶/任务栏状态完全恢复（与进入前一致）。

---

## 五、偏差列表

1. **controller 传逻辑选区而非物理选区**：capture controller 内部按
   DPR 折算物理区域，插件 API 面只暴露逻辑坐标，换算下沉到内部；
2. **`imageLogicalSize` 实际携带底图像素尺寸**（`Rect(0,0,像素宽,像素高)`，
   left/top 恒 0），字段名义与实际语义有偏差，已在文档注释中说明；
3. **overlay 工具条文案键无 `shot` 前缀**：使用宿主 `regionSelector*`
   键（宿主自有文案），未遵循插件 `shot_*` 前缀约定（文案归宿主层）；
4. **测试驱动修复 `screenshotPhysicalRegionFromLogical` 钳制顺序 bug**：
   原实现先推导宽高后钳制，越界拖拽会产生负宽高，改为先钳四边再推导；
5. **`HostWindowOps` 由 `abstract final class` 改为 `abstract interface
   class`**：`final` 禁止库外实现，测试 fake 需库外 implement；
6. **`_buildSizeLabel` ParentData 修复**：`Positioned` 必须是 Stack
   直接子级，`IgnorePointer` 移入 `Positioned.child`（widget 测试驱动
   发现，原先包在 Positioned 外层会抛 ParentDataWidget 异常）。

---

## 六、约束遵守

- 修改范围仅触及指定四处；未动 contracts/runtime/plugin_flutter/
  plugin_sidecar/calculator；
- window_manager 仅宿主 app 层，web 分支零调用（条件导出三件套）；
- 插件零平台依赖不变（barrel 边界扫描测试持续守护）；
- 未执行 git 操作，未改 progress.yaml。
