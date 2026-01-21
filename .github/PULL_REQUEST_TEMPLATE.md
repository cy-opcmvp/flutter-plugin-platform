# Pull Request 模板

## 📝 变更说明
<!-- 请简要描述本次 PR 的变更内容 -->

**变更类型**:
- [ ] 🎉 新功能 (feature)
- [ ] 🐛 Bug 修复 (fix)
- [ ] 📚 文档更新 (docs)
- [ ] 🎨 代码重构 (refactor)
- [ ] ⚡ 性能优化 (perf)
- [ ] ✅ 测试相关 (test)
- [ ] 🔧 构建/工具 (chore)

---

## 🔧 修改内容
<!-- 请列出本次 PR 的主要修改内容 -->

- [ ] 修改1
- [ ] 修改2
- [ ] 修改3

---

## 📚 文档变更

### 本次变更涉及的文档
<!-- 请勾选已更新的文档 -->

- [ ] 用户指南 (`docs/guides/*.md`)
- [ ] API 文档 (`docs/reference/*.md`)
- [ ] 配置文档 (`lib/plugins/*/config/*_config_docs.md`)
- [ ] 项目主文档 (`README.md`)
- [ ] 变更日志 (`CHANGELOG.md`)
- [ ] 插件文档 (`docs/plugins/*/README.md`)
- [ ] 平台服务文档 (`docs/platform-services/*.md`)
- [ ] 不适用（无需更新文档）

### 文档变更说明
<!-- 请详细说明本次变更中所有文档的修改 -->

**示例**:
- 更新了 `docs/guides/internal-plugin-development.md`，添加了新功能的说明
- 更新了 `CHANGELOG.md`，记录了 v0.x.x 版本的变更
- 新增了 `lib/plugins/myplugin/config/myplugin_config_docs.md`

---

## 📋 文档变更检查清单

### 自动化检查
<!-- 运行文档检查脚本的结果 -->

```bash
# Windows PowerShell
.\scripts\check-docs.ps1

# Linux/macOS Bash
./scripts/check-docs.sh
```

- [ ] 所有检查通过
- [ ] 有警告但已确认可忽略

### 手动检查清单
- [ ] 所有相关文档已更新
- [ ] 文档中的代码示例已验证可运行
- [ ] 新增功能有完整的文档说明
- [ ] 变更的功能有更新说明
- [ ] 文档中的所有链接有效
- [ ] 国际化文件（中英文）都已更新（如适用）

---

## 🧪 测试
<!-- 请描述测试情况 -->

### 测试环境
- [ ] Windows
- [ ] macOS
- [ ] Linux
- [ ] Web
- [ ] Android
- [ ] iOS

### 测试类型
- [ ] 单元测试通过
- [ ] Widget 测试通过
- [ ] 集成测试通过
- [ ] 手动测试通过

### 测试详情
<!-- 请描述测试步骤和结果 -->

1. 测试步骤1
2. 测试步骤2
3. 测试步骤3

---

## 📸 截图（如果有 UI 变更）
<!-- 请添加变更前后的对比截图 -->

### 变更前
![Before](screenshot-before.png)

### 变更后
![After](screenshot-after.png)

---

## ✅ 检查清单

### 代码质量
- [ ] 代码已通过 `dart format` 格式化
- [ ] 代码已通过 `dart analyze` 静态分析
- [ ] 所有测试已通过 (`flutter test`)
- [ ] 遵循项目编码规范 (`.claude/rules/CODE_STYLE_RULES.md`)
- [ ] 遵循项目错误处理规范 (`.claude/rules/ERROR_HANDLING_RULES.md`)

### 文档质量
- [ ] 所有用户可见的文本使用了国际化 (l10n)
- [ ] 没有硬编码的中文字符串
- [ ] 没有硬编码的英文字符串
- [ ] 中英文翻译都已添加到 `.arb` 文件
- [ ] 已运行 `flutter gen-l10n` 生成代码
- [ ] 在中英文环境下都测试过 UI 显示

### 提交信息
- [ ] 提交信息遵循规范 (`.claude/rules/GIT_COMMIT_RULES.md`)
- [ ] 提交信息清晰描述了改动
- [ ] 提交信息包含了 Co-Authored-By

### 变更影响
- [ ] 已评估对现有功能的影响
- [ ] 已评估对插件系统的影响
- [ ] 已评估对平台服务的影响
- [ ] 已评估对国际化的影响

---

## 🔗 相关 Issue
<!-- 关联相关的 Issue -->

Closes #(issue number)
Related to #(issue number)

---

## 📝 其他说明
<!-- 其他需要说明的内容 -->

---

## 📞 Reviewer 注意事项
<!-- 请 PR 创建者填写，提醒 Reviewer 关注的重点 -->

### 重点检查区域
- [ ] 重点关注模块1
- [ ] 重点关注模块2

### 特殊说明
<!-- 如：某些改动看似不寻常但实际必要 -->

---

**感谢您的贡献！** 🙏

<!--
审核流程：
1. 自动化检查（CI）
2. 文档检查（人工）
3. 代码审查（至少1个 Reviewer 批准）
4. 测试验证
5. 合并到主分支
-->
