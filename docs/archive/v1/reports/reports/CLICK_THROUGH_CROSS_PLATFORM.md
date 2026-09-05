# 桌宠点击穿透 - 跨平台实现指南

**日期**: 2026-01-22
**版本**: v1.0.0
**状态**: 设计文档

---

## 📋 实现状态

| 平台 | 接口预留 | 原生实现 | 状态 |
|------|---------|---------|------|
| **Windows** | ✅ | ✅ WM_NCHITTEST | ✅ 完成 |
| **macOS** | ✅ | ❌ 未实现 | ⏳ 待实现 |
| **Linux** | ✅ | ❌ 未实现 | ⏳ 待实现 |
| **Web** | ✅ | ❌ 不支持 | ⚠️ 不适用 |
| **Android** | ✅ | ❌ 不支持 | ⚠️ 不适用 |
| **iOS** | ✅ | ❌ 不支持 | ⚠️ 不适用 |

---

## 🍎 macOS 实现方案

### 技术原理

macOS 使用 `NSWindow` 的 `ignoresMouseEvents` 属性和 `acceptsFirstMouse` 方法来实现点击穿透。

### 实现步骤

#### 步骤1：创建 Swift 方法处理

**文件**: `macos/Runner/MainFlutterWindow.swift`

```swift
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var petRegion: NSRect?
  private var petRegionValid = false

  override func awakeFromNib() {
    super.awakeFromNib()
    // 注册方法通道
    registerMethodChannel()
  }

  func registerMethodChannel() {
    guard let controller = flutterViewController?.engine.binaryMessenger else { return }

    let channel = FlutterMethodChannel(
      name: "desktop_pet",
      binaryMessenger: controller
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE",
                            message: "Window not available",
                            details: nil))
        return
      }

      if call.method == "updatePetRegion" {
        self.handleUpdatePetRegion(call: call, result: result)
      } else if call.method == "setClickThrough" {
        self.handleSetClickThrough(call: call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleUpdatePetRegion(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let args = call.arguments as? [String: Any],
          let left = args["left"] as? Int,
          let top = args["top"] as? Int,
          let right = args["right"] as? Int,
          let bottom = args["bottom"] as? Int else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "Missing region coordinates",
                          details: nil))
      return
    }

    // macOS 的坐标系是从左下角开始的，需要转换
    let windowHeight = Int(self.frame.height)
    let flippedTop = windowHeight - bottom
    let flippedBottom = windowHeight - top

    petRegion = NSRect(
      x: CGFloat(left),
      y: CGFloat(flippedTop),
      width: CGFloat(right - left),
      height: CGFloat(flippedBottom - flippedTop)
    )
    petRegionValid = true

    NSLog("Pet region updated: (\(left),\(top)) to (\(right),\(bottom))")
    result(true)
  }

  private func handleSetClickThrough(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "Missing enabled parameter",
                          details: nil))
      return
    }

    if enabled {
      // 启用智能点击穿透
      self.acceptsFirstMouse = false
    } else {
      // 禁用点击穿透
      self.acceptsFirstMouse = true
    }

    result(true)
  }

  // 重写鼠标事件处理
  override var acceptsFirstResponder: Bool {
    // 检查鼠标是否在宠物区域内
    if let event = NSApp.currentEvent(),
       petRegionValid,
       let locationInWindow = event.locationInWindow as? NSPoint {
      if petRegion!.contains(locationInWindow) {
        return true  // 在宠物区域内，接收事件
      }
    }

    // 在宠物区域外，不接收事件（穿透）
    return acceptsFirstResponder
  }

  override func mouseLocationOutsideOfEventStream() -> NSPoint {
    guard let event = NSApp.currentEvent() else {
      return super.mouseLocationOutsideOfEventStream()
    }

    let location = event.locationInWindow
    if petRegionValid && petRegion!.contains(location) {
      return location  // 在宠物区域内
    }

    // 在宠物区域外，让事件穿透
    return super.mouseLocationOutsideOfEventStream()
  }
}
```

#### 步骤2：添加头文件声明

**文件**: `macos/Runner/MainFlutterWindow.h`

```objc
#import <Flutter/Flutter.h>
#import <Cocoa/Cocoa.h>

@interface MainFlutterWindow : NSWindow <FlutterPluginRegistry>
// 现有声明...
- (void)handleUpdatePetRegion:(FlutterMethodCall*)call
                       result:(FlutterResult)result;
- (void)handleSetClickThrough:(FlutterMethodCall*)call
                       result:(FlutterResult)result;
@end
```

