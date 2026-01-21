# 计算器插件 (Dart)

一个演示使用 Dart/Flutter 的插件 SDK 基本用法的简单计算器插件。

## 功能

- 基本算术运算（加、减、乘、除）
- 内存函数（存储、召回、清除）
- 历史记录跟踪
- 主题适配
- 键盘快捷键

## 快速开始

### 前提条件

- Flutter SDK 3.0+
- 插件 SDK
- Flutter 插件平台主机

### 安装

1. 克隆或下载此示例
2. 安装依赖：
   ```bash
   flutter pub get
   ```
3. 构建插件：
   ```bash
   dart tools/plugin_cli.dart build
   ```
4. 打包以分发：
   ```bash
   dart tools/plugin_cli.dart package --output calculator.pkg
   ```

### 测试

本地测试插件：

```bash
dart tools/plugin_cli.dart test --plugin calculator.pkg
```

## 代码结构

```
dart_calculator/
├── lib/
│   ├── main.dart              # 主入口点
│   ├── calculator_engine.dart # 计算逻辑
│   ├── calculator_ui.dart     # 用户界面
│   └── calculator_history.dart # 历史记录管理
├── plugin_manifest.json      # 插件配置
├── pubspec.yaml              # Dart 依赖
└── README.md                 # 本文件
```

## 演示的关键 SDK 功能

1. **插件初始化**: 设置 SDK 连接
2. **事件处理**: 响应主机事件（主题更改等）
3. **API 调用**: 调用主机 API 进行首选项和通知
4. **配置**: 管理插件设置
5. **生命周期管理**: 正确的启动和关闭
6. **错误处理**: 优雅的错误处理和报告

## 使用方法

安装到 Flutter 插件平台后：

1. 从插件菜单打开计算器插件
2. 使用屏幕按钮或键盘执行计算
3. 在历史记录面板中查看计算历史
4. 通过插件设置菜单访问设置

## 配置选项

插件支持以下配置选项：

- `precision`: 小数位数（默认：2）
- `show_history`: 显示/隐藏历史记录面板（默认：true）
- `keyboard_shortcuts`: 启用键盘快捷键（默认：true）
- `theme_mode`: 主题首选项（auto, light, dark）

## API 集成

插件演示了与主机 API 的集成：

- `getUserPreference()`: 获取用户主题和区域设置首选项
- `showNotification()`: 将计算结果显示为通知
- `saveUserData()`: 持久化计算历史
- `loadUserData()`: 恢复计算历史

## 开发说明

此示例展示了基于 Dart 的外部插件的最佳实践：

- 正确的 SDK 初始化和清理
- 适应主机主题的响应式 UI
- 高效的状态管理
- 错误处理和日志记录
- 配置管理
- 测试和调试支持
