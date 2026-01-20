# 截图插件配置说明

## 配置概述

截图插件配置文件定义了保存路径、文件命名、图片质量、剪贴板行为、历史记录、快捷键和钉图设置等行为。所有配置项都有合理的默认值，一般情况下无需修改。

## 配置项说明

### version
- **类型**: `string`
- **默认值**: `"1.0.0"`
- **说明**: 配置文件版本号，用于未来的配置迁移和兼容性管理
- **注意**: 不要手动修改此字段

### savePath
- **类型**: `string`
- **默认值**: `"{documents}/Screenshots"`
- **说明**: 截图保存路径，支持占位符
- **支持的占位符**:
  - `{documents}` - 用户文档目录
  - `{desktop}` - 桌面目录
  - `{pictures}` - 图片目录
  - `{downloads}` - 下载目录
- **平台路径示例**:
  - Windows: `C:\Users\{用户名}\Documents\Screenshots`
  - macOS: `/Users/{用户名}/Documents/Screenshots`
  - Linux: `/home/{用户名}/Documents/Screenshots`
- **自定义路径**:
  ```json
  "savePath": "{documents}/MyScreenshots"
  "savePath": "{desktop}/截图"
  "savePath": "D:/Screenshots"  // Windows 绝对路径
  ```
- **注意**: 目录不存在时会自动创建

### filenameFormat
- **类型**: `string`
- **默认值**: `"screenshot_{timestamp}"`
- **说明**: 文件名格式，支持占位符
- **支持的占位符**:
  - `{timestamp}` - Unix 时间戳（毫秒）
  - `{date}` - 日期 (YYYY-MM-DD)
  - `{time}` - 时间 (HH-MM-SS)
  - `{datetime}` - 日期时间 (YYYY-MM-DD_HH-MM-SS)
  - `{index}` - 自增序号（当天内递增）
- **示例**:
  ```json
  "filenameFormat": "screenshot_{timestamp}"
  // 结果: screenshot_1736952645000.png

  "filenameFormat": "Screenshot_{date}_{time}"
  // 结果: Screenshot_2026-01-15_19-30-45.png

  "filenameFormat": "{datetime}"
  // 结果: 2026-01-15_19-30-45.png

  "filenameFormat": "Screenshot_{date}_{index}"
  // 结果: Screenshot_2026-01-15_1.png
  //       Screenshot_2026-01-15_2.png
  //       Screenshot_2026-01-15_3.png
  ```
- **注意**: 占位符会被自动替换，无需手动添加

### imageFormat
- **类型**: `string`
- **默认值**: `"png"`
- **可选值**: `"png"`, `"jpeg"`, `"webp"`
- **说明**: 图片格式
- **格式对比**:
  | 格式 | 优点 | 缺点 | 适用场景 |
  |------|------|------|----------|
  | `png` | 无损压缩、支持透明度 | 文件较大 | 需要高质量截图 |
  | `jpeg` | 文件小、压缩率高 | 有损压缩、无透明度 | 快速分享、存档 |
  | `webp` | 现代格式、高压缩比 | 兼容性稍差 | Web 发布、存储优化 |
- **建议**:
  - 一般使用: `"png"`（默认）
  - 节省空间: `"jpeg"` 或 `"webp"`
  - Web 发布: `"webp"`
- **示例**:
  ```json
  "imageFormat": "png"  // 无损 PNG 格式
  ```

### imageQuality
- **类型**: `integer`
- **默认值**: `95`
- **取值范围**: `1-100`
- **说明**: 图片质量（仅对 JPEG 和 WebP 格式有效）
- **质量说明**:
  - `1-49` - 低质量，文件小，但有明显压缩痕迹
  - `50-79` - 中等质量，适合快速分享
  - `80-94` - 高质量，适合存档
  - `95-100` - 最高质量，文件较大
- **注意**: PNG 格式忽略此设置（无损）
- **示例**:
  ```json
  "imageQuality": 95  // 95% 质量
  ```

### autoCopyToClipboard
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 截图后是否自动复制到剪贴板
- **建议**:
  - 快速分享: `true`（默认）
  - 仅保存文件: `false`
- **示例**:
  ```json
  "autoCopyToClipboard": true  // 自动复制到剪贴板
  ```

### clipboardContentType
- **类型**: `string`
- **默认值**: `"image"`
- **可选值**: `"image"`, `"filename"`, `"fullPath"`, `"directoryPath"`
- **说明**: 剪贴板内容类型
- **选项说明**:
  - `"image"` - 复制图片本身（可直接粘贴到文档、聊天工具）
  - `"filename"` - 复制文件名（如：screenshot_2026-01-15_19-30-45.png）
  - `"fullPath"` - 复制完整路径（如：C:\Users...\screenshot.png）
  - `"directoryPath"` - 复制目录路径（如：C:\Users...\Screenshots）
