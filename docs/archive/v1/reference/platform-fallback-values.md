# Platform Fallback Values 参考手册

## 概述

本文档提供了 `PlatformEnvironment` 服务在环境变量不可用或在支持环境变量访问的平台（如 Web 浏览器）上运行时使用的所有回退值的综合参考。

## 环境变量回退值

### 系统路径

#### 主目录变量

| 变量 | Web 平台 | Windows 回退值 | macOS 回退值 | Linux 回退值 |
|------|---------|---------------|--------------|-------------|
| `HOME` | `/browser-home` | `C:\Users\Default` | `/Users/Shared` | `/home/user` |
| `USERPROFILE` | `/browser-home` | `C:\Users\Default` | `/Users/Shared` | `/home/user` |
| `HOMEPATH` | `/browser-home` | `\Users\Default` | `/Users/Shared` | `/home/user` |

#### 应用数据目录

| 变量 | Web 平台 | Windows 回退值 | macOS 回退值 | Linux 回退值 |
|------|---------|---------------|--------------|-------------|
| `APPDATA` | `/browser-appdata` | `C:\Users\Default\AppData\Roaming` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `LOCALAPPDATA` | `/browser-appdata` | `C:\Users\Default\AppData\Local` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `XDG_DATA_HOME` | `/browser-appdata` | `C:\Users\Default\AppData\Local` | `/Users/Shared/Library` | `/home/user/.local/share` |
| `XDG_CONFIG_HOME` | `/browser-config` | `C:\Users\Default\AppData\Roaming` | `/Users/Shared/Library/Preferences` | `/home/user/.config` |

#### 临时目录

| 变量 | Web 平台 | Windows 回退值 | macOS 回退值 | Linux 回退值 |
|------|---------|---------------|--------------|-------------|
| `TEMP` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |
| `TMP` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |
| `TMPDIR` | `/browser-temp` | `C:\Temp` | `/tmp` | `/tmp` |

### 系统配置

#### 路径变量

| 变量 | Web 平台 | Windows 回退值 | macOS 回退值 | Linux 回退值 |
|------|---------|---------------|--------------|-------------|
| `PATH` | `/usr/bin:/bin` | `C:\Windows\System32;C:\Windows` | `/usr/bin:/bin:/usr/local/bin` | `/usr/bin:/bin:/usr/local/bin` |
| `PATHEXT` | `.exe;.bat;.cmd` | `.COM;.EXE;.BAT;.CMD;.VBS;.JS` | N/A | N/A |

#### 用户信息

| 变量 | Web 平台 | Windows 回退值 | macOS 回退值 | Linux 回退值 |
|------|---------|---------------|--------------|-------------|
| `USER` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |
| `USERNAME` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |
| `LOGNAME` | `browser-user` | `DefaultUser` | `SharedUser` | `user` |

### 应用特定变量

#### Steam 集成

| 变量 | Web 平台 | 所有原生平台 |
|------|---------|-------------|
| `STEAM_PATH` | `null` | `null`（动态检测） |
| `STEAMAPPS` | `null` | `null`（动态检测） |
| `STEAM_COMPAT_DATA_PATH` | `null` | `null`（动态检测） |

#### 开发环境

| 变量 | Web 平台 | 所有原生平台 |
|------|---------|-------------|
| `DEVELOPMENT_MODE` | `null` | `null`（从其他指示器检测） |
| `DEBUG` | `null` | `null`（从其他指示器检测） |
| `FLUTTER_TEST` | `null` | `null`（从测试框架检测） |
| `NODE_ENV` | `production` | `null`（动态检测） |

#### 构建和编译

| 变量 | Web 平台 | 所有原生平台 |
|------|---------|-------------|
| `FLUTTER_ROOT` | `null` | `null`（从 SDK 检测） |
| `DART_SDK` | `null` | `null`（从 SDK 检测） |
| `PUB_CACHE` | `null` | 平台特定默认值 |

## 路径解析方法

### PlatformEnvironment 路径方法

#### getHomePath()

**Web 平台**: `/browser-home`

**原生平台**:
- Windows: `%USERPROFILE%` → `C:\Users\Default`
- macOS: `$HOME` → `/Users/Shared`
- Linux: `$HOME` → `/home/user`

```dart
String getHomePath() {
  if (isWeb) return '/browser-home';

  if (Platform.isWindows) {
    return getVariable('USERPROFILE') ?? 'C:\\Users\\Default';
  } else {
    return getVariable('HOME') ?? (Platform.isMacOS ? '/Users/Shared' : '/home/user');
  }
}
```

#### getDocumentsPath()

**Web 平台**: `/browser-documents`

**原生平台**:
- Windows: `%USERPROFILE%\Documents` → `C:\Users\Default\Documents`
- macOS: `$HOME/Documents` → `/Users/Shared/Documents`
- Linux: `$HOME/Documents` → `/home/user/Documents`

