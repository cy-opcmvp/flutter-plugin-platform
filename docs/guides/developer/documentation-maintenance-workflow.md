# 文档维护流程指南

> 📋 **本文档定义了项目的文档维护流程和最佳实践**

**版本**: v1.0.0
**更新**: 2026-01-21
**维护者**: Flutter Plugin Platform 团队

---

## 🎯 维护目标

1. **保持文档准确性** - 确保文档与代码保持同步
2. **提高文档可用性** - 让文档易于查找和使用
3. **建立维护机制** - 自动化和流程化文档维护
4. **持续改进质量** - 定期审计和优化文档

---

## 📅 维护周期

### 日常维护（每日）

**时机**: 每次代码提交前

**任务**:
- [ ] 检查相关文档是否需要更新
- [ ] 运行文档检查脚本
- [ ] 更新变更日志（如需要）

**工具**: `check-docs.sh` 或 `check-docs.ps1`

```bash
# 检查暂存区的文档变更
./scripts/check-docs.sh staged

# 或 PowerShell
.\scripts\check-docs.ps1 -Mode staged
```

---

### 周度维护（每周）

**时机**: 每周五下午

**任务**:
- [ ] 检查本周新增的文档
- [ ] 验证文档链接有效性
- [ ] 检查文档索引是否需要更新
- [ ] 处理文档相关的 Issue

**流程**:
1. 查看本周提交的文档
2. 运行链接检查
3. 更新索引文件
4. 回复用户反馈

---

### 月度维护（每月）

**时机**: 每月最后一个工作日

**任务**:
- [ ] 运行文档覆盖率检查
- [ ] 检查过时内容
- [ ] 更新文档统计
- [ ] 审计文档质量

**检查清单**:
```markdown
## 月度文档检查清单

### 覆盖率检查
- [ ] 代码文档覆盖率 ≥80%
- [ ] 功能文档完整率 100%
- [ ] API 文档准确率 ≥95%

### 内容检查
- [ ] 检查过时的技术说明
- [ ] 检查失效的链接
- [ ] 检查过时的截图
- [ ] 检查不一致的术语

### 结构检查
- [ ] 文档分类是否合理
- [ ] 索引是否完整
- [ ] 命名是否符合规范
- [ ] 目录组织是否清晰

### 用户反馈
- [ ] 处理文档 Issue
- [ ] 回复文档 PR
- [ ] 收集用户建议
```

---

### 季度维护（每季度）

**时机**: 每季度末（3/6/9/12月）

**任务**:
- [ ] 全面文档审计
- [ ] 文档结构优化
- [ ] 更新维护流程
- [ ] 文档质量评估

**审计内容**:
1. **文档完整性** - 是否覆盖所有功能
2. **文档准确性** - 是否与代码同步
3. **文档可用性** - 是否易于查找和使用
4. **文档质量** - 写作质量和技术准确性

**输出**: 季度文档审计报告

---

### 年度维护（每年）

**时机**: 每年12月

**任务**:
- [ ] 文档体系回顾
- [ ] 重大结构调整
- [ ] 工具和流程升级
- [ ] 年度总结报告

---

## 🔧 维护工具

### 1. 文档检查脚本

**位置**: `scripts/check-docs.sh` / `scripts/check-docs.ps1`

**功能**:
- 检查代码变更是否伴随文档更新
- 检查配置文件与文档同步
- 检查国际化文件同步
- 检查 CHANGELOG 更新

**使用**:
```bash
# Git Hook 自动检查
git commit

# 手动检查暂存区
./scripts/check-docs.sh staged

# 手动检查最近提交
./scripts/check-docs.sh committed
```

---

### 2. 文档覆盖率检查

**创建**: `scripts/check-doc-coverage.sh`

