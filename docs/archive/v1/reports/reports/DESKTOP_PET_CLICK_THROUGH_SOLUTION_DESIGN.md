# 桌宠点击穿透问题技术方案设计文档

**日期**: 2026-01-22
**版本**: v1.0.0
**状态**: 技术设计阶段

---

## 📋 问题分析

### 当前状态

**已实现的功能**：
1. ✅ Flutter 层点击穿透 - 使用 `IgnorePointer` 让背景层不捕获事件
2. ✅ 双击检测优化 - 延迟拖拽启动（100ms），双击优先，距离阈值判断
3. ✅ 拖拽功能 - 可拖动桌宠窗口

**存在的问题**：
1. ❌ 无法真正点击到桌面图标 - Flutter 层的 `IgnorePointer` 只在应用内生效
2. ❌ 使用 `SetWindowRgn(120x120)` 裁剪后 - 右键菜单无法操作，拖拽受限

### 核心技术限制

```
Flutter 层穿透 vs OS 层穿透

Flutter 层 (IgnorePointer):
  ✅ 背景层不捕获鼠标事件
  ❌ 事件不会穿透到其他应用（如桌面）
  原因：Flutter 的 widget 树只在应用内部处理事件

OS 层 (Windows API):
  ✅ 可以真正让鼠标事件穿透到桌面
  ⚠️  需要精细控制，否则影响其他交互
  方法：SetWindowRgn, WM_NCHITTEST, 动态隐藏等
```

---

## 🎯 需求分析

### 功能需求

| 需求 | 优先级 | 说明 |
|------|--------|------|
| 真正穿透到桌面 | P0 | 点击窗口外围可以操作桌面图标 |
| 宠物图标可点击 | P0 | 宠物图标必须可以交互 |
| 拖拽功能正常 | P0 | 可以拖动桌宠窗口 |
| 双击返回主应用 | P0 | 双击宠物图标返回主界面 |
| 右键菜单可用 | P0 | 右键菜单正常显示和操作 |
| 拖拽状态切换 | P1 | 拖拽时显示不同状态 |

### 非功能需求

| 需求 | 说明 |
|------|------|
| 性能 | 不能影响窗口流畅度 |
| 稳定性 | 不能出现窗口闪烁或卡死 |
| 兼容性 | 支持 Windows 10/11 |
| 可维护性 | 代码清晰，易于调试 |

---

## 🔧 技术方案对比

### 方案总览

| 方案 | 技术原理 | 穿透效果 | 交互完整性 | 实现难度 | 推荐度 |
|------|---------|---------|-----------|---------|--------|
| **方案1：SetWindowRgn 动态裁剪** | 设置窗口可点击区域 | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **方案2：WM_NCHITTEST 消息处理** | 拦截命中测试消息 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **方案3：动态窗口隐藏** | 鼠标离开时隐藏窗口 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **方案4：WS_EX_TRANSPARENT** | 设置窗口透明样式 | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ | ⭐ |
| **方案5：混合方案** | 结合多种方法 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 📐 详细方案设计

### 方案2：WM_NCHITTEST 消息处理（推荐）

#### 原理

拦截 Windows 的 `WM_NCHITTEST` 消息，根据鼠标位置动态判断返回：
- `HTCLIENT` - 客户区，接收鼠标事件
- `HTTRANSPARENT` - 透明，穿透到下层窗口

#### 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Layer                        │
├─────────────────────────────────────────────────────────┤
│  DesktopPetWidget                                       │
│  ├─ GlobalKey (用于获取宠物图标位置)                    │
│  ├─ GestureDetector (拖拽、双击、右键)                  │
│  └─ MethodChannel 调用 updatePetRegion()               │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Windows Native Layer                  │
├─────────────────────────────────────────────────────────┤
│  flutter_window.cpp                                     │
│  ├─ MethodChannel handler: updatePetRegion              │
│  ├─ 全局变量: g_petRegion (RECT)                        │
│  └─ MessageHandler: WM_NCHITTEST                        │
│                                                          │
│  LRESULT MessageHandler(..., UINT message, ...) {       │
│    if (message == WM_NCHITTEST) {                       │
│      if (IsPointInPetRegion(mousePos)) {                │
│        return HTCLIENT;      // 可点击                  │
│      } else {                                          │
│        return HTTRANSPARENT;  // 穿透                   │
│      }                                                 │
│    }                                                   │
│    ...                                                 │
│  }                                                     │
└─────────────────────────────────────────────────────────┘
```

#### 实现步骤

**步骤1：Flutter 层 - 获取并传递宠物位置**

```dart
// lib/ui/widgets/desktop_pet_widget.dart

