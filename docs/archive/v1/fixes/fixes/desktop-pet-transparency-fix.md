# 桌面宠物透明化背景闪现修复

## 修复日期
2026-01-23

## 修复历史

### 第四次修复（2026-01-23）：重构窗口创建逻辑 - 透明度优先策略

**问题根源**（通过日志分析发现）：
1. 调用 `hide()` 后，某些窗口属性设置（如 `setAsFrameless()` 或 `setSize()`）会自动显示窗口
2. 窗口在透明设置完成前就已经可见，导致背景闪现

**解决方案**：**透明度优先策略**

不再尝试隐藏窗口，而是：
1. **先设置透明度为0**（完全透明）
2. 然后设置所有其他属性（即使窗口可见，也是透明的，看不到）
3. 最后逐渐恢复透明度

**新的窗口创建流程**：

```dart
// 步骤 1: 准备
- 获取当前位置
- 确定目标透明度

// 步骤 2: 先设置透明度为0（关键！）
await windowManager.setOpacity(0.0);
await Future.delayed(50ms);

// 步骤 3: 设置所有窗口属性（透明状态下）
- setMinimumSize(0, 0)
- setBackgroundColor(透明)
- setAsFrameless()
- setSize(120x120)
- setAlwaysOnTop(true)
- 其他属性...

// 步骤 4: 确保窗口可见（如果还没显示）
if (!isVisible) {
  await windowManager.show();
}

// 步骤 5: 恢复透明度
await windowManager.setOpacity(targetOpacity);
```

**核心优势**：
- ✅ 窗口从始至终都是透明的，即使中间状态可见也看不到背景
- ✅ 不依赖 `hide()` 方法，避免了某些属性设置自动显示窗口的问题
- ✅ 流程更简单、更可靠

**实施的改动**（`desktop_pet_manager.dart`）：

1. **删除了 Step 2 的 hide() 调用**
2. **Step 2 改为设置初始透明度为0**
3. **Step 3 在透明状态下设置所有属性**
4. **Step 4 确保窗口可见（如果需要）**
5. **Step 5 恢复透明度**

**日志格式优化**：
- 使用 `🎯` 标记关键步骤
- 更清晰的步骤说明
- 更详细的验证信息

**预期效果**：
- 完全消除背景闪现问题
- 窗口过渡更平滑
- 代码逻辑更清晰

**测试结果**（2026-01-23）：

✅ **成功！** 通过日志验证，新方案完美解决了背景闪现问题：

```
🎯 Step 2: 设置初始透明度为 0.0（完全透明）...
   验证: 初始透明度 = 0.0 (应为 0.0)

🎯 Step 3: 配置窗口属性（透明状态下）...
   [设置各种属性...]

🎯 Step 3 验证:
   尺寸: 136.0x120.0
   可见性: true          ← 窗口已可见
   透明度: 0.0 (应为 0.0) ← 但是完全透明！
   置顶: true

🎯 Step 5: 恢复透明度到 1.0...
🎯 完成！桌面宠物窗口创建成功
```

**关键成功点**：
- 窗口在配置过程中虽然可见（visible = true），但透明度为 0，用户看不到
- 避免了 `hide()` 方法导致的问题（某些属性设置会自动显示窗口）
- 整个过程平滑、无闪现

**测试方法**：
1. 运行应用：`flutter run -d windows`
2. 进入宠物模式
3. 观察是否还有背景闪现
4. 查看日志验证透明度设置顺序

**已知问题**：
- 窗口宽度为 136 而非 120（可能是 Windows DPI 缩放或边框导致）
- 这不影响透明化效果，但可能需要后续优化

---

### 第三次修复（2026-01-23）：添加详细窗口状态监听日志

**问题**：用户报告窗口变小后仍然会展示背景

**分析**：
- 需要更详细的日志来追踪窗口状态变化
- 需要在每个关键步骤后验证窗口的实际状态
- 需要监听所有窗口事件，找出背景闪现的确切时机

**实施的修复**：

1. **增强 WindowListener 回调日志**（`desktop_pet_manager.dart`）
   - `onWindowEvent`: 记录事件名称、尺寸、位置、透明度、可见性
   - `onWindowFocus`: 记录尺寸和透明度
   - `onWindowRestore`: 记录尺寸和透明度
   - `onWindowResize`: 记录新尺寸、透明度、可见性
   - `onWindowMove`: 记录新位置和尺寸

2. **添加窗口状态验证日志**（`_createDesktopPetWindow` 方法）
   - **Step 2 验证**：检查窗口是否已隐藏
   - **Step 3 背景色验证**：检查背景色是否设置为透明
   - **Step 3 最终验证**：检查尺寸、可见性、置顶状态
   - **Step 4 显示前验证**：检查透明度是否为 0.0
   - **Step 4 显示后验证**：检查可见性、尺寸、透明度
   - **Step 4 最终验证**：检查最终透明度是否达到目标值

3. **添加 UI 层初始化日志**（`desktop_pet_screen.dart`）
   - 记录初始窗口状态（尺寸、位置、透明度、可见性）
   - 记录延迟后的窗口状态
   - 记录 UI 显示时机和淡入动画启动

**日志格式**：
- `📊 [窗口事件]` - WindowListener 回调事件
- `🎨 [UI层]` - UI 层初始化过程
- `Step X 验证` - 窗口创建步骤验证

**发现的问题**（通过日志分析）：

1. **窗口尺寸异常**：
   ```
   Requested size: 120.0x120.0, Actual size: 136.0x120.0
   ```
   - 请求的宽度是 120，但实际宽度是 136（多了16像素）
   - 这可能是 Windows 窗口边框或 DPI 缩放导致的

