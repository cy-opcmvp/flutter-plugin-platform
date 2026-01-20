# AI 编码规则 - 文档命名规范

> 📋 **本文档定义了项目中所有文档文件的命名规范，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有文档文件（.md 文件）

---

## 🎯 核心原则

### 1. 统一性原则
所有文档文件名必须遵循统一的命名风格，不得混用多种风格。

### 2. 可读性原则
文件名应该清晰表达文档内容，便于理解和搜索。

### 3. 一致性原则
同类型文档使用相同的命名模式。

### 4. 兼容性原则
文件名在所有操作系统（Windows, macOS, Linux）上都能正常使用。

---

## 📝 命名规范详解

### 规范 1: kebab-case（小写字母 + 连字符）

**适用范围**: 大部分文档文件

**格式**: `lowercase-with-hyphens.md`

**示例**:
```
✅ getting-started.md
✅ internal-plugin-development.md
✅ external-plugin-development.md
✅ plugin-sdk-guide.md
✅ project-structure.md
✅ platform-user-guide.md
✅ quick-start.md
✅ migration-guide.md
```

**使用场景**:
- 用户指南（guides/）
- 插件文档（plugins/）
- 示例文档（examples/）
- 工具文档（tools/）
- 参考文档（reference/）

---

### 规范 2: UPPERCASE_WITH_UNDERSCORES（大写字母 + 下划线）

**适用范围**: 特殊重要文档

**格式**: `UPPERCASE_WITH_UNDERSCORES.md`

**示例**:
```
✅ README.md
✅ CHANGELOG.md
✅ MASTER_INDEX.md
✅ RELEASE_NOTES_v0.4.0.md
✅ CONFIG_FEATURE_AUDIT.md
✅ VERSION_CONTROL_HISTORY.md
```

**使用场景**:
- 项目根目录核心文档（README.md, CHANGELOG.md）
- 文档主索引（MASTER_INDEX.md）
- 发布说明（RELEASE_NOTES_*.md）
- 版本历史（VERSION_CONTROL_*.md）
- 重要审计报告（*_AUDIT.md）

**限制**: 仅用于最重要的文档，过度使用会降低可读性。

---

### 规范 3: snake_case（小写字母 + 下划线）

**适用范围**: 配置相关文档

**格式**: `lowercase_with_underscores.md`

**示例**:
```
✅ screenshot_config_docs.md
✅ world_clock_config_docs.md
✅ calculator_config_docs.md
```