class _DesktopPetWidgetState extends State<DesktopPetWidget> {
  final GlobalKey _petIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePetRegion();
    });
  }

  // 更新宠物图标区域到原生层
  void _updatePetRegion() {
    final RenderBox? renderBox =
        _petIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 获取宠物图标在窗口中的位置和大小
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // 通过 MethodChannel 传递给原生层
    DesktopPetClickThroughService.instance.updatePetRegion(
      left: position.dx,
      top: position.dy,
      right: position.dx + size.width,
      bottom: position.dy + size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (_) => _updatePetRegion(), // 拖拽后更新区域
      child: Container(
        key: _petIconKey,
        child: // 宠物图标内容
      ),
    );
  }
}
```

**步骤2：Flutter 层 - 添加更新区域的方法**

```dart
// lib/core/services/desktop_pet_click_through_service.dart

class DesktopPetClickThroughService {
  static const MethodChannel _channel = MethodChannel('desktop_pet');

  /// 更新宠物图标区域（用于 WM_NCHITTEST 判断）
  Future<void> updatePetRegion({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) async {
    try {
      await _channel.invokeMethod('updatePetRegion', {
        'left': left.toInt(),
        'top': top.toInt(),
        'right': right.toInt(),
        'bottom': bottom.toInt(),
      });
    } catch (e) {
      PlatformLogger.instance.logError('Failed to update pet region', e);
    }
  }
}
```

**步骤3：Windows 原生层 - 添加 MethodChannel 处理**

```cpp
// windows/runner/flutter_window.cpp

// 全局变量存储宠物区域
RECT g_petRegion = {0};
bool g_petRegionValid = false;

void FlutterWindow::RegisterDesktopPetMethodChannel() {
  // 现有的注册代码...

  // 在 HandleDesktopPetMethodCall 中添加新的方法处理
  if (call.method_name() == "updatePetRegion") {
    auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    // 提取区域参数
    auto leftIt = arguments->find(flutter::EncodableValue("left"));
    auto topIt = arguments->find(flutter::EncodableValue("top"));
    auto rightIt = arguments->find(flutter::EncodableValue("right"));
    auto bottomIt = arguments->find(flutter::EncodableValue("bottom"));

    if (leftIt != arguments->end() && topIt != arguments->end() &&
        rightIt != arguments->end() && bottomIt != arguments->end()) {

      g_petRegion.left = std::get<int>(leftIt->second);
      g_petRegion.top = std::get<int>(topIt->second);
      g_petRegion.right = std::get<int>(rightIt->second);
      g_petRegion.bottom = std::get<int>(bottomIt->second);
      g_petRegionValid = true;

      LOG_FLUTTER_FMT("Pet region updated: (%d,%d) to (%d,%d)",
                      g_petRegion.left, g_petRegion.top,
                      g_petRegion.right, g_petRegion.bottom);

      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("INVALID_ARGUMENTS", "Missing region parameters");
    }
  }
  // 其他方法处理...
}
```

**步骤4：Windows 原生层 - 处理 WM_NCHITTEST 消息**

```cpp
// windows/runner/flutter_window.cpp

LRESULT FlutterWindow::MessageHandler(
    HWND hwnd,
    UINT const message,
    WPARAM const wparam,
    LPARAM const lparam) noexcept {

  // 处理 WM_NCHITTEST 消息
  if (message == WM_NCHITTEST && g_petRegionValid) {
    // 获取鼠标位置（屏幕坐标）
    POINT pt;
    pt.x = GET_X_LPARAM(lparam);
    pt.y = GET_Y_LPARAM(lparam);

    // 转换为窗口客户区坐标
    ScreenToClient(hwnd, &pt);

    // 检查是否在宠物区域内
    if (PtInRect(&g_petRegion, pt)) {
      // 在宠物区域内 - 接收鼠标事件
      return HTCLIENT;
    } else {
      // 在宠物区域外 - 穿透到下层窗口
      return HTTRANSPARENT;
    }
  }

  // 其他消息处理...
  return flutter_controller_->engine()->ProcessWindowsMessage(
      hwnd, message, wparam, lparam);
}
```

#### 优点

- ✅ 完美的点击穿透 - 真正穿透到桌面图标
- ✅ 交互完整 - 右键菜单、拖拽、双击都正常
- ✅ 性能优秀 - 只在鼠标移动时判断
- ✅ 易于维护 - 逻辑清晰，易于调试
- ✅ 无闪烁 - 不需要显示/隐藏窗口

#### 缺点

- ⚠️ 只支持 Windows（macOS/Linux 需要不同实现）
- ⚠️ 需要精确计算宠物图标位置

---

### 方案5：混合方案（备选）

#### 原理

结合多种方法，根据不同场景使用不同策略：

```
默认状态:
  ├─ Flutter 层: IgnorePointer (背景不捕获事件)
  ├─ OS 层: WM_NCHITTEST (动态判断穿透)
  └─ 完美平衡: 性能 + 用户体验

拖拽状态:
  ├─ 取消穿透 - 确保拖拽流畅
  └─ 拖拽结束后恢复穿透

菜单打开:
  ├─ 暂时取消穿透 - 允许操作菜单
  └─ 菜单关闭后恢复穿透
```

#### 实现要点

1. **状态管理**
   ```dart
   enum PetWindowState {
     normal,      // 正常状态（穿透启用）
     dragging,    // 拖拽中（不穿透）
     menuOpen,    // 菜单打开（不穿透）
     interacting, // 交互中（短暂不穿透）
   }
   ```

2. **动态切换**
   ```dart
   void _setClickThrough(bool enabled) {
     if (enabled) {
       // 启用 WM_NCHITTEST 判断
       DesktopPetClickThroughService.instance.setClickThrough(true);
     } else {
       // 禁用穿透（整个窗口可点击）
       DesktopPetClickThroughService.instance.setClickThrough(false);
     }
   }
   ```

3. **场景处理**
   ```dart
   // 拖拽开始
   onPanStart: () {
     _setClickThrough(false); // 取消穿透
   },

