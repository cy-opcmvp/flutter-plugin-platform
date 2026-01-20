# AI 编码规则 - 错误处理规范

> 📋 **本文档定义了项目中所有错误处理必须遵守的规范，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有 Dart/Flutter 代码

---

## 🎯 核心原则

### 1. 用户友好
错误信息应该清晰、有用、可操作。

### 2. 早期发现
尽可能在早期发现和处理错误（输入验证、类型检查）。

### 3. 适当处理
根据错误类型采取适当的处理策略（重试、回退、提示用户）。

### 4. 记录完整
错误日志应该包含足够的上下文信息。

---

## 🏷️ 异常类型使用

### Dart 内置异常

| 异常类型 | 使用场景 | 示例 |
|---------|---------|------|
| **ArgumentError** | 参数验证失败 | `ArgumentError.value(value, 'name', '不能为空')` |
| **StateError** | 对象状态错误 | `StateError('已释放')` |
| **RangeError** | 范围越界 | `RangeError.range(i, 0, length)` |
| **UnsupportedError** | 不支持的操作 | `UnsupportedError('此方法未实现')` |
| **FormatException** | 格式错误 | `FormatException('无效的邮箱格式')` |

---

### 自定义异常

#### 项目异常基类

```dart
/// 应用异常基类
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return '$code: $message';
    }
    return message;
  }
}
```

#### 具体异常类

```dart
/// 网络请求异常
class NetworkException extends AppException {
  final int? statusCode;
  final String? response;

  const NetworkException(
    super.message, {
    this.statusCode,
    this.response,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.requestFailed({
    required String url,
    int? statusCode,
    String? response,
  }) {
    return NetworkException(
      '网络请求失败: $url',
      statusCode: statusCode,
      response: response,
      code: 'NETWORK_REQUEST_FAILED',
    );
  }
}

/// 数据解析异常
class ParseException extends AppException {
  final String? source;

  const ParseException(
    super.message, {
    this.source,
    super.code: 'PARSE_ERROR',
  });

  factory ParseException.json({
    required String source,
    required String expectedType,
    required Object? actualValue,
  }) {
    return ParseException(
      'JSON 解析失败: 期望 $expectedType，实际为 $actualValue',
      source: source,
    );
  }
}

/// 配置异常
class ConfigException extends AppException {
  const ConfigException(
    super.message, {
    super.code: 'CONFIG_ERROR',
  });

  factory ConfigException.missingRequired({
    required String key,
    required String section,
  }) {
    return ConfigException(
      '缺少必需的配置项: $section.$key',
    );
  }

  factory ConfigException.invalidValue({
    required String key,
    required String value,
    required String allowedValues,
  }) {
    return ConfigException(
      '配置项 $key 的值 "$value" 无效，允许的值: $allowedValues',
    );
  }
}

/// 插件异常
class PluginException extends AppException {
  final String? pluginId;

  const PluginException(
    super.message, {
    this.pluginId,
    super.code: 'PLUGIN_ERROR',
  });

  factory PluginException.notFound({
    required String pluginId,
  }) {
    return PluginException(
      '插件未找到: $pluginId',
      pluginId: pluginId,
    );
  }

  factory PluginException.loadFailed({
    required String pluginId,
    required String reason,
  }) {
    return PluginException(
      '插件加载失败: $pluginId - $reason',
      pluginId: pluginId,
    );
  }
}
```

---

## 🧹 输入验证

### 参数验证

```dart
/// 用户服务类
class UserService {
  /// 创建用户
  ///
  /// 抛出 [ArgumentError] 如果参数无效
  User createUser({
    required String name,
    required String email,
    required int age,
  }) {
    // 验证 name
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '不能为空');
    }
    if (name.length > 100) {
      throw ArgumentError.value(name, 'name', '长度不能超过 100');
    }

    // 验证 email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw const FormatException('无效的邮箱格式');
    }

    // 验证 age
    if (age < 0 || age > 150) {
      throw ArgumentError.value(age, 'age', '必须在 0-150 之间');
    }

    // 创建用户
    return User(
      name: name.trim(),
      email: email.trim(),
      age: age,
    );
  }
}
```

---

### 提前返回模式

