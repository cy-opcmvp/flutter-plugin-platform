# AI 编码规则 - Git 提交规范

> 📋 **本文档定义了 Git 提交信息格式和版本控制规范，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有 Git 提交
**提交规范**: 约定式提交 (Conventional Commits)

---

## 🎯 核心原则

### 1. 清晰性
提交信息必须清晰描述做了什么和为什么做。

### 2. 原子性
每次提交应该是一个完整的、不可分割的单元。

### 3. 可追溯性
提交历史应该容易理解和追溯。

---

## 📝 提交信息格式

### 基本格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 格式说明

| 部分 | 必需 | 说明 |
|------|------|------|
| **type** | ✅ 是 | 提交类型（见下方列表） |
| **scope** | ⚠️ 可选 | 影响范围（插件、服务、UI 等） |
| **subject** | ✅ 是 | 简短描述（不超过 50 字符） |
| **body** | ⚠️ 可选 | 详细描述（不少于什么、为什么） |
| **footer** | ⚠️ 可选 | 关联 Issue、破坏性变更说明 |

---

## 🔖 提交类型（Type）

### 标准类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **feat** | 新功能 | feat: 添加用户认证功能 |
| **fix** | Bug 修复 | fix: 修复登录页面崩溃问题 |
| **docs** | 文档更新 | docs: 更新 README 安装说明 |
| **style** | 代码格式（不影响功能） | style: 格式化代码 |
| **refactor** | 重构（不添加功能也不修复 Bug） | refactor: 重构用户服务层 |
| **perf** | 性能优化 | perf: 优化列表渲染性能 |
| **test** | 测试相关 | test: 添加用户模型测试 |
| **chore** | 构建过程或辅助工具变动 | chore: 更新依赖版本 |
| **ci** | CI 配置文件和脚本 | ci: 添加 GitHub Actions 工作流 |
| **build** | 影响构建系统或依赖 | build: 升级 Flutter 版本 |

---

## 📌 提交范围（Scope）

### 常用范围

| 范围 | 说明 | 示例 |
|------|------|------|
| **plugins** | 插件相关 | feat(plugins): 添加计算器插件 |
| **screenshot** | 截图插件 | fix(screenshot): 修复截图保存问题 |
| **world-clock** | 世界时钟插件 | refactor(world-clock): 重构时区选择逻辑 |
| **services** | 平台服务 | feat(services): 添加通知服务 |
| **ui** | UI 组件 | style(ui): 统一按钮样式 |
| **models** | 数据模型 | feat(models): 添加用户配置模型 |
| **docs** | 文档 | docs(readme): 更新安装说明 |
| **tests** | 测试 | test(models): 添加用户模型测试 |

---

## ✍️ 提交信息示例

### 简单提交（无 Body）

```bash
# 新功能
git commit -m "feat: 添加用户认证功能"

# Bug 修复
git commit -m "fix: 修复登录时崩溃的问题"

# 文档更新
git commit -m "docs: 更新 README 安装说明"

# 代码格式
git commit -m "style: 格式化代码"
```

---

### 复杂提交（带 Body）

```bash
git commit -m "feat(screenshot): 添加截图预览功能

- 添加截图后显示预览窗口
- 支持预览窗口中快速保存
- 支持预览窗口中重新截图

Closes #123"
```

---

### 破坏性变更

```bash
git commit -m "feat(api)!: 移除旧版 API

BREAKING CHANGE: 旧版 login() 方法已移除，请使用 loginWithOAuth() 替代"
```

---

### 同时修复 Bug 和添加功能

```bash
# 提交 1: 修复 Bug
git commit -m "fix: 修复登录验证问题"

# 提交 2: 添加功能
git commit -m "feat: 添加记住密码功能"

# ❌ 不要混合
# git commit -m "fix: 修复登录并添加新功能"  # 禁止
```

---

## 🌏 提交信息语言

### 语言选择原则

**项目标准**: 使用中文提交信息（项目团队使用中文）

