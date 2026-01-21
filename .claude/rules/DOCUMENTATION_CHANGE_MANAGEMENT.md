# 文档变更管理规范

> 📋 **本文档定义了文档的变更管理机制，确保需求变更时不会遗漏对文档的修改**

**版本**: v1.0.0
**生效日期**: 2026-01-21
**适用范围**: 所有项目文档

---

## 🎯 核心原则

### 1. 文档即代码
文档与代码同等重要，必须随代码变更同步更新。

### 2. 分类管理
不同类型的文档有不同的变更频率和更新策略。

### 3. 自动化追踪
通过工具和流程自动追踪文档变更，减少人工疏漏。

### 4. 审查机制
代码审查时必须检查相关文档是否同步更新。

---

## 📊 文档分类

### 🔄 动态文档（高频变更）

**定义**: 随需求变更频繁更新的文档

#### 1. 规范类文档（.claude/rules/）

| 文档 | 变更频率 | 变更触发条件 |
|------|---------|-------------|
| `VERSION_CONTROL_HISTORY.md` | 🔴 极高 | 每次发布/push |
| `VERSION_CONTROL_RULES.md` | 🟡 中 | 版本管理策略变更 |
| `CODE_STYLE_RULES.md` | 🟢 低 | 代码标准变更 |
| `TESTING_RULES.md` | 🟢 低 | 测试策略变更 |
| `ERROR_HANDLING_RULES.md` | 🟢 低 | 错误处理策略变更 |
| `PLUGIN_CONFIG_SPEC.md` | 🟡 中 | 插件系统变更 |
| `PLUGIN_SETTINGS_SCREEN_RULES.md` | 🟡 中 | UI 规范变更 |
| `JSON_CONFIG_RULES.md` | 🟡 中 | 配置系统变更 |
| `DOCUMENTATION_NAMING_RULES.md` | 🟢 低 | 命名规范变更 |
| `FILE_ORGANIZATION_RULES.md` | 🟢 低 | 文件结构变更 |
| `GIT_COMMIT_RULES.md` | 🟢 低 | 提交规范变更 |

**更新策略**:
- 规范变更时必须立即更新
- 需要团队评审
- 标注版本号和更新日期

#### 2. 技术规范文档（.kiro/specs/）

| 规范类别 | 文档 | 变更频率 | 变更触发条件 |
|---------|------|---------|-------------|
| **平台服务** | design.md | 🟡 中 | 架构变更 |
| | implementation-plan.md | 🟡 中 | 实施计划调整 |
| | testing-validation.md | 🟡 中 | 测试策略变更 |
| **插件平台** | design.md | 🟢 低 | 核心架构变更 |
| | tasks.md | 🟡 中 | 任务进度更新 |
| | requirements.md | 🟢 低 | 需求变更 |
| **外部插件** | design.md | 🟡 中 | 架构演进 |
| | tasks.md | 🟡 中 | 实施进度更新 |
| | requirements.md | 🟡 中 | 功能需求变更 |
| **国际化** | design.md | 🟢 低 | 国际化策略变更 |
| | tasks.md | 🟡 中 | 实施进度更新 |
| | requirements.md | 🟡 中 | 语言支持变更 |
| **Web 兼容性** | design.md | 🟡 中 | 兼容性策略变更 |
| | tasks.md | 🟡 中 | 实施进度更新 |
| | requirements.md | 🟡 中 | 平台支持变更 |

**更新策略**:
- 需求变更时更新 `requirements.md`
- 设计变更时更新 `design.md`
- 任务完成时更新 `tasks.md`
- 大型变更需要创建新版本

#### 3. 项目核心文档

| 文档 | 变更频率 | 变更触发条件 |
|------|---------|-------------|
| `README.md` (根目录) | 🟡 中 | 功能变更、安装流程变更 |
| `CHANGELOG.md` | 🔴 极高 | 每次发布 |
| `.claude/CLAUDE.md` | 🟡 中 | 项目架构变更 |
| `.claude/PROJECT_OVERVIEW.md` | 🟡 中 | 项目结构变更 |

**更新策略**:
- README 随功能变更同步更新
- CHANGELOG 每次发布强制更新
- CLAUDE.md 架构变更时更新

#### 4. 插件文档（lib/plugins/*/config/）

| 文档类型 | 变更频率 | 变更触发条件 |
|---------|---------|-------------|
| `*_config_docs.md` | 🟡 中 | 配置项变更 |
| `plugin_descriptor.json` | 🟡 中 | 插件元数据变更 |
| `README.md` | 🟡 中 | 功能变更 |

**更新策略**:
- 配置项增删改时必须更新
- 插件版本变更时更新 descriptor

