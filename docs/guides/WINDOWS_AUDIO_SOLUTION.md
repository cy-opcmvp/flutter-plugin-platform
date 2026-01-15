# Windows 平台音频功能启用指南

## 🎯 当前状态

**音频服务**: ❌ 已禁用（由于 Windows 构建问题）
- **原因**: `audioplayers` 包在 Windows 上依赖 NuGet 包，导致构建失败
- **影响**: 无法播放系统音效和背景音乐

## 📋 解决方案对比

### 方案 1: 使用替代音频包 ⭐ **推荐**

#### 优点
- ✅ 无 NuGet 依赖问题
- ✅ 跨平台支持良好
- ✅ 活跃维护
- ✅ API 相似，迁移成本低

#### 推荐包
1. **`just_audio`** (最推荐)
   - Flutter 团队推荐
   - 跨平台支持好
   - Windows 使用 `dart_vlc` 或 `windows_media`
   - 文档: https://pub.dev/packages/just_audio

2. **`assets_audio_player`**
   - 功能更丰富
   - 支持更多音频格式
   - Windows 支持良好
   - 文档: https://pub.dev/packages/assets_audio_player

#### 实施步骤
```yaml
# pubspec.yaml
dependencies:
  just_audio: ^0.9.36  # 或最新版本
```

**需要修改的代码**:
- `lib/core/services/audio/audio_service.dart`
- `lib/core/interfaces/services/i_audio_service.dart` (可能需要适配新包的 API)

### 方案 2: 平台特定实现

#### 为 Windows 使用原生 API

**Windows API 实现**:
- 使用 `dart:ffi` 调用 Win32 API
- `PlaySound()` 或 `sndPlaySound()`
- 或使用 Media Foundation

**其他平台使用 audioplayers**

#### 优点
- ✅ 无外部依赖
- ✅ 完全控制
- ✅ 性能最佳

#### 缺点
- ❌ 需要编写 FFI 代码
- ❌ 维护成本高
- ❌ 需要处理平台差异

### 方案 3: 手动解决 NuGet 问题（临时）

#### 当前问题
```
Package 'Microsoft.Windows.ImplementationLibrary 1.0.210803.1' is not found
```

#### 尝试步骤

1. **安装 Windows SDK**
   ```bash
   # 下载并安装 Windows 10/11 SDK
   # https://developer.microsoft.com/windows/downloads/windows-sdk/
   ```

2. **配置 NuGet 源**
   ```powershell
   # 管理员权限运行
   nuget sources Add -Name "nuget.org" -Source "https://api.nuget.org/v3/index.json"
   ```

3. **手动安装包**
   ```powershell
   # 运行项目中的脚本
   .\scripts\fix-nuget.ps1
   .\scripts\install-cppwinrt.ps1
   ```

4. **清理并重新构建**
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

#### 成功率
- ⚠️ 不保证成功
- ⚠️ 可能在其他机器上失败
- ⚠️ NuGet 包版本更新后可能再次失败

### 方案 4: 仅在非 Windows 平台启用

#### 使用条件导入

```dart
// lib/core/services/audio/audio_service_stub.dart
// Windows 平台的存根实现

import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';

class AudioServiceImpl extends IAudioService {
  @override
  Future<void> playSystemSound({required SystemSoundType soundType, double volume = 1.0}) async {
    // Windows 不播放声音，或使用系统 Beep
    print('Audio not supported on Windows in this build');
  }

  // ... 其他方法
}
```

```dart
// lib/core/services/audio/audio_service.dart
// 其他平台的实现

import 'package:audioplayers/audioplayers.dart';

class AudioServiceImpl extends IAudioService {
  // 完整实现
}
```

```dart
// lib/core/services/platform_service_manager.dart
export 'audio/audio_service_stub.dart' if (dart.library.io) 'audio/audio_service.dart';
```

## 🎯 推荐方案：使用 `just_audio`

### 步骤 1: 更新 pubspec.yaml

```yaml
dependencies:
  # 替换 audioplayers
  just_audio: ^0.9.36
```

### 步骤 2: 运行 flutter pub get

```bash
flutter pub get
```

### 步骤 3: 更新音频服务实现

修改 `lib/core/services/audio/audio_service.dart`:

```dart
import 'package:just_audio/just_audio.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';

class AudioServiceImpl extends IAudioService {
  final Map<String, AudioPlayer> _players = {};
  double _globalVolume = 1.0;

  @override
  Future<void> playSystemSound({
    required SystemSoundType soundType,
    double volume = 1.0,
  }) async {
    // just_audio 使用不同的方式播放系统音效
    // 可以使用 AssetSource 播放预定义的音效文件
    final player = AudioPlayer();
    await player.setAssetSource('assets/audio/notification.mp3');
    await player.setVolume(volume * _globalVolume);
    await player.play();
  }

  @override
  Future<String> playMusic({
    required String musicPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    final player = AudioPlayer();
    final playerId = DateTime.now().millisecondsSinceEpoch.toString();

    await player.setUrl(musicPath);
    await player.setVolume(volume * _globalVolume);
    if (loop) {
      await player.setLoopMode(LoopMode.one);
    }
    await player.play();

    _players[playerId] = player;
    return playerId;
  }

  @override
  Future<void> stopMusic(String musicId) async {
    final player = _players[musicId];
    if (player != null) {
      await player.stop();
      await player.dispose();
      _players.remove(musicId);
    }
  }

  // ... 其他方法实现
}
```

