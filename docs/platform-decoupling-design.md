# 平台解耦架构设计

> 📐 **版本**: v1.0.0
> **最后更新**: 2026-01-16
> **作者**: Claude Code

## 📋 概述

平台解耦架构是一套用于处理跨平台插件开发的设计模式和工具集，通过接口抽象和工厂模式实现平台特定代码的隔离，使插件能够优雅地声明和处理不同平台的支持状态。

### 设计目标

1. **声明式平台支持** - 插件通过配置声明各平台支持状态
2. **自动降级处理** - 不支持的平台自动显示友好提示或隐藏
3. **代码解耦** - 平台特定代码与核心逻辑分离
4. **类型安全** - 编译时检查平台能力
5. **易于扩展** - 新增平台支持不影响现有代码

---

## 🏗️ 核心架构

### 1. IPlatformPlugin 接口

扩展自 `IPlugin` 接口，添加平台能力管理：

```dart
abstract class IPlatformPlugin extends IPlugin {
  /// 获取平台能力配置
  PluginPlatformCapabilities get platformCapabilities;

  /// 检查当前平台是否支持
  bool get isCurrentPlatformSupported;

  /// 检查当前平台是否完全支持
  bool get isCurrentPlatformFullySupported;

  /// 是否应该在应用中显示此插件
  bool get shouldBeVisible;

  /// 获取当前平台的能力描述
  PlatformCapability get currentCapability;

  /// 构建 UI（自动处理平台支持）
  Widget buildUIWithContext(BuildContext context);

  /// 构建不支持的平台 UI（可重写）
  Widget buildUnsupportedPlatformUI(BuildContext context);
}
```

### 2. PlatformCapability 平台能力

描述插件在特定平台的支持状态：

```dart
class PlatformCapability {
  final TargetPlatform platform;
  final CapabilityType type;
  final String description;
  final String? limitations;
  final String? implementationStatus;
}
```

**能力类型**:

| 类型 | 说明 | 显示行为 |
|------|------|----------|
| `full` | 完整支持 | 正常显示插件功能 |
| `partial` | 部分支持 | 显示功能限制，提供"受限模式继续"按钮 |
| `unsupported` | 不支持 | 显示不支持原因，隐藏插件 |
| `planned` | 计划中 | 显示开发计划，提供"查看路线图"按钮 |

### 3. PluginPlatformCapabilities 配置

统一管理所有平台的能力配置：

```dart
class PluginPlatformCapabilities {
  final String pluginId;
  final Map<TargetPlatform, PlatformCapability> capabilities;
  final bool hideIfUnsupported; // 不支持的平台是否隐藏

  // 获取当前平台的能力
  PlatformCapability get currentPlatformCapability;

  // 检查当前平台是否支持
  bool get isCurrentPlatformSupported;
}
```

### 4. PlatformCapabilityHelper 辅助工具

提供便捷方法创建常用平台配置：

```dart
class PlatformCapabilityHelper {
  // 跨平台完全支持
  static PluginPlatformCapabilities fullySupported(...)

  // 桌面平台支持
  static PluginPlatformCapabilities desktopSupported(...)

  // 移动平台支持
  static PluginPlatformCapabilities mobileSupported(...)

  // Windows 专用
  static PluginPlatformCapabilities windowsOnly(...)

  // 自定义配置
  static PluginPlatformCapabilities custom(...)
}
```

---

## 🎯 使用示例

### 示例 1: 纯 Dart 跨平台插件

适用于所有平台的纯 Dart 实现：

```dart
class WorldClockPlugin implements IPlatformPlugin {
  @override
  PluginPlatformCapabilities get platformCapabilities =>
      _platformCapabilities ??= _createPlatformCapabilities();

  PluginPlatformCapabilities _createPlatformCapabilities() {
    return PlatformCapabilityHelper.fullySupported(
      pluginId: id,
      description: '支持多时区显示和倒计时提醒功能（纯 Dart 实现）',
      hideIfUnsupported: false, // 所有平台都显示
    );
  }
}
```

### 示例 2: Windows 专用插件

仅在 Windows 平台实现的插件：

```dart
class ScreenshotPlugin implements IPlatformPlugin {
  @override
  PluginPlatformCapabilities get platformCapabilities {
    return PluginPlatformCapabilities.custom(
      pluginId: id,
      capabilities: {
        TargetPlatform.windows: PlatformCapability.fullSupported(
          TargetPlatform.windows,
          '支持全屏截图、区域截图、窗口截图和原生桌面级区域选择',
        ),
        TargetPlatform.linux: PlatformCapability.planned(
          TargetPlatform.linux,
          '计划支持 X11 和 Wayland 显示服务器',
        ),
        TargetPlatform.macos: PlatformCapability.planned(
          TargetPlatform.macos,
          '计划支持 Quartz API',
        ),
        TargetPlatform.android: PlatformCapability.partialSupported(
          TargetPlatform.android,
          '应用内截图',
          '只能截取本应用内容，无法实现真正的桌面级截图',
        ),
        TargetPlatform.ios: PlatformCapability.partialSupported(
          TargetPlatform.ios,
          '应用内截图',
          '只能截取本应用内容，无法实现真正的桌面级截图',
        ),
        TargetPlatform.web: PlatformCapability.unsupported(
          TargetPlatform.web,
          '浏览器安全策略限制，无法访问操作系统屏幕',
        ),
      },
      hideIfUnsupported: true, // 不支持的平台隐藏插件
    );
  }
}
```