```dart
String getDocumentsPath() {
  if (isWeb) return '/browser-documents';

  final home = getHomePath();
  return '$home${Platform.isWindows ? '\\Documents' : '/Documents'}';
}
```

#### getTempPath()

**Web 平台**: `/browser-temp`

**原生平台**:
- Windows: `%TEMP%` → `C:\Temp`
- macOS: `$TMPDIR` → `/tmp`
- Linux: `$TMPDIR` → `/tmp`

```dart
String getTempPath() {
  if (isWeb) return '/browser-temp';

  return getVariable('TEMP') ??
         getVariable('TMP') ??
         getVariable('TMPDIR') ??
         (Platform.isWindows ? 'C:\\Temp' : '/tmp');
}
```

#### getAppDataPath()

**Web 平台**: `/browser-appdata`

**原生平台**:
- Windows: `%APPDATA%` → `C:\Users\Default\AppData\Roaming`
- macOS: `$HOME/Library` → `/Users/Shared/Library`
- Linux: `$XDG_DATA_HOME` → `/home/user/.local/share`

```dart
String getAppDataPath() {
  if (isWeb) return '/browser-appdata';

  if (Platform.isWindows) {
    return getVariable('APPDATA') ?? 'C:\\Users\\Default\\AppData\\Roaming';
  } else if (Platform.isMacOS) {
    return '${getHomePath()}/Library';
  } else {
    return getVariable('XDG_DATA_HOME') ?? '${getHomePath()}/.local/share';
  }
}
```

## Web 平台特定行为

### 浏览器存储集成

Web 平台使用浏览器存储 API 代替文件系统路径：

| 路径类型 | 浏览器存储 | 回退行为 |
|---------|-----------|---------|
| Home | localStorage | 跨会话持久化 |
| Documents | localStorage | 跨会话持久化 |
| Temp | sessionStorage | 标签关闭时清除 |
| AppData | localStorage | 跨会话持久化 |

### URL 参数覆盖

Web 平台可以使用 URL 参数覆盖默认值：

```javascript
// URL: https://app.example.com/?debug=true&user=testuser
// 结果：
// - DEBUG 环境变量: 'true'
// - USER 环境变量: 'testuser'
```

实现：
```dart
String? _getWebEnvironmentVariable(String key) {
  if (!kIsWeb) return null;

  // 首先检查 URL 参数
  final uri = Uri.base;
  if (uri.queryParameters.containsKey(key.toLowerCase())) {
    return uri.queryParameters[key.toLowerCase()];
  }

  // 检查 localStorage
  try {
    return html.window.localStorage[key];
  } catch (e) {
    return null;
  }
}
```

## 平台能力默认值

### Web 平台的 PlatformCapabilities

```dart
PlatformCapabilities.forWeb() {
  return PlatformCapabilities(
    supportsEnvironmentVariables: false,
    supportsFileSystem: false,
    supportsSteamIntegration: false,
    supportsNativeProcesses: false,
    supportsDesktopPet: false,
    supportsAlwaysOnTop: false,
    supportsSystemTray: false,
    supportsWindowManagement: false,
    supportsMultipleWindows: false,
    supportsClipboard: true, // 有限的浏览器剪贴板访问
    supportsNotifications: true, // 浏览器通知
    supportsLocalStorage: true,
    supportsSessionStorage: true,
  );
}
```

### 原生平台的 PlatformCapabilities

```dart
PlatformCapabilities.forNative() {
  return PlatformCapabilities(
    supportsEnvironmentVariables: true,
    supportsFileSystem: true,
    supportsSteamIntegration: _detectSteamSupport(),
    supportsNativeProcesses: true,
    supportsDesktopPet: _isDesktopPlatform(),
    supportsAlwaysOnTop: _isDesktopPlatform(),
    supportsSystemTray: _detectSystemTraySupport(),
    supportsWindowManagement: _isDesktopPlatform(),
    supportsMultipleWindows: _isDesktopPlatform(),
    supportsClipboard: true,
    supportsNotifications: true,
    supportsLocalStorage: false, // 使用文件系统代替
    supportsSessionStorage: false,
  );
}
```

## 配置覆盖系统

### 环境变量优先级

1. **实际环境变量**（仅原生平台）
2. **URL 参数**（仅 Web 平台）
3. **localStorage 值**（仅 Web 平台）
4. **配置文件值**
5. **平台特定默认值**
6. **通用回退值**

### 配置文件格式

```json
{
  "platformDefaults": {
    "web": {
      "HOME": "/custom-browser-home",
      "USER": "web-user",
      "TEMP": "/custom-browser-temp"
    },
    "windows": {
      "HOME": "C:\\CustomUsers\\Default",
      "TEMP": "C:\\CustomTemp"
    },
    "macos": {
      "HOME": "/CustomUsers/Shared",
      "TEMP": "/custom-tmp"
    },
    "linux": {
      "HOME": "/custom-home/user",
      "TEMP": "/custom-tmp"
    }
  }
}
```