---

### 📦 静态文档（低频变更）

**定义**: 相对稳定，不随日常开发变更的文档

#### 1. 用户指南（docs/guides/）

| 文档 | 变更频率 | 说明 |
|------|---------|------|
| `getting-started.md` | 🟢 低 | 快速入门指南 |
| `internal-plugin-development.md` | 🟡 中 | 内部插件开发 |
| `external-plugin-development.md` | 🟡 中 | 外部插件开发 |
| `platform-services-user-guide.md` | 🟡 中 | 平台服务使用 |
| `icon-generation-guide.md` | 🟢 低 | 图标生成 |
| `audio-quick-reference.md` | 🟢 低 | 音频参考 |
| `desktop-pet-*.md` | 🟢 低 | Desktop Pet 相关 |

**更新策略**:
- 功能重大变更时更新
- 用户反馈问题时修正

#### 2. 实施报告（docs/reports/）

| 文档 | 变更频率 | 说明 |
|------|---------|------|
| `PLATFORM_SERVICES_PHASE0_COMPLETE.md` | 🟢 低 | 历史报告，不再变更 |
| `PLATFORM_SERVICES_PHASE1_COMPLETE.md` | 🟢 低 | 历史报告，不再变更 |
| `PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md` | 🟢 低 | 最终报告 |
| `CONFIG_FEATURE_AUDIT.md` | 🟢 低 | 审计报告 |
| `CONFIG_IMPLEMENTATION_PROGRESS.md` | 🟡 中 | 实施进度 |

**更新策略**:
- 历史报告不再变更
- 进度报告随进度更新

#### 3. 插件详细文档（docs/plugins/*/）

| 文档 | 变更频率 | 说明 |
|------|---------|------|
| `README.md` | 🟡 中 | 插件概述 |
| `implementation.md` | 🟡 中 | 实现细节 |
| `update-v*.md` | 🟢 低 | 版本更新记录 |
| `platform-support-analysis.md` | 🟡 中 | 平台支持分析 |
| `platform-todo.md` | 🟡 中 | 待办事项 |

**更新策略**:
- 重大版本更新时创建新的 update 文档
- TODO 完成时更新

#### 4. 归档文档（docs/archive/）

**变更频率**: 🚫 不变更

**说明**: 历史文档，仅供参考

---

## 🔗 文档与代码的关联

### 1. 代码变更 → 文档变更映射表

| 代码变更类型 | 必须更新的文档 | 更新策略 |
|------------|-------------|---------|
| **新增插件** | `docs/plugins/{plugin}/README.md`<br>`lib/plugins/{plugin}/config/{plugin}_config_docs.md`<br>`CHANGELOG.md` | 创建新文档 |
| **插件功能变更** | `docs/plugins/{plugin}/implementation.md`<br>`lib/plugins/{plugin}/config/{plugin}_config_docs.md`<br>`CHANGELOG.md` | 更新现有文档 |
| **插件配置变更** | `lib/plugins/{plugin}/config/{plugin}_config_defaults.dart`<br>`lib/plugins/{plugin}/config/{plugin}_config_docs.md` | 同步更新配置和文档 |
| **平台服务变更** | `docs/platform-services/README.md`<br>`docs/guides/platform-services-user-guide.md`<br>`.kiro/specs/platform-services/design.md` | 更新相关文档 |
| **新增服务** | `.kiro/specs/platform-services/implementation-plan.md`<br>`docs/platform-services/README.md`<br>`CHANGELOG.md` | 创建新文档 |
| **架构变更** | `.claude/CLAUDE.md`<br>`README.md`<br>相关 design.md | 更新架构文档 |
| **API 变更** | `docs/guides/xxx-development.md`<br>`README.md` | 更新 API 文档 |
| **规范变更** | `.claude/rules/{RULE}_RULES.md`<br>`CHANGELOG.md` | 更新规范文档 |
| **国际化变更** | `lib/l10n/app_*.arb`<br>`docs/guides/xxx.md` | 更新翻译和文档 |
| **发布新版本** | `CHANGELOG.md`<br>`VERSION_CONTROL_HISTORY.md`<br>`docs/releases/RELEASE_NOTES_v{version}.md` | 创建发布文档 |

### 2. 需求变更 → 文档变更映射表

| 需求类型 | 影响的文档 | 更新时机 |
|---------|-----------|---------|
| **功能需求** | `.kiro/specs/{feature}/requirements.md`<br>`docs/guides/xxx.md` | 需求确认后 |
| **设计变更** | `.kiro/specs/{feature}/design.md`<br>`docs/platform-services/README.md` | 设计确认后 |
| **任务分配** | `.kiro/specs/{feature}/tasks.md` | 任务变更时 |
| **Bug 修复** | `docs/troubleshooting/xxx.md` | 修复后添加说明 |

