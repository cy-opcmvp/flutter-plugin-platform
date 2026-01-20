# Kiro 编码规则

> 🤖 本项目遵循的编码规范和文件组织规则

## 📚 项目理解

**开始任何任务前，请先阅读**:
- [产品概述](product.md) - 项目定位和核心特性
- [项目结构](structure.md) - 代码组织和目录结构
- [技术栈](tech.md) - 技术选型和开发规范
- [.kiro/specs/](../specs/) - 技术规范目录

## 📋 核心规则

### 1. 文件组织规范

**核心原则**:
- ✅ 根目录保持简洁，只保留最核心的文件
- ✅ 所有脚本放入 `scripts/` 目录
- ✅ 所有详细文档放入 `docs/` 目录
- ✅ 所有技术规范放入 `.kiro/specs/` 目录

**根目录只允许**:
- `README.md` - 项目主文档
- `CHANGELOG.md` - 版本变更日志
- `pubspec.yaml` - Flutter 配置
- 用户直接运行的设置脚本（如 `setup-cli.bat`）

**禁止在根目录**:
- ❌ 临时脚本（`fix-xxx.ps1`）
- ❌ 临时文档（`*_FIX.md`）
- ❌ 实施报告（`FIXES_SUMMARY.md`）
- ❌ 插件详细文档

### 2. 代码规范

#### Dart/Flutter 代码

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南
- 使用 `flutter_lints` 包进行代码检查
- 所有公共 API 必须有文档注释
- 使用类型注解，避免 `var` 和 `dynamic`
- 优先使用 `const` 构造函数
- 使用 `async/await` 而非 `.then()`

#### 文件和目录命名

- **文件名**: `snake_case.dart` (如 `audio_service.dart`)
- **类名**: `PascalCase` (如 `AudioServiceImpl`)
- **变量/方法**: `camelCase` (如 `getNotification()`)
- **常量**: `lowerCamelCase` 或 `UPPER_SNAKE_CASE`
- **私有成员**: 前缀下划线 `_privateMethod`

### 3. 插件开发规范

#### 插件 ID 命名

**格式**: `{domain}.{category}.{plugin-name}`

**规则**:
- 使用**小写字母**和**点号**
- **禁止使用下划线**和连字符
- 反向域名格式

**示例**:
```
✅ com.example.calculator
✅ org.company.tools.texteditor
❌ com.example.text_editor (有下划线)
❌ com.example.world-clock (有连字符)
```

#### 插件文档结构

每个插件的文档必须放在：
```
docs/plugins/{plugin-name}/
├── README.md              # 插件概述
├── implementation.md      # 实现文档
└── UPDATE_v{version}.md  # 版本更新说明
```

### 4. 服务开发规范

#### 服务接口定义

- 所有服务必须先定义接口 (`I{ServiceName}`)
- 接口放在 `lib/core/interfaces/services/`
- 实现放在 `lib/core/services/{service-name}/`

#### 服务生命周期

```dart
abstract class I{ServiceName} {
  Future<bool> initialize();
  bool get isInitialized;
  Future<void> dispose();
}
```

### 5. 国际化规范（最高优先级）

**⚠️ 重要：国际化优先级高于所有其他开发任务**

#### 基本规则
1. **所有面向用户的文本必须国际化**
2. **禁止硬编码文本**

```dart
// ❌ 错误：硬编码文本
Text('Screenshot Plugin Config')

// ✅ 正确：使用国际化
Text(l10n.screenshot_config_title)
```

#### 开发流程
1. 在 `lib/l10n/app_zh.arb` 和 `lib/l10n/app_en.arb` 添加翻译键
2. 运行 `flutter gen-l10n` 生成本地化代码
3. 使用 `AppLocalizations.of(context)!` 获取 `l10n` 实例
4. 使用 `l10n.xxx` 访问翻译文本

#### 翻译键命名规范
- 使用下划线分隔的小写字母：`settings_save_path`
- 按功能分组：`screenshot_config_title`
- 通用命名：`common_save`, `common_cancel`
- 错误消息：`error_network`, `error_load_failed`

### 6. Git 提交规范

#### 提交信息格式

```
<type>(<scope>): <subject>

<body>

Co-Authored-By: Kiro <noreply@kiro.dev>
```

**类型**:
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档变更
- `style`: 代码格式
- `refactor`: 重构
- `test`: 添加测试
- `chore`: 构建/工具变更

### 7. 版本控制规范

#### 每次对话结束时必须
- ✅ 记录所有修改的文件
- ✅ 记录所有创建的文件
- ✅ 记录所有删除的文件
- ✅ 更新 CHANGELOG.md

#### Tag 命名格式
`v{major}.{minor}.{patch}`

- **Major**: 架构重大变更
- **Minor**: 新增功能
- **Patch**: Bug 修复

## 🚀 开发指南

### 常用命令

```bash
# 运行应用
flutter run -d windows

# 运行测试
flutter test

# 构建发布版本
flutter build windows --release

# 国际化生成
flutter gen-l10n

# 创建内部插件
dart tools/plugin_cli.dart create-internal --name "Plugin Name" --type tool
```

### 关键文件位置

| 文件 | 用途 |
|------|------|
| `lib/main.dart` | 应用入口 |
| `lib/core/` | 核心系统代码 |
| `lib/plugins/` | 插件目录 |
| `docs/` | 完整文档 |
| `.kiro/specs/` | 技术规范 |

## 📚 相关文档

- [文档主索引](../../docs/MASTER_INDEX.md)
- [插件开发指南](../../docs/guides/internal-plugin-development.md)
- [平台服务指南](../../docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)

---

**版本**: v1.0.0
**最后更新**: 2026-01-16
