# AI 编码规则 - 文件组织规范

> 📋 **本文档定义了项目的文件组织规则，所有 AI 助手（Claude Code 等）必须遵守**

## 🎯 核心原则

### 1. 根目录保持简洁

**根目录只能包含以下类型的文件**:

#### ✅ 必须保留的文件
- `README.md` - 项目主文档和快速开始指南
- `CHANGELOG.md` - 版本变更历史（遵循 Keep a Changelog 规范）
- `LICENSE` - 开源许可证（如果适用）
- `pubspec.yaml` - Flutter 项目配置
- `.gitignore` - Git 忽略规则

#### ✅ 功能入口文件（仅限最重要的）
- `PLATFORM_SERVICES.md` - 平台服务快速入口（如果项目有此功能）
- 其他类似的**核心功能快速入口**（必须是对用户最重要的功能）

#### ✅ 用户直接运行的脚本
- `setup-cli.bat` / `setup-cli.sh` - CLI 工具安装脚本
- 其他用户需要**直接从根目录运行**的设置脚本

#### ❌ 禁止在根目录放置的文件
- 临时修复脚本（如 `fix-xxx.ps1`）
- 临时文档（如 `WINDOWS_BUILD_FIX.md`）
- 实施细节文档
- 技术规范文档
- 插件或模块的 README
- 任何非必需的文档或脚本

### 2. 文件分类规则

#### 📁 脚本文件 (`scripts/`)

**所有非用户直接运行的脚本都必须放在 `scripts/` 目录**:

```
scripts/
├── setup/              # 设置和安装脚本
│   ├── fix-nuget.ps1
│   ├── install-cppwinrt.ps1
│   └── ...
├── build/              # 构建脚本
├── deploy/             # 部署脚本
└── development/        # 开发辅助脚本
```

**判断标准**:
- 用户是否需要直接从根目录运行此脚本？
- 是否是项目首次设置所必需的？
- 如果答案都是"否"，则放入 `scripts/` 目录

#### 📁 文档文件 (`docs/`)

**所有非核心文档都必须放在 `docs/` 目录**:

```
docs/
├── MASTER_INDEX.md                 # 📍 文档主索引
├── README.md                       # 文档中心
├── project-structure.md            # 项目结构说明
│
├── guides/                         # 📚 用户指南
│   ├── getting-started.md
│   ├── plugin-development.md
│   └── ...
│
├── platform-services/              # 🔧 平台服务
│   ├── README.md
│   └── ...
│
├── plugins/                        # 🔌 插件文档
│   ├── world-clock/
│   │   ├── README.md
│   │   ├── IMPLEMENTATION.md
│   │   └── UPDATE_v1.1.md
│   └── {plugin-name}/
│
├── releases/                       # 📦 发布文档
│   └── RELEASE_NOTES_v{version}.md
│
├── reports/                        # 📊 实施报告
│   ├── PLATFORM_SERVICES_PHASE0_COMPLETE.md
│   └── ...
│
├── troubleshooting/                # 🐛 故障排除
│   ├── WINDOWS_BUILD_FIX.md
│   └── ...
│
├── migration/                      # 🔄 迁移指南
├── examples/                       # 💡 示例代码
├── tools/                          # 🛠️ 工具文档
└── reference/                      # 📋 参考文档
```

**文档分类规则**:

1. **用户指南** (`guides/`)
   - 如何使用项目
   - 如何开发插件
   - 如何集成功能

2. **插件文档** (`plugins/{plugin-name}/`)
   - 插件概述
   - 实现文档
   - 更新说明
   - 不应在根目录或插件代码目录放置 README

3. **发布文档** (`releases/`)
   - 版本发布说明
   - 不应在根目录放置 `RELEASE_NOTES_v{x.x.x}.md`

4. **实施报告** (`reports/`)
   - 功能完成报告
   - 修复总结报告
   - 不应在根目录放置 `FIXES_SUMMARY.md` 等文件

5. **故障排除** (`troubleshooting/`)
   - 问题修复文档
   - 临时解决方案
   - 不应在根目录放置 `*_FIX.md` 等文件

#### 📁 技术规范 (`.kiro/specs/`)

**所有技术规范文档必须放在 `.kiro/specs/` 目录**:

```
.kiro/specs/
├── {feature-name}/
│   ├── requirements.md      # 需求文档
│   ├── design.md           # 设计文档
│   ├── tasks.md            # 任务清单
│   ├── implementation-plan.md  # 实施计划
│   └── testing-validation.md   # 测试文档
```