---

## ✅ 文档变更检查清单

### 开发阶段

在编写代码前，检查：

- [ ] 是否需要更新用户指南？
- [ ] 是否需要更新 API 文档？
- [ ] 是否需要更新配置文档？
- [ ] 是否需要更新示例代码？

### 提交阶段

在 git commit 前，检查：

- [ ] 相关文档是否已更新？
- [ ] CHANGELOG.md 是否需要更新？
- [ ] 文档中的代码示例是否仍然有效？
- [ ] 文档中的链接是否有效？

### 发布阶段

在发布新版本前，检查：

- [ ] CHANGELOG.md 是否完整？
- [ ] VERSION_CONTROL_HISTORY.md 是否更新？
- [ ] 是否需要创建 RELEASE_NOTES？
- [ ] README.md 是否需要更新？
- [ ] 过时的文档是否已归档？

---

## 🛠️ 文档变更管理工具

### 1. 自动化检查脚本

创建 `.claude/scripts/check-docs.sh`:

```bash
#!/bin/bash

# 检查文档变更
echo "🔍 检查文档变更..."

# 获取本次提交修改的文件
CHANGED_FILES=$(git diff --cached --name-only)

# 检查是否修改了代码但未更新文档
CODE_CHANGED=false
DOC_UPDATED=false

for file in $CHANGED_FILES; do
  if [[ $file == lib/plugins/* ]]; then
    CODE_CHANGED=true
  fi
  if [[ $file == docs/plugins/* ]] || [[ $file == lib/plugins/*/config/* ]]; then
    DOC_UPDATED=true
  fi
done

if $CODE_CHANGED && ! $DOC_UPDATED; then
  echo "⚠️  警告: 修改了插件代码，但未更新相关文档"
  echo "请检查是否需要更新以下文档："
  echo "  - docs/plugins/{plugin}/README.md"
  echo "  - lib/plugins/{plugin}/config/{plugin}_config_docs.md"
fi
```

### 2. 文档变更模板

创建 `.claude/templates/doc-change-template.md`:

```markdown
# 文档变更记录

## 变更信息
- **日期**: {date}
- **版本**: {version}
- **变更类型**: {feature|bug|docs|refactor}

## 变更描述
{description}

## 影响的文档
- [ ] `docs/guides/xxx.md` - {变更内容}
- [ ] `README.md` - {变更内容}
- [ ] `CHANGELOG.md` - {变更内容}

## 验证清单
- [ ] 所有链接有效
- [ ] 代码示例可运行
- [ ] 截图/图表最新
- [ ] 语法正确

## 审查状态
- [ ] 自查完成
- [ ] 同行评审
- [ ] 批准发布
```

### 3. PR 模板更新

在 `.github/PULL_REQUEST_TEMPLATE.md` 中添加文档检查项：

```markdown
## 📝 文档变更

### 本次变更涉及的文档
- [ ] 用户指南
- [ ] API 文档
- [ ] 配置文档
- [ ] README.md
- [ ] CHANGELOG.md

### 文档变更说明
<!-- 请列出本次变更中所有文档的修改 -->

### 文档检查清单
- [ ] 所有相关文档已更新
- [ ] 文档中的代码示例已验证
- [ ] 新增功能有文档说明
- [ ] 变更的功能有更新说明
```

---

## 🔄 文档变更流程

### 流程图

```
需求变更
    ↓
识别受影响的文档 ← 使用"文档与代码关联映射表"
    ↓
更新文档内容
    ↓
运行自动化检查 ← check-docs.sh
    ↓
代码审查（包含文档审查）
    ↓
提交变更（git commit）
    ↓
更新 CHANGELOG.md
    ↓
测试文档（链接、示例）
    ↓
合并到主分支
```

### 具体步骤

#### 1. 需求分析阶段

**输入**: 新需求或变更请求

**输出**: 受影响的文档列表

**操作**:
1. 使用"文档与代码关联映射表"识别受影响的文档
2. 评估文档变更的范围和难度
3. 将文档更新任务加入开发任务清单

#### 2. 开发阶段

**输入**: 代码变更

**输出**: 更新的文档

**操作**:
1. 在修改代码的同时更新文档
2. 使用文档变更模板记录变更
3. 运行 `check-docs.sh` 检查遗漏

#### 3. 提交阶段

**输入**: 代码和文档变更

**输出**: git commit

**操作**:
1. 将文档变更和代码变更一起提交
2. 提交信息中明确说明文档变更
3. 更新 VERSION_CONTROL_HISTORY.md（如果需要）

