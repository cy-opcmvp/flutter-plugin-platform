# 文档系统全面梳理报告

**审计日期**: 2026-01-20
**审计范围**: 项目中所有 .md 文档
**审计目的**: 评估文档重要性、识别过时内容、提出删除建议

---

## 📊 统计概览

### 文档总数
- **总文档数**: 110+ 个 .md 文件
- **核心文档**: 25 个
- **规范文档**: 18 个
- **报告文档**: 12 个
- **过时/重复**: 15+ 个
- **构建产物**: 3 个（应删除）

---

## 🎯 核心文档（必须保留）

### 根目录核心文档

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `README.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 项目主文档，**绝对不能删除** |
| `CHANGELOG.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 版本变更历史，**绝对不能删除** |
| `PLATFORM_SERVICES.md` | ⭐⭐⭐⭐ | ⚠️ 位置不当 | 应移到 `docs/platform-services/` |

### .claude/ 核心文档（AI 指导）

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `.claude/CLAUDE.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | Claude Code 主指导文档 |
| `.claude/rules/` | ⭐⭐⭐⭐⭐ | ✅ 最新 | **编码规范，绝对不能删除** |
| `.claude/rules/FILE_ORGANIZATION_RULES.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 文件组织规范 |
| `.claude/rules/JSON_CONFIG_RULES.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | JSON 配置规范 |
| `.claude/rules/PLUGIN_CONFIG_SPEC.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 插件配置规范 |
| `.claude/rules/VERSION_CONTROL_RULES.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 版本控制规范 |
| `.claude/rules/VERSION_CONTROL_HISTORY.md` | ⭐⭐⭐⭐ | ✅ 最新 | 版本历史记录 |

### docs/ 核心文档

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `docs/MASTER_INDEX.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 文档主索引，**导航中心** |
| `docs/README.md` | ⭐⭐⭐⭐ | ✅ 最新 | 文档中心 |
| `docs/index.md` | ⭐⭐⭐ | ⚠️ 可能重复 | 与 MASTER_INDEX 功能重复，需评估 |
| `docs/project-structure.md` | ⭐⭐⭐⭐ | ✅ 最新 | 项目结构说明 |

---

## 📚 开发指南（重要）