### 测试步骤

```bash
# 1. 清理构建
flutter clean

# 2. 构建 macOS 应用
flutter build macos --release

# 3. 运行测试
open build/macos/Build/Products/Release/flutter_app.app
```

---

## 🐧 Linux 实现方案

### 技术原理

Linux 需要根据显示服务器类型（X11 或 Wayland）使用不同的 API：

- **X11**: 使用 `XShape` 扩展的 `ShapeCombineRegion`
- **Wayland**: 使用 `wl_region` 和 `input_region`

### 实现步骤（X11）

#### 步骤1：创建 C++ 方法处理

**文件**: `linux/my_application.cc`

```cpp
#include "my_application.h"
#include <flutter_linux/flutter_linux.h>
#include <X11/Xlib.h>
#include <X11/extensions/shape.h>

struct _MyApplication {
  GtkApplication parent_instance;
  GtkWindow* window;
  FlFlutterLinuxPlugin* flutter_plugin;

  // 桌宠点击穿透区域
  bool pet_region_valid;
  int pet_left;
  int pet_top;
  int pet_right;
  int pet_bottom;
};

// 更新宠物区域
void my_application_update_pet_region(
    MyApplication* self,
    int left,
    int top,
    int right,
    int bottom) {

  self->pet_region_valid = true;
  self->pet_left = left;
  self->pet_top = top;
  self->pet_right = right;
  self->pet_bottom = bottom;

  g_print("Pet region updated: (%d,%d) to (%d,%d)\n",
          left, top, right, bottom);

  // 获取 X11 窗口
  GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(self->window));
  if (!GDK_IS_X11_WINDOW(gdk_window)) {
    g_print("Not an X11 window, click-through not supported\n");
    return;
  }

  Window xwindow = GDK_WINDOW_XID(gdk_window);
  Display* display = gdk_x11_display_get_xdisplay(
      gtk_widget_get_display(GTK_WIDGET(self->window)));

  // 创建宠物区域的矩形
  XRectangle pet_rect;
  pet_rect.x = left;
  pet_rect.y = top;
  pet_rect.width = right - left;
  pet_rect.height = bottom - top;

  // 创建区域
  Region pet_region = XCreateRegion();
  XUnionRectWithRegion(&pet_rect, pet_region, pet_region);

  // 设置输入区域（只有宠物区域接收鼠标事件）
  XShapeCombineRegion(
      display,
      xwindow,
      ShapeInput,  // ShapeInput 控制输入事件
      0,
      0,
      pet_region,
      ShapeSet
  );

  XFlush(display);
}

// 设置点击穿透
void my_application_set_click_through(MyApplication* self, bool enabled) {
  if (enabled && self->pet_region_valid) {
    // 使用当前的宠物区域
    my_application_update_pet_region(
        self,
        self->pet_left,
        self->pet_top,
        self->pet_right,
        self->pet_bottom
    );
  } else {
    // 禁用点击穿透 - 整个窗口可点击
    // 恢复默认输入区域
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(self->window));
    if (GDK_IS_X11_WINDOW(gdk_window)) {
      Window xwindow = GDK_WINDOW_XID(gdk_window);
      Display* display = gdk_x11_display_get_xdisplay(
          gtk_widget_get_display(GTK_WIDGET(self->window)));

      XShapeCombineMask(
          display,
          xwindow,
          ShapeInput,
          0,
          0,
          None,  // None 表示整个窗口
          ShapeSet
      );

      XFlush(display);
    }
  }
}
```

#### 步骤2：集成到方法通道

**文件**: `linux/my_application.cc`（在现有的 `plugin_registrar` 附近）

```cpp
// 在现有方法通道处理中添加
else if (flutter_value_compare_string(method, "updatePetRegion") == 0) {
  FlutterDesktopMessenger* messenger =
      fl_plugin_registrar_get_messenger(plugin_registrar);

  // 提取参数
  FlutterDesktopMessengerSetCallback(
      messenger,
      "desktop_pet",
      [](FlutterDesktopMessengerRef messenger,
         const char* channel,
         const FlutterDesktopMessage* message,
         void* userdata) -> FlutterDesktopMessageResponse {

        if (strcmp(message->method, "updatePetRegion") == 0) {
          // 解析参数...
          my_application_update_pet_region(
              self,
              left, top, right, bottom
          );
        }
      },
      self,
      nullptr
  );
}
```