**使用场景**:
- 插件配置文档（config/*_config_docs.md）
- 数据模型文档（models/*.md）

---

## 🚫 禁止的命名方式

### ❌ 混合使用大小写
```
❌ Platform-Services-Guide.md
❌ getting_started_guide.md
❌ QuickStart.md
```

### ❌ 包含空格
```
❌ My Document.md
❌ release notes v0.4.0.md
```

### ❌ 使用特殊字符（除 - _ 之外）
```
❌ guide@v1.md
❌ docs&tools.md
❌ guide/test.md
```

### ❌ 过于简短的缩写
```
❌ gd.md（应该是 getting-started.md）
❌ ps.md（应该是 platform-services.md）
```

---

## 📂 各目录命名规范

### 根目录（/）
**规范**: 仅使用特殊命名

```
✅ README.md
✅ CHANGELOG.md
❌ getting-started.md（应放在 docs/）
❌ platform-services.md（应放在 docs/platform-services/）
```

---

### docs/ 目录

#### guides/ - 用户指南
**规范**: kebab-case

```
guides/
├── getting-started.md
├── internal-plugin-development.md
├── external-plugin-development.md
├── plugin-sdk-guide.md
├── platform-user-guide.md
├── icon-generation-guide.md
└── migration-guide.md
```

---

#### plugins/ - 插件文档
**规范**: kebab-case

```
plugins/
├── screenshot/
│   ├── README.md
│   ├── platform-support-analysis.md
│   └── platform-todo.md
└── world-clock/
    ├── README.md
    ├── implementation.md
    └── update-v1.1.md
```

---

#### platform-services/ - 平台服务文档
**规范**: kebab-case

```
platform-services/
├── README.md
├── quick-start.md
├── structure.md
└── docs-navigation.md
```

---

#### reports/ - 实施报告
**规范**: 根据重要性选择

**重要报告**: UPPERCASE_WITH_UNDERSCORES
```
reports/
├── CONFIG_FEATURE_AUDIT.md
├── CONFIG_IMPLEMENTATION_PROGRESS.md
└── PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md
```

**普通报告**: kebab-case
```
reports/
├── notification-fixes.md
└── audio-implementation.md
```

---

#### releases/ - 发布文档
**规范**: RELEASE_NOTES_版本号.md

```
releases/
├── RELEASE_NOTES_v0.2.1.md
├── RELEASE_NOTES_v0.3.1.md
└── RELEASE_NOTES_v0.4.0.md
```

---

#### archive/ - 归档文档
**规范**: 保持原始命名

归档文档保留创建时的命名，不作修改。

---

### .claude/rules/ - AI 编码规则
**规范**: UPPERCASE_WITH_UNDERSCORES

```
.claude/rules/
├── FILE_ORGANIZATION_RULES.md
├── JSON_CONFIG_RULES.md
├── PLUGIN_CONFIG_SPEC.md
├── VERSION_CONTROL_RULES.md
├── VERSION_CONTROL_HISTORY.md
└── DOCUMENTATION_NAMING_RULES.md
```

---

### .kiro/specs/ - 技术规范
**规范**: 小写全名

```
.kiro/specs/
├── plugin-platform/
│   ├── design.md
│   ├── requirements.md
│   └── tasks.md
└── platform-services/
    ├── design.md
    ├── implementation-plan.md
    └── testing-validation.md
```

---

## 🔤 版本号命名规范

### 发布文档
**格式**: `RELEASE_NOTES_v{major}.{minor}.{patch}.md`

**示例**:
```
✅ RELEASE_NOTES_v0.4.0.md
✅ RELEASE_NOTES_v1.0.0.md
✅ RELEASE_NOTES_v2.1.3.md
```

### 更新说明
**格式**: `{feature}-update-v{version}.md`

**示例**:
```
✅ world-clock-update-v1.1.md
✅ plugin-system-update-v2.0.md
```

---

## 📋 特殊文件命名

### README 文件
**规范**: 统一使用 `README.md`

**说明**: 每个主要目录都应该有 README.md

### 索引文件
**规范**: 使用描述性名称

```
✅ MASTER_INDEX.md（文档主索引）
✅ project-structure.md（项目结构）
❌ index.md（过于通用）
```

---

## 🔄 重命名规则

### 批量重命名清单

根据新规范，以下文档需要重命名：

#### docs/guides/
| 当前命名 | 新命名 |
|---------|--------|
| `AUDIO_QUICK_REFERENCE.md` | `audio-quick-reference.md` |
| `ICON_GENERATION_GUIDE.md` | `icon-generation-guide.md` |
| `PLATFORM_SERVICES_USER_GUIDE.md` | `platform-services-user-guide.md` |

#### docs/platform-services/
| 当前命名 | 新命名 |
|---------|--------|
| `DOCS_NAVIGATION.md` | `docs-navigation.md` |
| `DOCS_REORGANIZATION.md` | `docs-reorganization.md` |
| `STRUCTURE.md` | `structure.md` |

#### docs/platforms/screenshots/
| 当前命名 | 新命名 |
|---------|--------|
| `PLATFORM_SUPPORT_ANALYSIS.md` | `platform-support-analysis.md` |
| `PLATFORM_TODO.md` | `platform-todo.md` |

#### docs/platforms/world-clock/
| 当前命名 | 新命名 |
|---------|--------|
| `IMPLEMENTATION.md` | `implementation.md` |
| `UPDATE_v1.1.md` | `update-v1.1.md` |

---

## ✅ 检查清单

创建新文档时，检查：

- [ ] 文件名符合对应目录的命名规范
- [ ] 没有使用空格
- [ ] 没有使用特殊字符（除 - _）
- [ ] 版本号格式正确（如：v0.4.0）
- [ ] 与同类型文档命名一致
- [ ] 在所有操作系统上兼容

---

## 🛠️ 重命名工具

### 使用脚本批量重命名

**Windows PowerShell**:
```powershell
# 重命名 guides 目录
Rename-Item "docs\guides\AUDIO_QUICK_REFERENCE.md" "audio-quick-reference.md"
Rename-Item "docs\guides\ICON_GENERATION_GUIDE.md" "icon-generation-guide.md"
Rename-Item "docs\guides\PLATFORM_SERVICES_USER_GUIDE.md" "platform-services-user-guide.md"

# 重命名 platform-services 目录
Rename-Item "docs\platform-services\DOCS_NAVIGATION.md" "docs-navigation.md"
Rename-Item "docs\platform-services\DOCS_REORGANIZATION.md" "docs-reorganization.md"

# 重命名 plugins/screenshot 目录
Rename-Item "docs\plugins\screenshot\PLATFORM_SUPPORT_ANALYSIS.md" "platform-support-analysis.md"
Rename-Item "docs\plugins\screenshot\PLATFORM_TODO.md" "platform-todo.md"

# 重命名 plugins/world-clock 目录
Rename-Item "docs\plugins\world-clock\IMPLEMENTATION.md" "implementation.md"
Rename-Item "docs\plugins\world-clock\UPDATE_v1.1.md" "update-v1.1.md"
```

**Linux/macOS Bash**:
```bash
# 重命名 guides 目录
mv docs/guides/AUDIO_QUICK_REFERENCE.md docs/guides/audio-quick-reference.md
mv docs/guides/ICON_GENERATION_GUIDE.md docs/guides/icon-generation-guide.md
mv docs/guides/PLATFORM_SERVICES_USER_GUIDE.md docs/guides/platform-services-user-guide.md

# 重命名 platform-services 目录
mv docs/platform-services/DOCS_NAVIGATION.md docs/platform-services/docs-navigation.md
mv docs/platform-services/DOCS_REORGANIZATION.md docs/platform-services/docs-reorganization.md

# 重命名 plugins/screenshot 目录
mv docs/plugins/screenshot/PLATFORM_SUPPORT_ANALYSIS.md docs/plugins/screenshot/platform-support-analysis.md
mv docs/plugins/screenshot/PLATFORM_TODO.md docs/plugins/screenshot/platform-todo.md

# 重命名 plugins/world-clock 目录
mv docs/plugins/world-clock/IMPLEMENTATION.md docs/plugins/world-clock/implementation.md
mv docs/plugins/world-clock/UPDATE_v1.1.md docs/plugins/world-clock/update-v1.1.md
```

---

## 📚 参考文档

- [文件组织规范](./FILE_ORGANIZATION_RULES.md)
- [版本控制规则](./VERSION_CONTROL_RULES.md)
- [JSON 配置规则](./JSON_CONFIG_RULES.md)
- [项目主文档](../../CLAUDE.md)

---

## 🎯 记忆要点

### 简化记忆

1. **普通文档**: 小写 + 连字符 `kebab-case`
2. **特殊文档**: 大写 + 下划线 `UPPERCASE_CASE`
3. **配置文档**: 小写 + 下划线 `snake_case`
4. **禁止**: 空格、特殊字符、大小写混用

### 决策树

```
是否为根目录核心文档（README, CHANGELOG）？
├─ 是 → UPPERCASE_CASE
└─ 否 → 继续

是否为发布说明（RELEASE_NOTES）？
├─ 是 → UPPERCASE_CASE
└─ 否 → 继续

是否为配置文档（*_config_docs）？
├─ 是 → snake_case
└─ 否 → kebab-case
```

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Flutter Plugin Platform 团队
