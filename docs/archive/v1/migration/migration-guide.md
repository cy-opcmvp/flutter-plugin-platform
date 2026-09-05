# 文档迁移指南

## 概述

本指南说明了如何从旧的文档结构迁移到新的组织化文档结构。

## 迁移内容

### 原始文档结构
```
docs/
├── backend_integration_guide.md
├── desktop_pet_guide.md
├── external_plugin_development_standard.md
├── getting_started_tutorial.md
├── internal_plugin_development_guide.md
├── plugin_development_guide.md
└── plugin_sdk_guide.md
```

### 新文档结构
```
docs_new/
├── README.md                           # 文档导航
├── guides/                             # 指南文档
│   ├── getting-started.md
│   ├── internal-plugin-development.md
│   ├── external-plugin-development.md
│   ├── desktop-pet-guide.md
│   ├── backend-integration.md
│   └── plugin-sdk-guide.md
├── api/                                # API参考
├── standards/                          # 开发标准
├── examples/                           # 示例代码
├── templates/                          # 代码模板
│   ├── internal-plugin/
│   ├── external-plugin/
│   ├── config/
│   └── test/
└── tools/                              # 工具文档
    └── plugin-cli.md
```

## 迁移步骤

### 1. 备份原始文档
```bash
# 创建备份
cp -r docs docs_backup
```

### 2. 使用新文档结构
```bash
# 重命名原始docs目录
mv docs docs_old

# 使用新的文档结构
mv docs_new docs
```

### 3. 更新引用链接

需要更新以下文件中的文档链接：

#### README.md
```markdown
# 旧链接
- [插件开发指南](docs/plugin_development_guide.md)
- [内部插件开发](docs/internal_plugin_development_guide.md)

# 新链接
- [内部插件开发](docs/guides/internal-plugin-development.md)
```

#### 代码注释中的链接
```dart
// 旧注释
/// 详细信息请参考: docs/internal_plugin_development_guide.md

// 新注释
/// 详细信息请参考: docs/guides/internal-plugin-development.md
```

### 4. 安装CLI工具

```bash
# Windows
setup-cli.bat

# Linux/macOS
chmod +x setup-cli.sh
./setup-cli.sh
```

### 5. 验证迁移

```bash
# 检查文档链接
find docs -name "*.md" -exec grep -l "docs/" {} \;

# 测试CLI工具
dart tools/plugin_cli.dart --help

# 创建测试插件
dart tools/plugin_cli.dart create-internal --name "Test Plugin" --type tool
```

## 文档映射表

| 原始文件 | 新位置 | 说明 |
|---------|--------|------|
| `getting_started_tutorial.md` | `guides/getting-started.md` | 快速入门指南 |
| `internal_plugin_development_guide.md` | `guides/internal-plugin-development.md` | 内部插件开发 |
| `external_plugin_development_standard.md` | `guides/external-plugin-development.md` | 外部插件开发 |
| `plugin_development_guide.md` | 已删除（与internal重复） | 通用插件开发 |
| `plugin_sdk_guide.md` | `guides/plugin-sdk-guide.md` | SDK使用指南 |
| `desktop_pet_guide.md` | `guides/desktop-pet-guide.md` | 桌面宠物功能 |
| `backend_integration_guide.md` | `guides/backend-integration.md` | 后端集成 |

## 新增功能

### 1. 代码模板系统
- 内部插件模板
- 外部插件模板
- 配置文件模板
- 测试模板

### 2. CLI工具
- 一键创建插件
- 构建和测试功能
- 打包和发布功能

### 3. 示例代码
- 完整的插件示例
- 最佳实践示例
- 集成示例

## 使用新功能

### 创建内部插件
```bash
# 使用CLI创建
dart tools/plugin_cli.dart create-internal --name "My Calculator" --type tool --author "Your Name"

# 手动使用模板
cp -r docs/templates/internal-plugin/plugin-template.dart lib/plugins/my_plugin/
```

### 创建外部插件
```bash
# 创建Dart插件
dart tools/plugin_cli.dart create-external --name "Data Processor" --type executable --language dart

# 创建Python插件
dart tools/plugin_cli.dart create-external --name "ML Plugin" --type executable --language python
```

### 查看示例
```bash
# 浏览示例代码
ls docs/examples/

# 运行示例
cd docs/examples/internal-plugins/calculator
flutter run
```

## 注意事项

### 1. 链接更新
- 更新所有文档内的相对链接
- 更新代码注释中的文档引用
- 更新README和其他说明文件

### 2. 工具依赖
- 确保安装了Flutter SDK
- 确保Dart在PATH中
- 安装必要的依赖包

### 3. 权限设置
- Linux/macOS需要给脚本执行权限
- Windows可能需要管理员权限

### 4. 配置文件
- CLI工具会创建配置目录
- 可以自定义默认设置
- 支持项目级配置

## 回滚方案

如果需要回滚到原始结构：

```bash
# 恢复原始文档
mv docs docs_new_backup
mv docs_old docs

# 恢复原始链接
# 手动恢复README.md和其他文件中的链接
```

## 获取帮助

如果在迁移过程中遇到问题：

1. 查看 [CLI工具文档](docs/tools/plugin-cli.md)
2. 检查 [示例代码](docs/examples/)
3. 提交 [Issue](https://github.com/flutter-platform/issues)
4. 联系技术支持

## 迁移检查清单

- [ ] 备份原始文档
- [ ] 重命名文档目录
- [ ] 更新README.md中的链接
- [ ] 更新代码注释中的文档引用
- [ ] 安装CLI工具
- [ ] 测试CLI工具功能
- [ ] 验证文档链接
- [ ] 测试模板功能
- [ ] 运行示例代码
- [ ] 更新团队文档

完成以上步骤后，您就可以享受新的文档结构和CLI工具带来的便利了！