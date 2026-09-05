# Web 平台兼容性指南

## 概述

本指南记录了 Flutter 插件平台中实现的 Web 平台兼容性功能。系统现在通过平台抽象层支持 Web 和原生平台，优雅地处理环境变量和桌面特定功能。

## 平台功能矩阵

### 核心功能

| 功能 | Web 平台 | 原生平台 | 说明 |
|---------|---------|----------|------|
| 环境变量 | ❌ (使用默认值) | ✅ (完全访问) | Web 使用安全的默认值 |
| 文件系统访问 | ❌ (浏览器存储) | ✅ (完全访问) | Web 使用 localStorage/sessionStorage |
| 进程执行 | ❌ (已禁用) | ✅ (完全访问) | Web 无法执行外部进程 |
| Steam 集成 | ❌ (已禁用) | ✅ (可用时) | Web 完全跳过 Steam 检测 |
| 开发模式 | ✅ (有限) | ✅ (完全检测) | Web 使用替代检测方法 |
| 插件系统 | ✅ (核心功能) | ✅ (完整功能) | Web 支持大多数插件功能 |

### Desktop Pet 功能

| 功能 | Web 平台 | Windows | macOS | Linux | 移动平台 |
|---------|---------|---------|-------|-------|--------|
| Desktop Pet 小组件 | ❌ | ✅ | ✅ | ✅ | ❌ |
| 始终置顶 | ❌ | ✅ | ✅ | ✅ | ❌ |
| 系统托盘 | ❌ | ✅ | ✅ | ✅ | ❌ |
| 窗口管理 | ❌ | ✅ | ✅ | ✅ | ❌ |
| Desktop Pet UI 控件 | 隐藏 | 可见 | 可见 | 可见 | 隐藏 |

### 路径解析

| 路径类型 | Web 平台 | 原生平台 |
|-----------|---------|----------|
| 主目录 | `/browser-home` | `$HOME` 或等效路径 |
| 文档目录 | `/browser-documents` | 平台特定的文档文件夹 |
| 临时文件 | `/browser-temp` | 系统临时目录 |
| 应用数据 | `/browser-appdata` | 平台特定的应用数据文件夹 |

## 迁移指南

### 对于使用 Platform.environment 的开发者

如果您的代码当前直接使用 `Platform.environment`，请按照以下步骤进行迁移：

#### 之前（在 Web 上有问题）
```dart
import 'dart:io';

// 这在 Web 平台上会抛出异常
String? steamPath = Platform.environment['STEAM_PATH'];
String home = Platform.environment['HOME'] ?? '/default';
```

#### 之后（Web 兼容）
```dart
import 'package:your_app/core/services/platform_environment.dart';

// 这在所有平台上都能工作
String? steamPath = PlatformEnvironment.instance.getVariable('STEAM_PATH');
String home = PlatformEnvironment.instance.getHomePath();
```

### 逐步迁移

1. **替换直接的 Platform.environment 调用**
   ```dart
   // 旧方式
   Platform.environment['KEY']

   // 新方式
   PlatformEnvironment.instance.getVariable('KEY')
   ```

2. **添加默认值**
   ```dart
   // 旧方式
   String value = Platform.environment['KEY'] ?? 'default';

   // 新方式
   String value = PlatformEnvironment.instance.getVariable('KEY', defaultValue: 'default') ?? 'default';
   ```

3. **使用路径解析方法**
   ```dart
   // 旧方式
   String home = Platform.environment['HOME'] ?? '/';

   // 新方式
   String home = PlatformEnvironment.instance.getHomePath();
   ```

4. **检查平台能力**
   ```dart
   // 旧方式
   if (Platform.isWindows) { /* 桌面平台逻辑 */ }

   // 新方式
   if (!PlatformEnvironment.instance.isWeb && Platform.isWindows) {
     /* 桌面平台逻辑 */
   }
   ```

## 环境变量默认值

### Web 平台默认值

在 Web 平台上运行时，使用以下默认值：

| 环境变量 | 默认值 | 用途 |
|---------|-------|------|
| `HOME` | `/browser-home` | 用户主目录 |
| `USERPROFILE` | `/browser-home` | Windows 用户配置文件 |
| `APPDATA` | `/browser-appdata` | 应用程序数据目录 |
| `LOCALAPPDATA` | `/browser-appdata` | 本地应用程序数据 |
| `TEMP` | `/browser-temp` | 临时文件目录 |
| `TMP` | `/browser-temp` | 临时文件目录 |
| `PATH` | `/usr/bin:/bin` | 可执行文件搜索路径 |
| `STEAM_PATH` | `null` | Steam 安装路径 |
| `DEVELOPMENT_MODE` | `null` | 开发模式指示器 |

### 原生平台行为

在原生平台上，返回实际的环境变量值。如果变量不存在，使用以下回退值：

| 平台 | HOME 回退值 | TEMP 回退值 | APPDATA 回退值 |
|------|-----------|------------|---------------|
| Windows | `C:\Users\Default` | `C:\Temp` | `C:\Users\Default\AppData` |
| macOS | `/Users/Shared` | `/tmp` | `/Users/Shared/Library` |
| Linux | `/home/user` | `/tmp` | `/home/user/.local/share` |

## Desktop Pet 功能文档

### 平台可用性

Desktop pet 功能仅在桌面平台（Windows、macOS、Linux）上可用。该功能在 Web 和移动平台上完全禁用。

