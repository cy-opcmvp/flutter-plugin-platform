# 日志级别使用指南

本文档说明应用中日志级别功能的使用方法和行为。

## 📊 日志级别说明

应用支持 4 个日志级别，按严重程度从低到高排列：

| 级别 | 说明 | 示例 |
|------|------|------|
| **DEBUG** | 调试信息，最详细的日志 | "窗口移动事件，更新位置记录" |
| **INFO** | 一般信息 | "桌面宠物已启动" |
| **WARNING** | 警告信息，但不影响运行 | "平台功能降级" |
| **ERROR** | 错误信息，影响功能 | "初始化失败" |

## 🎯 日志过滤规则

### Debug 模式（`flutter run`）

日志输出受**配置的日志级别**控制：

**配置为 `error`**：
```
❌ [ERROR] Error in context: ...
```
- 只显示 ERROR 级别

**配置为 `warning`**：
```
⚠️ [WARNING] Feature unavailable: ...
❌ [ERROR] Error in context: ...
```
- 显示 WARNING 和 ERROR

**配置为 `info`**（默认）：
```
[INFO] Desktop pet started
⚠️ [WARNING] Feature unavailable: ...
❌ [ERROR] Error in context: ...
```
- 显示 INFO、WARNING 和 ERROR

**配置为 `debug`**：
```
[DEBUG] Window move event
[INFO] Desktop pet started
⚠️ [WARNING] Feature unavailable: ...
❌ [ERROR] Error in context: ...
```
- 显示所有日志

### Release 模式（生产构建）

**不受配置影响**，固定只显示 WARNING 和 ERROR：

```
⚠️ [WARNING] Feature unavailable: ...
❌ [ERROR] Error in context: ...
```

这是为了保护性能和用户体验。

## ⚙️ 如何修改日志级别

### 方法 1：通过应用界面

1. 打开应用
2. 进入 **设置** → **高级设置**
3. 点击 **日志级别**
4. 选择想要的级别（DEBUG/INFO/WARNING/ERROR）

### 方法 2：直接修改配置文件

编辑配置文件（通常是 `config.json`）：

```json
{
  "advanced": {
    "logLevel": "info"
  }
}
```

## 🔍 调试模式 vs 日志级别

### 调试模式（Debug Mode）

- **位置**：设置 → 高级设置 → 调试模式
- **作用**：控制是否输出详细日志
- **开关**：布尔值（开/关）

**调试模式关闭时**：
- 只显示 ERROR 和 WARNING 级别（即使在 Debug 构建中）

**调试模式开启时**：
- 根据"日志级别"设置输出相应的日志

### 日志级别（Log Level）

- **位置**：设置 → 高级设置 → 日志级别
- **作用**：控制日志的详细程度
- **选项**：DEBUG/INFO/WARNING/ERROR

### 两者的关系

```
调试模式 = 主开关
日志级别 = 细节控制

┌─────────────────┬──────────────────┬─────────────────┐
│ 调试模式        │ 日志级别         │ 实际输出        │
├─────────────────┼──────────────────┼─────────────────┤
│ 关闭            │ 任意             │ ERROR + WARNING │
├─────────────────┼──────────────────┼─────────────────┤
│ 开启            │ ERROR            │ ERROR          │
├─────────────────┼──────────────────┼─────────────────┤
│ 开启            │ WARNING          │ WARNING + ERROR │
├─────────────────┼──────────────────┼─────────────────┤
│ 开启            │ INFO             │ ALL            │
├─────────────────┼──────────────────┼─────────────────┤
│ 开启            │ DEBUG            │ ALL            │
└─────────────────┴──────────────────┴─────────────────┘
```

## 📝 使用建议

### 开发阶段
- **推荐设置**：调试模式开启 + INFO 级别
- **优点**：看到关键信息，不会被 DEBUG 日志淹没
- **何时使用 DEBUG 级别**：排查特定问题时

### 测试阶段
- **推荐设置**：调试模式开启 + WARNING 级别
- **优点**：只看到潜在问题和错误

### 生产环境
- **推荐设置**：调试模式关闭
- **优点**：只记录错误和警告，不影响性能

## 💡 常见问题

### Q: 为什么修改日志级别后没有立即生效？

A: 日志级别是**实时生效**的，不需要重启应用。如果没看到效果，请确认：
1. 调试模式是否已开启
2. 使用的日志方法是否正确（`logInfo()` 还是 `logDebug()`）

### Q: Release 模式下能否看到 DEBUG 日志？

A: **不能**。Release 模式固定只显示 WARNING 和 ERROR，这是为了保护性能。如果需要调试，请使用 Debug 构建或添加 `--profile` 参数。

### Q: 为什么设置了 ERROR 级别还能看到 WARNING？

A: WARNING 的严重程度低于 ERROR，按照日志过滤规则，ERROR 级别只显示 ERROR。如果看到 WARNING，可能是：
1. 配置保存失败
2. 读取配置失败
3. 使用了其他日志方法

### Q: 如何输出完全不受控制的日志？

A: 不要使用 `PlatformLogger`，直接使用 `print()` 或 `debugPrint()`。但不推荐这样做，因为这会破坏日志管理。

## 🔧 技术实现

### 日志级别枚举

```dart
enum LogLevel { debug, info, warning, error }
```

索引顺序：`debug (0) < info (1) < warning (2) < error (3)`

### 过滤逻辑

```dart
bool _shouldLog(LogLevel messageLevel) {
  final configLevel = _parseLogLevel(config.advanced.logLevel);

  // 只有当消息级别 >= 配置级别时才输出
  return messageLevel.index >= configLevel.index;
}
```

### 使用示例

```dart
// 输出调试日志
PlatformLogger.instance.logDebug('详细调试信息');

// 输出信息日志
PlatformLogger.instance.logInfo('应用已启动');

// 输出警告日志
PlatformLogger.instance.logWarning('配置文件未找到，使用默认值');

// 输出错误日志
PlatformLogger.instance.logError('初始化失败', exception, stackTrace);
```

## 📚 相关文档

- [错误处理规范](../../.claude/rules/ERROR_HANDLING_RULES.md)
- [性能优化规范](../../.claude/rules/PERFORMANCE_OPTIMIZATION_RULES.md)
- [平台服务文档](../platform-services/README.md)

---

**最后更新**: 2026-01-24
**版本**: v0.4.3
