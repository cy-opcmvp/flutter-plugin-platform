# 截图插件 - 平台实现 TODO

> 📋 **当前版本**: v0.3.4
> **最后更新**: 2026-01-16
> **状态**: Windows 已完成，其他平台待实现

## ✅ 已完成

### Windows 平台 (v0.3.4)
- [x] 全屏截图 (GDI/GDI+)
- [x] 区域截图 (BitBlt)
- [x] 窗口截图 (GetWindowDC)
- [x] 窗口枚举 (EnumWindows)
- [x] 原生区域选择窗口 (Native Screenshot Window)
- [x] 双缓冲绘制技术
- [x] 分段遮罩算法
- [x] 半透明混合效果
- [x] MethodChannel 轮询机制
- [x] ESC 键取消支持

---

## 🔴 Linux 平台

### Phase 1: X11 支持 (基础)
- [ ] 创建 `linux/runner/screenshot_plugin.cc`
- [ ] 创建 `linux/runner/screenshot_plugin.h`
- [ ] 实现全屏截图 (XGetImage)
  - [ ] 链接 libX11 库
  - [ ] 打开 X 显示连接
  - [ ] 获取根窗口
  - [ ] 捕获屏幕图像
  - [ ] 转换为 PNG 格式
- [ ] 实现区域截图
- [ ] 实现 MethodChannel 处理
- [ ] 更新 CMakeLists.txt
- [ ] 测试 X11 环境功能

### Phase 2: X11 增强
- [ ] 实现窗口枚举 (XQueryTree)
  - [ ] 获取窗口列表
  - [ ] 获取窗口标题
  - [ ] 过滤不可见窗口
- [ ] 实现窗口截图
- [ ] 实现原生区域选择窗口
  - [ ] 创建全屏覆盖窗口
  - [ ] 处理鼠标事件
  - [ ] 绘制选择区域
  - [ ] 半透明遮罩效果

### Phase 3: Wayland 支持
- [ ] 检测显示服务器类型
- [ ] 实现 xdg-desktop-portal 集成
  - [ ] DBus 接口封装
  - [ ] 请求屏幕捕获权限
  - [ ] 处理用户授权流程
- [ ] 实现全屏截图 (Wayland)
- [ ] 实现区域截图
- [ ] 实现原生区域选择窗口
  - [ ] 使用 layer-shell 协议
  - [ ] 处理 Wayland 限制

### Phase 4: 混合方案
- [ ] 运行时检测 X11/Wayland
- [ ] 自动切换实现方式
- [ ] 统一错误处理
- [ ] 完善日志输出

**预估工作量**: 3-5 天
**技术难度**: ⭐⭐⭐⭐
**优先级**: 🔴 高 (桌面平台)

---

## 🔴 macOS 平台

### Phase 1: 基础截图功能
- [ ] 创建 `macos/Runner/ScreenshotPlugin.swift`
- [ ] 创建 `macos/Runner/ScreenshotPlugin.m` (ObjC 桥接)
- [ ] 实现全屏截图 (CGDisplayCreateImage)
  - [ ] 导入 Quartz 框架
  - [ ] 获取主显示器 ID
  - [ ] 创建 CGImage
  - [ ] 转换为 PNG 数据
- [ ] 实现 MethodChannel 处理
- [ ] 测试基础功能

### Phase 2: 高级功能
- [ ] 实现区域截图 (CGImageCreateWithImageInRect)
- [ ] 实现窗口枚举 (CGWindowListCopyWindowInfo)
  - [ ] 获取窗口列表
  - [ ] 提取窗口信息
  - [ ] 过滤不可见窗口
- [ ] 实现窗口截图 (CGWindowListCreateImage)

### Phase 3: 原生区域选择窗口
- [ ] 创建全屏 NSWindow
  - [ ] 设置窗口级别 (screenSaver)
  - [ ] 设置窗口样式 (无边框)
- [ ] 实现鼠标事件处理
  - [ ] 鼠标按下
  - [ ] 鼠标拖拽
  - [ ] 鼠标释放
- [ ] 绘制选择区域
  - [ ] 半透明遮罩
  - [ ] 红色边框
  - [ ] 尺寸信息
- [ ] ESC 键取消支持

### Phase 4: 多显示器支持
- [ ] 检测所有显示器
- [ ] 支持跨显示器选择
- [ ] 处理显示器坐标转换

**预估工作量**: 2-3 天
**技术难度**: ⭐⭐⭐
**优先级**: 🔴 高 (桌面平台)

---

## 🟡 Android 平台

### Phase 1: 权限和基础设置
- [ ] 添加依赖和权限
  - [ ] 在 `AndroidManifest.xml` 添加权限
  - [ ] 配置前台服务
  - [ ] 添加 MediaProjection 依赖
- [ ] 创建 `ScreenshotPlugin.kt`
- [ ] 实现权限请求流程
  - [ ] MediaProjectionManager 初始化
  - [ ] 启动权限请求 Intent
  - [ ] 处理权限结果

### Phase 2: 全屏截图
- [ ] 实现 MediaProjection 会话
  - [ ] 创建 VirtualDisplay
  - [ ] 设置 ImageReader
  - [ ] 处理图像回调
- [ ] 实现图像处理
  - [ ] 将 Image 转换为 Bitmap
  - [ ] 压缩为 PNG
  - [ ] 返回字节数据
- [ ] 实现生命周期管理
  - [ ] 启动/停止前台服务
  - [ ] 释放资源

### Phase 3: 区域截图 (应用内)
- [ ] 实现应用内区域选择 UI
  - [ ] 全屏覆盖 Activity
  - [ ] 处理触摸事件
  - [ ] 绘制选择区域
- [ ] 实现区域裁剪
  - [ ] 全屏截图后裁剪
  - [ ] 返回选中区域