### 步骤 4: 重新启用音频服务

修改 `lib/core/services/platform_service_manager.dart`:

```dart
// 取消注释音频服务导入
import 'package:plugin_platform/core/services/audio/audio_service.dart';

// 在 _registerServices 中取消注释
locator.registerSingleton<IAudioService>(
  AudioServiceImpl(),
);

// 在 _initializeServices 中取消注释
final audioService = locator.get<IAudioService>();
final audioInitialized = await audioService.initialize();
```

修改 `pubspec.yaml`:

```yaml
# 取消注释
audioplayers: ^5.2.1

# 或者替换为
just_audio: ^0.9.36
```

### 步骤 5: 测试

```bash
flutter clean
flutter pub get
flutter run -d windows
```

## 🔄 迁移成本评估

### 从 audioplayers 迁移到 just_audio

| 功能 | audioplayers | just_audio | 迁移难度 |
|------|---------------|------------|---------|
| 系统音效 | ✅ 直接支持 | ⚠️ 需要使用音频文件 | 中等 |
| 背景音乐 | ✅ 支持 | ✅ 支持 | 简单 |
| 音量控制 | ✅ 支持 | ✅ 支持 | 简单 |
| 音频池 | ✅ 内置 | ⚠️ 需要自己管理 | 中等 |
| 流媒体 | ✅ 支持 | ✅ 支持 | 简单 |
| 跨平台 | ✅ 全平台 | ✅ 全平台 | 简单 |

### 需要修改的代码量

- **接口定义**: `lib/core/interfaces/services/i_audio_service.dart` - 可能需要微调
- **服务实现**: `lib/core/services/audio/audio_service.dart` - 重写（~200 行）
- **音频文件**: 需要添加实际的 .mp3 文件到 `assets/audio/`
- **测试更新**: `test/core/services/audio/` - 更新测试用例

## ⚡ 快速开始（推荐）

如果您想快速启用音频功能，建议：

### 选项 A: 使用 just_audio（1-2小时）

**适合**: 希望快速解决问题，愿意接受一些 API 差异

**步骤**:
1. 修改 `pubspec.yaml`，添加 `just_audio: ^0.9.36`
2. 重写 `audio_service.dart`（使用上面的模板）
3. 添加音频文件到 `assets/audio/`
4. 测试

**时间**: 1-2 小时
**风险**: 低

### 选项 B: 暂时接受无音频（推荐用于开发）

**适合**: 当前开发阶段，音频不是核心功能

**做法**: 保持现状，专注其他功能

**时间**: 0 分钟
**风险**: 无

### 选项 C: 深度定制（1-2天）

**适合**: 音频是核心功能，需要完全控制

**做法**:
1. 为 Windows 实现 FFI 调用 Win32 API
2. 其他平台使用 audioplayers
3. 处理所有平台差异

**时间**: 1-2 天
**风险**: 中等（需要 FFI 知识）

## 📊 决策树

```
需要音频功能吗？
├── 否 → 保持现状（选项 B）
└── 是 → 音频是核心功能吗？
    ├── 否 → 使用 just_audio（选项 A）
    └── 是 → 有 FFI 经验吗？
        ├── 是 → 深度定制（选项 C）
        └── 否 → 使用 just_audio（选项 A）
```

## 🎯 我的建议

根据当前项目状态，我建议：

### 短期（现在）
**保持现状** - 音频功能暂时禁用，优先完成其他核心功能

理由:
- ✅ 应用可以正常运行
- ✅ 通知和任务调度功能正常
- ✅ 不阻塞开发进度

### 中期（下个版本）
**使用 `just_audio`** - 重写音频服务

理由:
- ✅ 解决 Windows 构建问题
- ✅ 跨平台支持更好
- ✅ 迁移成本可接受
- ✅ 长期维护性更好

### 长期（如果需要）
**添加实际音频文件** - 完善 UX

需要添加:
- `assets/audio/notification.mp3`
- `assets/audio/click.mp3`
- `assets/alarm.mp3`
- 其他音效文件

## 📞 下一步行动

请告诉我您想采用哪个方案：

**A. 现在就实现 just_audio**
- 我可以帮您重写音频服务代码
- 1-2 小时完成

**B. 等待更合适的时机**
- 保持现状
- 专注其他功能

**C. 探索其他方案**
- 我可以研究其他音频包
- 或评估其他技术方案

---

**最后更新**: 2026-01-15
**维护者**: Flutter Plugin Platform Team
