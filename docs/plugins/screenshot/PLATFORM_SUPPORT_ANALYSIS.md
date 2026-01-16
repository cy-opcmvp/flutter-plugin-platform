# 截图插件 - 平台支持分析

> 📋 **文档版本**: v0.3.4
> **最后更新**: 2026-01-16
> **分析范围**: Windows, Linux, macOS, Android, iOS, Web

## 📊 平台支持总览

| 平台 | 全屏截图 | 区域截图 | 窗口截图 | 窗口枚举 | 原生选择窗口 | 状态 |
|------|---------|---------|---------|---------|-------------|------|
| **Windows** | ✅ 已实现 | ✅ 已实现 | ✅ 已实现 | ✅ 已实现 | ✅ 已实现 | 🟢 完整支持 |
| **Linux** | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | 🔴 未实现 |
| **macOS** | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | ⏳ 待实现 | 🔴 未实现 |
| **Android** | ⏳ 待实现 | ⏳ 待实现 | ❌ 无法实现 | ❌ 无法实现 | ❌ 无法实现 | 🟡 受限支持 |
| **iOS** | ⏳ 待实现 | ⏳ 待实现 | ❌ 无法实现 | ❌ 无法实现 | ❌ 无法实现 | 🟡 受限支持 |
| **Web** | ❌ 无法实现 | ❌ 无法实现 | ❌ 无法实现 | ❌ 无法实现 | ❌ 无法实现 | 🔴 不支持 |

---

## 🪟 Windows 平台

### ✅ 已实现功能

#### 1. 全屏截图
- **技术栈**: Win32 GDI/GDI+
- **实现文件**:
  - `windows/runner/screenshot_plugin.cpp` (CaptureFullScreen)
  - `windows/runner/screenshot_plugin.h`
  - `lib/plugins/screenshot/platform/screenshot_platform_interface.dart` (WindowsScreenshotService)
- **核心 API**:
  - `GetDC(NULL)` - 获取屏幕设备上下文
  - `CreateCompatibleBitmap()` - 创建兼容位图
  - `BitBlt()` - 位块传输，拷贝屏幕内容
  - `Gdiplus::Bitmap` - 图像编码为 PNG
- **状态**: 🟢 完整实现，生产可用

#### 2. 区域截图
- **技术栈**: Win32 GDI/GDI+
- **实现文件**: 同上
- **核心 API**:
  - `BitBlt(hdcMem, 0, 0, width, height, hdcScreen, x, y, SRCCOPY)` - 拷贝指定区域
- **状态**: 🟢 完整实现，生产可用

#### 3. 窗口截图
- **技术栈**: Win32 GDI/GDI+
- **实现文件**: 同上
- **核心 API**:
  - `GetWindowDC(hwnd)` - 获取窗口设备上下文
  - `GetWindowRect()` - 获取窗口尺寸
- **状态**: 🟢 完整实现，生产可用

#### 4. 窗口枚举
- **技术栈**: Win32 API
- **实现文件**: 同上
- **核心 API**:
  - `EnumWindows()` - 枚举所有顶层窗口
  - `GetWindowText()` - 获取窗口标题
  - `IsWindowVisible()` - 检查可见性
- **状态**: 🟢 完整实现，生产可用

#### 5. 原生区域选择窗口 (v0.3.4 新增)
- **技术栈**: Win32 API, GDI/GDI+
- **实现文件**:
  - `windows/runner/native_screenshot_window.cpp` (400+ 行)
  - `windows/runner/native_screenshot_window.h`
  - `lib/plugins/screenshot/widgets/screenshot_window.dart`
- **核心功能**:
  - 桌面背景捕获 (BitBlt)
  - 双缓冲绘制 (消除闪烁)
  - 分段遮罩算法 (上/下/左/右独立绘制)
  - 半透明混合 (AlphaBlend, 63% 不透明度)
  - 实时尺寸显示
  - ESC 键取消支持
- **状态**: 🟢 完整实现，生产可用

### 📝 技术细节

```cpp
// 关键代码片段：全屏截图
HDC hdcScreen = GetDC(NULL);
HDC hdcMem = CreateCompatibleDC(hdcScreen);
HBITMAP hBitmap = CreateCompatibleBitmap(hdcScreen, screenWidth, screenHeight);
BitBlt(hdcMem, 0, 0, screenWidth, screenHeight, hdcScreen, 0, 0, SRCCOPY);
```

### 🎯 Windows 平台优势

