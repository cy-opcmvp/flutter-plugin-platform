# Desktop Pet 平台支持指南

## 概述

Desktop Pet 功能提供了一个可交互的桌面伴侣小组件，可以显示在用户的桌面上。由于技术限制和平台能力差异，此功能在不同平台上有不同的支持级别。

## 平台支持矩阵

### 完全支持 ✅

**Windows (桌面版)**
- Desktop pet 小组件: ✅ 完全支持
- 始终置顶: ✅ 支持
- 系统托盘集成: ✅ 支持
- 窗口管理: ✅ 完全控制
- 透明度效果: ✅ 支持
- 点击穿透模式: ✅ 支持
- 多显示器支持: ✅ 支持

**macOS (桌面版)**
- Desktop pet 小组件: ✅ 完全支持
- 始终置顶: ✅ 支持
- 系统托盘集成: ✅ 支持 (菜单栏)
- 窗口管理: ✅ 完全控制
- 透明度效果: ✅ 支持
- 点击穿透模式: ✅ 支持
- 多显示器支持: ✅ 支持

**Linux (桌面版)**
- Desktop pet 小组件: ✅ 完全支持
- 始终置顶: ✅ 支持
- 系统托盘集成: ✅ 支持 (取决于桌面环境)
- 窗口管理: ✅ 完全控制
- 透明度效果: ✅ 支持 (取决于合成器)
- 点击穿透模式: ✅ 支持
- 多显示器支持: ✅ 支持

### 不支持 ❌

**Web 平台**
- Desktop pet 小组件: ❌ 不可用
- 始终置顶: ❌ 浏览器安全限制
- 系统托盘集成: ❌ 浏览器中不可用
- 窗口管理: ❌ 浏览器沙箱限制
- 透明度效果: ❌ 浏览器支持有限
- 点击穿透模式: ❌ 浏览器安全限制
- 多显示器支持: ❌ 浏览器 API 限制

**iOS**
- Desktop pet 小组件: ❌ 无桌面环境
- 始终置顶: ❌ iOS 应用模型限制
- 系统托盘集成: ❌ 不可用
- 窗口管理: ❌ 单应用焦点模型

**Android**
- Desktop pet 小组件: ❌ 无桌面环境
- 始终置顶: ❌ 叠加层权限受限
- 系统托盘集成: ❌ 不同的通知模型
- 窗口管理: ❌ 基于 Activity 的模型

## 技术实现细节

### 平台检测

Desktop Pet 系统使用多层平台检测：

```dart
class DesktopPetManager {
  /// 主要平台支持检查
  static bool isSupported() {
    // 首先检查 Web 平台（编译时常量）
    if (kIsWeb) return false;

    // 移动平台检查
    if (Platform.isIOS || Platform.isAndroid) return false;

    // 桌面平台检查
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 运行时能力检查
  bool get hasWindowManagement {
    return isSupported() && _checkWindowManagerCapabilities();
  }

  /// 系统托盘可用性
  bool get hasSystemTray {
    if (!isSupported()) return false;

    // 平台特定的系统托盘检查
    if (Platform.isWindows) return true;
    if (Platform.isMacOS) return true;
    if (Platform.isLinux) return _checkLinuxSystemTray();

    return false;
  }
}
```

### Web 平台行为

在 Web 平台上，Desktop Pet 功能完全禁用：

#### UI 行为
- Desktop pet 按钮从主界面隐藏
- Desktop pet 菜单项不显示
- Desktop pet 设置不可访问
- 导航到 desktop pet 屏幕显示回退消息

#### API 行为
```dart
// 所有 desktop pet API 在 web 上返回安全的回退值
class DesktopPetManager {
  Future<void> initialize() async {
    if (!isSupported()) {
      // 优雅的无操作 - 不抛出错误
      return;
    }
    // 仅原生初始化
  }

  Future<bool> showPet() async {
    if (!isSupported()) return false;
    // 原生实现
  }

  Future<void> hidePet() async {
    if (!isSupported()) return;
    // 原生实现
  }
}
```