```bash
#!/bin/bash

# 文档覆盖率检查脚本

echo "📊 文档覆盖率检查"

# 检查插件文档覆盖率
plugin_count=$(find lib/plugins -name "*_plugin.dart" | wc -l)
doc_count=$(find docs/plugins -name "README.md" | wc -l)

echo "插件数量: $plugin_count"
echo "文档数量: $doc_count"

if [ $doc_count -lt $plugin_count ]; then
    echo "⚠️  部分插件缺少文档"
else
    echo "✅ 所有插件都有文档"
fi

# 检查配置文档覆盖率
config_count=$(find lib/plugins/*/config -name "*_settings.dart" 2>/dev/null | wc -l)
config_doc_count=$(find lib/plugins/*/config -name "*_config_docs.md" 2>/dev/null | wc -l)

echo "配置数量: $config_count"
echo "配置文档数量: $config_doc_count"

if [ $config_doc_count -lt $config_count ]; then
    echo "⚠️  部分配置缺少文档"
else
    echo "✅ 所有配置都有文档"
fi
```

---

### 3. 链接有效性检查

**创建**: `scripts/check-doc-links.sh`

```bash
#!/bin/bash

# 检查 Markdown 文档中的链接

echo "🔗 检查文档链接..."

find docs .claude .kiro -name "*.md" -type f | while read file; do
    # 提取相对链接
    links=$(grep -oE '\[.*\]\(([^)]+)\)' "$file" | grep -oE '\(([^)]+)\)' | tr -d '()' | grep -E '^\.\./|^\./')

    for link in $links; do
        target=$(dirname "$file")/$link
        if [ ! -f "$target" ]; then
            echo "❌ $file: 无效链接 $link"
        fi
    done
done

echo "✅ 链接检查完成"
```

---

## 📋 维护流程

### 1. 代码变更时的文档维护

```
开始代码变更
    ↓
识别受影响的文档（使用映射表）
    ↓
同步更新文档
    ↓
运行 check-docs.sh 检查
    ↓
修复文档问题
    ↓
提交代码和文档
    ↓
更新 CHANGELOG.md
```

---

### 2. 新功能开发时的文档维护

```
需求分析
    ↓
创建/更新需求文档 (.kiro/specs/{feature}/requirements.md)
    ↓
设计阶段
    ↓
创建/更新设计文档 (.kiro/specs/{feature}/design.md)
    ↓
开发阶段
    ↓
更新用户指南 (docs/guides/*.md)
    ↓
测试阶段
    ↓
验证文档准确性
    ↓
发布阶段
    ↓
创建发布文档 (docs/releases/RELEASE_NOTES_v{version}.md)
    ↓
更新索引文件
```

---

### 3. Bug 修复时的文档维护

```
Bug 报告
    ↓
分析影响范围
    ↓
修复代码
    ↓
是否需要更新文档？
    ├─ 是 → 更新相关文档
    │        - 故障排除指南
    │        - API 文档
    │        - 用户指南
    └─ 否 → 继续
    ↓
提交修复
    ↓
更新 CHANGELOG.md
```

---

## 📊 文档质量指标

### 1. 覆盖率指标

| 指标 | 目标 | 检查方法 |
|------|------|---------|
| **代码文档覆盖率** | ≥80% | `scripts/check-doc-coverage.sh` |
| **功能文档完整率** | 100% | 人工检查每个功能 |
| **API 文档准确率** | ≥95% | 代码示例验证 |

### 2. 时效性指标

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| **文档更新延迟** | ≤1 天 | 代码提交与文档提交的时间差 |
| **文档审查响应** | ≤2 天 | PR 创建到审查完成的时间 |
| **文档修复时间** | ≤3 天 | Issue 报告到修复完成的时间 |

### 3. 质量指标

| 指标 | 目标 | 检查方法 |
|------|------|---------|
| **链接有效率** | 100% | `scripts/check-doc-links.sh` |
| **示例可运行率** | 100% | 运行文档中的代码示例 |
| **用户满意度** | ≥4.5/5 | 用户反馈评分 |

---

## 🎯 最佳实践

### 1. 文档先行

在开始编码前，先创建或更新文档：

```markdown
1. 需求文档 - 描述要做什么
2. 设计文档 - 描述怎么做
3. API 文档 - 描述接口
4. 用户指南 - 描述如何使用
```