- ✅ 完整的原生 API 支持
- ✅ 性能优异
- ✅ 功能最完整
- ✅ 支持跨应用截图
- ✅ 支持全屏选择窗口

---

## 🐧 Linux 平台

### ⏳ 待实现功能

#### 1. 全屏截图 & 区域截图
- **技术栈选项**:
  1. **X11** (传统显示服务器)
     - API: `XGetImage()`, `XShmGetImage()`
     - 优点: 成熟稳定，文档丰富
     - 缺点: 正在被 Wayland 替代
  2. **Wayland** (现代显示服务器)
     - API: `xdg-desktop-portal` (DBus 接口)
     - 优点: 安全性高，现代架构
     - 缺点: 需要用户授权，实现复杂
  3. **混合方案** (推荐)
     - 检测当前显示服务器类型
     - X11 环境使用 X11 API
     - Wayland 环境使用 xdg-desktop-portal
- **实现文件**: 需要创建
  - `linux/runner/screenshot_plugin.cc` (C++ 实现)
  - `linux/runner/CMakeLists.txt` (添加链接库)
- **状态**: 🔴 未实现，技术方案明确

#### 2. 窗口截图 & 窗口枚举
- **技术栈**:
  - X11: `XQueryTree()`, `XFetchName()`
  - Wayland: 需要通过 xdg-desktop-portal 请求
- **状态**: 🔴 未实现，技术方案明确

#### 3. 原生区域选择窗口
- **技术挑战**:
  - 需要创建透明/半透明窗口覆盖整个屏幕
  - X11: 可行，使用 composite 扩展
  - Wayland: 需要特殊的 layer-shell 协议
- **状态**: 🔴 未实现，技术难度较高

### 📝 实现参考

```cpp
// X11 示例代码
#include <X11/Xlib.h>
Display* display = XOpenDisplay(NULL);
Window root = DefaultRootWindow(display);
XImage* image = XGetImage(display, root, 0, 0, width, height, AllPlanes, ZPixmap);
```

### 🎯 Linux 平台挑战

- ⚠️ 显示服务器分裂 (X11 vs Wayland)
- ⚠️ Wayland 安全限制严格
- ⚠️ 需要处理多种桌面环境 (GNOME, KDE, XFCE)
- ⚠️ 依赖库管理复杂

---

## 🍎 macOS 平台

### ⏳ 待实现功能

#### 1. 全屏截图 & 区域截图
- **技术栈**: Cocoa / Quartz
- **核心 API**:
  - `CGDisplayCreateImage()` - 捕获整个显示器的图像
  - `CGWindowListCreateImage()` - 捕获窗口或区域
  - `CGImageCreateWithImageInRect()` - 裁剪图像
- **实现文件**: 需要创建
  - `macos/Runner/ScreenshotPlugin.swift` (Swift 实现)
  - `macos/Runner/ScreenshotPlugin.m` (Objective-C 桥接)
- **状态**: 🔴 未实现，技术方案明确

#### 2. 窗口截图 & 窗口枚举
- **核心 API**:
  - `CGWindowListCopyWindowInfo()` - 获取窗口列表
  - `CGWindowListCreateImage()` - 截取窗口
- **状态**: 🔴 未实现，技术方案明确

#### 3. 原生区域选择窗口
- **技术栈**: AppKit
- **实现方案**:
  - 创建 NSWindow，设置为全屏
  - 设置 `window.level = NSWindowLevel.screenSaver` (置顶)
  - 使用半透明背景
  - 处理鼠标拖拽事件
- **状态**: 🔴 未实现，技术方案明确

### 📝 实现参考

```swift
// Swift 示例代码
import Quartz

let displayID = CGMainDisplayID()
guard let image = CGDisplayCreateImage(displayID) else { return }
// 将 CGImage 转换为 PNG 数据
```

### 🎯 macOS 平台优势

- ✅ API 统一，没有 Linux 的显示服务器分裂问题
- ✅ 文档完善，社区活跃
- ✅ 性能优异

---

## 📱 Android 平台

### ⏳ 待实现功能

#### 1. 全屏截图
- **技术栈**: Android MediaProjection API
- **核心 API**:
  - `MediaProjectionManager.createScreenCaptureIntent()` - 请求屏幕捕获权限
  - `MediaProjection` - 创建屏幕捕获会话
  - `ImageReader` - 获取屏幕画面
