# 桌宠窗口边框移除解决方案

**问题**: Windows 桌面宠物窗口存在 1 像素系统边框，使用 `setTitleBarStyle(TitleBarStyle.hidden)` 无法移除。

**解决方案**: 使用 `setAsFrameless()` 方法

## 问题描述

桌面宠物窗口在 Windows 上存在以下问题：
1. 使用 `setTitleBarStyle(TitleBarStyle.hidden)` 只能隐藏标题栏
2. **1 像素系统边框仍然存在**（outline border）
3. `setHasShadow(false)` 在 Windows 上不生效

## 根本原因

根据 window_manager 插件官方文档：
- `setTitleBarStyle(TitleBarStyle.hidden)` 只隐藏标题栏，但保留窗口框架
- Windows 系统的 1 像素边框是窗口框架的一部分
- `setHasShadow(false)` 只有在窗口是**真正无边框**时才会生效

## 解决方案

### 使用 `setAsFrameless()` 方法

**文件**: `lib/core/services/desktop_pet_manager.dart`

**修改位置**: `_createDesktopPetWindow()` 方法

**修改前**:
```dart
await windowManager.ensureInitialized();

// 只隐藏标题栏，边框仍然存在
await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

await windowManager.setSize(petWindowSize);
await windowManager.setPosition(Offset(position['x'], position['y']));
```

**修改后**:
```dart
await windowManager.ensureInitialized();

// 移除整个窗口框架（包括标题栏和轮廓边框）
await windowManager.setAsFrameless();

await windowManager.setSize(petWindowSize);
await windowManager.setPosition(Offset(position['x'], position['y']));
```

### 关键区别

| 方法 | 效果 | 边框移除 | 阴影移除 |
|------|------|---------|---------|
| `setTitleBarStyle(TitleBarStyle.hidden)` | 只隐藏标题栏 | ❌ | ❌ |
| `setAsFrameless()` | 移除整个窗口框架 | ✅ | ✅ |

## API 文档参考

根据 [window_manager 官方文档](https://pub.dev/documentation/window_manager/latest/window_manager/WindowManager-class.html):

> **setAsFrameless()** → Future<void>
>
> You can call this to remove the window frame (title bar, **outline border**, etc), which is basically everything except the Flutter view, also can call setTitleBarStyle(TitleBarStyle.normal) or setTitleBarStyle(TitleBarStyle.hidden) to restore it.

> **setHasShadow()** → Future<void>
>
> Sets whether the window should have a shadow. On Windows, **doesn't do anything unless window is frameless**.

## 验证清单

使用 `setAsFrameless()` 后，确认以下效果：
- ✅ 标题栏完全隐藏
- ✅ **1 像素系统边框已移除**
- ✅ 窗口阴影已移除
- ✅ 拖拽功能正常工作
- ✅ 透明背景正常显示

## 版本信息

- **window_manager**: 0.5.1
- **Flutter**: 3.27+
- **平台**: Windows 10/11
- **解决日期**: 2026-01-22

## 相关文件

- `lib/core/services/desktop_pet_manager.dart` - 桌宠窗口管理
- `lib/ui/screens/desktop_pet_screen.dart` - 桌宠界面
- `lib/ui/widgets/desktop_pet_widget.dart` - 桌宠组件

## 注意事项

1. **必须在 `setSize()` 之前调用** `setAsFrameless()`
2. 调用 `setAsFrameless()` 后，如需恢复窗口框架，使用 `setTitleBarStyle(TitleBarStyle.normal)`
3. 此方法会影响窗口行为，需要确保拖拽功能使用 `windowManager.startDragging()`

## 参考资料

- [window_manager API 文档](https://pub.dev/documentation/window_manager/latest/window_manager/WindowManager-class.html)
- [GitHub Issue #108 - Window Effects Bug](https://github.com/leanflutter/window_manager/issues/108)
- [Frameless Window 实现讨论](https://github.com/flutter/flutter/issues/71042)
