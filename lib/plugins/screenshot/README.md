# 截图插件 (Screenshot Plugin)

> 📸 **当前版本**: v0.3.4
> **完整支持**: Windows 平台

## 📋 快速链接

**详细文档**: [docs/plugins/screenshot/README.md](../../../../docs/plugins/screenshot/)
- [平台支持分析](../../../../docs/plugins/screenshot/PLATFORM_SUPPORT_ANALYSIS.md) - 各平台功能实现情况
- [平台实现 TODO](../../../../docs/plugins/screenshot/PLATFORM_TODO.md) - 开发任务清单

## 🎯 功能概述

### Windows 平台 (✅ 已完成)
- 全屏截图
- 区域截图
- 窗口截图
- 窗口枚举
- 原生桌面级区域选择窗口
- 双缓冲绘制技术
- 半透明遮罩效果

### 其他平台 (🔴 待实现)
- **Linux**: X11/Wayland 支持
- **macOS**: Quartz API 支持
- **Android/iOS**: 应用内截图 (受限)
- **Web**: 不支持

## 📁 代码结构

```
lib/plugins/screenshot/
├── models/                      # 数据模型
│   ├── screenshot_models.dart   # 核心模型
│   ├── screenshot_settings.dart # 配置模型
│   └── annotation_models.dart   # 标注模型
├── platform/                    # 平台接口
│   └── screenshot_platform_interface.dart  # 跨平台接口
├── services/                    # 服务层
│   ├── screenshot_service.dart         # 截图服务
│   ├── screenshot_capture_service.dart  # 捕获服务
│   ├── clipboard_service.dart          # 剪贴板服务
│   ├── file_manager_service.dart       # 文件管理
│   └── hotkey_service.dart             # 快捷键服务
├── widgets/                     # UI 组件
│   ├── screenshot_main_widget.dart     # 主界面
│   ├── screenshot_overlay.dart         # 覆盖层
│   ├── screenshot_window.dart          # 截图窗口
│   ├── history_screen.dart             # 历史记录
│   ├── image_editor_screen.dart        # 图像编辑
│   └── settings_screen.dart            # 设置页面
├── screenshot_plugin.dart              # 插件主类
└── screenshot_plugin_factory.dart      # 插件工厂
```

## 🚀 使用方式

### 基本用法

```dart
// 获取截图服务实例
final screenshotService = ScreenshotPlatformInterface.instance;

// 检查平台支持
if (screenshotService.isAvailable) {
  // 捕获全屏
  final imageData = await screenshotService.captureFullScreen();

  // 显示原生区域选择窗口
  await screenshotService.showNativeRegionCapture();
}
```

### 在应用中使用

1. 通过插件工厂创建实例
2. 调用 `buildUI()` 获取界面组件
3. 通过 `PluginContext` 访问平台服务

## 📖 更多信息

查看详细文档了解：
- 各平台实现状态
- 技术栈详情
- 开发任务清单
- 实现指南

---

**插件 ID**: `com.example.screenshot`
**实现平台**: Windows (完整), 其他 (待实现)
**最后更新**: 2026-01-16