```dart
// ✅ 正确：提前返回
void saveUserData(String name, String email) {
  // 验证输入
  if (name.isEmpty) {
    throw ArgumentError('name 不能为空');
  }
  if (email.isEmpty) {
    throw ArgumentError('email 不能为空');
  }
  if (!_isValidEmail(email)) {
    throw const FormatException('无效的邮箱格式');
  }

  // 保存数据（此时输入已验证）
  _database.save(name, email);
}

// ❌ 避免：深层嵌套
void saveUserData(String name, String email) {
  if (name.isNotEmpty) {
    if (email.isNotEmpty) {
      if (_isValidEmail(email)) {
        _database.save(name, email);
      } else {
        throw const FormatException('无效的邮箱格式');
      }
    } else {
      throw ArgumentError('email 不能为空');
    }
  } else {
    throw ArgumentError('name 不能为空');
  }
}
```

---

## 🌐 异步错误处理

### try-catch-finally

```dart
/// 加载用户数据
Future<User?> loadUser(String userId) async {
  try {
    // 1. 验证输入
    if (userId.isEmpty) {
      throw ArgumentError('userId 不能为空');
    }

    // 2. 从 API 获取
    final response = await _api.getUser(userId);

    // 3. 解析响应
    final user = User.fromJson(response);

    // 4. 返回结果
    return user;

  } on NetworkException {
    // 网络错误：记录日志并返回 null
    Log.error('网络请求失败', exception: e);
    return null;

  } on ParseException {
    // 解析错误：记录详细信息
    Log.error('数据解析失败', exception: e);
    rethrow;  // 重新抛出让上层处理

  } catch (e, stackTrace) {
    // 未预期的错误：记录详细信息
    Log.error(
      '加载用户失败',
      exception: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}
```

---

### 错误传播

```dart
/// 保存配置
Future<void> saveConfig(Config config) async {
  try {
    await _configService.save(config);
  } on ConfigException {
    // 配置错误：直接向上传播
    rethrow;

  } catch (e, stackTrace) {
    // 包装为更具体的异常
    throw ConfigException(
      '保存配置失败',
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
```

---

## 📱 用户错误提示

### UI 错误显示

```dart
/// 显示错误提示
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 用户操作处理
Future<void> _handleLogin(
  BuildContext context, {
  required String email,
  required String password,
}) async {
  try {
    // 尝试登录
    await _authService.login(email, password);

    // 成功
    _showSuccess(context, '登录成功');
  } on ArgumentError catch (e) {
    // 输入验证错误
    _showError(context, e.message);

  } on AuthException catch (e) {
    // 认证错误
    _showError(context, '登录失败: ${e.message}');

  } catch (e, stackTrace) {
    // 未预期错误
    Log.error('登录失败', exception: e, stackTrace: stackTrace);
    _showError(context, '登录失败，请稍后重试');
  }
}
```

---

### 错误信息规范

| 场景 | 错误信息格式 | 示例 |
|------|-------------|------|
| **参数验证** | `{参数} {错误描述}` | "用户名不能为空" |
| **网络请求** | `{操作}失败: {原因}` | "加载用户数据失败: 网络连接失败" |
| **文件操作** | `{文件} {操作}失败: {原因}` | "保存文件失败: 磁盘空间不足" |
| **权限错误** | "需要{权限}权限" | "需要存储权限才能保存图片" |
| **通用错误** | "{操作}失败，请{建议}" | "加载失败，请稍后重试" |

---

## 📊 错误日志规范

### 日志级别

```dart
/// 日志服务
class Log {
  /// 调试日志
  static void debug(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  /// 信息日志
  static void info(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, context: context);
  }

  /// 警告日志
  static void warning(
    String message, {
    Map<String, dynamic>? context,
    Object? exception,
  }) {
    _log(
      LogLevel.warning,
      message,
      context: context,
      exception: exception,
    );
  }

  /// 错误日志
  static void error(
    String message, {
    Map<String, dynamic>? context,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    // 实现日志记录
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('[$timestamp] [$level] $message');

    if (context != null && context.isNotEmpty) {
      buffer.writeln('Context: $context');
    }

    if (exception != null) {
      buffer.writeln('Exception: $exception');
    }

    if (stackTrace != null) {
      buffer.writeln('StackTrace:\n$stackTrace');
    }

    // 输出到控制台或日志服务
    debugPrint(buffer.toString());
  }
}

enum LogLevel { debug, info, warning, error }
```

---

### 日志记录示例