### 示例 3: 桌面平台插件

支持 Windows、macOS、Linux 的桌面插件：

```dart
class DesktopPetPlugin implements IPlatformPlugin {
  @override
  PluginPlatformCapabilities get platformCapabilities {
    return PlatformCapabilityHelper.desktopSupported(
      pluginId: id,
      description: '桌面宠物功能',
      hideIfUnsupported: true,
    );
  }
}
```

---

## 📂 代码组织

### 目录结构

```
lib/plugins/{plugin_name}/
├── {plugin_name}_plugin.dart         # 插件主类 (实现 IPlatformPlugin)
├── platform/                          # 平台接口定义
│   └── {plugin_name}_platform_interface.dart
├── services/                          # 服务层
│   ├── base/                          # 基础服务 (跨平台)
│   │   └── {service}_base.dart
│   └── platforms/                     # 平台特定实现
│       ├── windows/
│       │   └── {service}_windows.dart
│       ├── linux/
│       │   └── {service}_linux.dart
│       ├── macos/
│       │   └── {service}_macos.dart
│       ├── android/
│       │   └── {service}_android.dart
│       └── ios/
│           └── {service}_ios.dart
├── models/                            # 数据模型
└── widgets/                           # UI 组件
```

### 平台特定实现示例

**平台接口定义**:

```dart
// lib/plugins/screenshot/platform/screenshot_platform_interface.dart
abstract class ScreenshotPlatformInterface {
  bool get isAvailable;
  Future<Uint8List?> captureFullScreen();
  Future<Uint8List?> captureRegion(Rect rect);
  // ...
}
```

**Windows 实现**:

```dart
// lib/plugins/screenshot/services/platforms/windows/screenshot_service_windows.dart
class WindowsScreenshotService implements ScreenshotPlatformInterface {
  @override
  bool get isAvailable => Platform.isWindows;

  @override
  Future<Uint8List?> captureFullScreen() async {
    // Windows GDI+ 实现
  }
}
```

**Linux 实现**:

```dart
// lib/plugins/screenshot/services/platforms/linux/screenshot_service_linux.dart
class LinuxScreenshotService implements ScreenshotPlatformInterface {
  @override
  bool get isAvailable => Platform.isLinux;

  @override
  Future<Uint8List?> captureFullScreen() async {
    // Linux X11/Wayland 实现
  }
}
```

---

## 🔄 工作流程

### 1. 插件初始化流程

```
┌──────────────────────────────────────────────────────────────┐
│ 1. 加载插件                                                   │
│    └── PluginLoader.loadPlugin()                             │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. 检查平台支持                                               │
│    └── plugin.isCurrentPlatformSupported                     │
└──────────────────────────────────────────────────────────────┘
                          ↓
              ┌─────────────────────┐
              │ 是否支持当前平台？    │
              └─────────────────────┘
                    ↓         ↓
                  是          否
                  ↓           ↓
┌─────────────────────────┐  ┌──────────────────────────┐
│ 3. 正常初始化插件         │  │ 4. 处理不支持的平台       │
│    └── plugin.initialize()│  │    └── 根据 hideIfUnsupported │
└─────────────────────────┘  │       决定是否显示插件      │
                             └──────────────────────────┘
```

### 2. UI 构建流程

```
┌──────────────────────────────────────────────────────────────┐
│ 1. 构建 UI                                                   │
│    └── plugin.buildUIWithContext(context)                    │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. 检查平台支持                                               │
│    └── if (plugin.isCurrentPlatformSupported)                │
└──────────────────────────────────────────────────────────────┘
                          ↓
              ┌─────────────────────┐
              │ 是否支持当前平台？    │
              └─────────────────────┘
                    ↓         ↓
                  是          否
                  ↓           ↓
┌─────────────────────────┐  ┌──────────────────────────┐
│ 3. 构建正常 UI           │  │ 4. 构建不支持平台 UI     │
│    └── plugin.buildUI()  │  │    └── buildUnsupported │
└─────────────────────────┘  │       PlatformUI()       │
                             └──────────────────────────┘
```

---

## 🛠️ 开发指南

### 步骤 1: 实现 IPlatformPlugin

所有新插件必须实现 `IPlatformPlugin` 接口：

