# 桌宠拖拽和透明度问题修复

**问题**:
1. 桌宠拖拽时，鼠标会先位移一段位置，然后才能移动
2. 拖拽时，有时不会触发拖拽特效，不展示为黄色和"拖拽中"
3. 变为桌宠时，会先保留背景图片，再变透明
4. 拖拽结束后，宠物状态不会恢复（仍然显示为拖拽中）

**解决日期**: 2026-01-22

---

## 问题 1 & 2: 拖拽延迟和状态不显示

### 问题现象

1. **拖拽延迟**: 鼠标按下后需要移动一段距离才能开始拖拽
2. **状态不显示**: 拖拽时 `_isDragging` 状态有时不更新，导致不显示黄色和"拖拽中"文字

### 根本原因

1. **使用 `onPanStart`**: `GestureDetector` 的 `onPanStart` 需要手势移动一定距离（默认约 10 像素）才会触发
2. **状态更新时机**: `_isDragging` 状态更新和 `windowManager.startDragging()` 的顺序可能导致 UI 不及时刷新

### 解决方案

**文件**: `lib/ui/widgets/desktop_pet_widget.dart`

**关键改进**: 使用 `onPanDown` 替代 `onPanStart`

**修改前**:
```dart
onPanStart: _isInteractionsEnabled
    ? (details) {
        setState(() {
          _isDragging = true;
        });
        windowManager.startDragging();
      }
    : null,
```

**修改后**:
```dart
onPanDown: _isInteractionsEnabled
    ? (details) {
        // 立即更新拖拽状态，确保 UI 响应
        setState(() {
          _isDragging = true;
        });
        // 使用原生窗口拖拽 - 鼠标按下时立即开始
        windowManager.startDragging();
      }
    : null,
```

---

## 问题 4: 拖拽后状态不重置

### 问题现象

拖拽结束后，宠物状态不会恢复，仍然显示为拖拽中（黄色背景和"拖拽中"文字）。

### 根本原因

**`windowManager.startDragging()` 阻止事件**: 系统级拖拽会接管鼠标事件，导致 `GestureDetector` 的 `onPanEnd` 无法触发，拖拽状态无法重置。

### 解决方案

**文件**: `lib/ui/widgets/desktop_pet_widget.dart`

**关键改进**: 使用 `Listener` 监听全局 `onPointerUp` 事件

**修改前**:
```dart
child: GestureDetector(
  onPanDown: _isInteractionsEnabled
      ? (details) {
          setState(() {
            _isDragging = true;
          });
          windowManager.startDragging();
        }
      : null,
  onPanEnd: _isInteractionsEnabled
      ? (_) {
          setState(() {
            _isDragging = false;
          });
        }
      : null,
  child: MouseRegion(...),
)
```

**修改后**:
```dart
child: Listener(
  onPointerUp: (_) {
    // 监听全局鼠标抬起事件，确保拖拽状态正确重置
    // windowManager.startDragging() 会阻止 GestureDetector 的 onPanEnd
    if (_isInteractionsEnabled && _isDragging) {
      setState(() {
        _isDragging = false;
      });
    }
  },
  child: GestureDetector(
    onDoubleTap: _isInteractionsEnabled ? widget.onDoubleClick : null,
    onSecondaryTap: _isInteractionsEnabled ? widget.onRightClick : null,
    onPanDown: _isInteractionsEnabled
        ? (details) {
            // 立即更新拖拽状态，确保 UI 响应
            setState(() {
              _isDragging = true;
            });
            // 使用原生窗口拖拽 - 鼠标按下时立即开始
            windowManager.startDragging();
          }
        : null,
    child: MouseRegion(...),
  ),
)
```

### 关键改进

| 改进 | 说明 |
|------|------|
| **使用 `Listener`** | 监听全局鼠标事件，不被系统拖拽阻止 |
| **`onPointerUp`** | 鼠标抬起时触发，无论是否发生了拖拽 |
| **状态检查** | 检查 `_isDragging` 避免不必要的状态更新 |

### Listener vs GestureDetector

| 特性 | Listener | GestureDetector |
|------|----------|-----------------|
| **事件级别** | 低级别（原始指针事件） | 高级别（手势识别） |
| **事件阻止** | 不被系统拖拽阻止 | 会被系统拖拽阻止 |
| **适用场景** | 需要监听所有指针事件 | 需要识别特定手势 |

---

## 问题 3: 透明度过渡闪烁

### 问题现象

变为桌宠时，会先显示背景图片（非透明），然后才变透明，造成视觉闪烁。

### 根本原因

**修改前的代码流程**:
```dart
// 1. 设置透明度为 0
await windowManager.setOpacity(0.0);

// 2. 显示窗口
await windowManager.show();

// 3. 延迟 50ms
await Future.delayed(const Duration(milliseconds: 50));

// 4. 设置实际透明度
await windowManager.setOpacity(_petPreferences['opacity'] ?? 1.0);
```

**问题**:
- 步骤 1-3 之间，窗口虽然是透明的，但 Flutter 可能还未完成透明内容渲染
- 步骤 4 设置实际透明度时，窗口可能短暂显示非透明内容

### 解决方案

**文件**: `lib/core/services/desktop_pet_manager.dart`

**关键改进**: 使用 `waitUntilReadyToShow` 确保窗口准备好后才显示