   // 拖拽结束
   onPanEnd: (_) {
     _setClickThrough(true); // 恢复穿透
   },

   // 菜单打开
   onContextMenuRequest: () {
     _setClickThrough(false); // 取消穿透
   },

   // 菜单关闭
   onMenuDismiss: () {
     _setClickThrough(true); // 恢复穿透
   },
   ```

---

## 🚀 实施计划

### 阶段1：基础实现（核心功能）

**目标**：实现基本的 WM_NCHITTEST 穿透

**任务清单**：
1. ✅ 在 `DesktopPetWidget` 添加 `GlobalKey` 获取位置
2. ✅ 在 `DesktopPetClickThroughService` 添加 `updatePetRegion` 方法
3. ✅ 在 `flutter_window.cpp` 添加 `updatePetRegion` MethodChannel 处理
4. ✅ 在 `MessageHandler` 添加 `WM_NCHITTEST` 处理
5. ✅ 测试点击穿透功能

**预期结果**：
- ✅ 点击宠物图标外区域可以操作桌面
- ✅ 点击宠物图标可以交互
- ✅ 右键菜单、拖拽、双击都正常

### 阶段2：优化完善（用户体验）

**目标**：优化拖拽和菜单体验

**任务清单**：
1. ⏳ 添加拖拽状态管理
2. ⏳ 添加菜单状态管理
3. ⏳ 优化区域更新时机（拖拽后、窗口大小变化）
4. ⏳ 添加日志输出用于调试

**预期结果**：
- ✅ 拖拽流畅无卡顿
- ✅ 菜单操作顺畅
- ✅ 状态切换平滑

### 阶段3：跨平台支持（可选）

**目标**：支持 macOS 和 Linux

**任务清单**：
1. ⏳ macOS 实现方案
2. ⏳ Linux (X11/Wayland) 实现方案
3. ⏳ 统一的平台接口

---

## 📊 方案对比总结

### 推荐方案：方案2（WM_NCHITTEST）

**选择理由**：
1. ✅ **功能完整** - 满足所有需求（穿透、交互、菜单、拖拽）
2. ✅ **性能优秀** - 只在消息处理时判断，无额外开销
3. ✅ **无副作用** - 不需要显示/隐藏窗口，无闪烁
4. ✅ **可维护** - 代码逻辑清晰，易于理解和调试

### 技术风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| 坐标计算不准确 | 中 | 高 | 使用 GlobalKey 获取精确位置 |
| 拖拽时穿透失效 | 低 | 中 | 拖拽时临时禁用穿透判断 |
| 性能问题 | 低 | 低 | WM_NCHITTEST 本身性能很好 |
| 兼容性问题 | 低 | 中 | 在 Windows 10/11 上测试 |

### 实现复杂度评估

| 模块 | 复杂度 | 工作量 |
|------|--------|--------|
| Flutter 层位置获取 | ⭐⭐ | 2-3 小时 |
| MethodChannel 通信 | ⭐⭐ | 1-2 小时 |
| WM_NCHITTEST 处理 | ⭐⭐⭐ | 2-3 小时 |
| 状态管理优化 | ⭐⭐⭐ | 3-4 小时 |
| 测试和调试 | ⭐⭐⭐ | 4-5 小时 |
| **总计** | ⭐⭐⭐ | **12-17 小时** |

---

## 📝 技术参考资料

### Windows API 文档

- [WM_NCHITTEST message](https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-nchittest)
- [PtInRect function](https://docs.microsoft.com/en-us/windows/win32/api/windowsuser/nf-windowsuser-ptinrect)
- [ScreenToClient function](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-screentoclient)

### Flutter 文档

- [Platform channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Writing custom Windows code](https://docs.flutter.dev/development/platform-integration/windows)

### 相关项目参考

- [bitsdojo_window](https://pub.dev/packages/bitsdojo_window) - 窗口管理插件
- [window_manager](https://pub.dev/packages/window_manager) - 窗口管理插件

---

## 🎯 下一步行动

1. **审查方案设计** - 确认技术方案和实施计划
2. **开始实施阶段1** - 实现核心 WM_NCHITTEST 功能
3. **测试验证** - 确保所有功能正常
4. **优化完善** - 根据测试结果进行优化

---

**文档版本**: v1.0.0
**创建日期**: 2026-01-22
**作者**: Claude Code
**状态**: 待审查