#### 错误处理
```dart
// Web 安全的错误处理
try {
  await desktopPetManager.initialize();
} catch (e) {
  // 由于提前返回，这在 web 上不应发生
  logger.warning('Desktop pet 初始化失败: $e');
}
```

### 原生平台实现

#### Windows 特定功能
```dart
class WindowsDesktopPet {
  // Windows 特定的窗口管理
  Future<void> setAlwaysOnTop(bool enabled) async {
    if (!Platform.isWindows) return;
    // Windows API 调用
  }

  // Windows 系统托盘集成
  Future<void> createSystemTrayIcon() async {
    if (!Platform.isWindows) return;
    // Windows 系统托盘实现
  }
}
```

#### macOS 特定功能
```dart
class MacOSDesktopPet {
  // macOS 菜单栏集成
  Future<void> createMenuBarItem() async {
    if (!Platform.isMacOS) return;
    // macOS 菜单栏实现
  }

  // macOS 窗口级别管理
  Future<void> setWindowLevel(int level) async {
    if (!Platform.isMacOS) return;
    // macOS 窗口级别 API
  }
}
```

#### Linux 特定功能
```dart
class LinuxDesktopPet {
  // Linux 桌面环境检测
  String? detectDesktopEnvironment() {
    if (!Platform.isLinux) return null;

    final env = PlatformEnvironment.instance;
    return env.getVariable('XDG_CURRENT_DESKTOP') ??
           env.getVariable('DESKTOP_SESSION');
  }

  // Linux 系统托盘（取决于桌面环境）
  bool get supportsSystemTray {
    final de = detectDesktopEnvironment()?.toLowerCase();
    return de != null && (
      de.contains('gnome') ||
      de.contains('kde') ||
      de.contains('xfce') ||
      de.contains('mate')
    );
  }
}
```

## 各平台的用户体验

### 桌面平台 (Windows、macOS、Linux)

**初始设置**
1. Desktop pet 按钮出现在主界面
2. 用户可以点击访问 desktop pet 设置
3. Desktop pet 可以启用/禁用
4. 可使用自定义选项

**运行时行为**
1. Desktop pet 作为桌面覆盖层出现
2. 宠物可以在屏幕上移动
3. 宠物响应用户交互
4. 宠物可以最小化到系统托盘

**可用功能**
- 动画宠物精灵
- 交互行为
- 可自定义外观
- 始终置顶模式
- 点击穿透模式
- 系统托盘集成
- 多显示器支持

### Web 平台

**初始设置**
1. Desktop pet 按钮隐藏
2. Desktop pet 菜单项不显示
3. 设置页面排除 desktop pet 选项
4. 无 desktop pet 相关通知

**运行时行为**
1. 应用程序正常运行，无 desktop pet
2. 无关于缺少功能的错误或警告
3. 核心插件功能保持可用
4. 可提供替代的交互功能

**用户沟通**
- 关于平台限制的清晰文档
- 为 Web 用户突出替代功能
- 无暗示不可用功能的混淆 UI 元素

### 移动平台 (iOS、Android)

**行为**
- 与 Web 平台相同 - desktop pet 功能隐藏
- 移动优化的界面，无 desktop pet 选项
- 专注于适合移动平台的插件功能

## 开发指南

### 添加 Desktop Pet 功能

添加新的 desktop pet 功能时：

1. **始终检查平台支持**
   ```dart
   if (!DesktopPetManager.isSupported()) {
     return; // 或提供替代方案
   }
   ```

2. **提供 Web 安全的替代方案**
   ```dart
   Widget buildPetControls() {
     if (DesktopPetManager.isSupported()) {
       return DesktopPetControls();
     } else {
       return WebAlternativeControls(); // 或 SizedBox.shrink()
     }
   }
   ```