#### 📁 代码组织 (`lib/`)

**代码文件按功能模块组织**:

```
lib/
├── core/                   # 核心系统
│   ├── interfaces/        # 接口定义
│   ├── models/            # 数据模型
│   └── services/          # 核心服务
├── plugins/               # 插件目录
│   └── {plugin-name}/
│       ├── {plugin_name}.dart
│       ├── {plugin_name}_factory.dart
│       ├── models/        # 插件数据模型
│       ├── widgets/       # 插件 UI 组件
│       └── README.md      # 指向 docs/plugins/{plugin-name}/
├── ui/                    # 用户界面
└── main.dart             # 应用入口
```

## 🔍 决策树

在创建新文件时，按照以下流程判断：

```
是否是 README.md、CHANGELOG.md、pubspec.yaml？
├── 是 → 放在根目录 ✅
└── 否 → 继续

是否是用户必须直接运行的设置脚本？
├── 是 → 放在根目录 ✅
└── 否 → 继续

是否是核心功能的快速入口（如 PLATFORM_SERVICES.md）？
├── 是 → 评估必要性，如果不是最重要的功能 → 放入 docs/
└── 否 → 继续

是否是脚本文件？
├── 是 → 放入 scripts/ ✅
└── 否 → 继续

是否是技术规范（需求、设计、任务）？
├── 是 → 放入 .kiro/specs/{feature}/ ✅
└── 否 → 继续

是否是文档？
├── 是 → 按类型分类：
│   - 用户指南 → docs/guides/
│   - 插件文档 → docs/plugins/{plugin}/
│   - 发布说明 → docs/releases/
│   - 实施报告 → docs/reports/
│   - 故障排除 → docs/troubleshooting/
│   - 其他文档 → docs/
└── 否 → 按代码组织规则放置
```

## ⚠️ 常见错误

### ❌ 错误示例

1. **在根目录创建临时修复脚本**
   ```
   ❌ fix-nuget.ps1
   ❌ install-dependencies.sh
   ```
   **正确做法**: `scripts/setup/fix-nuget.ps1`

2. **在根目录创建实施报告**
   ```
   ❌ FIXES_SUMMARY.md
   ❌ IMPLEMENTATION_COMPLETE.md
   ```
   **正确做法**: `docs/reports/FIXES_SUMMARY.md`

3. **在根目录创建插件文档**
   ```
   ❌ WORLD_CLOCK_IMPLEMENTATION.md
   ❌ PLUGIN_UPDATE_v1.1.md
   ```
   **正确做法**: `docs/plugins/world-clock/IMPLEMENTATION.md`

4. **在插件代码目录创建详细 README**
   ```
   lib/plugins/world_clock/README.md (5000+ 字)
   ```
   **正确做法**:
   - `lib/plugins/world_clock/README.md` (简短，指向详细文档)
   - `docs/plugins/world-clock/README.md` (详细文档)

## 📝 文件命名规范

### 文档文件

- 使用**大写字母和下划线**：`PLATFORM_SERVICES_README.md`
- 或使用**kebab-case**：`platform-services-readme.md`
- 避免使用空格和特殊字符

### 脚本文件

- PowerShell: `.ps1` 后缀，kebab-case: `fix-nuget.ps1`
- Bash: `.sh` 后缀，kebab-case: `install-dependencies.sh`
- Batch: `.bat` 后缀，kebab-case: `setup-cli.bat`

### 代码文件

- Dart: `snake_case.dart`: `audio_service.dart`
- 类名: `PascalCase`: `AudioServiceImpl`

## ✅ 检查清单

创建新文件前，检查：

- [ ] 是否真的需要创建这个文件？
- [ ] 是否应该放在根目录？（通常是"否"）
- [ ] 是否有合适的子目录？
- [ ] 文件命名是否符合规范？
- [ ] 是否需要更新文档索引？

## 🔄 违规纠正

如果发现违规文件（如根目录有临时文档）：

1. **立即移动到正确位置**
2. **更新所有交叉引用**
3. **更新相关索引文件**
4. **提交 PR 说明移动原因**

## 📚 参考文档

- [文档主索引](../docs/MASTER_INDEX.md)
- [文档重组记录](../docs/DOCS_REORGANIZATION.md)
- [项目结构说明](../docs/project-structure.md)

---

**版本**: v1.0.0
**最后更新**: 2026-01-15
**适用范围**: 所有 AI 编码助手和开发者