**修改后的代码**:
```dart
// 使用 waitUntilReadyToShow 确保窗口准备好后才显示
// 注意：不要在 WindowOptions 中设置 titleBarStyle，会与 setAsFrameless() 冲突
final targetOpacity = _petPreferences['opacity'] ?? 1.0;
await windowManager.waitUntilReadyToShow(
  WindowOptions(
    size: petWindowSize,
    center: false,
    backgroundColor: const Color(0x00000000),
  ),
  () async {
    // 窗口准备就绪后，先设置位置和透明度，再显示窗口
    await windowManager.setPosition(Offset(position['x'], position['y']));
    await windowManager.setOpacity(targetOpacity);
    await windowManager.show();
    await windowManager.focus();
  },
);
```

### 关键改进

| 改进 | 说明 |
|------|------|
| **使用 `waitUntilReadyToShow`** | 确保窗口完全准备好后才显示 |
| **提前设置目标透明度** | 在 `show()` 之前就设置好透明度 |
| **移除延迟** | 不再需要 50ms 的延迟等待 |
| **避免冲突** | `WindowOptions` 中不设置 `titleBarStyle`，避免与 `setAsFrameless()` 冲突 |

### waitUntilReadyToShow 优势

1. **避免闪烁**: 窗口在完全准备好后才显示
2. **性能优化**: 减少不必要的重绘和状态切换
3. **用户体验**: 用户看到的是最终状态，没有中间过程

---

## 验证清单

修复后，请确认以下效果：

### 拖拽功能
- ✅ 鼠标按下时立即开始拖拽（无需移动）
- ✅ 拖拽时宠物变为橙色（黄色）背景
- ✅ 拖拽时显示"拖拽中"文字
- ✅ 鼠标光标变为抓取状态（grabbing）
- ✅ **松开鼠标后状态恢复正常**（新增修复）

### 透明度过渡
- ✅ 切换到桌宠模式时，直接显示透明窗口
- ✅ 没有背景闪烁
- ✅ 没有中间过渡状态
- ✅ 窗口平滑出现

### 窗口属性
- ✅ 边框完全移除
- ✅ 阴影完全移除
- ✅ 拖拽功能正常
- ✅ 置顶功能正常

---

## 技术要点

### 1. GestureDetector 事件选择

**原则**:
- 需要立即响应 → 使用 `onPanDown`
- 需要区分点击和拖拽 → 使用 `onPanStart`

**示例**:
```dart
GestureDetector(
  onPanDown: (details) {
    // 鼠标按下时立即触发
    // 适用于：窗口拖拽、游戏控制
  },
  onPanStart: (details) {
    // 移动后才触发
    // 适用于：绘图、滑动操作
  },
)
```

### 2. Listener 监听全局指针事件

**原则**:
- 当 `GestureDetector` 事件被系统操作阻止时
- 使用 `Listener` 监听低级别指针事件

**示例**:
```dart
Listener(
  onPointerUp: (_) {
    // 无论是否发生拖拽，鼠标抬起时都会触发
    // 适用于：重置拖拽状态、监听全局鼠标事件
  },
  child: GestureDetector(...),
)
```

### 3. 状态更新顺序

**原则**:
- UI 状态更新 → 原生操作调用
- 确保 `setState` 在异步操作之前

**示例**:
```dart
// ✅ 正确
setState(() {
  _isDragging = true;  // 先更新 UI 状态
});
windowManager.startDragging();  // 再执行原生操作

// ❌ 错误
windowManager.startDragging();  // 原生操作可能优先执行
setState(() {
  _isDragging = true;
});
```

### 4. 窗口显示时机

**原则**:
- 使用 `waitUntilReadyToShow` 而非 `show()` + 延迟
- 在回调中设置最终状态
- 避免在 `WindowOptions` 中设置与前面调用冲突的属性

**示例**:
```dart
// ✅ 正确 - 使用 waitUntilReadyToShow
await windowManager.waitUntilReadyToShow(
  WindowOptions(
    size: petWindowSize,
    backgroundColor: Colors.transparent,
    // 不设置 titleBarStyle，避免与 setAsFrameless() 冲突
  ),
  () async {
    await windowManager.setOpacity(targetOpacity);
    await windowManager.show();
  },
);

// ❌ 错误 - show() + 延迟
await windowManager.show();
await Future.delayed(const Duration(milliseconds: 50));
await windowManager.setOpacity(targetOpacity);
```

---

## 相关文件

- `lib/ui/widgets/desktop_pet_widget.dart` - 拖拽逻辑修复
- `lib/core/services/desktop_pet_manager.dart` - 透明度过渡修复
- `lib/ui/screens/desktop_pet_screen.dart` - 桌宠界面

## 参考资料

- [Flutter Listener 文档](https://api.flutter.dev/flutter/widgets/Listener-class.html)
- [Flutter GestureDetector 文档](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [window_manager waitUntilReadyToShow 文档](https://pub.dev/documentation/window_manager/latest/window_manager/WindowManager-class.html)
- [WINDOW_BORDER_REMOVAL.md](./WINDOW_BORDER_REMOVAL.md) - 边框移除解决方案

---

## 版本信息

- **修改日期**: 2026-01-22
- **window_manager**: 0.5.1
- **Flutter**: 3.27+
- **平台**: Windows 10/11