```dart
class MyPlugin implements IPlatformPlugin {
  @override
  PluginPlatformCapabilities get platformCapabilities =>
      _platformCapabilities ??= _createPlatformCapabilities();
}
```

### 步骤 2: 定义平台能力

根据插件特性定义平台支持状态：

```dart
PluginPlatformCapabilities _createPlatformCapabilities() {
  return PlatformCapabilityHelper.custom(
    pluginId: id,
    capabilities: {
      TargetPlatform.windows: PlatformCapability.fullSupported(...),
      TargetPlatform.web: PlatformCapability.unsupported(...),
    },
    hideIfUnsupported: true,
  );
}
```

### 步骤 3: 实现平台特定代码

如果需要平台特定实现，使用接口和工厂模式：

```dart
// 1. 定义接口
abstract class MyService {
  Future<void> doSomething();
}

// 2. 实现平台特定版本
class WindowsMyService implements MyService { /* ... */ }
class LinuxMyService implements MyService { /* ... */ }

// 3. 使用工厂创建
MyService createMyService() {
  if (Platform.isWindows) return WindowsMyService();
  if (Platform.isLinux) return LinuxMyService();
  throw UnsupportedError('Platform not supported');
}
```

### 步骤 4: 在初始化时检查平台支持

```dart
@override
Future<void> initialize(PluginContext context) async {
  if (!isCurrentPlatformSupported) {
    debugPrint('$name: ${currentCapability.description}');
    return; // 或实现降级模式
  }
  // 继续初始化...
}
```

---

## ✅ 最佳实践

### 1. 使用辅助工具

优先使用 `PlatformCapabilityHelper` 提供的辅助方法：

```dart
// ✅ 推荐
PlatformCapabilityHelper.desktopSupported(pluginId: id)

// ❌ 不推荐（过于冗长）
PluginPlatformCapabilities.custom(
  pluginId: id,
  capabilities: {
    TargetPlatform.windows: PlatformCapability.fullSupported(...),
    TargetPlatform.linux: PlatformCapability.fullSupported(...),
    TargetPlatform.macos: PlatformCapability.fullSupported(...),
    // ...
  },
)
```

### 2. 明确描述限制

对于 `partial` 支持的平台，明确说明限制：

```dart
PlatformCapability.partialSupported(
  TargetPlatform.android,
  '应用内截图',
  '只能截取本应用内容，无法实现桌面级截图', // 明确限制
)
```

### 3. 提供降级体验

对于不支持的平台，提供友好的 UI：

```dart
@override
Widget buildUnsupportedPlatformUI(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Column(
        children: [
          Icon(Icons.block_outlined),
          Text('此功能暂不支持 ${PlatformCapabilityHelper.getCurrentPlatform()}'),
          Text('限制: ${currentCapability.limitations}'),
          ElevatedButton(
            onPressed: () => _viewRoadmap(),
            child: Text('查看开发计划'),
          ),
        ],
      ),
    ),
  );
}
```

### 4. 保持代码同步

当添加新平台支持时，更新平台能力配置：

```dart
// 添加 macOS 支持后
capabilities: {
  TargetPlatform.windows: PlatformCapability.fullSupported(...),
  TargetPlatform.macos: PlatformCapability.fullSupported(...), // 新增
  TargetPlatform.linux: PlatformCapability.planned(...),
  // ...
}
```

---

## 📊 已实现插件

| 插件 | 类型 | Windows | Linux | macOS | Android | iOS | Web |
|------|------|---------|-------|-------|---------|-----|-----|
| **Calculator** | 跨平台 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 |
| **WorldClock** | 跨平台 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 |
| **Screenshot** | 桌面 | ✅ 完整 | ⏳ 计划 | ⏳ 计划 | 🟡 受限 | 🟡 受限 | ❌ 不支持 |

**说明**:
- ✅ 完整 - 完整支持所有功能
- 🟡 受限 - 部分支持，有明确限制
- ⏳ 计划 - 计划中，待实现
- ❌ 不支持 - 不支持此平台

---

## 🔄 版本历史

### v1.0.0 (2026-01-16)
- ✅ 创建 `IPlatformPlugin` 接口
- ✅ 实现 `PlatformCapability` 系统
- ✅ 添加 `PlatformCapabilityHelper` 辅助工具
- ✅ 改造 3 个现有插件（Calculator, WorldClock, Screenshot）
- ✅ 更新开发规范，添加平台解耦规则

---

## 📚 相关文档

- [文件组织规范](../../.claude/rules/FILE_ORGANIZATION_RULES.md) - 平台解耦开发规则
- [插件开发指南](../guides/internal-plugin-development.md) - 插件开发完整指南
- [平台服务架构](../platform-services/) - 平台服务系统
- [截图插件平台支持](../plugins/screenshot/PLATFORM_SUPPORT_ANALYSIS.md) - 截图插件详细分析

---

**维护者**: Flutter Plugin Platform 团队
**最后更新**: 2026-01-16
