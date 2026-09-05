# CLI工具使用说明

## 🚀 快速开始

### 1. 设置CLI工具

**Windows:**
```cmd
.\setup-cli.bat
```

**Linux/macOS:**
```bash
chmod +x setup-cli.sh
./setup-cli.sh
```

### 2. 创建你的第一个插件

```bash
# 创建工具插件
dart tools/plugin_cli.dart create-internal --name "My Calculator" --type tool --author "Your Name"

# 创建游戏插件
dart tools/plugin_cli.dart create-internal --name "Puzzle Game" --type game --author "Game Developer"
```

### 3. 查看生成的文件

```
lib/plugins/my_calculator/
├── my_calculator_plugin.dart          # 主插件类
├── my_calculator_plugin_factory.dart  # 插件工厂
├── widgets/                           # UI组件目录
├── models/                            # 数据模型目录
└── README.md                          # 插件说明
```

### 4. 注册插件

在 `lib/plugins/plugin_registry.dart` 中添加生成的注册代码：

```dart
import 'my_calculator/my_calculator_plugin_factory.dart';

static final Map<String, PluginFactory> _factories = {
  // 添加你的插件
  'com.example.my_calculator': PluginFactory(
    createPlugin: MyCalculatorPluginFactory.createPlugin,
    getDescriptor: MyCalculatorPluginFactory.getDescriptor,
  ),
  // ... 其他插件
};
```

## 📋 可用命令

### create-internal - 创建内部插件

```bash
dart tools/plugin_cli.dart create-internal [选项]
```

**选项:**
- `--name, -n`: 插件名称 (必需)
- `--type, -t`: 插件类型 (tool/game, 默认: tool)
- `--author, -a`: 作者名称
- `--email, -e`: 作者邮箱
- `--description, -d`: 插件描述
- `--output, -o`: 输出目录 (默认: lib/plugins)

**示例:**
```bash
# 基础用法
dart tools/plugin_cli.dart create-internal --name "My Plugin" --type tool

# 完整信息
dart tools/plugin_cli.dart create-internal \
  --name "Advanced Calculator" \
  --type tool \
  --author "John Doe" \
  --email "john@example.com" \
  --description "A powerful calculator with advanced functions"
```

### list-templates - 列出可用模板

```bash
dart tools/plugin_cli.dart list-templates
```

### --help - 显示帮助

```bash
dart tools/plugin_cli.dart --help
```

### --version - 显示版本

```bash
dart tools/plugin_cli.dart --version
```

## 🎯 生成的插件结构

### 主插件类 (plugin.dart)

```dart
class MyPluginPlugin implements IPlugin {
  @override
  String get id => 'com.example.my_plugin';
  
  @override
  String get name => 'My Plugin';
  
  @override
  Future<void> initialize(PluginContext context) async {
    // 插件初始化逻辑
  }
  
  @override
  Widget buildUI(BuildContext context) {
    // 插件UI构建
  }
  
  // ... 其他必需方法
}
```

### 插件工厂 (factory.dart)

```dart
class MyPluginPluginFactory {
  static IPlugin createPlugin() {
    return MyPluginPlugin();
  }
  
  static PluginDescriptor getDescriptor() {
    return const PluginDescriptor(
      id: 'com.example.my_plugin',
      name: 'My Plugin',
      version: '1.0.0',
      type: PluginType.tool,
      // ... 其他配置
    );
  }
}
```

### 测试文件 (test.dart)

```dart
void main() {
  group('MyPlugin Tests', () {
    test('should initialize correctly', () async {
      final plugin = MyPluginPlugin();
      // ... 测试逻辑
    });
  });
}
```

## 🔧 自定义配置

### 插件类型

- `tool`: 工具插件 (计算器、编辑器等)
- `game`: 游戏插件 (拼图、小游戏等)

### 插件权限

生成的插件默认包含以下权限：
- `Permission.storage`: 数据存储
- `Permission.notifications`: 通知显示

可以根据需要在工厂类中添加更多权限：
```dart
requiredPermissions: [
  Permission.storage,
  Permission.notifications,
  Permission.networkAccess,  // 网络访问
  Permission.fileSystem,     // 文件系统
],
```

## 🧪 测试插件

### 运行单元测试

```bash
# 测试特定插件
flutter test test/plugins/my_plugin_test.dart

# 测试所有插件
flutter test test/plugins/
```

### 运行应用

```bash
flutter run
```

## 📝 最佳实践

### 1. 命名规范

- 使用描述性名称: "Weather Widget" 而不是 "Plugin1"
- 避免特殊字符和空格过多
- 使用英文名称以确保兼容性

### 2. 插件开发

- 在 `initialize()` 中进行必要的初始化
- 在 `dispose()` 中清理资源
- 使用 `buildUI()` 构建用户界面
- 实现适当的错误处理

### 3. 测试

- 为每个插件编写单元测试
- 测试插件的生命周期方法
- 测试UI组件的交互

## 🐛 故障排除

### 常见问题

**1. 命令未找到**
```bash
# 确保在项目根目录
pwd

# 检查Dart是否安装
dart --version

# 检查依赖是否安装
cd tools && dart pub get
```

**2. 插件创建失败**
```bash
# 检查目录权限
ls -la lib/plugins/

# 确保目录存在
mkdir -p lib/plugins
```

**3. 编码问题**
- Windows用户如果看到乱码，请使用UTF-8编码的终端
- 或者直接使用 `dart tools/plugin_cli.dart` 命令

### 获取帮助

- 查看 [完整文档](docs/README.md)
- 查看 [示例代码](docs/examples/)
- 提交 [Issue](https://github.com/flutter-platform/issues)

## 🎉 成功案例

使用CLI工具创建的插件示例：

```bash
# 已创建的插件
ls lib/plugins/
# my_plugin/
# puzzle_game/
# weather_widget/
```

每个插件都包含完整的代码结构、测试文件和文档，可以直接使用或作为开发基础。

---

**恭喜！** 你现在已经掌握了使用CLI工具快速创建插件的方法。开始构建你的第一个插件吧！ 🚀