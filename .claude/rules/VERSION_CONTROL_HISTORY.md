# 版本控制历史

本文档记录所有 tag 创建、push 操作和重要对话的详细历史，用于追溯项目演进过程。

## 版本索引

- [v0.3.2](#v032-2026-01-15) - 2026-01-15
- [v0.3.1](#v031-2025-01-14) - 2025-01-14
- [v0.3.0](#v030-2025-01-14) - 2025-01-14

---

## v0.3.2 (2026-01-15)

### Tag 信息
- **版本号**: v0.3.2
- **提交**: fbc2838
- **创建时间**: 2026-01-15
- **创建者**: cyamz
- **类型**: Minor 版本（新功能）

### 变更内容
- **新增配置页面** - 实现应用配置管理功能
  - 新增 SettingsScreen，提供统一的应用设置入口
  - 实现语言切换功能，支持中文/英文即时切换
  - 友好的语言选择界面，显示当前语言状态
- **国际化完善** - 测试和配置页面完整国际化
  - 测试页面所有文本支持中英文切换
  - 配置页面所有文本支持中英文切换
  - 新增国际化翻译条目 30+ 条
- **开发工具** - 新增国际化更新脚本
  - `scripts/update-i18n.bat` - 一键生成国际化文件
- **Bug 修复** - 修复语言切换后 SnackBar 无法关闭的问题

### 对话记录
- **对话时间**: 2026-01-15
- **对话主题 1**: Tag 管理 - 创建 v0.3.2 并删除 v0.3.3
- **对话主题 2**: 更新 v0.3.2 tag 注释，补充完整功能说明
- **操作内容**:
  - 删除错误的 v0.3.3 tag
  - 创建 v0.3.2 tag
  - 更新 tag 注释，包含完整的功能变更
  - 更新 CHANGELOG.md，准确反映版本内容

### Git 提交
```
fbc2838 fix: 修复语言切换后 SnackBar 无法关闭的问题
```

### 新增文件
- `lib/ui/screens/settings_screen.dart` - 配置页面（150+ 行）
- `scripts/update-i18n.bat` - 国际化更新脚本
- `docs/releases/RELEASE_NOTES_v0.3.1.md` - v0.3.1 发布说明

### 修改文件
- `lib/ui/screens/main_platform_screen.dart` - 添加配置页面入口
- `lib/ui/screens/service_test_screen.dart` - 测试页面国际化
- `lib/l10n/app_zh.arb` - 中文翻译新增 30+ 条
- `lib/l10n/app_en.arb` - 英文翻译新增 30+ 条
- `lib/l10n/generated/*` - 自动生成的国际化代码

### Tag 注释
```
Release v0.3.2

## ✨ 新增功能
### 配置页面
- 新增应用配置页面 (SettingsScreen)
- 支持语言切换功能
- 提供友好的语言选择界面
- 为未来的主题设置预留扩展空间

### 国际化完善
- 测试页面完整国际化
- 配置页面完整国际化
- 新增国际化相关翻译条目

## 🔧 改进
### 用户体验优化
- 语言切换后即时生效，无需重启应用
- 界面统一使用国际化文本
- 语言显示名称本地化

### 开发工具
- 新增国际化更新脚本 (update-i18n.bat)
- 简化国际化工作流程

## 🐛 Bug 修复
- 修复语言切换后 SnackBar 无法关闭的问题

## 📁 技术细节
### 新增文件
- lib/ui/screens/settings_screen.dart - 配置页面
- scripts/update-i18n.bat - 国际化更新脚本
- docs/releases/RELEASE_NOTES_v0.3.1.md - v0.3.1 发布说明

### 修改文件
- lib/ui/screens/main_platform_screen.dart - 添加配置页面入口
- lib/ui/screens/service_test_screen.dart - 测试页面国际化
- lib/l10n/app_zh.arb - 中文翻译更新
- lib/l10n/app_en.arb - 英文翻译更新
- lib/l10n/generated/* - 自动生成的国际化代码

## 📝 完整提交历史
- fbc2838 fix: 修复语言切换后 SnackBar 无法关闭的问题
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.2.md`（待创建）

### 关联文档
- [版本控制规则](.claude/rules/VERSION_CONTROL_RULES.md) - 创建于本次对话

---

## v0.3.1 (2025-01-14)

### Tag 信息
- **版本号**: v0.3.1
- **提交**: 2951c49
- **创建时间**: 2025-01-14
- **创建者**: cyamz
- **类型**: Patch 版本（Bug 修复）

### 变更内容
- Windows 平台服务兼容性修复

### Git 提交
```
2951c49 fix: Windows 平台服务兼容性修复 (v0.3.1)
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.1.md`（已存在）

---

## v0.3.0 (2025-01-14)

### Tag 信息
- **版本号**: v0.3.0
- **提交**: fc55179
- **创建时间**: 2025-01-14
- **创建者**: cyamz
- **类型**: Minor 版本（新功能）

### 变更内容
- 添加 Windows 平台通知测试功能
- 增强通知服务的跨平台支持

### Git 提交
```
fc55179 feat: add Windows platform notice in notification test tab
```

### 发布文档
- `docs/releases/RELEASE_NOTES_v0.3.0.md`（已存在）

---

## 对话历史记录

### 2026-01-15 - 建立版本控制规则体系

#### 对话主题
建立版本控制规则体系，完善 tag 管理流程

#### 操作内容
1. **创建版本控制规则体系**:
   - 版本控制与 Tag 管理规范 (VERSION_CONTROL_RULES.md)
   - 版本控制历史记录 (VERSION_CONTROL_HISTORY.md)
   - 规则文档索引 (README.md)

2. **Tag 管理操作**:
   - 删除错误的 v0.3.3 tag
   - 创建正确的 v0.3.2 tag
   - 准备 tag 注释和版本说明

3. **文档完善**:
   - 更新主指导文档 (CLAUDE.md)
   - 创建规则索引 (README.md)
   - 更新 CHANGELOG.md

#### Git 提交
```
f9342ce docs: 建立版本控制规则体系，完善 tag 管理流程
e6df091 docs: 更新 CHANGELOG.md，记录 v0.3.2 版本变更
```

#### 创建的文件
- `.claude/rules/VERSION_CONTROL_RULES.md` - 版本控制与 Tag 管理规范
- `.claude/rules/VERSION_CONTROL_HISTORY.md` - 版本控制历史记录
- `.claude/rules/README.md` - 规则文档索引

#### 修改的文件
- `.claude/CLAUDE.md` - 添加版本控制规则说明
- `CHANGELOG.md` - 添加 v0.3.2 版本记录

#### Push 状态
- ✅ 已提交 2 个提交
- ⏳ 尚未 push 到远程

---

## 统计信息

### 版本发布频率
- v0.3.0 → v0.3.1: 1 天
- v0.3.1 → v0.3.2: 1 天

### 提交类型分布
- Bug 修复: 2 个 (v0.3.1, v0.3.2)
- 新功能: 1 个 (v0.3.0)
- 文档更新: 2 个 (f9342ce, e6df091)

### 对话记录
- 本次对话: 2026-01-15
- 主题: 建立版本控制规则体系
- 提交数: 2 个
- 文件创建: 3 个
- 文件修改: 2 个

---

**维护说明**: 每次 tag 创建或重要 push 操作后，都需要更新此文档。

**文档版本**: v1.1.0
**最后更新**: 2026-01-15

