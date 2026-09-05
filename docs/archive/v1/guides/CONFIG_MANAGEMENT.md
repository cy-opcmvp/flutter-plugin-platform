# 配置文件管理说明

## 概述

本项目使用基于文件的配置管理系统，支持：
- ✅ **默认配置模板** (`global_config.example.json`)
- ✅ **个人配置文件** (`global_config.json`)
- ✅ **自动初始化** - 首次运行自动生成配置文件
- ✅ **版本控制友好** - 个人设置不会被提交到 Git

---

## 配置文件结构

```
<应用文档目录>/config/
├── global_config.example.json  # 默认配置模板（由 assets 复制）
├── global_config.json          # 个人配置文件（自动生成，.gitignore）
├── plugin_screenshot.json       # 截图插件配置（.gitignore）
├── plugin_world_clock.json      # 世界时钟插件配置（.gitignore）
└── plugin_calculator.json       # 计算器插件配置（.gitignore）
```

---

## 工作流程

### 1. 首次运行应用

```
应用启动
    ↓
ConfigService.initialize()
    ↓
检查 global_config.example.json 是否存在？
    ├─ 不存在 → 从 assets/config/global_config.example.json 复制
    └─ 存在 → 跳过
    ↓
检查 global_config.json 是否存在？
    ├─ 不存在 → 从 global_config.example.json 复制
    └─ 存在 → 加载配置
    ↓
应用正常启动
```

### 2. 开发者修改默认配置

1. 编辑 `assets/config/global_config.example.json`
2. 重新构建应用：`flutter build windows`
3. 新用户首次运行会自动使用新的默认配置

### 3. 用户修改个人设置

1. 在应用设置中修改配置
2. 配置保存到 `global_config.json`
3. 个人设置不会被 Git 跟踪（.gitignore）

---

## Git 忽略规则

`.gitignore` 文件已配置忽略个人配置：

```gitignore
# User configuration (personal settings should not be committed)
/config/global_config.json
/config/plugin_*.json
```

---

## 配置文件字段说明

### 全局配置 (`global_config.example.json`)

| 字段路径 | 类型 | 说明 |
|---------|------|------|
| `app.name` | String | 应用名称 |
| `app.version` | String | 应用版本 |
| `app.language` | String | 语言设置 (`zh_CN`, `en_US`) |
| `app.theme` | String | 主题设置 (`system`, `light`, `dark`) |
| `app.autoStartPlugins` | List\<String\> | 自动启动的插件 ID 列表 |
| `features.autoStart` | Boolean | 应用开机自启 |
| `features.minimizeToTray` | Boolean | 最小化到托盘 |
| `features.showDesktopPet` | Boolean | 显示桌面宠物 |
| `features.enableNotifications` | Boolean | 启用通知 |
| `services.audio.enabled` | Boolean | 音频服务 |
| `services.notification.enabled` | Boolean | 通知服务 |
| `services.notification.mode` | String | 通知模式 (`app`, `system`) |
| `services.taskScheduler.enabled` | Boolean | 任务调度服务 |
| `advanced.debugMode` | Boolean | 调试模式 |
| `advanced.logLevel` | String | 日志级别 (`debug`, `info`, `warning`, `error`) |
| `advanced.maxLogFileSize` | Integer | 最大日志文件大小（MB） |

### 插件配置

#### 桌面宠物 (`desktopPet`)
- `enabled` - 是否启用桌面宠物
- `opacity` - 透明度 (0.3-1.0)
- `animationsEnabled` - 是否启用动画
- `interactionsEnabled` - 是否启用交互

#### 截图插件 (`screenshot`)
- `savePath` - 保存路径（支持 `{documents}` 占位符）
- `filenameFormat` - 文件名格式（支持 `{date}`, `{time}` 占位符）
- `imageFormat` - 图片格式 (`png`, `jpeg`, `webp`)
- `quality` - 图片质量 (1-100)
- `showPreview` - 是否显示预览
- `copyToClipboard` - 是否复制到剪贴板
- `clipboardContentType` - 剪贴板内容类型 (`image`, `filename`, `fullPath`, `directoryPath`)

#### 世界时钟 (`worldClock`)
- `showSeconds` - 是否显示秒
- `use24HourFormat` - 是否使用 24 小时制
- `timeZones` - 时区列表（IANA 时区标识符）

#### 计算器 (`calculator`)
- `precision` - 计算精度（小数位数）
- `angleMode` - 角度模式 (`deg`, `rad`)
- `showHistory` - 是否显示历史记录
- `historySize` - 历史记录大小

---

## 配置重置

### 方式 1：通过应用 UI

在应用设置中点击"恢复默认设置"按钮。

### 方式 2：手动删除配置文件

1. 关闭应用
2. 删除配置文件：
   - Windows: `%LOCALAPPDATA%/plugin_platform/config/global_config.json`
   - macOS: `~/Library/Application Support/plugin_platform/config/global_config.json`
   - Linux: `~/.local/share/plugin_platform/config/global_config.json`
3. 重新启动应用（会自动从 example 生成新配置）

---

## 开发注意事项

### 修改默认配置

1. ✅ **修改**: `assets/config/global_config.example.json`
2. ✅ **提交**: Git 提交到仓库
3. ✅ **测试**: 删除个人配置，重新运行应用验证

### 不要修改

- ❌ 不要修改用户数据目录中的 `global_config.example.json`（每次启动会被覆盖）
- ❌ 不要提交个人配置到 Git

---

## 故障排除

### 问题：配置未生效

**解决方案**：
1. 检查 `global_config.json` 是否存在
2. 查看日志：`ConfigService initialized: ...`
3. 尝试删除配置文件，重新启动应用

### 问题：配置被重置

**可能原因**：
- `global_config.json` 损坏或格式错误
- 应用自动使用默认配置

**解决方案**：
1. 检查 JSON 格式是否正确
2. 参考本文档的字段说明修复配置

---

**版本**: v1.0.0
**最后更新**: 2026-01-25
**维护者**: Flutter Plugin Platform 团队
