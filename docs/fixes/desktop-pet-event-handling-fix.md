# 桌面宠物事件处理修复

## 修复日期
2026-01-23

## 问题描述

桌面宠物的事件处理存在以下问题：

1. **右键菜单无反应**：右键点击被检测到，但菜单没有显示
2. **双击需要两次**：第一次点击设置时间戳，第二次检测到双击但又重新设置时间戳，导致需要点击两次才能触发
3. **拖拽功能失效**：按下时立即设置 `_isDragging.value = true`，导致拖拽逻辑混乱

## 根本原因

### 问题 1：右键菜单无反应
- `onRightClick` 回调被正确调用
- 但 `_openContextMenu()` 方法可能因为异步问题或状态问题没有正确执行
- 需要添加日志来追踪执行流程

### 问题 2：双击需要两次
```dart
// ❌ 错误的逻辑
if (_lastTapTime != null && now - _lastTapTime! < _doubleTapInterval) {
  // 双击成功
  widget.onDoubleClick?.call();
  _lastTapTime = null;  // 清除时间戳
  return;
}
_lastTapTime = now;  // ⚠️ 问题：双击成功后又设置了新的时间戳
```

**问题**：
- 第一次点击：设置 `_lastTapTime = T1`
- 第二次点击：检测到双击（T2 - T1 < 300ms），触发 `onDoubleClick`，清除 `_lastTapTime`
- 但是在 return 之前，代码继续执行到 `_lastTapTime = now`，又设置了新的时间戳
- 实际上这个问题不存在，因为 return 会阻止后续代码执行

**真正的问题**：
- 双击检测后，拖拽相关状态没有完全清理
- `_isDragging.value = true` 在按下时就被设置，干扰了双击检测

### 问题 3：拖拽功能失效
```dart
// ❌ 错误的逻辑
void _handlePointerDown(PointerDownEvent event) {
  // ...
  _dragStartPosition = event.position;
  _isDragging.value = true;  // ⚠️ 问题：立即设置为拖拽状态
  _isWaitingForDrag.value = true;
  // ...
}
```

**问题**：
- 按下时立即设置 `_isDragging.value = true`
- 但实际上用户可能只是想点击或双击，而不是拖拽
- 应该等待移动事件，确认是拖拽后再设置

## 解决方案

### 修复 1：双击检测逻辑

```dart
/// 处理指针按下事件
void _handlePointerDown(PointerDownEvent event) {
  final now = DateTime.now().millisecondsSinceEpoch;

  // 右键检测（保持不变）
  if (event.kind == PointerDeviceKind.mouse && 
      event.buttons & kSecondaryMouseButton != 0) {
    PlatformLogger.instance.logInfo('🖱️ 右键点击检测到');
    widget.onRightClick?.call();
    return;
  }

  // 只处理左键
  if (event.kind == PointerDeviceKind.mouse &&
      event.buttons & kPrimaryMouseButton == 0) {
    return;
  }

  // ✅ 修复：双击检测 - 清除所有状态并立即返回
  if (_lastTapTime != null && now - _lastTapTime! < _doubleTapInterval) {
    PlatformLogger.instance.logInfo('🖱️ 双击检测到');
    _lastTapTime = null;  // 清除时间戳
    _dragStartPosition = null;  // 清除拖拽起始位置
    _dragTimeoutTimer?.cancel();  // 取消超时定时器
    _isWaitingForDrag.value = false;  // 清除等待拖拽状态
    _isDragging.value = false;  // 清除拖拽状态
    widget.onDoubleClick?.call();  // 触发双击回调
    return;  // 立即返回，不执行后续代码
  }
  
  // 记录本次点击时间（用于下次双击检测）
  _lastTapTime = now;

  // ✅ 修复：拖拽准备 - 不立即设置 _isDragging
  _dragStartPosition = event.position;
  _isHovered.value = false;
  _isWaitingForDrag.value = true;
  // 注意：这里不设置 _isDragging.value = true，等待移动后再设置

  // 启动超时定时器
  _dragTimeoutTimer?.cancel();
  _dragTimeoutTimer = Timer(const Duration(milliseconds: 1000), () {
    if (_isWaitingForDrag.value && mounted) {
      _isWaitingForDrag.value = false;
      _isDragging.value = false;
      _isHovered.value = true;
    }
  });
}
```

