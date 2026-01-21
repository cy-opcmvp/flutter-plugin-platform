# Platform.environment 迁移指南

## 概述

本指南帮助开发者从直接使用 `Platform.environment` 迁移到新的 `PlatformEnvironment` 抽象层。此迁移对于 Web 平台兼容性是必需的。

## 为什么要迁移？

Flutter Web 平台不支持访问 `Platform.environment`，导致应用在浏览器中运行时出现运行时错误。`PlatformEnvironment` 服务提供了一个在所有平台上都能工作的统一 API。

## 快速迁移检查清单

- [ ] 将所有 `Platform.environment` 调用替换为 `PlatformEnvironment.instance`
- [ ] 为环境变量添加适当的默认值
- [ ] 使用路径解析方法代替环境变量解析
- [ ] 在需要的地方添加平台能力检查
- [ ] 在 Web 和原生平台上测试

## 常见迁移模式

### 1. 基本环境变量访问

#### 之前（Web 不兼容）
```dart
import 'dart:io';

String? getValue() {
  return Platform.environment['MY_VAR'];
}
```

#### 之后（Web 兼容）
```dart
import 'package:your_app/core/services/platform_environment.dart';

String? getValue() {
  return PlatformEnvironment.instance.getVariable('MY_VAR');
}
```

### 2. 带默认值的环境变量

#### 之前
```dart
String getConfigPath() {
  return Platform.environment['CONFIG_PATH'] ?? '/default/config';
}
```

#### 之后
```dart
String getConfigPath() {
  return PlatformEnvironment.instance.getVariable(
    'CONFIG_PATH',
    defaultValue: '/default/config'
  ) ?? '/default/config';
}
```

### 3. 路径解析

#### 之前
```dart
String getHomePath() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
  } else {
    return Platform.environment['HOME'] ?? '/home/user';
  }
}
```

#### 之后
```dart
String getHomePath() {
  return PlatformEnvironment.instance.getHomePath();
}
```

### 4. 多个环境变量

#### 之前
```dart
Map<String, String> getSystemInfo() {
  return {
    'home': Platform.environment['HOME'] ?? 'unknown',
    'user': Platform.environment['USER'] ?? 'unknown',
    'path': Platform.environment['PATH'] ?? 'unknown',
  };
}
```

#### 之后
```dart
Map<String, String> getSystemInfo() {
  final env = PlatformEnvironment.instance;
  return {
    'home': env.getVariable('HOME', defaultValue: 'unknown') ?? 'unknown',
    'user': env.getVariable('USER', defaultValue: 'unknown') ?? 'unknown',
    'path': env.getVariable('PATH', defaultValue: 'unknown') ?? 'unknown',
  };
}
```

### 5. 平台特定逻辑

#### 之前
```dart
bool isSteamEnvironment() {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return false;
  }
  return Platform.environment.containsKey('STEAM_PATH') ||
       Platform.environment.containsKey('STEAMAPPS');
}
```

#### 之后
```dart
bool isSteamEnvironment() {
  final env = PlatformEnvironment.instance;

  // 在 Web 平台上跳过 Steam 检测
  if (env.isWeb) {
    return false;
  }

  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return false;
  }

  return env.containsKey('STEAM_PATH') || env.containsKey('STEAMAPPS');
}
```

### 6. 开发环境检测

#### 之前
```dart
bool isDevelopmentMode() {
  return Platform.environment['DEVELOPMENT_MODE'] == 'true' ||
       Platform.environment['DEBUG'] == '1' ||
       Platform.environment.containsKey('FLUTTER_TEST');
}
```

#### 之后
```dart
bool isDevelopmentMode() {
  final env = PlatformEnvironment.instance;

  // 在 Web 上，使用替代检测方法
  if (env.isWeb) {
    return kDebugMode ||
           Uri.base.queryParameters.containsKey('debug') ||
           Uri.base.host == 'localhost';
  }

  return env.getVariable('DEVELOPMENT_MODE') == 'true' ||
       env.getVariable('DEBUG') == '1' ||
       env.containsKey('FLUTTER_TEST');
}
```

## 逐文件迁移示例

### CLI 工具

#### 之前: `lib/cli/cli_utils.dart`
```dart
Map<String, dynamic> getSystemInfo() {
  return {
    'platform': Platform.operatingSystem,
    'environment': Platform.environment,
    'home': Platform.environment['HOME'],
  };
}
```

#### 之后: `lib/cli/cli_utils.dart`
```dart
Map<String, dynamic> getSystemInfo() {
  final env = PlatformEnvironment.instance;
  return {
    'platform': env.isWeb ? 'web' : Platform.operatingSystem,
    'environment': env.getAllVariables(),
    'home': env.getHomePath(),
  };
}
```

### 配置服务

#### 之前: `lib/core/config/platform_config.dart`
```dart
bool _isSteamEnvironment() {
  return Platform.environment.containsKey('STEAM_PATH');
}
```

#### 之后: `lib/core/config/platform_config.dart`
```dart
bool _isSteamEnvironment() {
  final env = PlatformEnvironment.instance;

  // Steam 仅在桌面平台上可用
  if (env.isWeb || !_isDesktopPlatform()) {
    return false;
  }

  return env.containsKey('STEAM_PATH');
}

bool _isDesktopPlatform() {
  return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}
```