- **使用场景**:
  - 文档编辑: `"image"`（直接粘贴图片）
  - 文件管理: `"filename"` 或 `"fullPath"`（快速定位文件）
  - 批量操作: `"directoryPath"`（快速打开文件夹）
- **示例**:
  ```json
  "clipboardContentType": "image"  // 复制图片本身
  ```

### showPreview
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 截图后是否显示预览窗口
- **预览窗口功能**:
  - 查看截图效果
  - 编辑和标注
  - 重新截图
  - 保存或复制
- **建议**:
  - 需要编辑: `true`（默认）
  - 快速截图: `false`
- **示例**:
  ```json
  "showPreview": true  // 显示预览窗口
  ```

### saveHistory
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 是否保存截图历史记录
- **历史记录功能**:
  - 快速访问历史截图
  - 按时间排序和过滤
  - 重新编辑或导出
- **建议**: 保持默认值 `true`，方便管理截图
- **示例**:
  ```json
  "saveHistory": true  // 保存历史记录
  ```

### maxHistoryCount
- **类型**: `integer`
- **默认值**: `100`
- **取值范围**: `10-500`
- **说明**: 最大历史记录数量
- **建议**:
  - 轻度使用: `30-50`
  - 一般使用: `100`（默认）
  - 重度使用: `200-500`
- **注意**: 超出限制时，最旧的记录会被删除
- **示例**:
  ```json
  "maxHistoryCount": 100  // 最多保存100条历史记录
  ```

### historyRetentionDays
- **类型**: `integer`
- **默认值**: `30`
- **取值范围**: `1-365`
- **说明**: 历史记录保留天数（以天为单位）
- **清理机制**: 超过此天数的历史记录会在下次启动时自动清理
- **建议**:
  - 短期保留: `7` 或 `14`
  - 中期保留: `30`（默认）
  - 长期存档: `90` 或 `180`
- **示例**:
  ```json
  "historyRetentionDays": 30  // 保留30天
  ```

### shortcuts
- **类型**: `object`
- **默认值**:
  ```json
  {
    "regionCapture": "Ctrl+Shift+A",
    "fullScreenCapture": "Ctrl+Shift+F",
    "windowCapture": "Ctrl+Shift+W",
    "showHistory": "Ctrl+Shift+H",
    "showSettings": "Ctrl+Shift+S"
  }
  ```
- **说明**: 快捷键设置
- **快捷键功能**:
  - `regionCapture` - 区域截图（选择屏幕区域）
  - `fullScreenCapture` - 全屏截图（整个屏幕）
  - `windowCapture` - 窗口截图（单个窗口）
  - `showHistory` - 显示历史记录
  - `showSettings` - 打开设置页面
- **快捷键格式**:
  - 修饰键: `Ctrl`, `Shift`, `Alt`, `Meta`（Win键/Cmd键）
  - 普通键: `A-Z`, `0-9`, `F1-F12`
  - 组合: 用 `+` 连接，如 `"Ctrl+Shift+A"`
- **macOS 说明**: 使用 `Meta` 或 `Cmd` 表示 Command 键
- **自定义示例**:
  ```json
  {
    "regionCapture": "Ctrl+Alt+A",
    "fullScreenCapture": "Ctrl+Alt+F",
    "windowCapture": "Ctrl+Alt+W"
  }
  ```
- **注意**: 确保快捷键不与其他应用冲突

### pinSettings
- **类型**: `object`
- **默认值**:
  ```json
  {
    "alwaysOnTop": true,
    "defaultOpacity": 0.9,
    "enableDrag": true,
    "enableResize": false,
    "showCloseButton": true
  }
  ```
- **说明**: 钉图设置（将截图固定在屏幕上）
- **子选项**:
  - `alwaysOnTop` - 是否始终置顶（`true`/`false`）
  - `defaultOpacity` - 默认透明度（`0.1-1.0`）
  - `enableDrag` - 是否启用拖拽（`true`/`false`）
  - `enableResize` - 是否启用调整大小（`true`/`false`）
  - `showCloseButton` - 是否显示关闭按钮（`true`/`false`）
- **自定义示例**:
  ```json
  {
    "alwaysOnTop": true,
    "defaultOpacity": 0.8,
    "enableDrag": true,
    "enableResize": true,
    "showCloseButton": true
  }
  ```

## 配置示例

### 最小配置（使用所有默认值）
```json
{
}
```