3. **谨慎使用条件导入**
   ```dart
   // 在共享代码中避免直接 dart:io 导入
   import 'desktop_pet_stub.dart'
     if (dart.library.io) 'desktop_pet_io.dart'
     if (dart.library.html) 'desktop_pet_web.dart';
   ```

### 测试 Desktop Pet 功能

#### 单元测试
```dart
group('Desktop Pet Platform Support', () {
  test('应在桌面平台上支持', () {
    // 模拟平台检测
    expect(DesktopPetManager.isSupported(), isTrue);
  });

  test('不应在 Web 平台上支持', () {
    // 模拟 Web 平台
    expect(DesktopPetManager.isSupported(), isFalse);
  });
});
```

#### 集成测试
```dart
testWidgets('desktop pet UI 应在 web 上隐藏', (tester) async {
  // 模拟 Web 平台
  await tester.pumpWidget(MyApp());

  // 验证 desktop pet 按钮不存在
  expect(find.byKey(Key('desktop_pet_button')), findsNothing);
});
```

### 错误处理最佳实践

1. **优雅降级**
   ```dart
   Future<void> initializeDesktopPet() async {
     try {
       if (DesktopPetManager.isSupported()) {
         await desktopPetManager.initialize();
       }
     } catch (e) {
       logger.warning('Desktop pet 初始化失败: $e');
       // 继续运行，无 desktop pet
     }
   }
   ```

2. **用户友好的消息**
   ```dart
   String getDesktopPetStatusMessage() {
     if (!DesktopPetManager.isSupported()) {
       if (kIsWeb) {
         return 'Desktop pet 在 Web 浏览器中不可用';
       } else {
         return 'Desktop pet 仅在桌面平台上可用';
       }
     }
     return 'Desktop pet 可用';
   }
   ```

## 故障排除

### 常见问题

**问题**: Desktop pet 按钮在 Web 平台上出现
**解决方案**: 检查 UI 条件渲染逻辑

**问题**: 在 Web 上访问 desktop pet 时应用程序崩溃
**解决方案**: 验证在 desktop pet API 调用之前是否进行了平台检查

**问题**: Desktop pet 在 Linux 上不工作
**解决方案**: 检查桌面环境兼容性和系统托盘支持

### 调试平台检测

```dart
void debugPlatformSupport() {
  print('平台: ${Platform.operatingSystem}');
  print('是 Web: $kIsWeb');
  print('Desktop Pet 支持: ${DesktopPetManager.isSupported()}');
  print('系统托盘可用: ${desktopPetManager.hasSystemTray}');
  print('窗口管理: ${desktopPetManager.hasWindowManagement}');
}
```

### 性能考虑

- Desktop pet 功能仅在受支持时初始化
- Web 平台避免加载 desktop pet 资源
- 平台检测尽可能使用编译时常量
- 平台特定实现的延迟加载

## 未来增强

### 计划的改进

1. **增强的 Web 体验**
   - 使用 CSS 动画的基于 Web 的宠物替代方案
   - 浏览器通知集成
   - 渐进式 Web 应用功能

2. **移动平台支持**
   - 基于 Widget 的宠物，用于 iOS/Android 主屏幕
   - 基于通知的交互
   - 移动优化的宠物行为

3. **跨平台同步**
   - 宠物状态跨设备同步
   - 基于云的宠物进度
   - 多设备宠物交互

### 实验性功能

- **浏览器扩展集成**: 通过浏览器扩展实现 desktop pet 功能
- **WebAssembly 性能**: 使用 WASM 增强 web pet 性能
- **AR/VR 支持**: 在支持的平台上的沉浸式宠物体验

## 支持和资源

对于 desktop pet 平台支持问题：

1. 检查上面的平台兼容性矩阵
2. 验证平台检测是否正常工作
3. 查看错误日志以了解平台特定问题
4. 在开发期间在目标平台上测试
5. 咨询平台特定文档以了解高级功能

对于功能请求或平台特定增强，请提交 issue 并包含：
- 目标平台详细信息
- 具体功能需求
- 用例描述
- 技术约束或考虑因素
