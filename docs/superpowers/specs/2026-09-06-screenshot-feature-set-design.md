# 截图功能集 v2 回归设计（roadmap #8–15）

| | |
|---|---|
| **日期** | 2026-09-06 |
| **状态** | 设计草案（待用户确认后排期实施；对应 roadmap 第二组「截图七件套」） |
| **背景** | v1 截图是完整产品级功能（8 能力簇，见 `docs/archive/v1/plugins/screenshot/` 与差异清单 §A）；v2 目前只有全屏捕获地基。本设计给出在 v2 架构下的回归路线。 |
| **前置架构事实** | 捕获能力已契约化（`ScreenCapture` 接口 + Windows GDI 真实现）；截图是 builtin 插件（零平台依赖）；详情页已支持内嵌插件页面（一次点击达场景）。 |

---

## 0. 总原则

1. **原生代码只进能力适配包**（`platform_capabilities_windows`，FFI 已收敛于既定文件模式）；截图插件本体保持零平台依赖。
2. **优先复用 v2 已验证的机制**：条件导出、声明式设置表单、ResultRenderer（image bytesLoader 已支持）、FFI 三件套模式。
3. 每个能力簇独立可交付、独立可验收（沿用 SDD 分批模式）。

## 1. 依赖图与实施顺序

```text
存储契约#7 ──────────┐
                     ├──▶ S2 历史记录(#11)
热键契约#2 ──▶ S1 热键(#12)          ┌─▶ S3 窗口捕获(#9)（需窗口枚举新能力）
                     │               │
区域选择(#8, 方案A) ──┴─▶ S1 快捷闭环 ─┤
剪贴板(#14) ────────────┘             └─▶ S3 定时截图(#13)（插件内 Timer MVP）
编辑器(#10, 纯Flutter) ──▶ S2（无前置）
保存配置(#15) ──▶ 随 S1 扩展字段回归
```

**推荐三个迭代**（每个都产出完整可用的用户体验增量）：

| 迭代 | 内容 | 出口体验 |
|---|---|---|
| **S1 快捷闭环**（建议先做） | 热键契约最小实现 + 区域选择 + 裁剪保存 + 剪贴板复制 + 保存配置扩展 | “按热键 → 框选 → 自动保存+复制”——v1 的核心日常体验 |
| **S2 编辑与历史** | 标注编辑器（撤销/重做）+ 存储契约（若未建）+ 历史列表 | “截后标注 → 历史里翻找” |
| **S3 窗口与定时** | 窗口枚举 + 窗口捕获 + 定时任务 | 完整对齐 v1 能力面 |

## 2. 各能力簇技术设计

### 2.1 区域选择 overlay（#8，S1 核心）

**路线对比**：

| | v1 原生路线（C++ 全屏窗口） | **方案 A：Flutter 层 overlay（推荐）** |
|---|---|---|
| 原理 | 原生全屏窗口画遮罩 | 先全屏捕获底图 → Flutter **无边框全屏透明置顶窗口**显示底图 → 用户框选 → 按 DPI 换算裁剪 |
| 新原生代码 | ~400 行 C++ | **零**（透明窗口是 Flutter 桌面既有能力，宠物 PoC 的 Godot 侧已旁证 Windows 合成透明可靠） |
| 多屏/DPI | 手工处理 | 底图即物理像素，坐标换算集中在 `captureRegion` 既有 Rect 约定（自绘 Rect → GDI 已含 DPI 换算） |
| 风险 | 维护双端 | 需要新增 `window_manager` 类桌面窗口依赖（仅宿主 app 层，走条件导出三件套模式，不污染六端编译图） |

**交互规格**（对齐 v1）：全屏半透明遮罩 + 选区高亮 + 红框与控制点 + 拖动实时尺寸 + ESC 取消 + 双击/回车确认；确认后进入「立即保存 / 标注（S2 后） / 复制 / 放弃」浮动条。

### 2.2 全局热键契约（#2，S1）

- 新能力接口 `GlobalHotkeys`（platform_capabilities）：`register(id, combo) → granted` / `unregister(id)` + 事件流 `hotkeyFired(id)`；Windows 实现 `RegisterHotKey` FFI + 消息轮询线程（或 `MessageWindow`）。
- **双消费者同底座**：宿主内截图插件与 PetLink `hotkey.register` 动词共用此实现（协议词汇已冻结，正好落地）。
- 插件侧经声明式设置声明默认热键（如 `Ctrl+Shift+A`），用户可在设置表单改。