```bash
# ✅ 正确（中文）
git commit -m "feat: 添加用户认证功能"
git commit -m "fix: 修复登录页面崩溃问题"
git commit -m "docs: 更新 README 安装说明"

# ✅ 也正确（英文，如果团队偏好）
git commit -m "feat: add user authentication"
git commit -m "fix: fix login page crash"
git commit -m "docs: update README installation guide"
```

**一致性要求**:
- 项目必须统一使用一种语言
- 不得中英文混用
- 技术术语保持原文（如 API、JSON、Plugin）

---

### 中文提交示例

```bash
# 简单提交
git commit -m "feat: 添加用户认证功能"
git commit -m "fix: 修复登录页面崩溃问题"
git commit -m "refactor(services): 重构通知服务"

# 复杂提交
git commit -m "feat(screenshot): 添加截图预览功能

- 添加截图后显示预览窗口
- 支持预览窗口中快速保存
- 支持预览窗口中重新截图

关联任务: #123"
```

---

## 📦 提交粒度规范

### 提交大小原则

| 场景 | 粒度 | 说明 |
|------|------|------|
| **小修改** | 一个提交 | 修复拼写错误、格式化代码 |
| **单一功能** | 多个提交 | 每个提交完成一个逻辑步骤 |
| **大功能** | 分阶段提交 | 拆分为多个小提交 |

---

### 提交粒度示例

```bash
# ❌ 错误：太大的提交（包含多个不相关的修改）
git commit -m "feat: 添加用户功能、修改 UI、更新文档"

# ✅ 正确：拆分为多个提交
git commit -m "feat(models): 添加用户数据模型"
git commit -m "feat(ui): 添加用户设置页面"
git commit -m "docs: 更新用户功能文档"
```

---

### 提交频率

- ✅ **频繁提交**: 每完成一个小功能就提交
- ✅ **逻辑完整**: 每个提交都应该是可运行的代码
- ❌ **禁止**: 长时间不提交，导致代码丢失
- ❌ **禁止**: 提交调试代码或临时文件

---

## 🚫 禁止的提交信息

### 格式错误

```bash
# ❌ 错误：没有类型
git commit -m "添加新功能"

# ❌ 错误：类型错误
git commit -m "feature: 添加新功能"

# ❌ 错误：subject 过长
git commit -m "feat: 添加一个非常复杂的用户认证功能，包括登录、注册和密码找回"

# ❌ 错误：首字母大写
git commit -m "Feat: 添加新功能"
git commit -m "Fix: 修复 Bug"

# ❌ 错误：subject 以句号结尾
git commit -m "feat: 添加新功能。"

# ❌ 错误：中英文混用
git commit -m "feat: add 用户认证"
```

---

### 内容错误

```bash
# ❌ 错误：模糊不清
git commit -m "update"
git commit -m "fix bug"
git commit -m "修改"

# ❌ 错误：包含调试代码
git commit -m "feat: 添加功能（debug）"

# ❌ 错误：混合多个修改
git commit -m "feat: 添加功能并修复 Bug 并更新文档"

# ❌ 错误：无关的废话
git commit -m "feat: 添加功能😊"
git commit -m "fix: 修复 Bug (终于)"
```

---

## 🔄 Git 工作流

### 分支策略

```
main (生产)
  ↑
  └─ develop (开发)
       ↑
       ├─ feature/user-auth
       ├─ feature/screenshot-preview
       └─ fix/login-crash
```

---

### 分支命名

| 类型 | 命名格式 | 示例 |
|------|---------|------|
| **功能分支** | `feature/<name>` | `feature/user-auth` |
| **修复分支** | `fix/<name>` | `fix/login-crash` |
| **重构分支** | `refactor/<name>` | `refactor/user-service` |
| **文档分支** | `docs/<name>` | `docs/api-guide` |
| **测试分支** | `test/<name>` | `test/user-model` |
| **发布分支** | `release/<version>` | `release/v0.4.0` |

---

### 分支操作

```bash
# 创建功能分支
git checkout -b feature/user-auth

# 开发并提交
git add .
git commit -m "feat: 添加登录界面"

# 推送到远程
git push -u origin feature/user-auth

# 合并到 develop
git checkout develop
git merge --no-ff feature/user-auth
git push origin develop

# 删除已合并的分支
git branch -d feature/user-auth
git push origin --delete feature/user-auth
```