- **权限要求**:
  - `FOREGROUND_SERVICE` (前台服务)
  - `FOREGROUND_SERVICE_MEDIA_PROJECTION` (Android 14+)
- **状态**: 🔴 未实现，需要用户授权

#### 2. 区域截图
- **实现方式**: 全屏截图后裁剪
- **状态**: ⏳ 待实现，依赖全屏截图

#### 3. 原生区域选择窗口
- **技术挑战**:
  - Android 无法创建真正意义上的"桌面覆盖"窗口
  - 无法截取其他应用的内容（安全限制）
  - 只能在应用内部实现区域选择
- **限制**: 🟡 无法实现真正的桌面级截图

### ❌ 无法实现的功能

#### 1. 窗口截图
- **原因**:
  - Android 没有传统桌面操作系统的"窗口"概念
  - 应用间相互隔离，无法截取其他应用的窗口
  - 安全机制禁止跨应用截图
- **状态**: ❌ 无法实现

#### 2. 窗口枚举
- **原因**:
  - `ActivityManager.getRunningAppProcesses()` 只能获取基本信息
  - 无法获取其他应用的窗口详情
  - 隐私限制
- **状态**: ❌ 无法实现

#### 3. 原生桌面级区域选择
- **原因**:
  - 系统级覆盖窗口需要 SYSTEM_ALERT_WINDOW 权限
  - Android 10+ 对该权限严格限制
  - 无法真正覆盖整个桌面
- **状态**: ❌ 无法实现

### 📝 实现参考

```kotlin
// Kotlin 示例代码
val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), SCREEN_CAPTURE_REQUEST_CODE)
```

### 🎯 Android 平台限制

- ⚠️ 需要用户授权
- ⚠️ 只能截取本应用内容（或通过 MediaProjection 截取整个屏幕）
- ⚠️ 无法实现桌面级区域选择
- ⚠️ 无法枚举其他应用的窗口

---

## 🍎 iOS 平台

### ⏳ 待实现功能

#### 1. 全屏截图
- **技术栈**: ReplayKit
- **核心 API**:
  - `RPSystemBroadcastPickerView` - 系统广播选择器
  - `ScreenCaptureKit` (iOS 16+) - 现代屏幕捕获 API
  - `UIGraphicsImageRenderer` - 传统截图方式（仅限应用内）
- **状态**: 🔴 未实现，需要用户授权

#### 2. 区域截图
- **实现方式**: 全屏截图后裁剪
- **状态**: ⏳ 待实现

### ❌ 无法实现的功能

#### 1. 窗口截图
- **原因**:
  - iOS 应用沙盒隔离
  - 无法访问其他应用的界面
  - Apple 审核指南禁止此类功能
- **状态**: ❌ 无法实现

#### 2. 窗口枚举
- **原因**: iOS 不提供窗口枚举 API
- **状态**: ❌ 无法实现

#### 3. 原生桌面级区域选择
- **原因**:
  - iOS 没有桌面概念
  - 系统级覆盖窗口被严格禁止
  - App Store 审核无法通过
- **状态**: ❌ 无法实现

### 📝 实现参考

```swift
// Swift 示例代码 (iOS 16+)
import ScreenCaptureKit

Task {
  let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
}
```

### 🎯 iOS 平台限制

- ⚠️ 需要用户授权
- ⚠️ 只能通过 ReplayKit 或 ScreenCaptureKit 实现
- ⚠️ 无法实现桌面级区域选择
- ⚠️ 无法枚举其他应用的窗口
- ⚠️ App Store 审核严格

---

## 🌐 Web 平台

### ❌ 无法实现的功能

#### 所有截图功能
- **原因**:
  - 浏览器安全策略（同源策略）
  - 无法访问操作系统屏幕内容
  - 无法访问其他标签页或窗口
  - `Screen Capture API` (`getDisplayMedia()`) 只能捕获当前标签页且需要用户授权
- **状态**: ❌ 无法实现桌面级截图

### 🟡 可行的替代方案

#### 1. 使用 Screen Capture API (部分支持)
```javascript
// 仅能捕获当前标签页或用户授权的内容
const stream = await navigator.mediaDevices.getDisplayMedia({
  video: { cursor: "always" },
  audio: false
});
```
- **限制**:
  - 需要用户授权
  - 只能捕获当前浏览器标签页
  - 无法实现桌面级区域选择
  - 无法枚举窗口

#### 2. html2canvas (应用内截图)
- **功能**: 只能截图应用内的 DOM 元素
- **状态**: 🟡 有限支持

