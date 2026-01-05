# 插件模板

本目录包含各种插件开发模板，帮助开发者快速创建新插件。

## 可用模板

### 内部插件模板

#### 工具插件模板
- **基础工具插件**: 简单的工具插件模板
- **数据处理插件**: 处理数据的工具插件
- **UI组件插件**: 包含复杂UI的插件

#### 游戏插件模板
- **基础游戏插件**: 简单的游戏插件模板
- **拼图游戏**: 拼图类游戏模板
- **益智游戏**: 益智类游戏模板

### 外部插件模板

#### 可执行插件模板
- **Dart可执行插件**: 使用Dart开发的可执行插件
- **Python可执行插件**: 使用Python开发的可执行插件
- **Node.js可执行插件**: 使用Node.js开发的可执行插件

#### Web插件模板
- **基础Web插件**: HTML/CSS/JS Web插件
- **React Web插件**: 使用React的Web插件
- **Vue.js Web插件**: 使用Vue.js的Web插件

## 使用方法

### 通过CLI工具使用

```bash
# 列出所有可用模板
dart tools/plugin_cli.dart list-templates

# 使用特定模板创建插件
dart tools/plugin_cli.dart create-internal --name "My Plugin" --template basic-tool

# 创建外部插件
dart tools/plugin_cli.dart create-external --name "My External Plugin" --template dart-executable
```

### 手动使用模板

1. 复制相应的模板目录
2. 重命名文件和类名
3. 修改插件ID和元数据
4. 实现具体功能

## 模板结构

每个模板包含以下文件：

```
template-name/
├── plugin_template.dart          # 主插件类模板
├── plugin_factory_template.dart  # 插件工厂模板
├── plugin_descriptor.json        # 插件描述文件模板
├── test_template.dart            # 测试文件模板
├── README_template.md            # 说明文档模板
└── widgets/                      # UI组件模板（如果适用）
    └── widget_template.dart
```

## 自定义模板

你可以创建自己的模板：

1. 在相应目录下创建新的模板文件夹
2. 添加必要的模板文件
3. 使用占位符标记需要替换的内容：
   - `{{PLUGIN_NAME}}`: 插件名称
   - `{{PLUGIN_ID}}`: 插件ID
   - `{{AUTHOR_NAME}}`: 作者名称
   - `{{DESCRIPTION}}`: 插件描述

### 占位符示例

```dart
class {{PLUGIN_NAME}}Plugin implements IPlugin {
  @override
  String get id => '{{PLUGIN_ID}}';
  
  @override
  String get name => '{{PLUGIN_NAME}}';
  
  // ... 其他代码
}
```

## 贡献模板

欢迎贡献新的模板：

1. Fork 项目
2. 创建新的模板
3. 添加文档和示例
4. 提交 Pull Request

## 模板维护

- 定期更新模板以匹配最新的API
- 确保所有模板都能正常工作
- 添加新的最佳实践和功能

---

使用这些模板可以大大加快插件开发速度，确保代码质量和一致性。