### Phase 4: 用户提示和文档
- [ ] 明确告知用户限制
  - [ ] 只能截取本应用或授权的屏幕
  - [ ] 无法实现真正的桌面级截图
- [ ] 添加使用说明

**预估工作量**: 3-4 天
**技术难度**: ⭐⭐⭐⭐
**优先级**: 🟡 中 (移动平台受限)

---

## 🟡 iOS 平台

### Phase 1: 基础截图
- [ ] 选择技术方案
  - [ ] ReplayKit (系统录制)
  - [ ] ScreenCaptureKit (iOS 16+)
- [ ] 创建 `ScreenshotPlugin.swift`
- [ ] 实现权限请求
  - [ ] 配置 Info.plist
  - [ ] 请求屏幕录制权限
- [ ] 实现基础截图功能

### Phase 2: 区域截图 (应用内)
- [ ] 实现应用内区域选择
  - [ ] 全屏覆盖 UIViewController
  - [ ] 处理触摸事件
  - [ ] 绘制选择区域
- [ ] 实现图像裁剪
  - [ ] UIKit 截图 (UIGraphicsImageRenderer)
  - [ ] 裁剪选中区域

### Phase 3: ScreenCaptureKit (iOS 16+)
- [ ] 实现现代 API
  - [ ] SCShareableContent
  - [ ] SCStreamConfiguration
  - [ ] SCStream
- [ ] 处理多显示器
- [ ] 性能优化

### Phase 4: 用户提示和文档
- [ ] 明确告知用户限制
  - [ ] 只能截取本应用
  - [ ] 无法实现真正的桌面级截图
  - [ ] App Store 审核注意事项
- [ ] 添加使用说明

**预估工作量**: 3-4 天
**技术难度**: ⭐⭐⭐⭐
**优先级**: 🟡 中 (移动平台受限)

---

## ❌ Web 平台

### 评估结果
- [x] 评估技术可行性
  - [x] 浏览器安全策略限制
  - [x] 无法访问操作系统屏幕
  - [x] Screen Capture API 限制

### 可行的替代方案 (可选)
- [ ] 评估 html2canvas
  - [ ] 仅支持应用内 DOM 截图
  - [ ] 无法实现真正的桌面截图
  - [ ] 用户体验差距较大
- [ ] 或直接标注为"不支持"

**预估工作量**: N/A
**技术难度**: N/A
**优先级**: ❌ 不推荐

---

## 📋 通用任务

### 代码重构
- [ ] 统一平台接口错误处理
- [ ] 完善日志输出
- [ ] 添加单元测试
- [ ] 添加集成测试

### 文档完善
- [x] 平台支持分析文档 (PLATFORM_SUPPORT_ANALYSIS.md)
- [ ] 平台实现指南
  - [ ] Linux 实现指南
  - [ ] macOS 实现指南
  - [ ] Android 实现指南
  - [ ] iOS 实现指南
- [ ] 更新主 README
- [ ] 更新 CHANGELOG.md

### 用户体验
- [ ] 平台功能检测和提示
  - [ ] 运行时检测平台支持的功能
  - [ ] 显示不支持功能的说明
  - [ ] 引导用户使用可用的功能
- [ ] 错误提示优化
  - [ ] 友好的错误信息
  - [ ] 建议解决方案

---

## 🎯 里程碑

### Milestone 1: Linux 支持 (下一步)
- [ ] X11 基础截图功能
- [ ] X11 原生区域选择窗口
- [ ] 发布 v0.4.0

### Milestone 2: macOS 支持
- [ ] macOS 基础截图功能
- [ ] macOS 原生区域选择窗口
- [ ] 发布 v0.5.0

### Milestone 3: 移动平台支持 (受限)
- [ ] Android 应用内截图
- [ ] iOS 应用内截图
- [ ] 发布 v0.6.0

### Milestone 4: 功能完善
- [ ] 所有平台单元测试
- [ ] 集成测试
- [ ] 文档完善
- [ ] 发布 v1.0.0

---

## 📊 进度追踪

| 平台 | 基础截图 | 区域截图 | 窗口截图 | 原生窗口 | 完成度 |
|------|---------|---------|---------|---------|--------|
| **Windows** | ✅ | ✅ | ✅ | ✅ | 100% |
| **Linux** | 🔴 | 🔴 | 🔴 | 🔴 | 0% |
| **macOS** | 🔴 | 🔴 | 🔴 | 🔴 | 0% |
| **Android** | 🔴 | 🔴 | ❌ | ❌ | 0% (受限) |
| **iOS** | 🔴 | 🔴 | ❌ | ❌ | 0% (受限) |
| **Web** | ❌ | ❌ | ❌ | ❌ | 不支持 |

**总体完成度**: 16.7% (1/6 平台)

---

## 🔗 相关资源

### 技术文档
- [平台支持分析](./PLATFORM_SUPPORT_ANALYSIS.md) - 详细的技术分析
- [Linux X11 编程](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html)
- [Wayland Portal](https://flatpak.github.io/xdg-desktop-portal/)
- [macOS Quartz 2D](https://developer.apple.com/documentation/quartz)
- [Android MediaProjection](https://developer.android.com/reference/android/media/projection/MediaProjection)
- [iOS ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)

### 开发工具
- **Linux**: X11 开发库 (`libx11-dev`, `libxext-dev`)
- **macOS**: Xcode, Quartz Debugger
- **Android**: Android Studio, ADB
- **iOS**: Xcode, iOS Simulator

---

**维护说明**: 当开始实现新平台时，请在对应的任务前添加 `[进行中]` 标记，完成后更新为 `[x]`。

**最后更新**: 2026-01-16
**下一个目标**: Linux 平台 X11 支持