### 2.3 剪贴板复制（#14，S1）

- 新能力接口 `Clipboard`：`writeImage(bytes)` / `writeFiles(paths)` / `writeText(text)`；Windows 实现 FFI `OpenClipboard/EmptyClipboard/SetClipboardData`（CF_DIBV5 与 CF_HDROP）。
- 截图动作链：捕获 → （可选标注）→ 保存文件 + 按配置自动复制（图片或路径）。

### 2.4 保存配置回归（#15，S1）

现有声明式设置表单扩展字段：保存目录（占位符 `{documents}/{pictures}/{pluginData}`）、文件名模板（`{date}{time}{seq}` tokens）、格式（PNG/JPEG + 质量）、自动复制开关与内容（图像/路径）、保存后行为（提示/静默）。**全部走 FormRenderer，零新 UI 框架**。

### 2.5 标注编辑器（#10，S2）

- 纯 Flutter：`CustomPaint` + 手势识别；元素模型 `AnnotationShape`（矩形/椭圆/画笔路径/文字[后置]/马赛克[后置]）；**命令模式撤销栈**（`UndoStack`，插入即执行）。
- 入口：区域选择确认后的浮动条「标注」→ 编辑画布（内嵌或全屏）→ 完成 → 导出合成 PNG（`image` 包合成，或 Flutter `canvas.toImage`）。
- 零平台依赖、零新原生代码——S2 中最独立的一项。

### 2.6 插件数据存储契约（#7，S2 前置）

最小可用版：`PluginStorage` 能力接口——插件作用域 KV（`get/set/delete`）+ 文件区（`list/read/write/delete`，落宿主数据目录 `pluginDataDir`）。Windows/桌面真实现（dart:io，条件导出），六端 stub。**这是 roadmap 第一组的地基项，S2 开工前先立**。

### 2.7 历史记录（#11，S2）

- 存储：截图元数据列表（KV：时间/路径/尺寸/缩略图路径）+ 缩略图文件（`image` 包 resize 至 ~240px）。
- 保留策略：数量上限（默认 100）+ 按天清理，设置表单可调。
- UI：截图插件内嵌页面的「历史」区——缩略图网格（`GridView.builder`）+ 点击预览（ResultRenderer image）+ 重新复制/删除。

### 2.8 窗口枚举与窗口捕获（#9，S3）

- 新能力接口 `WindowEnumeration`（`listVisibleWindows() → [handle, title, bounds]`）+ `ScreenCapture.captureWindow(handle)`；Windows 实现 `EnumWindows/PrintWindow|BitBlt` FFI（DWM 下 `PrintWindow` + `DwmGetWindowAttribute` 取客户区）。
- 交互：热键变体或按钮 → 窗口列表浮层（宿主渲染）→ 选中隐藏本窗后截取。

### 2.9 定时/循环截图（#13，S3）

- **MVP 简化**：不等平台级任务调度契约，截图插件内 `Timer`（进程内、随宿主生命周期）即可满足"宿主开着才定时截"的日常场景；间隔/次数/保留策略进设置表单。平台级调度契约（跨进程、宿主关闭也能触发）留 roadmap 原项，需要时再立。

## 3. 横切关注点

| 项 | 约定 |
|---|---|
| 错误码扩展 | `hotkey.register_failed`（reason: conflict\|invalid）、`clipboard.locked`、`storage.io_error`、`capture.window_not_found`、`annotate.export_failed` |
| 多屏 DPI | 一切选区坐标先经 `screen.info`（PetLink 已定义同形能力）换算物理像素再裁剪 |
| 六端边界 | 所有新原生依赖仅入 windows 能力包 + 宿主条件导出；web/移动 stub 结构化降级 |
| 测试策略 | 沿用精简原则：坐标换算/撤销栈/保留策略/模板展开为纯逻辑全测；overlay 与热键走真机烟囱 + fake 能力注入的插件级测试 |
| 验收 | 每迭代独立 G 门（Terra 分簇 + 抽真机证据） |

## 4. 与既有资产的对齐

- 差异清单（`docs/superpowers/cutover/v1-v2-feature-diff.md`）§A 的 8 行在本设计全部有归宿；完成后更新 roadmap #8–15 状态。
- v1 可参考实现：区域遮罩绘制算法（`docs/archive/v1/` 的双缓冲/分段遮罩文档）、热键修复记录（`troubleshooting/screenshot-hotkey-fix-*.md`）——**只参考行为语义，不复制代码**。