```dart
try {
  final user = await _api.getUser(userId);
  Log.info('用户加载成功', context: {'userId': userId});
} on NetworkException catch (e) {
  Log.error(
    '网络请求失败',
    context: {
      'userId': userId,
      'statusCode': e.statusCode,
    },
    exception: e,
  );
} catch (e, stackTrace) {
  Log.error(
    '加载用户失败',
    context: {'userId': userId},
    exception: e,
    stackTrace: stackTrace,
  );
}
```

---

## 🔄 错误恢复策略

### 重试机制

```dart
/// 带重试的网络请求
Future<T?> fetchWithRetry<T>({
  required Future<T> Function() request,
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      return await request();
    } on NetworkException catch (e) {
      attempts++;
      if (attempts >= maxRetries) {
        Log.error('请求失败，已达到最大重试次数', exception: e);
        return null;
      }
      Log.warning('请求失败，${delay.inSeconds}秒后重试 ($attempts/$maxRetries)');
      await Future.delayed(delay);
    }
  }

  return null;
}
```

---

### 降级策略

```dart
/// 加载数据（带降级）
Future<Data?> loadData() async {
  try {
    // 1. 尝试从网络加载
    return await _loadFromNetwork();
  } on NetworkException {
    Log.warning('网络加载失败，尝试从缓存加载');
    // 2. 降级：从缓存加载
    return await _loadFromCache();
  } catch (e, stackTrace) {
    Log.error('加载失败', exception: e, stackTrace: stackTrace);
    // 3. 最终降级：返回默认数据
    return _getDefaultData();
  }
}
```

---

## 🚫 禁止的错误处理

### 1. 禁止忽略异常

```dart
// ❌ 错误：忽略所有异常
try {
  riskyOperation();
} catch (e) {
  // 什么都不做
}

// ✅ 正确：至少记录日志
try {
  riskyOperation();
} catch (e, stackTrace) {
  Log.error('操作失败', exception: e, stackTrace: stackTrace);
}

// ✅ 或明确说明为什么忽略
try {
  riskyOperation();
} catch (e) {
  // 忽略预期的清理错误
  Log.debug('清理时的预期错误', exception: e);
}
```

---

### 2. 禁止捕获所有异常

```dart
// ❌ 错误：捕获所有异常
try {
  riskyOperation();
} catch (e) {
  // 无法区分错误类型
}

// ✅ 正确：捕获特定异常
try {
  riskyOperation();
} on NetworkException catch (e) {
  // 处理网络错误
} on ParseException catch (e) {
  // 处理解析错误
}
```

---

### 3. 禁止使用 print 输出错误

```dart
// ❌ 错误：使用 print 输出错误
try {
  riskyOperation();
} catch (e) {
  print('Error: $e');  // 错误信息丢失
}

// ✅ 正确：使用日志服务
try {
  riskyOperation();
} catch (e, stackTrace) {
  Log.error('操作失败', exception: e, stackTrace: stackTrace);
}
```

---

## ✅ 检查清单

### 错误处理检查

- [ ] 所有公共方法都有输入验证
- [ ] 异常类型使用正确
- [ ] 异常信息清晰有用
- [ ] 错误日志包含足够上下文
- [ ] 异步操作有错误处理
- [ ] 用户看到友好的错误提示
- [ ] 没有忽略异常（除非有明确原因）

---

## 📚 参考资源

### 官方文档
- [Dart 异常处理](https://dart.dev/guides/libraries/library-tour#exceptions)
- [Flutter 错误处理](https://flutter.dev/docs/cookbook/maintenance/error-reporting)

### 相关规范
- [代码风格规范](./CODE_STYLE_RULES.md)
- [测试规范](./TESTING_RULES.md)
- [日志规范](./LOGGING_RULES.md)

---

## 🎯 快速参考

| 场景 | 异常类型 | 处理方式 |
|------|---------|---------|
| **参数验证** | `ArgumentError` | 抛出异常 |
| **状态错误** | `StateError` | 抛出异常 |
| **网络错误** | `NetworkException` | 记录日志，返回 null 或重试 |
| **解析错误** | `ParseException` | 记录日志，向上传播 |
| **配置错误** | `ConfigException` | 记录日志，向上传播 |
| **用户错误** | UI 提示 | 显示友好提示，不抛异常 |

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 好的错误处理让应用更稳定！