### 平台适配器

#### 之前: `lib/core/services/platform_adapters.dart`
```dart
String _getWindowsPath() {
  return Platform.environment['PATH'] ?? '';
}
```

#### 之后: `lib/core/services/platform_adapters.dart`
```dart
String _getWindowsPath() {
  return PlatformEnvironment.instance.getVariable(
    'PATH',
    defaultValue: 'C:\\Windows\\System32'
  ) ?? 'C:\\Windows\\System32';
}
```

## 测试迁移结果

### 1. 单元测试

创建测试以验证迁移正常工作：

```dart
import 'package:test/test.dart';
import 'package:your_app/core/services/platform_environment.dart';

void main() {
  group('Platform Environment Migration', () {
    test('should handle missing environment variables gracefully', () {
      final result = PlatformEnvironment.instance.getVariable(
        'NONEXISTENT_VAR',
        defaultValue: 'fallback'
      );
      expect(result, equals('fallback'));
    });

    test('should return valid paths on all platforms', () {
      final homePath = PlatformEnvironment.instance.getHomePath();
      expect(homePath, isNotNull);
      expect(homePath, isNotEmpty);
    });

    test('should detect web platform correctly', () {
      final isWeb = PlatformEnvironment.instance.isWeb;
      expect(isWeb, equals(kIsWeb));
    });
  });
}
```

### 2. 集成测试

在不同平台上测试应用：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Compatibility Integration Tests', () {
    testWidgets('app should start without errors on web', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证应用成功加载
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('environment-dependent features should work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 测试需要环境变量的功能正常工作
      // 这在任何平台上都不应抛出异常
    });
  });
}
```

## 常见陷阱和解决方案

### 1. 忘记平台检查

**问题**: 代码在 Web 上假设桌面平台能力
```dart
// 不好 - 会在 Web 上失败
if (Platform.isWindows) {
  // 桌面特定逻辑
}
```

**解决方案**: 始终先检查 Web 平台
```dart
// 好 - Web 安全
if (!kIsWeb && Platform.isWindows) {
  // 桌面特定逻辑
}
```

### 2. 不提供默认值

**问题**: 环境变量缺失时返回空值
```dart
// 不好 - 在 Web 上可能返回 null
String? path = PlatformEnvironment.instance.getVariable('MY_PATH');
```

**解决方案**: 始终提供合理的默认值
```dart
// 好 - 始终返回一个值
String path = PlatformEnvironment.instance.getVariable(
  'MY_PATH',
  defaultValue: '/default/path'
) ?? '/default/path';
```

### 3. 在 Web 编译代码中导入 dart:io

**问题**: Desktop pet 或平台特定代码导入 dart:io
```dart
// 不好 - 会破坏 Web 编译
import 'dart:io';

class DesktopPetManager {
  void initialize() {
    if (Platform.isWindows) { /* ... */ }
  }
}
```

**解决方案**: 使用条件平台检测
```dart
// 好 - Web 安全
import 'package:flutter/foundation.dart';

class DesktopPetManager {
  void initialize() {
    if (!kIsWeb && Platform.isWindows) { /* ... */ }
  }

  static bool isSupported() {
    return !kIsWeb && _isDesktopPlatform();
  }
}
```

## 验证检查清单

迁移后，验证：

- [ ] 应用在 Web 平台上成功启动
- [ ] Web 编译代码中没有剩余的 `Platform.environment` 调用
- [ ] 所有环境变量访问都有适当的默认值
- [ ] Desktop pet 功能在 Web 上正确禁用
- [ ] 路径解析在所有平台上工作
- [ ] Steam 检测在 Web 平台上跳过
- [ ] 开发模式检测在 Web 上工作
- [ ] 单元测试在所有平台上通过
- [ ] 集成测试在 Web 和原生平台上通过

## 性能影响

迁移应该对性能影响最小：

- **正面**: 环境变量缓存减少系统调用
- **正面**: 平台特定功能的延迟初始化
- **中性**: 抽象层增加的开销最小
- **正面**: Web 平台避免不必要的平台检查

## 回滚计划

如果出现问题，您可以临时回滚：

1. 在迁移期间将旧代码保留在注释中
2. 使用功能标志在旧实现和新实现之间切换
3. 逐步迁移 - 一次迁移一个服务

```dart
// 功能标志方法
String getEnvironmentVariable(String key) {
  if (useNewPlatformEnvironment) {
    return PlatformEnvironment.instance.getVariable(key);
  } else {
    // 旧实现（Web 不兼容）
    return Platform.environment[key];
  }
}
```

## 获取帮助

如果在迁移期间遇到问题：

1. 查看 Web 平台兼容性文档
2. 查看基于属性的测试以了解预期行为
3. 在 Web 和原生平台上测试
4. 提交 issue 并包含具体的错误消息和平台详细信息

## 后续步骤

完成迁移后：

1. 删除所有注释掉的旧代码
2. 更新 CI/CD 流水线以测试 Web 平台
3. 考虑添加 Web 特定功能
4. 为您的团队记录任何平台特定行为
