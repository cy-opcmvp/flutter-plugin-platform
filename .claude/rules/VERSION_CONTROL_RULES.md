# AI 编码规则 - 版本控制与 Tag 管理规范

> 📋 **本文档定义了项目的版本控制和 tag 管理规则，所有 AI 助手（Claude Code 等）必须遵守**

## 🎯 核心原则

### 1. 每次对话都要做好记录

**在每次对话结束时**，AI 助手必须：

- ✅ **记录本次对话的所有代码修改**
- ✅ **记录所有创建的文件**
- ✅ **记录所有删除的文件**
- ✅ **记录所有重构的内容**
- ✅ **更新变更日志（CHANGELOG.md）**

### 2. 每次 Push 都要记录

**在执行 git push 前**，AI 助手必须：

- ✅ **检查是否有未提交的变更**
- ✅ **确认提交信息符合规范**
- ✅ **更新 CHANGELOG.md**
- ✅ **评估是否需要创建新的 tag**
- ✅ **记录 push 的目的和内容**

### 3. Tag 创建规范

**Tag 命名格式**: `v{major}.{minor}.{patch}`

**Tag 类型判断**:
- **Major 版本** (v1.0.0 → v2.0.0): 架构重大变更、不兼容的 API 变更
- **Minor 版本** (v0.3.0 → v0.4.0): 新增功能、重要特性
- **Patch 版本** (v0.3.1 → v0.3.2): Bug 修复、小改进、文档更新

## 📝 对话记录模板

### 对话开始时

在对话开始时，AI 应该：

```markdown
## 📋 对话记录

**开始时间**: {timestamp}
**当前版本**: {current-tag}
**目的**: {user-request}
```

### 对话结束时

在对话结束时，AI 必须输出：

```markdown
## 📊 本次对话总结

### 修改的文件
- [file-path-1]: {修改原因和内容}
- [file-path-2]: {修改原因和内容}

### 创建的文件
- [new-file-path-1]: {文件用途}
- [new-file-path-2]: {文件用途}

### 删除的文件
- [deleted-file-path-1]: {删除原因}

### 重构的内容
- {module-name}: {重构原因和变更}

### Git 提交信息
```

**提交类型**:
- `feat:` - 新功能
- `fix:` - Bug 修复
- `docs:` - 文档更新
- `refactor:` - 重构
- `test:` - 测试相关
- `chore:` - 构建/工具相关

**提交格式**:
```
{type}: {简短描述}

{详细描述（可选）}

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### 变更日志更新

**必须在 CHANGELOG.md 中添加条目**:

```markdown
## [{version}] - {date}

### Added
- 新增的功能

### Changed
- 变更的内容

### Fixed
- 修复的问题

### Removed
- 移除的内容

### Docs
- 文档更新
```

## 🏷️ Tag 管理规范

### Tag 创建流程

**1. 检查当前版本**

```bash
git describe --tags --abbrev=0
```

**2. 查看自上一个 tag 以来的所有提交**

```bash
git log v{previous-version}..HEAD --oneline
```

**3. 确定新版本号**

根据提交内容判断版本类型：
- 如果只包含 bug 修复 → Patch 版本 (+0.0.1)
- 如果包含新功能 → Minor 版本 (+0.1.0)
- 如果包含重大变更 → Major 版本 (+1.0.0)

**4. 创建归档文件** ⭐ 重要

**必须创建归档文件存放详细信息**：

文件路径: `docs/releases/archive/v{version}-details.md`

**归档文件内容模板**：
```markdown
# v{version} 详细归档

**发布日期**: {date}
**版本类型**: {Major/Minor/Patch}

## 📦 完整功能列表

### 新增功能
- 功能1（3-5行详细说明）
- 功能2（3-5行详细说明）

### 改进
- 改进1（3-5行详细说明）
- 改进2（3-5行详细说明）

### Bug 修复
- 修复1（3-5行详细说明）
- 修复2（3-5行详细说明）

## 🔧 技术细节

### 新增文件
- `path/to/file1` - 说明
- `path/to/file2` - 说明

### 修改文件
- `path/to/file3` - 修改说明
- `path/to/file4` - 修改说明

### 代码统计
- 文件变更数
- 代码行数变更

## 📝 完整提交历史
- {hash} {message}
- {hash} {message}

## ⚠️ 已知问题
- 问题1
- 问题2

## 🎯 下版本计划
- 计划1
- 计划2
```

**5. 创建 Tag 注释** ⭐ 简洁原则

**Tag 注释必须简洁，只包含核心信息，详细内容放在归档文件中**

```markdown
Release v{version}

{简洁的一句话总结}

## 主要更新
- {核心功能1}
- {核心功能2}

## 完整提交
{commit-range} ({commit-count} commits)

## 详细文档
docs/releases/archive/v{version}-details.md
```

**示例**：
```markdown
Release v0.4.4

外部插件国际化支持和配置管理系统优化

## 主要更新
- 外部插件国际化接口系统（IPluginI18n）
- 配置管理文档和示例文件
- 桌面宠物和插件配置优化

## 完整提交
1e12358..5fcd384 (3 commits)

## 详细文档
docs/releases/archive/v0.4.4-details.md
```

**6. 创建并推送 Tag**

```bash
# 1. 提交所有更改（包括归档文件）
git add -A
git commit -m "chore: prepare v{version} release"

# 2. 创建 tag
git tag -a v{version} -m "{tag-message}"