### 默认配置（显式指定）
```json
{
  "version": "1.0.0",
  "savePath": "{documents}/Screenshots",
  "filenameFormat": "screenshot_{timestamp}",
  "imageFormat": "png",
  "imageQuality": 95,
  "autoCopyToClipboard": true,
  "clipboardContentType": "image",
  "showPreview": true,
  "saveHistory": true,
  "maxHistoryCount": 100,
  "historyRetentionDays": 30,
  "shortcuts": {
    "regionCapture": "Ctrl+Shift+A",
    "fullScreenCapture": "Ctrl+Shift+F",
    "windowCapture": "Ctrl+Shift+W",
    "showHistory": "Ctrl+Shift+H",
    "showSettings": "Ctrl+Shift+S"
  },
  "pinSettings": {
    "alwaysOnTop": true,
    "defaultOpacity": 0.9,
    "enableDrag": true,
    "enableResize": false,
    "showCloseButton": true
  }
}
```

### 优化存储空间配置
```json
{
  "version": "1.0.0",
  "savePath": "{documents}/Screenshots",
  "filenameFormat": "screenshot_{datetime}",
  "imageFormat": "webp",
  "imageQuality": 85,
  "autoCopyToClipboard": true,
  "clipboardContentType": "image",
  "showPreview": false,
  "saveHistory": true,
  "maxHistoryCount": 50,
  "historyRetentionDays": 14
}
```

### 快速工作流配置（无预览）
```json
{
  "version": "1.0.0",
  "savePath": "{desktop}/Screenshots",
  "filenameFormat": "{timestamp}",
  "imageFormat": "png",
  "imageQuality": 95,
  "autoCopyToClipboard": true,
  "clipboardContentType": "image",
  "showPreview": false,
  "saveHistory": false
}
```

### 文件管理优化配置
```json
{
  "version": "1.0.0",
  "savePath": "{documents}/Screenshots/{date}",
  "filenameFormat": "Screenshot_{time}",
  "imageFormat": "png",
  "autoCopyToClipboard": true,
  "clipboardContentType": "fullPath",
  "showPreview": true,
  "saveHistory": true,
  "maxHistoryCount": 200,
  "historyRetentionDays": 90
}
```

## 配置验证

所有配置项在保存前都会进行验证，不符合规范的配置将被拒绝：

- ✅ `imageQuality`: 必须在 1-100 范围内
- ✅ `imageFormat`: 必须是 "png"、"jpeg" 或 "webp"
- ✅ `clipboardContentType`: 必须是 "image"、"filename"、"fullPath" 或 "directoryPath"
- ✅ `maxHistoryCount`: 必须在 10-500 范围内
- ✅ `historyRetentionDays`: 必须在 1-365 范围内
- ✅ `defaultOpacity`: 必须在 0.1-1.0 范围内

## 常见问题

### Q: 如何修改快捷键？
**A**: 在配置文件的 `shortcuts` 部分修改对应的快捷键组合。

### Q: 如何让截图文件按日期分类？
**A**: 在 `savePath` 中使用 `{date}` 占位符，如 `"{documents}/Screenshots/{date}"`。

### Q: PNG 和 JPEG 有什么区别？
**A**: PNG 是无损格式，文件较大但质量高；JPEG 是有损格式，文件小但会损失一些质量。

### Q: 如何减少截图文件大小？
**A**:
  1. 使用 `jpeg` 或 `webp` 格式
  2. 降低 `imageQuality` 到 80-85
  3. 使用 `webp` 格式可以达到最佳的压缩比

### Q: 历史记录会占用大量空间吗？
**A**: 会。建议定期清理，或调整 `maxHistoryCount` 和 `historyRetentionDays`。

### Q: 为什么粘贴的是文件路径而不是图片？
**A**: 检查 `clipboardContentType` 设置，确保为 `"image"`。

### Q: 如何禁用预览窗口？
**A**: 将 `showPreview` 设为 `false`。

### Q: 钉图的透明度如何调整？
**A**: 修改 `pinSettings.defaultOpacity` 值（0.1-1.0）。

## 技术说明

### 占位符替换
占位符会在截图时被动态替换为实际值。例如：
- `{timestamp}` → `1736952645000`
- `{date}` → `2026-01-15`
- `{time}` → `19-30-45`
- `{datetime}` → `2026-01-15_19-30-45`
- `{index}` → `1`, `2`, `3`...（自增）

### 文件名冲突处理
如果文件名已存在，会自动添加序号：
- `screenshot.png`（已存在）
- `screenshot (1).png`（自动添加）
- `screenshot (2).png`

### 快捷键系统
- 使用平台原生快捷键注册机制
- 全局监听，即使应用在后台也能触发
- 自动处理快捷键冲突

### 历史记录管理
- 使用 SQLite 数据库存储元数据
- 自动清理过期记录
- 支持搜索和过滤

## 更新日志

- **v1.0.0** (2026-01-19) - 初始版本