2. **窗口提前可见**：
   ```
   Step 3 最终验证:
      尺寸: 136.0x120.0 (目标: 120x120)
      可见性: true (应为 false)  ← 问题！
      置顶: true
   ```
   - 在 Step 2 调用 `hide()` 后，窗口应该是隐藏的
   - 但在 Step 3 设置属性时，窗口又变成可见了
   - 这说明某些窗口属性设置（如 `setAsFrameless()` 或 `setSize()`）会自动显示窗口

**根本原因**：
Windows 平台的 `window_manager` 在设置某些属性时会自动显示窗口，即使之前调用了 `hide()`。这导致窗口在背景色和透明度设置完成前就已经可见，从而出现背景闪现。

**下一步优化方向**：

1. **调整窗口操作顺序**：
   - 不要在设置属性前隐藏窗口
   - 而是先设置所有属性（包括透明度为0），然后再显示窗口

2. **处理窗口尺寸问题**：
   - 考虑 Windows DPI 缩放因素
   - 可能需要设置更小的尺寸（如 104x120）来得到实际的 120x120

3. **考虑原生实现**：
   - 如果 Flutter 层面无法完全解决，考虑在 Windows 原生层面处理
   - 通过 MethodChannel 调用 Win32 API 直接控制窗口属性

---

## 问题描述

### 1. 点击穿透逻辑冗余
- 代码中存在 `_updatePetRegion()` 方法调用，但该功能暂不需要
- 导入了未使用的 `desktop_pet_click_through_service.dart`

### 2. 窗口透明化时背景闪现
**现象**：宠物模式启动时，窗口会短暂显示白色或系统主题色背景

**根本原因**：
在 Windows 平台上，窗口设置过程中的操作顺序导致：
1. 窗口先变成无边框（此时还是原来的背景色）
2. 设置透明背景色 `setBackgroundColor(Color(0x00000000))`
3. 调整窗口大小

在步骤 1-2 之间，会短暂显示窗口的默认背景色，造成闪现。

## 解决方案

### 1. 删除点击穿透逻辑
**修改文件**：`lib/ui/widgets/desktop_pet_widget.dart`

- 删除 `_updatePetRegion()` 方法
- 删除 `_handlePointerUp()` 和 `_endDragging()` 中的 `_updatePetRegion()` 调用
- 删除 `desktop_pet_click_through_service.dart` 导入

### 2. 优化窗口初始化顺序
**修改文件**：`lib/core/services/desktop_pet_manager.dart`

**关键改动**：调整 `transitionToDesktopPet()` 方法中的窗口设置顺序

```dart
// ❌ 原来的顺序（会闪现）
await windowManager.setAsFrameless();        // 1. 无边框
await windowManager.setSize(petWindowSize);  // 2. 调整大小
await windowManager.setBackgroundColor(...); // 3. 透明背景

// ✅ 优化后的顺序（不闪现）
await windowManager.setBackgroundColor(...); // 1. 先设置透明背景
await windowManager.setAsFrameless();        // 2. 再无边框
await windowManager.setSize(petWindowSize);  // 3. 最后调整大小
```

**原理**：先设置透明背景，后续的窗口操作就不会显示不透明的背景色。

### 3. 增加 UI 层延迟
**修改文件**：`lib/ui/screens/desktop_pet_screen.dart`

**改动**：增加 `_initializeWindow()` 中的延迟时间

```dart
// ❌ 原来：50ms（可能不够）
await Future.delayed(const Duration(milliseconds: 50));

// ✅ 优化：150ms（确保窗口完全设置好）
await Future.delayed(const Duration(milliseconds: 150));
```

**配合机制**：
- `_isReady = false`：初始时不显示任何内容（`SizedBox.shrink()`）
- 延迟 150ms 后设置 `_isReady = true`
- 使用 `FadeTransition` 淡入动画平滑显示

## 技术细节

### 窗口透明化的三层防护

1. **底层**：优化窗口 API 调用顺序（`desktop_pet_manager.dart`）
2. **中层**：延迟显示内容，等待窗口设置完成（`desktop_pet_screen.dart`）
3. **表层**：使用淡入动画平滑过渡（`FadeTransition`）

### 为什么需要延迟？

即使调整了 API 调用顺序，Windows 窗口系统的异步特性仍可能导致：
- `setBackgroundColor()` 返回后，实际渲染可能还未完成
- 窗口大小调整时会触发重绘，可能短暂显示旧背景

因此需要在 Flutter Widget 层面增加延迟，确保底层窗口完全准备好。

## 测试验证

### 测试步骤
1. 运行应用：`flutter run -d windows`
2. 点击"桌面宠物模式"
3. 观察窗口过渡过程

### 预期结果
- ✅ 不应看到白色或系统主题色背景闪现
- ✅ 宠物图标平滑淡入显示
- ✅ 窗口大小正确（120x120）
- ✅ 窗口透明，只显示圆形宠物

## 相关文件

- `lib/ui/widgets/desktop_pet_widget.dart` - 宠物组件
- `lib/ui/screens/desktop_pet_screen.dart` - 宠物屏幕
- `lib/core/services/desktop_pet_manager.dart` - 宠物管理器

## 后续优化建议

如果未来需要实现点击穿透功能：
1. 使用 Windows 原生 API（WM_NCHITTEST）
2. 在 `windows/runner/` 中实现 C++ 代码
3. 通过 MethodChannel 与 Dart 通信
4. 恢复 `desktop_pet_click_through_service.dart` 的使用