**好处**:
- 文档成为设计的一部分
- 减少返工
- 提高代码质量

---

### 2. 文档与代码同仓库

- ✅ 使用 Markdown 格式
- ✅ 与代码一起版本控制
- ✅ 通过 PR 管理文档变更
- ✅ 文档变更纳入 Code Review

---

### 3. 自动化检查

- ✅ 使用 Git Hooks 自动运行检查
- ✅ 在 CI 中添加文档验证
- ✅ 使用脚本检查链接和示例
- ✅ 自动生成文档统计

**Git Hook 示例**:
```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "🔍 检查文档变更..."
./scripts/check-docs.sh staged

if [ $? -ne 0 ]; then
    echo "❌ 文档检查未通过"
    echo "使用 git commit --no-verify 跳过检查"
    exit 1
fi
```

---

### 4. 定期审计

- ✅ 每周检查新增文档
- ✅ 每月检查文档覆盖率
- ✅ 每季度全面审计
- ✅ 每年回顾和优化

---

### 5. 用户反馈

- ✅ 在文档中添加反馈链接
- ✅ 在 GitHub Issues 中标记 `documentation` 标签
- ✅ 定期处理文档问题
- ✅ 根据反馈改进文档

**反馈链接示例**:
```markdown
---
[📝 反馈问题](https://github.com/user/repo/issues/new?title=Doc:+{title})
[🔙 返回文档索引](../MASTER_INDEX.md)
---
```

---

## 🚨 常见问题和解决方案

### 问题1: 文档与代码不同步

**症状**: 文档描述与实际代码不符

**原因**:
- 代码变更后忘记更新文档
- 文档更新滞后

**解决方案**:
1. 使用 `check-docs.sh` 脚本在提交前检查
2. 在 Code Review 时强制检查文档
3. 定期运行文档审计

---

### 问题2: 文档链接失效

**症状**: 点击文档中的链接出现 404

**原因**:
- 文档重命名后未更新链接
- 文档删除后未更新引用

**解决方案**:
1. 使用 `check-doc-links.sh` 定期检查
2. 文档重命名时搜索所有引用
3. 在 CI 中添加链接检查

---

### 问题3: 文档难以找到

**症状**: 用户找不到需要的文档

**原因**:
- 文档组织不合理
- 索引不完整
- 命名不规范

**解决方案**:
1. 优化文档目录结构
2. 完善索引文件
3. 统一命名规范
4. 添加搜索功能

---

### 问题4: 文档质量不高

**症状**: 文档内容不清晰、不准确

**原因**:
- 缺少写作规范
- 没有审查机制
- 缺少用户反馈

**解决方案**:
1. 制定文档写作规范
2. 在 Code Review 中审查文档
3. 收集和处理用户反馈
4. 定期培训文档写作

---

## 📚 参考资源

### 内部文档
- [文档变更管理规范](../../.claude/rules/DOCUMENTATION_CHANGE_MANAGEMENT.md)
- [文档命名规范](../../.claude/rules/DOCUMENTATION_NAMING_RULES.md)
- [文档主索引](../MASTER_INDEX.md)

### 外部资源
- [Write the Docs](https://www.writethedocs.org/)
- [Google Technical Writing](https://developers.google.com/tech-writing)
- [Markdown 指南](https://www.markdownguide.org/)

---

## 🔄 持续改进

### 改进机制

1. **定期回顾** - 每季度回顾维护流程
2. **收集反馈** - 收集团队和用户的反馈
3. **优化流程** - 根据反馈优化流程
4. **更新工具** - 持续改进自动化工具

### 改进目标

- **提高效率** - 减少手动操作
- **提高质量** - 提高文档准确性
- **提高满意度** - 提高用户满意度

---

## 📞 联系方式

如有问题或建议，请联系：
- GitHub Issues: [提交问题](https://github.com/user/repo/issues)
- 文档维护者: @maintainer

---

**版本**: v1.0.0
**最后更新**: 2026-01-21
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 好的文档是项目成功的关键！请认真对待文档维护！