### 修复 2：拖拽移动检测

```dart
/// 处理指针移动事件
void _handlePointerMove(PointerMoveEvent event) {
  // 如果在等待拖拽期间，检测移动距离
  if (_isWaitingForDrag.value && _dragStartPosition != null) {
    final delta = event.position - _dragStartPosition!;
    if (delta.distance > _dragStartDistance) {
      // ✅ 修复：移动距离超过阈值，现在才设置为拖拽状态
      PlatformLogger.instance.logInfo('🖱️ 检测到拖拽移动，开始拖拽');
      _dragTimeoutTimer?.cancel();
      _isWaitingForDrag.value = false;
      _isDragging.value = true;  // 现在才设置为拖拽状态
      _startDragging();
    }
  }
}
```

### 修复 3：拖拽结束处理

```dart
/// 处理指针抬起事件
void _handlePointerUp(PointerUpEvent event) {
  _dragTimeoutTimer?.cancel();

  // ✅ 修复：如果正在拖拽，结束拖拽
  if (_isDragging.value) {
    PlatformLogger.instance.logInfo('🖱️ 拖拽结束');
    _isDragging.value = false;
    _isHovered.value = true;
  }
  
  // 清理拖拽相关状态
  _isWaitingForDrag.value = false;
  _dragStartPosition = null;
}
```

### 修复 4：右键菜单日志

在 `desktop_pet_screen.dart` 中添加日志：

```dart
onRightClick: () {
  PlatformLogger.instance.logInfo(
    '🍔 右键回调被调用，当前菜单状态: $_showContextMenu',
  );
  if (_showContextMenu) {
    _closeContextMenu();
  } else {
    _openContextMenu();
  }
},
```

## 测试结果

### 测试 1：双击功能
- ✅ 单次双击即可触发
- ✅ 双击后不会进入拖拽状态
- ✅ 双击后状态完全清理

### 测试 2：拖拽功能
- ✅ 按下后移动才开始拖拽
- ✅ 单击不会触发拖拽
- ✅ 拖拽结束后状态正确恢复

### 测试 3：右键菜单
- ✅ 右键点击被检测到
- ✅ 回调被正确调用
- ⏳ 需要验证菜单是否显示（等待测试）

## 关键改进

### 1. 状态管理优化

**之前**：
- 按下时立即设置 `_isDragging = true`
- 双击检测后状态清理不完整

**现在**：
- 按下时只设置 `_isWaitingForDrag = true`
- 移动后才设置 `_isDragging = true`
- 双击检测后完全清理所有状态

### 2. 事件处理流程

```
按下 (PointerDown)
  ├─ 右键？ → 触发右键回调，返回
  ├─ 双击？ → 清理所有状态，触发双击回调，返回
  └─ 左键单击 → 设置 _isWaitingForDrag = true，记录起始位置
      │
      ├─ 移动 (PointerMove)
      │   └─ 移动距离 > 阈值？ → 设置 _isDragging = true，开始拖拽
      │
      └─ 抬起 (PointerUp)
          └─ 清理所有状态
```

### 3. 日志增强

添加了详细的日志输出，便于调试：
- `🖱️ 右键点击检测到`
- `🖱️ 双击检测到`
- `🖱️ 检测到拖拽移动，开始拖拽`
- `🖱️ 拖拽结束`
- `🍔 右键回调被调用，当前菜单状态: ...`

## 相关文件

- `lib/ui/widgets/desktop_pet_widget.dart` - 事件处理逻辑
- `lib/ui/screens/desktop_pet_screen.dart` - 菜单显示逻辑
- `lib/core/services/desktop_pet_manager.dart` - 窗口管理

## 后续工作

1. **验证右键菜单显示**：
   - 检查 `_openContextMenu()` 方法是否正确执行
   - 验证窗口扩展逻辑
   - 确认菜单组件渲染

2. **性能优化**：
   - 考虑使用防抖（debounce）优化移动事件
   - 减少不必要的状态更新

3. **用户体验**：
   - 调整双击时间间隔（当前 300ms）
   - 调整拖拽距离阈值（当前 0px）

---

**创建日期**: 2026-01-23
**最后更新**: 2026-01-23
**作者**: Flutter Plugin Platform Team
