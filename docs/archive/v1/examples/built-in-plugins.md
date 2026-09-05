# 示例插件

本目录包含演示如何为插件平台实现工具和游戏的示例插件。

## 可用的示例插件

### 1. 计算器插件 (`com.example.calculator`)
- **类型**: 工具
- **描述**: 一个用于基本算术运算的简单计算器
- **功能**:
  - 基本算术运算 (+, -, ×, ÷)
  - 百分比计算
  - 符号切换
  - 清除功能
  - 跨会话的状态持久化
- **权限**: 通知
- **位置**: `lib/plugins/calculator/`

### 2. 滑动拼图游戏 (`com.example.puzzle_game`)
- **类型**: 游戏
- **描述**: 一个经典的有数字方块滑动拼图游戏
- **功能**:
  - 3x3 滑动拼图
  - 移动计数器
  - 计时器
  - 游戏状态持久化
  - 洗牌和新游戏功能
  - 胜利检测和庆祝动画
- **权限**: 通知、存储
- **位置**: `lib/plugins/puzzle_game/`

## 插件结构

每个插件遵循以下结构：
```
plugin_name/
├── plugin_name_plugin.dart          # 主插件实现
├── plugin_name_plugin_factory.dart  # 创建插件实例的工厂
└── plugin_descriptor.json           # 插件元数据和配置
```

## 插件实现指南

### 1. 插件接口实现
所有插件必须实现 `IPlugin` 接口：
- `id`: 唯一标识符（反向域命名）
- `name`: 显示名称
- `version`: 语义版本
- `type`: `PluginType.tool` 或 `PluginType.game`
- `initialize()`: 使用上下文设置插件
- `dispose()`: 清理资源
- `buildUI()`: 创建 Flutter widget
- `onStateChanged()`: 处理状态转换
- `getState()`: 返回当前状态数据

### 2. 状态管理
- 使用 `PluginContext.dataStorage` 持久化状态
- 在 `onStateChanged()` 中处理状态变化
- 在销毁前保存关键状态
- 在初始化期间恢复状态

### 3. 平台服务使用
- 使用 `PluginContext.platformServices` 进行：
  - 显示通知
  - 请求权限
  - 打开外部 URL
  - 监听平台事件

### 4. 资源管理
- 在 `dispose()` 中正确释放资源
- 处理插件隔离和沙箱
- 尊重权限边界
- 高效管理内存和 CPU 使用

### 5. 错误处理
- 优雅地处理错误而不崩溃
- 提供用户友好的错误消息
- 维护插件隔离（错误不应影响其他插件）
- 出错时重置到安全状态

## 插件描述符格式

```json
{
  "id": "com.example.plugin_name",
  "name": "Plugin Display Name",
  "version": "1.0.0",
  "type": "tool|game",
  "requiredPermissions": ["notifications", "storage"],
  "metadata": {
    "description": "Plugin description",
    "author": "Author Name",
    "category": "Category",
    "tags": ["tag1", "tag2"],
    "icon": "icon_name",
    "minPlatformVersion": "1.0.0",
    "supportedPlatforms": ["mobile", "desktop", "steam"]
  },
  "entryPoint": "lib/plugins/plugin_name/plugin_name_plugin.dart"
}
```

## 使用示例插件

### 在插件管理器中
```dart
import 'package:flutter_app/plugins/plugin_registry.dart';

// 获取所有示例插件描述符
final descriptors = ExamplePluginRegistry.getAllDescriptors();

// 创建特定插件实例
final calculator = ExamplePluginRegistry.createPlugin('com.example.calculator');

// 获取插件描述符
final descriptor = ExamplePluginRegistry.getDescriptor('com.example.calculator');
```

### 测试插件
这些示例插件可用于：
1. 测试插件加载和卸载
2. 验证插件隔离和沙箱
3. 测试状态持久化和恢复
4. 验证权限系统
5. 测试 UI 集成和导航
6. 验证错误处理和恢复

## 开发说明

### 计算器插件
- 演示工具插件实现
- 展示计算器操作的状态持久化
- 使用平台服务进行通知
- 实现正确的资源清理

### 拼图游戏插件
- 演示游戏插件实现
- 展示复杂的状态管理（棋盘、移动、计时器）
- 实现游戏特定功能（洗牌、胜利检测）
- 演示正确的游戏状态持久化
- 展示游戏的资源管理

这两个插件都为开发者创建自己的插件提供了参考实现。