# 3. 推送
git push origin main
git push origin v{version}
```

### Tag 记录文档

**每次创建 tag 后，必须更新以下文档**：

1. **CHANGELOG.md** - 简洁的版本条目
2. **VERSION_CONTROL_HISTORY.md** - 简洁的版本记录
3. **归档文件** - `docs/releases/archive/v{version}-details.md` - 详细信息
4. **发布说明** - `docs/releases/RELEASE_NOTES_v{version}.md` - 用户友好的发布说明

### 归档文件管理

**⚠️ 重要：归档文件必须加入 git 提交**

```bash
# 创建 tag 时的标准流程
git add docs/releases/archive/v{version}-details.md  # ⭐ 必须包含
git add CHANGELOG.md
git add VERSION_CONTROL_HISTORY.md
git add docs/releases/RELEASE_NOTES_v{version}.md
git commit -m "chore: prepare v{version} release"
git tag -a v{version} -m "..."
```

**归档文件组织**：
```
docs/releases/
├── archive/
│   ├── v0.4.4-details.md
│   ├── v0.4.5-details.md
│   └── ...
├── RELEASE_NOTES_v0.4.4.md
├── RELEASE_NOTES_v0.4.5.md
└── ...
```

内容模板:

```markdown
# Release Notes - v{version}

**发布日期**: {date}
**上一个版本**: v{previous-version}

## 📦 版本概述

{版本概述}

## ✨ 新增功能

{详细描述新功能}

## 🔧 改进

{详细描述改进内容}

## 🐛 Bug 修复

{详细描述修复的问题}

## 📝 完整变更列表

| 提交 ID | 描述 | 作者 |
|---------|------|------|
| {hash} | {message} | {author} |
| {hash} | {message} | {author} |

## 🔄 升级指南

{如果有破坏性变更，提供升级指南}

## 📋 已知问题

{列出已知问题}
```

## 🚀 Push 操作规范

### Push 前检查清单

**在执行 git push 前**，必须确认：

- [ ] 所有变更已提交
- [ ] 提交信息符合规范
- [ ] CHANGELOG.md 已更新
- [ ] 代码已通过测试（flutter test）
- [ ] 代码已通过格式化检查（flutter format）
- [ ] 代码已通过静态分析（flutter analyze）
- [ ] 评估是否需要创建 tag

### Push 命令规范

```bash
# 普通推送
git push origin {branch}

# 推送 tag
git push origin v{version}

# 推送所有 tags
git push origin --tags
```

### Push 后记录

**Push 成功后，必须记录**：

```markdown
## 📤 Push 记录

**时间**: {timestamp}
**分支**: {branch-name}
**提交数**: {number-of-commits}
**提交范围**: {start-hash}..{end-hash}
**Tag**: {如果有 tag，列出 tag 名称}

**推送内容**:
- {summary-of-changes}

**远程仓库状态**:
- {remote-url}
```

## 📊 版本历史追踪

### 版本历史文档

**维护以下文档以追踪版本历史**:

1. **CHANGELOG.md** - 根目录，所有版本变更的快速索引
2. **docs/releases/RELEASE_NOTES_v{version}.md** - 每个版本的详细发布说明
3. **.claude/rules/VERSION_CONTROL_HISTORY.md** - 本次文件，记录所有 tag 和 push 操作

### 版本控制历史记录

**在 `.claude/rules/VERSION_CONTROL_HISTORY.md` 中记录**:

```markdown
# 版本控制历史

## v0.3.2 (2026-01-15)

### Tag 信息
- 提交: fbc2838
- 创建时间: 2026-01-15
- 创建者: Claude Code

### 变更内容
- 修复语言切换后 SnackBar 无法关闭的问题

### 对话记录
- 对话主题: 修复语言切换后 SnackBar 问题
- 修改文件: lib/ui/widgets/app_shell.dart
- 提交信息: fbc2838 fix: 修复语言切换后 SnackBar 无法关闭的问题

### 发布文档
- docs/releases/RELEASE_NOTES_v0.3.2.md

---
（继续记录之前的版本...）
```

## ⚠️ 常见错误

### ❌ 错误示例

1. **忘记更新 CHANGELOG.md**
   ```
   ❌ 直接 push，没有更新变更日志
   ✅ Push 前更新 CHANGELOG.md
   ```

2. **Tag 注释不清晰**
   ```
   ❌ git tag v0.3.2
   ✅ git tag -a v0.3.2 -m "Release v0.3.2\n\n## 修复内容\n- ..."
   ```

3. **没有记录对话内容**
   ```
   ❌ 对话结束后直接退出
   ✅ 输出完整的对话总结和修改记录
   ```

4. **Push 前没有检查**
   ```
   ❌ 直接 push，可能有未提交的变更
   ✅ 运行 git status 确认工作区干净
   ```

## ✅ 检查清单

### 对话结束时
- [ ] 输出本次对话总结
- [ ] 列出所有修改的文件
- [ ] 列出所有创建的文件
- [ ] 列出所有删除的文件
- [ ] 准备 git 提交信息
- [ ] 更新 CHANGELOG.md

### Push 前
- [ ] 确认所有变更已提交
- [ ] 确认提交信息符合规范
- [ ] 确认 CHANGELOG.md 已更新
- [ ] 运行 flutter test
- [ ] 运行 flutter format
- [ ] 运行 flutter analyze
- [ ] 评估是否需要创建 tag
- [ ] 记录 push 内容

### Tag 创建时
- [ ] 检查当前版本
- [ ] 查看自上次 tag 以来的提交
- [ ] 确定新版本号
- [ ] 编写详细的 tag 注释
- [ ] 创建 tag
- [ ] 创建发布文档
- [ ] 更新版本控制历史
- [ ] 推送 tag

## 📚 参考文档

- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [约定式提交](https://www.conventionalcommits.org/zh-hans/)
- [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)
- [项目主索引](../docs/MASTER_INDEX.md)

---

**版本**: v1.0.0
**最后更新**: 2026-01-15
**适用范围**: 所有 AI 编码助手和开发者
