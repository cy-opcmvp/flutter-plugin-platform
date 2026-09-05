# 开机自启功能测试指南

## ⚠️ 重要提示

**开发阶段无法测试开机自启功能！**

### 原因
- `flutter run` 启动的应用依赖开发服务器
- 重启后开发服务器已关闭
- 即使启动 Debug exe，应用也无法正常运行

---

## ✅ 正确的测试步骤

### 1. 构建发布版本

```bash
# 清理旧的构建
flutter clean

# 构建 Windows 发布版本
flutter build windows --release
```

### 2. 找到发布版本

发布版本位于：
```
build\windows\x64\runner\Release\plugin_platform.exe
```

### 3. 测试运行（在当前会话）

直接运行 Release exe：
```bash
.\build\windows\x64\runner\Release\plugin_platform.exe
```

或双击 `plugin_platform.exe` 文件

### 4. 在应用中启用开机自启

1. 打开应用
2. 进入 **设置** → **功能设置**
3. 启用 **开机自启** 开关

### 5. 验证注册表

运行诊断工具：
```bash
dart tools/check_autostart.dart
```

应该看到：
```
[✓] 找到注册表项
[✓] 可执行文件存在
可执行文件路径: D:\flutter-plugin-platform\build\windows\x64\runner\Release\plugin_platform.exe
```

### 6. 重启电脑测试

重启后，应用应该自动启动

---

## 🔧 改进建议

### 在应用中添加提示

在用户启用开机自启时，检测是否为开发模式：

```dart
// 检查是否为开发模式
final isDebug = bool.fromEnvironment('dart.vm.product') == false;

if (isDebug) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('开发模式检测'),
      content: Text('当前运行的是开发版本，重启后无法正常启动。\n\n'
          '请使用以下步骤测试开机自启功能：\n'
          '1. 运行：flutter build windows --release\n'
          '2. 运行 build\\windows\\x64\\runner\\Release\\plugin_platform.exe\n'
          '3. 在发布版本中启用开机自启'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('知道了'),
        ),
      ],
    ),
  );
  return;
}
```

### 添加环境检测

```dart
bool get isRunningFromBuild {
  // 检查可执行文件路径
  final exePath = Platform.resolvedExecutable;
  return exePath.contains('Release') || exePath.contains('release');
}
```

---

## 📋 总结

| 运行方式 | 能否测试开机自启 | 原因 |
|---------|----------------|------|
| `flutter run` | ❌ 不能 | 依赖开发服务器 |
| Debug exe | ❌ 不能 | 缺少运行时环境 |
| **Release exe** | ✅ 可以 | 独立可执行文件 |

---

## 🎯 快速命令

```bash
# 完整的测试流程
flutter clean
flutter build windows --release
.\build\windows\x64\runner\Release\plugin_platform.exe
# 然后在应用中启用开机自启
dart tools/check_autostart.dart  # 验证
# 重启电脑测试
```