### 插件开发

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `docs/guides/internal-plugin-development.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 内部插件开发指南 |
| `docs/guides/external-plugin-development.md` | ⭐⭐⭐⭐ | ⚠️ 需要警告 | 外部插件规范（部分未实现） |
| `docs/guides/plugin-sdk-guide.md` | ⭐⭐⭐⭐ | ⚠️ 需要警告 | SDK 指南（部分 SDK 不存在） |
| `docs/guides/getting-started.md` | ⭐⭐⭐⭐⭐ | ✅ 最新 | 快速开始指南 |
| `docs/guides/ICON_GENERATION_GUIDE.md` | ⭐⭐⭐ | ✅ 最新 | 图标生成指南 |
| `docs/tools/plugin-cli.md` | ⭐⭐⭐⭐ | ✅ 最新 | CLI 工具文档 |

### 平台服务

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `docs/guides/PLATFORM_SERVICES_USER_GUIDE.md` | ⭐⭐⭐⭐ | ✅ 最新 | 平台服务用户指南 |
| `docs/platform-services/README.md` | ⭐⭐⭐⭐ | ✅ 最新 | 平台服务文档中心 |
| `docs/platform-services/PLATFORM_SERVICES_README.md` | ⭐⭐⭐⭐ | ⚠️ 可能重复 | 与上面重复，需评估 |
| `docs/platform-services/STRUCTURE.md` | ⭐⭐⭐ | ✅ 最新 | 服务文档结构 |
| `docs/platform-services/DOCS_NAVIGATION.md` | ⭐⭐⭐ | ✅ 最新 | 导航指南 |

### 过时/特定功能文档

| 文件名 | 重要程度 | 状态 | 建议 |
|--------|---------|------|------|
| `docs/guides/backend-integration.md` | ⭐⭐ | ❓ 未知 | 后端集成，需确认是否使用 |
| `docs/guides/desktop-pet-*.md` (3个) | ⭐⭐ | ❓ 未知 | 桌面宠物功能，需确认是否保留 |
| `docs/guides/AUDIO_QUICK_REFERENCE.md` | ⭐⭐ | ⚠️ 功能禁用 | 音频服务已禁用，**可归档** |
| `docs/guides/WINDOWS_AUDIO_SOLUTION.md` | ⭐⭐ | ⚠️ 功能禁用 | Windows 音频方案，**可归档** |
| `docs/web-platform-compatibility.md` | ⭐⭐⭐ | ✅ 最新 | Web 平台兼容性 |

---

## 📐 技术规范（重要）

### .kiro/specs/ 目录

| 功能模块 | 文件数 | 重要程度 | 状态 | 说明 |
|---------|--------|---------|------|------|
| **plugin-platform** | 3 | ⭐⭐⭐⭐ | ✅ 最新 | 插件平台核心规范 |
| **platform-services** | 4 | ⭐⭐⭐⭐ | ✅ 最新 | 平台服务规范 |
| **external-plugin-system** | 3 | ⭐⭐⭐⭐ | ⚠️ 部分未实现 | 外部插件系统规范 |
| **internationalization** | 3 | ⭐⭐⭐ | ✅ 最新 | 国际化规范 |
| **web-platform-compatibility** | 3 | ⭐⭐⭐ | ✅ 最新 | Web 兼容性规范 |

**建议**: 全部保留，规范文档是开发的重要参考

### .kiro/steering/ 目录

| 文件名 | 重要程度 | 状态 | 说明 |
|--------|---------|------|------|
| `.kiro/steering/overview.md` | ⭐⭐⭐ | ✅ 最新 | 项目概述 |
| `.kiro/steering/product.md` | ⭐⭐⭐ | ✅ 最新 | 产品规划 |
| `.kiro/steering/structure.md` | ⭐⭐⭐ | ✅ 最新 | 组织结构 |
| `.kiro/steering/tech.md` | ⭐⭐⭐ | ✅ 最新 | 技术栈 |
| `.kiro/steering/rules.md` | ⭐⭐⭐ | ✅ 最新 | 规则 |

**建议**: 全部保留

---

## 🔌 插件文档（重要）

### 已实现的插件

| 插件 | 文档数 | 重要程度 | 状态 | 说明 |
|------|--------|---------|------|------|
| **world-clock** | 3 | ⭐⭐⭐⭐ | ✅ 最新 | 世界时钟插件，**保留** |
| **screenshot** | 3 | ⭐⭐⭐⭐ | ✅ 最新 | 截图插件，**保留** |
| **calculator** | 1 | ⭐⭐⭐ | ✅ 最新 | 计算器插件配置文档 |

### 配置文档

| 文件位置 | 重要程度 | 状态 | 说明 |
|---------|---------|------|------|
| `lib/plugins/{plugin}/config/*_config_docs.md` | ⭐⭐⭐⭐ | ✅ 最新 | 配置说明文档，**必须保留** |

---

## 📊 报告文档（部分过时）

### 实施报告

| 文件名 | 重要程度 | 状态 | 建议 |
|--------|---------|------|------|
| `docs/reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md` | ⭐⭐⭐ | ⚠️ 历史文档 | 可归档 |
| `docs/reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md` | ⭐⭐⭐ | ⚠️ 历史文档 | 可归档 |
| `docs/reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md` | ⭐⭐⭐ | ⚠️ 历史文档 | 可归档 |
| `docs/reports/FIXES_WORLD_CLOCK_v1.1.md` | ⭐⭐ | ⚠️ 历史文档 | 可归档 |
| `docs/reports/PLUGIN_ID_FIX_SUMMARY.md` | ⭐⭐ | ⚠️ 历史文档 | 可归档 |
| `docs/reports/CONFIG_FEATURE_AUDIT.md` | ⭐⭐⭐⭐ | ✅ 最新 (2026-01-20) | **保留，最新审计** |
| `docs/reports/CONFIG_IMPLEMENTATION_PROGRESS.md` | ⭐⭐⭐ | ✅ 最新 | 配置实施进度 |

**建议**: 创建 `docs/reports/archive/` 目录，移动历史报告

---

## 🗑️ 可以删除的文档

### 根目录的过时文档

| 文件名 | 大小 | 原因 | 建议 |
|--------|------|------|------|
| `CHANGELOG_NOTIFICATION_FIX.md` | 8KB | 内容已在主 CHANGELOG 中 | ❌ **删除** |
| `NOTIFICATION_FIX_SUMMARY.md` | 5.6KB | 历史修复报告，已过时 | ❌ **删除** |
| `WINDOWS_PLATFORM_FIXES_REPORT.md` | 8KB | 历史修复报告，已过时 | ❌ **删除** |
| `ICON_UPDATE_GUIDE.md` | 3.5KB | 功能已集成到 `guides/ICON_GENERATION_GUIDE.md` | ❌ **删除** |
| `PLATFORM_SERVICES.md` | 3.5KB | 与 `docs/platform-services/` 内容重复 | ⚠️ **移到 docs/** |

### 构建产物中的文档

| 文件路径 | 原因 | 建议 |
|---------|------|------|
| `build/flutter_assets/assets/audio/README.md` | 构建产物 | ✅ 自动忽略（.gitignore） |
| `build/windows/.../assets/audio/README.md` | 构建产物 | ✅ 自动忽略（.gitignore） |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | iOS 默认文件 | ✅ 保留 |

### 脚本目录中的验证文档

| 文件名 | 原因 | 建议 |
|--------|------|------|
| `scripts/verify-audio-fix.md` | 音频功能已禁用 | ❌ **删除** |
| `scripts/verify-notification-fix.md` | 通知修复已完成，内容已过时 | ❌ **删除** |

### 功能禁用相关文档

| 文件名 | 原因 | 建议 |
|--------|------|------|
| `docs/platform-services/notification-windows-fix.md` | 历史修复文档 | ⚠️ **归档** |
| `docs/troubleshooting/desktop-pet-fix.md` | 历史修复文档 | ⚠️ **归档** |

---

## 🔄 需要更新的文档

### 添加警告的文档

1. **`docs/guides/external-plugin-development.md`**
   ```markdown
   > ⚠️ **开发状态警告**
   >
   > - ✅ Dart SDK 已实现
   > - ❌ Python/JavaScript SDK 待实现
   > - ❌ 代码签名系统待实现
   >
   > 建议仅使用 Dart SDK 开发外部插件，或等待多语言 SDK 完成。
   ```

2. **`docs/guides/plugin-sdk-guide.md`**
   ```yaml
   # ❌ 删除虚假的 git 依赖
   dependencies:
     plugin_sdk:
       git:
         url: https://github.com/flutter-platform/plugin-sdk

   # ✅ 改为
   dependencies:
     plugin_sdk:
       path: ../../lib/sdk
   ```

### 需要合并的重复文档

| 重复组 | 保留 | 删除 |
|--------|------|------|
| `docs/MASTER_INDEX.md` vs `docs/index.md` | `MASTER_INDEX.md` | `index.md` |
| `docs/platform-services/README.md` vs `PLATFORM_SERVICES_README.md` | `README.md` | `PLATFORM_SERVICES_README.md` |
| `ICON_UPDATE_GUIDE.md` vs `guides/ICON_GENERATION_GUIDE.md` | `guides/` 版本 | 根目录版本 |

---

## 📋 建议的文档重组

### 创建归档目录

```
docs/
├── archive/                    # 📦 历史文档归档
│   ├── reports/
│   │   ├── PLATFORM_SERVICES_PHASE0_COMPLETE.md
│   │   ├── PLATFORM_SERVICES_PHASE1_COMPLETE.md
│   │   ├── FIXES_WORLD_CLOCK_v1.1.md
│   │   └── PLUGIN_ID_FIX_SUMMARY.md
│   └── fixes/
│       ├── notification-windows-fix.md
│       └── desktop-pet-fix.md
```

### 移动根目录文档

```
docs/platform-services/
└── quick-start.md              # 从根目录移动 PLATFORM_SERVICES.md
```

---

## ✅ 立即行动清单

### 立即删除（5个文件）

```bash
# 根目录过时文档
rm CHANGELOG_NOTIFICATION_FIX.md
rm NOTIFICATION_FIX_SUMMARY.md
rm WINDOWS_PLATFORM_FIXES_REPORT.md
rm ICON_UPDATE_GUIDE.md

# 脚本目录过时文档
rm scripts/verify-audio-fix.md
rm scripts/verify-notification-fix.md
```

### 移动到归档（8个文件）

```bash
mkdir -p docs/archive/reports
mkdir -p docs/archive/fixes

# 移动历史报告
mv docs/reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md docs/archive/reports/
mv docs/reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md docs/archive/reports/
mv docs/reports/FIXES_WORLD_CLOCK_v1.1.md docs/archive/reports/
mv docs/reports/PLUGIN_ID_FIX_SUMMARY.md docs/archive/reports/

# 移动历史修复文档
mv docs/platform-services/notification-windows-fix.md docs/archive/fixes/
mv docs/troubleshooting/desktop-pet-fix.md docs/archive/fixes/
```

### 移动到正确位置（1个文件）

```bash
mv PLATFORM_SERVICES.md docs/platform-services/quick-start.md
```

### 合并重复文档（2个文件）

```bash
# 删除重复的索引文件
rm docs/index.md  # 保留 MASTER_INDEX.md

# 删除重复的快速开始文档
rm docs/platform-services/PLATFORM_SERVICES_README.md  # 保留 README.md
```

### 添加警告标记（2个文件）

1. 更新 `docs/guides/external-plugin-development.md` - 添加开发状态警告
2. 更新 `docs/guides/plugin-sdk-guide.md` - 修正虚假依赖

---

## 📊 清理后的文档结构

### 预期效果

| 类别 | 清理前 | 清理后 | 减少 |
|------|--------|--------|------|
| **根目录文档** | 7 | 2 | -5 |
| **报告文档** | 7 | 2 | -5 |
| **修复文档** | 2 | 0 | -2 |
| **脚本文档** | 2 | 0 | -2 |
| **重复文档** | 2 | 0 | -2 |
| **总计** | 110+ | 95+ | -15+ |

### 保留的核心文档（25个）

- ✅ README.md, CHANGELOG.md (根目录)
- ✅ .claude/ 核心文档（7个）
- ✅ docs/ 核心索引（3个）
- ✅ docs/guides/ 开发指南（10个）
- ✅ docs/platform-services/ 平台服务（3个）
- ✅ .kiro/specs/ 技术规范（16个）

---

## 🎯 维护建议

### 文档生命周期

1. **活跃文档** - 经常更新，保留在主目录
2. **稳定文档** - 很少变化，保留但归档旧版本
3. **历史文档** - 仅作参考，移到 `archive/`
4. **过时文档** - 无参考价值，删除

### 文档审查周期

- **每月**: 检查文档链接是否有效
- **每季度**: 评估报告文档是否需要归档
- **每半年**: 全面审计，删除过时内容

### 新文档创建原则

1. **根目录**: 仅保留 README.md, CHANGELOG.md
2. **功能文档**: 必须放在 `docs/` 对应子目录
3. **临时文档**: 必须标记过期时间
4. **重复文档**: 禁止创建

---

**审计完成时间**: 2026-01-20
**下次审计时间**: 2026-04-20（3个月后）
**负责人**: Claude Code
