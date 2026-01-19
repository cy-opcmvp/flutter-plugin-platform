# 应用图标和应用名称更新

## 📋 更新内容

### 1. 应用名称国际化
- **中文**: 多功能插件平台
- **英文**: Multi-Function Plugin Platform

### 2. 图标设计
- **形状**: 3:4 比例的蓝色长方形框
- **内容**: 中间有一个白色大写字母 "P"
- **颜色**:
  - 背景色: #2962FF (蓝色)
  - 文字色: #FFFFFF (白色)
  - 边框: 白色细边框

## 🚀 快速开始

### 生成图标

#### Windows 用户
双击运行 `scripts/generate_icon.bat`

#### macOS/Linux 用户
```bash
cd scripts
python3 generate_app_icon.py
```

### 安装依赖
首次运行需要安装 Pillow 库：
```bash
pip install Pillow
```

## 📁 生成文件

脚本会自动生成以下位置的图标文件：

### Windows
- `windows/runner/resources/app_icon.ico`

### macOS
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png`

### 通用
- `assets/icons/app_icon_*.png`

### 预览
- `assets/icon_preview.png`

## ✅ 应用更改

### 1. 重新生成国际化文件
```bash
flutter gen-l10n
```

### 2. 重新编译项目
```bash
# Windows
flutter build windows

# macOS
flutter build macos
```

### 3. 运行应用
```bash
flutter run
```

## 🎨 图标设计说明

```
蓝色长方形框 (3:4)
┌──────────────┐
│              │
│      ┌───┐   │
│      │ P │   │  ← 白色大写字母P
│      └───┘   │
│              │
└──────────────┘
    蓝色背景
```

### 尺寸说明
- 支持多种尺寸: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512, 1024x1024
- 所有尺寸保持相同的设计和比例
- 自动适配高DPI显示

## 📝 更新的文件

### 国际化文件
- `lib/l10n/app_zh.arb` - 应用名称: 多功能插件平台
- `lib/l10n/app_en.arb` - 应用名称: Multi-Function Plugin Platform

### 配置文件
- `lib/core/models/tray_config.dart` - 系统托盘默认提示文字

### 新增文件
- `scripts/generate_app_icon.py` - Python 图标生成脚本
- `scripts/generate_icon.bat` - Windows 批处理脚本
- `docs/guides/ICON_GENERATION_GUIDE.md` - 详细指南

## 🔍 验证更改

### 应用名称
- [ ] Windows 窗口标题显示 "多功能插件平台"
- [ ] 系统托盘提示显示 "多功能插件平台"
- [ ] 切换语言后名称正确更新

### 图标
- [ ] 任务栏图标显示新图标
- [ ] 桌面快捷方式显示新图标
- [ ] 系统托盘显示新图标
- [ ] 各种尺寸下图标清晰可见

## 🛠️ 故障排除

### 图标未更新
1. 清理项目: `flutter clean`
2. 删除 build 目录
3. 重新生成图标
4. 重新编译

### Windows 图标缓存
```bash
# 清除图标缓存
ie4uinit.exe -show
```

### Python/Pillow 问题
```bash
# 使用国内镜像安装
pip install Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple
```

## 📚 相关文档

- [图标生成详细指南](../docs/guides/ICON_GENERATION_GUIDE.md)
- [国际化规范](../.claude/CLAUDE.md#国际化开发规范)
- [文件组织规范](../.claude/rules/FILE_ORGANIZATION_RULES.md)

## 🎯 下一步

1. ✅ 运行图标生成脚本
2. ✅ 重新生成国际化文件
3. ✅ 重新编译项目
4. ✅ 验证图标和名称显示正确

---

**版本**: v1.0.0
**更新时间**: 2026-01-19
**适用平台**: Windows, macOS, Linux
