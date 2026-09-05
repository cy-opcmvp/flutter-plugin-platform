# 桌面宠物可扩展菜单功能

## 功能概述

桌面宠物的右键菜单现在可以**超越窗口范围**显示，通过动态扩大窗口来容纳菜单内容。

## 实现原理

### 核心思路

由于 Flutter 的限制，无法直接创建独立的子窗口。我们采用了一个实用的方案：

1. **显示菜单时**：临时扩大窗口以容纳菜单
2. **关闭菜单时**：恢复窗口到原始宠物大小（120x120）

### 技术实现

#### 1. 智能菜单定位

```dart
/// 计算菜单在屏幕上的绝对位置
Offset _calculateMenuScreenPosition(Size screenSize) {
  // 根据宠物在屏幕的位置（左/右、上/下）
  // 智能选择菜单显示位置
  
  // 宠物在左边 → 菜单显示在右边
  // 宠物在右边 → 菜单显示在左边
  // 宠物在上边 → 菜单显示在下边
  // 宠物在下边 → 菜单显示在上边
}
```

#### 2. 动态窗口扩展

```dart
Future<void> _openContextMenu() async {
  // 1. 计算菜单在屏幕上的位置
  final menuScreenPos = _calculateMenuScreenPosition(screenSize);
  
  // 2. 计算菜单相对于窗口的位置
  final menuRelativeX = menuScreenPos.dx - _windowPosition.dx;
  final menuRelativeY = menuScreenPos.dy - _windowPosition.dy;
  
  // 3. 计算需要的窗口大小
  final requiredWidth = menuRelativeX + kMenuWidth + 20;
  final requiredHeight = menuRelativeY + menuHeight + 20;
  
  // 4. 如果需要，扩大窗口
  if (requiredWidth > _petWindowSize.width || 
      requiredHeight > _petWindowSize.height) {
    await windowManager.setSize(Size(newWidth, newHeight));
  }
  
  // 5. 显示菜单
  setState(() => _showContextMenu = true);
}
```

#### 3. 窗口恢复

```dart
Future<void> _closeContextMenu() async {
  // 1. 隐藏菜单
  setState(() => _showContextMenu = false);
  
  // 2. 恢复窗口到宠物大小
  if (_windowSize.width > _petWindowSize.width ||
      _windowSize.height > _petWindowSize.height) {
    await windowManager.setSize(_petWindowSize);
  }
}
```

## 使用效果

### 显示菜单

1. 用户右键点击宠物
2. 窗口自动扩大（如果需要）
3. 菜单显示在宠物旁边（智能定位）
4. 菜单可以超出原始 120x120 窗口范围

### 关闭菜单

1. 用户点击菜单外区域或选择菜单项
2. 菜单消失
3. 窗口自动恢复到 120x120

## 日志示例

```
🍔 扩大窗口以显示菜单
   当前尺寸: 120.0x120.0
   新尺寸: 280.0 x 250.0
   菜单屏幕位置: (1350.0, 650.0)
   菜单相对位置: (130.0, 80.0)

🍔 恢复窗口到宠物大小: 120.0x120.0
```

## 优势

✅ **用户体验好**：菜单不受窗口大小限制，可以完整显示
✅ **实现简单**：不需要复杂的原生代码
✅ **性能好**：窗口大小调整很快，用户几乎感觉不到
✅ **跨平台**：基于 `window_manager`，支持所有桌面平台

## 局限性

⚠️ **窗口会短暂变大**：显示菜单时窗口会扩大，但由于背景透明，用户看不到
⚠️ **不是真正的子窗口**：菜单仍然是主窗口的一部分

## 相关文件

- `lib/ui/screens/desktop_pet_screen.dart` - 菜单显示逻辑
- `lib/ui/widgets/desktop_pet_widget.dart` - 宠物组件
- `lib/core/services/desktop_pet_menu_manager.dart` - 菜单管理器（备用）

## 未来优化

如果需要更完美的实现，可以考虑：

1. **原生子窗口**：使用 Windows/macOS/Linux 原生 API 创建真正的子窗口
2. **系统托盘菜单**：使用系统托盘菜单（但位置固定）
3. **Overlay 窗口**：使用原生 Overlay 技术

---

**创建日期**: 2026-01-23
**作者**: Flutter Plugin Platform Team