### 运行时覆盖 API

```dart
class PlatformEnvironment {
  // 为当前会话覆盖特定变量
  void setOverride(String key, String value) {
    _overrides[key] = value;
  }

  // 清除特定覆盖
  void clearOverride(String key) {
    _overrides.remove(key);
  }

  // 清除所有覆盖
  void clearAllOverrides() {
    _overrides.clear();
  }

  // 获取支持覆盖的变量
  String? getVariable(String key, {String? defaultValue}) {
    // 首先检查覆盖
    if (_overrides.containsKey(key)) {
      return _overrides[key];
    }

    // 继续正常解析...
  }
}
```

## 测试回退值

### 单元测试示例

```dart
group('Fallback Values', () {
  test('should return web defaults on web platform', () {
    // 模拟 Web 平台
    when(() => mockPlatformEnvironment.isWeb).thenReturn(true);

    expect(mockPlatformEnvironment.getHomePath(), equals('/browser-home'));
    expect(mockPlatformEnvironment.getTempPath(), equals('/browser-temp'));
  });

  test('should return platform-specific defaults on native', () {
    // 模拟 Windows 平台
    when(() => mockPlatformEnvironment.isWeb).thenReturn(false);
    when(() => Platform.isWindows).thenReturn(true);

    final home = mockPlatformEnvironment.getHomePath();
    expect(home, contains('Users\\Default'));
  });

  test('should handle missing environment variables gracefully', () {
    // 模拟缺失的环境变量
    when(() => mockPlatformEnvironment.getVariable('NONEXISTENT'))
        .thenReturn(null);

    final result = mockPlatformEnvironment.getVariable(
      'NONEXISTENT',
      defaultValue: 'fallback'
    );
    expect(result, equals('fallback'));
  });
});
```

### 基于属性的测试示例

```dart
import 'package:test/test.dart';

void main() {
  group('Platform Fallback Properties', () {
    test('all path methods return non-null values', () {
      final env = PlatformEnvironment.instance;

      // 属性: 路径方法从不返回 null
      expect(env.getHomePath(), isNotNull);
      expect(env.getDocumentsPath(), isNotNull);
      expect(env.getTempPath(), isNotNull);
      expect(env.getAppDataPath(), isNotNull);
    });

    test('web platform never accesses Platform.environment', () {
      // 如果 Web 平台尝试访问 Platform.environment，此测试将失败
      // 属性: Web 平台仅使用回退值
      if (kIsWeb) {
        final env = PlatformEnvironment.instance;
        expect(() => env.getVariable('ANY_KEY'), returnsNormally);
      }
    });
  });
}
```

## 性能考虑

### 缓存策略

```dart
class PlatformEnvironment {
  final Map<String, String?> _cache = {};
  final Map<String, String> _overrides = {};

  String? getVariable(String key, {String? defaultValue}) {
    // 首先检查缓存
    if (_cache.containsKey(key)) {
      return _cache[key] ?? defaultValue;
    }

    // 解析并缓存
    final value = _resolveVariable(key, defaultValue);
    _cache[key] = value;
    return value;
  }
}
```

### 延迟初始化

```dart
class PlatformEnvironment {
  late final bool _isWeb = kIsWeb;
  late final PlatformCapabilities _capabilities = _isWeb
    ? PlatformCapabilities.forWeb()
    : PlatformCapabilities.forNative();

  // 路径计算一次并缓存
  String? _homePath;
  String getHomePath() => _homePath ??= _computeHomePath();
}
```

## 安全考虑

### Web 平台安全

- 环境变量从不暴露给 Web 平台
- URL 参数在使用前进行清理
- localStorage 访问包装在 try-catch 块中
- 回退值中不使用敏感的默认值

### 原生平台安全

- 环境变量通过抽象层只读
- 回退值使用安全、非敏感的默认值
- 路径解析验证防止目录遍历
- 覆盖系统需要显式权限

## 故障排除

### 常见问题

**问题**: 原生平台出现意外的回退值
**解决方案**: 检查系统中是否实际设置了环境变量

**问题**: Web 平台不使用浏览器存储
**解决方案**: 验证浏览器支持 localStorage 且用户未禁用它

**问题**: 路径解析返回不正确的值
**解决方案**: 检查平台检测和环境变量可用性

### 调试工具

```dart
void debugFallbackValues() {
  final env = PlatformEnvironment.instance;

  print('平台: ${env.isWeb ? 'Web' : Platform.operatingSystem}');
  print('主目录: ${env.getHomePath()}');
  print('临时目录: ${env.getTempPath()}');
  print('应用数据: ${env.getAppDataPath()}');

  // 测试常见环境变量
  final testVars = ['HOME', 'USER', 'PATH', 'TEMP'];
  for (final variable in testVars) {
    final value = env.getVariable(variable);
    print('$variable: ${value ?? 'null (使用回退值)'}');
  }
}
```
