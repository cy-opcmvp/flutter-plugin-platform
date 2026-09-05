# 截图插件文档

> 📸 **插件版本**: v0.3.4
> **最后更新**: 2026-01-16

## 📋 文档索引

### 平台支持
- **[平台支持分析](./PLATFORM_SUPPORT_ANALYSIS.md)** - 各平台功能实现情况详解
  - Windows (✅ 已完成)
  - Linux (🔴 待实现)
  - macOS (🔴 待实现)
  - Android (🟡 受限支持)
  - iOS (🟡 受限支持)
  - Web (❌ 不支持)

### 开发任务
- **[平台实现 TODO](./PLATFORM_TODO.md)** - 各平台开发任务清单
  - Linux X11/Wayland 实现
  - macOS Quartz 实现
  - Android MediaProjection 实现
  - iOS ReplayKit/ScreenCaptureKit 实现

## 🎯 快速概览

| 平台 | 状态 | 完成度 | 备注 |
|------|------|--------|------|
| **Windows** | ✅ 已完成 | 100% | 功能最完整，支持桌面级区域选择 |
| **Linux** | 🔴 待实现 | 0% | 需要支持 X11 和 Wayland |
| **macOS** | 🔴 待实现 | 0% | API 统一，实现相对简单 |
| **Android** | 🟡 受限 | 0% | 只能实现应用内截图 |
| **iOS** | 🟡 受限 | 0% | 只能实现应用内截图 |
| **Web** | ❌ 不支持 | N/A | 浏览器安全限制 |

## 📚 核心功能

### 已实现 (Windows)
- ✅ 全屏截图
- ✅ 区域截图
- ✅ 窗口截图
- ✅ 窗口枚举
- ✅ 原生桌面级区域选择窗口
- ✅ 双缓冲绘制
- ✅ 半透明遮罩效果

### 待实现 (Linux, macOS)
- 🔴 基础截图功能
- 🔴 原生区域选择窗口
- 🔴 窗口管理功能

### 受限支持 (Android, iOS)
- 🟡 全屏截图 (需要用户授权)
- 🟡 应用内区域选择
- ❌ 无法实现真正的桌面级截图

### 不支持 (Web)
- ❌ 浏览器安全策略限制
- ❌ 无法访问操作系统屏幕

## 🚀 下一步计划

1. **Linux 平台支持** (优先级: 🔴 高)
   - X11 基础截图
   - Wayland 支持
   - 原生区域选择窗口

2. **macOS 平台支持** (优先级: 🔴 高)
   - Quartz API 集成
   - 原生区域选择窗口

3. **移动平台支持** (优先级: 🟡 中)
   - Android 应用内截图
   - iOS 应用内截图

## 📖 技术栈

### Windows
- C++ / Win32 API
- GDI/GDI+
- 双缓冲绘制

### Linux (待实现)
- C++ / X11 或 Wayland
- xdg-desktop-portal

### macOS (待实现)
- Swift / Objective-C
- Cocoa / Quartz

### Android (待实现)
- Kotlin
- MediaProjection API

### iOS (待实现)
- Swift
- ReplayKit / ScreenCaptureKit

---

## 📞 联系方式

如有问题或建议，请查看详细文档或提交 Issue。