### Web 平台行为

在 Web 平台上：
- Desktop pet UI 控件从界面中隐藏
- Desktop pet 管理器初始化被跳过
- 所有 desktop pet API 调用返回安全的回退值
- 访问 desktop pet 功能时不抛出错误

### 实现细节

```dart
// Desktop pet 可用性检查
bool isDesktopPetSupported() {
  return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}

// 安全的 desktop pet 初始化
class DesktopPetManager {
  static bool isSupported() {
    return !kIsWeb && _isDesktopPlatform();
  }

  Future<void> initialize() async {
    if (!isSupported()) {
      // 在不支持的平台上优雅地无操作
      return;
    }
    // 原生初始化逻辑
  }
}
```

### 按平台的 UI 行为

#### Web 平台
- Desktop pet 按钮：隐藏
- Desktop pet 屏幕：显示"功能不可用"消息
- Desktop pet 小组件：返回空容器
- 导航：优雅地处理不可用的路由

#### 桌面平台
- Desktop pet 按钮：可见且功能正常
- Desktop pet 屏幕：完整功能
- Desktop pet 小组件：完整功能集
- 导航：完整的 desktop pet 导航可用

#### 移动平台
- Desktop pet 按钮：隐藏
- Desktop pet 功能：已禁用（与 Web 相同）

## 开发和调试

### 调试模式功能

在调试模式下运行时，提供额外的日志记录：

```dart
// 启用详细的平台日志
PlatformLogger.setLevel(LogLevel.debug);

// 检查平台能力
PlatformCapabilities caps = PlatformEnvironment.instance.capabilities;
print('支持环境变量: ${caps.supportsEnvironmentVariables}');
print('支持 Desktop Pet: ${caps.supportsDesktopPet}');
```

### 常见问题和解决方案

#### 问题：应用程序在 Web 上因 Platform.environment 错误而崩溃
**解决方案**：将直接的 `Platform.environment` 使用替换为 `PlatformEnvironment.instance.getVariable()`

#### 问题：Desktop pet 功能在 Web 上不工作
**解决方案**：这是预期行为。Desktop pet 功能在 Web 平台上已禁用。

#### 问题：文件路径在 Web 上不工作
**解决方案**：使用 `PlatformEnvironment.instance.getHomePath()` 和类似方法，而不是环境变量。

#### 问题：在 Web 上未检测到 Steam 集成
**解决方案**：Steam 集成在 Web 平台上故意禁用。

### 测试平台兼容性

```dart
// 测试环境变量访问
test('环境变量在所有平台上都能工作', () {
  String? value = PlatformEnvironment.instance.getVariable('HOME');
  expect(value, isNotNull); // 由于有回退值，永远不应该为 null
});

// 测试 desktop pet 可用性
test('desktop pet 可用性与平台匹配', () {
  bool expected = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  expect(DesktopPetManager.isSupported(), equals(expected));
});
```

## 最佳实践

### 1. 始终使用平台抽象
```dart
// 好的做法
String home = PlatformEnvironment.instance.getHomePath();

// 坏的做法
String home = Platform.environment['HOME'] ?? '/';
```

### 2. 检查平台能力
```dart
// 好的做法
if (PlatformEnvironment.instance.capabilities.supportsDesktopPet) {
  // Desktop pet 逻辑
}

// 坏的做法
if (Platform.isWindows) {
  // 这不考虑 Web 平台
}
```

### 3. 提供优雅的回退
```dart
// 好的做法
Widget buildDesktopPetButton() {
  if (!DesktopPetManager.isSupported()) {
    return SizedBox.shrink(); // 在不支持的平台上隐藏
  }
  return ElevatedButton(/* desktop pet 按钮 */);
}
```

### 4. 使用适当的默认值
```dart
// 好的做法
String configPath = PlatformEnvironment.instance.getVariable(
  'CONFIG_PATH',
  defaultValue: '/default/config'
);

// 坏的做法
String configPath = Platform.environment['CONFIG_PATH']; // 在 Web 上崩溃
```

## 性能考虑

- 环境变量查找被缓存以避免重复的系统调用
- 平台检测尽可能使用编译时常量（`kIsWeb`）
- Desktop pet 初始化是延迟的，仅在需要时发生
- Web 平台避免在 desktop pet 模块中导入 `dart:io`

## 安全考虑

- Web 平台无法访问实际的环境变量（浏览器安全）
- 默认值是安全的，不暴露敏感信息
- Desktop pet 功能在桌面平台上需要明确的用户权限
- 文件系统访问在每个平台上都受到适当的沙箱保护

## 未来增强

计划对 Web 平台兼容性的改进：

1. **增强的 Web 存储**：更好地与浏览器存储 API 集成
2. **渐进式 Web 应用功能**：支持 PWA 特定的功能
3. **Web 特定插件**：专为 Web 平台设计的插件
4. **改进的回退机制**：为缺失的功能提供更复杂的回退机制

## 支持和故障排除

有关 Web 平台兼容性的问题：

1. 检查浏览器控制台以获取详细的错误消息
2. 验证 `kIsWeb` 检测是否正常工作
3. 确保 Web 编译代码中没有直接的 `dart:io` 导入
4. 在目标平台上测试平台特定功能

如需额外支持，请参考主文档或提交包含平台详细信息的问题。