#### 4. 发布阶段

**输入**: 完成的功能

**输出**: 发布文档

**操作**:
1. 更新 CHANGELOG.md
2. 创建 RELEASE_NOTES
3. 更新 VERSION_CONTROL_HISTORY.md
4. 创建/更新标签

---

## 📋 文档变更跟踪表

### 使用方法

在每个 `.kiro/specs/{feature}/` 目录下创建 `docs-tracking.md`:

```markdown
# 文档变更跟踪

## 当前文档状态

| 文档 | 状态 | 最后更新 | 负责人 | 备注 |
|------|------|---------|--------|------|
| requirements.md | ✅ 完成 | 2026-01-21 | @user | |
| design.md | ✅ 完成 | 2026-01-21 | @user | |
| tasks.md | 🔄 进行中 | 2026-01-20 | @user | 任务6待更新 |

## 变更历史

### 2026-01-21
- 更新 design.md：新增外部插件架构图
- 更新 tasks.md：标记任务1-5为完成

### 2026-01-20
- 创建 requirements.md
- 创建 design.md
- 创建 tasks.md

## 待更新文档

- [ ] README.md - 需要添加外部插件示例
- [ ] guides/external-plugin-development.md - 需要更新 API 说明
```

---

## 🚨 常见问题和解决方案

### 问题1: 忘记更新文档

**症状**: 代码已提交，但文档未更新

**解决方案**:
1. 使用 `check-docs.sh` 脚本在提交前检查
2. 在 PR 模板中强制填写文档变更
3. Code Review 时强制检查文档

### 问题2: 文档与代码不同步

**症状**: 文档描述与实际代码不符

**解决方案**:
1. 定期运行文档审计（每月一次）
2. 在 CI 中添加文档检查（检查代码示例是否可运行）
3. 用户反馈时及时修正

### 问题3: 不知道要更新哪些文档

**症状**: 需求变更后，不清楚需要更新哪些文档

**解决方案**:
1. 使用本文档的"文档与代码关联映射表"
2. 在需求分析阶段就列出需要更新的文档
3. 使用文档跟踪表记录状态

### 问题4: 文档变更太频繁

**症状**: 小改动都要更新大量文档

**解决方案**:
1. 区分"必须更新"和"建议更新"
2. 小改动可以批量积累后统一更新
3. 使用文档版本标记，避免频繁更新核心文档

---

## 📊 文档质量指标

### 覆盖率指标

- **代码文档覆盖率**: ≥80%（代码与文档的比例）
- **功能文档完整率**: 100%（所有功能都有文档）
- **API 文档准确率**: ≥95%（API 文档与实际代码一致）

### 时效性指标

- **文档更新延迟**: ≤1 天（代码变更后文档更新的时间）
- **文档审查响应**: ≤2 天（文档 PR 的审查时间）
- **文档修复时间**: ≤3 天（用户反馈的文档问题修复时间）

### 质量指标

- **链接有效率**: 100%（文档中的所有链接有效）
- **示例可运行率**: 100%（文档中的代码示例可运行）
- **用户满意度**: ≥4.5/5（文档质量评分）

---

## 🎯 最佳实践

### 1. 文档先行

在开始编码前，先更新或创建相关文档：
- 设计文档描述做什么
- API 文档描述接口
- 用户指南描述如何使用

### 2. 文档与代码同仓库

将文档与代码放在同一个仓库中：
- 使用 Markdown 格式
- 与代码一起版本控制
- 通过 PR 管理文档变更

### 3. 文档即代码

将文档视为代码的一部分：
- 遵循编码规范（命名、格式）
- 进行代码审查
- 自动化检查（拼写、链接）

### 4. 定期审计

定期审计文档质量：
- 每月检查一次文档覆盖率
- 每季度检查一次文档准确性
- 每年进行一次全面审查

### 5. 用户反馈

鼓励用户反馈文档问题：
- 在文档页面添加"反馈"链接
- 在 GitHub Issues 中标记"documentation"标签
- 定期处理文档相关的 Issue

---

## 📚 参考资源

### 内部资源
- [文档主索引](../docs/MASTER_INDEX.md)
- [文档命名规范](./DOCUMENTATION_NAMING_RULES.md)
- [版本控制规则](./VERSION_CONTROL_RULES.md)

### 外部资源
- [Write the Docs](https://www.writethedocs.org/)
- [Google Technical Writing](https://developers.google.com/tech-writing)
- [Documentation Driven Development](https://www.documentationdrivendevelopment.com/)

---

**版本**: v1.0.0
**最后更新**: 2026-01-21
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 文档是项目的重要组成部分，请像对待代码一样认真对待文档！