### 🎯 Web 平台限制

- ❌ 无法访问操作系统屏幕
- ❌ 无法实现真正的桌面截图
- ❌ 无法创建原生选择窗口
- 🟡 只能实现应用内 DOM 截图

---

## 📋 实现优先级建议

### 高优先级 (桌面平台)
1. ✅ **Windows** - 已完成
2. 🔴 **Linux** - 下一步目标
   - X11 支持 (相对简单)
   - Wayland 支持 (较复杂)
3. 🔴 **macOS** - 桌面平台补充
   - 实现相对简单
   - API 统一

### 中优先级 (移动平台 - 受限支持)
4. 🔴 **Android** - 应用内截图
   - 实现 MediaProjection 全屏截图
   - 实现应用内区域选择
   - 明确告知用户限制
5. 🔴 **iOS** - 应用内截图
   - 实现 ReplayKit / ScreenCaptureKit
   - 实现应用内区域选择
   - 明确告知用户限制

### 低优先级 (Web 平台)
6. 🔴 **Web** - DOM 截图
   - 使用 html2canvas 实现应用内截图
   - 明确告知用户限制
   - 或直接标注为"不支持"

---

## 🔧 技术栈汇总

### Windows
- **语言**: C++
- **API**: Win32 GDI/GDI+
- **库**: gdiplus.lib, msimg32.lib
- **文件**: `windows/runner/screenshot_plugin.cpp`

### Linux (待实现)
- **语言**: C++
- **API**: X11 或 Wayland (xdg-desktop-portal)
- **库**: libX11, libXext (X11) / dbus-1 (Wayland)
- **文件**: `linux/runner/screenshot_plugin.cc` (待创建)

### macOS (待实现)
- **语言**: Swift / Objective-C++
- **API**: Cocoa / Quartz
- **框架**: CoreGraphics, AppKit
- **文件**: `macos/Runner/ScreenshotPlugin.swift` (待创建)

### Android (待实现)
- **语言**: Kotlin
- **API**: MediaProjection API
- **权限**: FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PROJECTION
- **文件**: `android/app/src/main/kotlin/com/example/flutter_app/ScreenshotPlugin.kt` (待创建)

### iOS (待实现)
- **语言**: Swift
- **API**: ReplayKit / ScreenCaptureKit
- **框架**: ReplayKit, ScreenCaptureKit (iOS 16+)
- **文件**: `ios/Runner/ScreenshotPlugin.swift` (待创建)

### Web (无法实现)
- **替代方案**: html2canvas (应用内 DOM 截图)
- **限制**: 无法实现真正的桌面截图

---

## 📊 实现复杂度评估

| 平台 | 复杂度 | 预估工作量 | 备注 |
|------|--------|-----------|------|
| **Windows** | ⭐⭐ | 已完成 | GDI+ API 友好 |
| **Linux** | ⭐⭐⭐⭐ | 3-5 天 | X11 + Wayland 双实现 |
| **macOS** | ⭐⭐⭐ | 2-3 天 | API 统一，实现相对简单 |
| **Android** | ⭐⭐⭐⭐ | 3-4 天 | 权限处理复杂，功能受限 |
| **iOS** | ⭐⭐⭐⭐ | 3-4 天 | 功能受限，审核严格 |
| **Web** | N/A | N/A | 无法实现桌面截图 |

---

## 🎯 总结

### 完整支持
- ✅ **Windows** - 功能最完整，性能最佳

### 可以实现
- 🔴 **Linux** - 技术方案明确，但需要处理显示服务器差异
- 🔴 **macOS** - API 完善，实现难度适中

### 受限支持
- 🟡 **Android** - 可以实现应用内截图，但无法实现桌面级功能
- 🟡 **iOS** - 可以实现应用内截图，但无法实现桌面级功能

### 无法实现
- ❌ **Web** - 浏览器安全策略限制，无法实现桌面截图

### 架构建议
1. **分层设计**: 平台接口层 + 平台实现层
2. **功能降级**: 不支持的平台自动降级或提示用户
3. **统一接口**: Dart 层保持接口一致，平台层差异化实现
4. **文档完善**: 明确标注各平台支持的功能差异

---

**文档维护**: 当实现新平台支持时，请更新本文档。
**相关文档**:
- [插件开发指南](../../guides/internal-plugin-development.md)
- [平台服务架构](../../platform-services/)