### Wayland 支持（未来）

Wayland 的实现更加复杂，需要使用 `wl_compositor` 和 `wl_region` 接口。建议：

1. 优先支持 X11
2. 检测显示服务器类型
3. 为 Wayland 提供降级方案

---

## 📊 跨平台兼容性矩阵

| 功能 | Windows | macOS | Linux (X11) | Linux (Wayland) | Web | Mobile |
|------|---------|-------|-------------|-----------------|-----|--------|
| **接口预留** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **原生实现** | ✅ WM_NCHITTEST | ⏳ 待实现 | ⏳ XShape | ❌ 复杂 | ❌ 不支持 | ❌ 不支持 |
| **优雅降级** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **日志警告** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 🔧 实现优先级

### 阶段1：Windows（已完成）✅
- WM_NCHITTEST 消息处理
- 动态区域判断
- 完整测试

### 阶段2：macOS（建议优先）
- 相对简单的实现
- 使用原生 API
- 预计工作量：4-6 小时

### 阶段3：Linux X11（中等）
- XShape 扩展
- 需要处理 X11 特定逻辑
- 预计工作量：6-8 小时

### 阶段4：Linux Wayland（低优先级）
- 复杂的实现
- 需要使用 Wayland 协议
- 预计工作量：12-16 小时

---

## ⚠️ 注意事项

### 1. 坐标系转换

不同平台的坐标系不同：

| 平台 | 坐标原点 | Y轴方向 |
|------|---------|---------|
| **Windows** | 左上角 | 向下 |
| **macOS** | 左下角 | 向上 |
| **Linux (X11)** | 左上角 | 向下 |
| **Flutter** | 左上角 | 向下 |

**转换公式**（macOS）：
```swift
let windowHeight = Int(self.frame.height)
let flippedTop = windowHeight - bottom
let flippedBottom = windowHeight - top
```

### 2. 平台检测

在实现前需要检测平台：

```dart
import 'dart:io' if (dart.library.io) 'dart:io';

bool get usesWayland {
  if (!Platform.isLinux) return false;

  // 检查 WAYLAND_DISPLAY 环境变量
  return Platform.environment['WAYLAND_DISPLAY'] != null;
}

bool get usesX11 {
  if (!Platform.isLinux) return false;

  // 检查 DISPLAY 环境变量
  return Platform.environment['DISPLAY'] != null;
}
```

### 3. 降级策略

对于不支持的平台，应该：

```dart
Future<void> updatePetRegion({...}) async {
  if (!isSupported) {
    PlatformLogger.instance.logWarning(
      'Desktop Pet Click Through',
      'Platform $platform does not support click-through. Using Flutter-layer only.',
    );
    // 不执行原生调用，只记录日志
    return;
  }

  // 原生实现...
}
```

---

## 📝 实现检查清单

### macOS 实现检查

- [ ] 在 `MainFlutterWindow.swift` 添加方法处理
- [ ] 实现坐标转换（macOS 坐标系）
- [ ] 重写 `acceptsFirstResponder`
- [ ] 测试点击穿透功能
- [ ] 测试拖拽、双击、菜单

### Linux X11 实现检查

- [ ] 在 `my_application.cc` 添加方法处理
- [ ] 链接 X11 扩展库（`-lXext`）
- [ ] 使用 XShape 设置输入区域
- [ ] 测试 X11 环境
- [ ] 处理 Wayland 降级

---

## 🚀 快速开始

### macOS 实现

```bash
# 1. 编辑文件
code macos/Runner/MainFlutterWindow.swift

# 2. 复制上面的 Swift 代码

# 3. 构建
flutter build macos --release

# 4. 测试
open build/macos/Build/Products/Release/flutter_app.app
```

### Linux 实现

```bash
# 1. 编辑文件
code linux/my_application.cc

# 2. 复制上面的 C++ 代码

# 3. 确保 X11 开发库已安装
sudo apt-get install libx11-dev libxext-dev

# 4. 构建
flutter build linux --release

# 5. 测试
./build/linux/x64/release/bundle/flutter_app
```

---

**文档版本**: v1.0.0
**创建日期**: 2026-01-22
**作者**: Claude Code