---

## 👥 代码审查规范

### PR（Pull Request）规范

#### PR 标题

使用约定式提交格式：

```bash
# ✅ 正确
feat: 添加用户认证功能
fix(screenshot): 修复截图保存问题

# ❌ 错误
添加新功能
修复 Bug
Update code
```

---

#### PR 描述模板

```markdown
## 📝 变更说明
<!-- 简要描述本次变更的内容 -->

## 🔧 修改内容
- [ ] 新增功能
- [ ] Bug 修复
- [ ] 性能优化
- [ ] 文档更新

## 🧪 测试
- [ ] 单元测试通过
- [ ] Widget 测试通过
- [ ] 手动测试通过

## 📸 截图（如果有 UI 变更）
<!-- 添加前后对比截图 -->

## ✅ 检查清单
- [ ] 代码遵循项目规范
- [ ] 提交信息符合规范
- [ ] 已添加必要的测试
- [ ] 已更新相关文档
- [ ] 无编译警告和错误

## 🔗 相关 Issue
Closes #123
Related to #456
```

---

### 审查要点

1. **代码质量**: 代码是否符合项目规范
2. **功能完整**: 是否实现了承诺的功能
3. **测试覆盖**: 是否有足够的测试
4. **文档更新**: 是否更新了相关文档
5. **提交信息**: 提交信息是否清晰规范

---

## 📋 提交检查清单

### 提交前检查

- [ ] 代码已通过 `dart format` 格式化
- [ ] 代码已通过 `dart analyze` 静态分析
- [ ] 所有测试已通过（`flutter test`）
- [ ] 提交信息符合规范
- [ ] 提交信息清晰描述了改动
- [ ] 没有提交调试代码或临时文件
- [ ] 没有提交敏感信息（密码、密钥等）

### Push 前检查

- [ ] 所有更改已提交
- [ ] 提交信息准确反映更改
- [ ] 分支名称符合规范
- [ ] 已合并到正确的分支
- [ ] 远程仓库状态已更新

---

## 🔧 Git 配置

### .gitignore 必须包含

```
# Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# IDE
.idea/
.vscode/
*.iml
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Build
/build/
/windows/x64/
linux/x64/
macos/Flutter/ephemeral/

# Test
/coverage/
.test_coverage/

# Other
*.log
*.bak
*.tmp
.env.local
```

---

### Git Hooks 配置

使用 `pre-commit` hook 自动检查：

```bash
# .git/hooks/pre-commit
#!/bin/sh

# 格式化代码
echo "🔧 格式化代码..."
dart format .

# 运行静态分析
echo "🔍 运行静态分析..."
dart analyze

# 运行测试
echo "🧪 运行测试..."
flutter test

# 检查提交信息
echo "📝 检查提交信息..."
# 可以使用 commitlint 或类似工具

echo "✅ 所有检查通过！"
```

---

## 📚 参考资源

### 官方文档
- [约定式提交](https://www.conventionalcommits.org/)
- [约定式提交规范（中文）](https://xz1466040143.github.io/conventional-commits-zh/)
- [Git 工作流](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)

### 相关规范
- [版本控制规范](./VERSION_CONTROL_RULES.md)
- [代码风格规范](./CODE_STYLE_RULES.md)
- [测试规范](./TESTING_RULES.md)

---

## 🎯 快速参考

| 类型 | 格式 | 示例 |
|------|------|------|
| **新功能** | `feat: <描述>` | `feat: 添加用户认证` |
| **Bug 修复** | `fix: <描述>` | `fix: 修复登录崩溃` |
| **文档更新** | `docs: <描述>` | `docs: 更新 README` |
| **重构** | `refactor: <描述>` | `refactor: 重构用户服务` |
| **测试** | `test: <描述>` | `test: 添加用户模型测试` |
| **格式化** | `style: <描述>` | `style: 格式化代码` |
| **破坏性** | `feat!: <描述>` | `feat!: 移除旧版 API` |

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 清晰的提交历史是最好的文档！
