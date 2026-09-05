# AI 编码规则 - 配置响应式管理规范

> 📋 **本文档定义了配置响应式管理的核心原则和实现模式，确保所有配置修改都能实时生效**

**版本**: v1.0.0
**生效日期**: 2026-01-24
**适用范围**: 所有需要实时响应配置变更的功能
**核心原则**: **配置修改必须立即生效，无需重启应用或重新打开功能**

---

## 🎯 核心原则

### 1. 实时生效原则
**所有配置修改必须在用户操作后立即生效，无需重启或刷新**

- ✅ **正确**: 调整透明度滑块，宠物窗口立即变透明
- ❌ **错误**: 调整透明度滑块，需要关闭再打开宠物窗口才生效

### 2. 双向同步原则
**配置必须同时写入两个系统，确保一致性**

- **GlobalConfig** - 全局配置中心，负责持久化
- **运行时状态** - 功能模块内部状态，负责实时使用

### 3. 响应式通知原则
**配置变化必须通知所有监听者，触发 UI 更新**

---

## 📊 配置类型分类

根据配置的使用方式，分为以下几类：

### 类型 1: UI 样式配置（立即生效）
**特点**: 直接影响 UI 显示，配置变化需立即触发 Widget 重建

**示例**:
- 透明度（opacity）
- 颜色（color）
- 字体大小（font_size）
- 主题（theme）

**实现模式**: `ValueNotifier` + `build()` 重建

```dart
// ✅ 正确：使用 ValueNotifier
final ValueNotifier<double> _opacityNotifier = ValueNotifier<double>(1.0);

@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<double>(
    valueListenable: _opacityNotifier,
    builder: (context, opacity, _) {
      return Opacity(
        opacity: opacity,
        child: Widget(),
      );
    },
  );
}

// 修改配置
_opacityNotifier.value = 0.5; // UI 立即更新
```

---

### 类型 2: 功能开关配置（需状态切换）
**特点**: 控制 AnimationController、Timer 等资源的启动/停止

**示例**:
- 启用动画（animations_enabled）
- 启用交互（interactions_enabled）
- 启用自动刷新（auto_refresh）

**实现模式**: `didUpdateWidget` + 动画控制器重启

```dart
// ✅ 正确：使用 didUpdateWidget 监听配置变化
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);

  final oldEnabled = oldWidget.preferences['animations_enabled'] ?? true;
  final newEnabled = widget.preferences['animations_enabled'] ?? true;

  if (oldEnabled != newEnabled) {
    if (newEnabled) {
      // 启用 - 启动动画控制器
      _animationController.repeat(reverse: true);
    } else {
      // 禁用 - 停止动画控制器
      _animationController.stop();
      _animationController.reset();
    }
  }
}
```

---

### 类型 3: 窗口/平台配置（需 API 调用）
**特点**: 需要调用平台 API 或窗口管理 API

**示例**:
- 窗口位置（position）
- 窗口大小（size）
- 窗口置顶（always_on_top）
- 窗口透明度（opacity - window level）

**实现模式**: 直接调用平台 API

```dart
// ✅ 正确：配置修改后立即应用
Future<void> updatePreferences(Map<String, dynamic> preferences) async {
  // 1. 更新内部状态
  _preferences = {..._preferences, ...preferences};

  // 2. 如果功能正在运行，立即应用更改
  if (_isFeatureActive) {
    await _applyPreferences();
  }
}

Future<void> _applyPreferences() async {
  // 应用到窗口
  await windowManager.setOpacity(_preferences['opacity'] ?? 1.0);
  await windowManager.setPosition(Offset(_preferences['x'], _preferences['y']));
  await windowManager.setSize(Size(_preferences['width'], _preferences['height']));
}
```

---

### 类型 4: 回调开关配置（需重建监听器）
**特点**: 控制事件监听器的启用/禁用

**示例**:
- 启用交互（interactions_enabled）- 控制鼠标事件
- 启用拖拽（draggable）- 控制手势识别

**实现模式**: `build()` 重建时重新设置回调

```dart
// ✅ 正确：在 build() 中根据配置设置回调
@override
Widget build(BuildContext context) {
  return Listener(
    // 配置变化时，Widget 重建，回调会重新设置
    onPointerDown: _isInteractionsEnabled ? _handlePointerDown : null,
    onPointerMove: _isInteractionsEnabled ? _handlePointerMove : null,
    onPointerUp: _isInteractionsEnabled ? _handlePointerUp : null,
    behavior: HitTestBehavior.opaque,
    child: Widget(),
  );
}
```

---

## 🔄 完整实现模式

### 模式 1: ValueNotifier 模式（UI 样式配置）

**适用场景**: 配置影响 UI 显示，需要立即重建

**实现步骤**:

1. **在 Manager 层定义 ValueNotifier**
```dart
class MyManager {
  final ValueNotifier<Map<String, dynamic>> _preferencesNotifier =
      ValueNotifier<Map<String, dynamic>>({
    'opacity': 1.0,
    'color': Colors.blue,
  });

  // 对外暴露只读访问器
  Map<String, dynamic> get preferences => Map.from(_preferencesNotifier.value);
  ValueNotifier<Map<String, dynamic>> get preferencesNotifier => _preferencesNotifier;
}
```

2. **在 Screen 层监听变化**
```dart
class MyScreen extends StatefulWidget {
  final MyManager manager;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  Map<String, dynamic> _currentPreferences = {};

  @override
  void initState() {
    super.initState();
    _currentPreferences = widget.manager.preferences;
    widget.manager.preferencesNotifier.addListener(_onPreferencesChanged);
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        _currentPreferences = widget.manager.preferences;
      });
    }
  }

  @override
  void dispose() {
    widget.manager.preferencesNotifier.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyWidget(preferences: _currentPreferences);
  }
}
```

3. **在 Widget 层使用配置**
```dart
class MyWidget extends StatelessWidget {
  final Map<String, dynamic> preferences;

  const MyWidget({required this.preferences});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: preferences['opacity'] ?? 1.0,
      child: Widget(),
    );
  }
}
```

---

### 模式 2: didUpdateWidget 模式（功能开关配置）

**适用场景**: 配置控制 AnimationController、Timer 等资源

**实现步骤**:

1. **在 initState 中初始化资源**
```dart
@override
void initState() {
  super.initState();

  _animationController = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );

  // 根据初始配置启动动画
  if (_isAnimationsEnabled) {
    _animationController.repeat(reverse: true);
  }
}
```

2. **在 didUpdateWidget 中监听配置变化**
```dart
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);

  final oldEnabled = oldWidget.preferences['animations_enabled'] ?? true;
  final newEnabled = widget.preferences['animations_enabled'] ?? true;

  if (oldEnabled != newEnabled) {
    if (newEnabled) {
      // 启用动画
      _animationController.repeat(reverse: true);
    } else {
      // 禁用动画
      _animationController.stop();
      _animationController.reset();
    }
  }
}
```

3. **在 dispose 中释放资源**
```dart
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

---

### 模式 3: 双向同步模式（配置持久化）

**适用场景**: 配置需要同时写入 GlobalConfig 和运行时状态

**实现步骤**:

1. **配置修改时同时更新两个系统**
```dart
Future<void> updatePreferences(Map<String, dynamic> preferences) async {
  // 1️⃣ 更新运行时状态（ValueNotifier）
  _preferencesNotifier.value = {
    ..._preferencesNotifier.value,
    ...preferences,
  };

  // 2️⃣ 同时同步到 GlobalConfig（持久化）
  try {
    final globalConfig = ConfigManager.instance.globalConfig;
    final featureConfig = globalConfig.features.myFeature;

    final newFeatureConfig = featureConfig.copyWith(
      opacity: preferences['opacity'] ?? featureConfig.opacity,
      animationsEnabled: preferences['animations_enabled'] ?? featureConfig.animationsEnabled,
    );

    final newFeatures = globalConfig.features.copyWith(myFeature: newFeatureConfig);
    final newConfig = globalConfig.copyWith(features: newFeatures);

    await ConfigManager.instance.updateGlobalConfig(newConfig);
    PlatformLogger.instance.logInfo('✅ 已同步配置到 GlobalConfig');
  } catch (e) {
    PlatformLogger.instance.logError('Failed to sync to GlobalConfig', e);
  }

  // 3️⃣ 如果功能正在运行，立即应用
  if (_isFeatureActive) {
    await _applyPreferences();
  }
}
```

2. **功能启动时从 GlobalConfig 加载最新配置**
```dart
Future<void> _createFeatureWindow() async {
  // 【关键】从 GlobalConfig 加载最新配置
  await _loadPreferences();

  // 继续创建窗口...
}
```

---

## ⚠️ 常见错误

### 错误 1: 只更新 GlobalConfig，不更新运行时状态

```dart
// ❌ 错误：只更新 GlobalConfig
Future<void> updateOpacity(double opacity) async {
  final globalConfig = ConfigManager.instance.globalConfig;
  final newConfig = globalConfig.copyWith(
    features: globalConfig.features.copyWith(
      myFeature: globalConfig.features.myFeature.copyWith(opacity: opacity)
    )
  );
  await ConfigManager.instance.updateGlobalConfig(newConfig);
  // 运行时状态未更新，UI 不会刷新！
}

// ✅ 正确：同时更新两个系统
Future<void> updateOpacity(double opacity) async {
  // 1. 更新运行时状态
  _preferencesNotifier.value = {..._preferencesNotifier.value, 'opacity': opacity};

  // 2. 同步到 GlobalConfig
  final globalConfig = ConfigManager.instance.globalConfig;
  // ...（同上）
}
```

---

### 错误 2: 在 initState 中启动资源，但配置变化时不重启

```dart
// ❌ 错误：动画只在 initState 中启动一次
@override
void initState() {
  super.initState();
  _animationController = AnimationController(vsync: this);

  if (_isAnimationsEnabled) {
    _animationController.repeat(reverse: true);
  }
  // 配置变化时，initState 不会再次调用，动画不会重启！
}

// ✅ 正确：使用 didUpdateWidget 监听配置变化
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);

  final oldEnabled = oldWidget.preferences['animations_enabled'] ?? true;
  final newEnabled = widget.preferences['animations_enabled'] ?? true;

  if (oldEnabled != newEnabled) {
    if (newEnabled) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
    }
  }
}
```

---

### 错误 3: 配置在功能打开时加载，但不是最新值

```dart
// ❌ 错误：功能打开时使用缓存的配置
Future<void> _createFeatureWindow() async {
  final config = _cachedConfig; // 使用缓存，可能是旧值！
  await windowManager.setOpacity(config['opacity']);
}

// ✅ 正确：从 GlobalConfig 加载最新配置
Future<void> _createFeatureWindow() async {
  // 【关键】从 GlobalConfig 加载最新配置
  await _loadPreferences();

  final config = _preferences;
  await windowManager.setOpacity(config['opacity']);
}
```

---

## ✅ 检查清单

### 开发阶段
- [ ] 确定配置类型（UI 样式 / 功能开关 / 窗口 API / 回调开关）
- [ ] 选择正确的实现模式
- [ ] Manager 层使用 ValueNotifier 管理配置
- [ ] Screen 层监听配置变化
- [ ] Widget 层使用配置并响应变化

### 功能开关配置（如启用动画）
- [ ] 在 initState 中初始化资源
- [ ] 在 didUpdateWidget 中监听配置变化
- [ ] 配置启用时正确启动资源
- [ ] 配置禁用时正确停止资源
- [ ] 在 dispose 中释放资源

### 双向同步
- [ ] updatePreferences 同时更新运行时状态和 GlobalConfig
- [ ] 功能打开时从 GlobalConfig 加载最新配置
- [ ] 功能运行时立即应用配置变化

### 测试阶段
- [ ] 测试配置修改后立即生效
- [ ] 测试关闭再打开功能后使用新配置
- [ ] 测试多次调整配置都能正确保存和应用

---

## 📚 参考实现

### 完整参考：桌面宠物透明度配置

**涉及文件**:
- `lib/core/services/desktop_pet_manager.dart` - Manager 层
- `lib/ui/screens/desktop_pet_screen.dart` - Screen 层
- `lib/ui/widgets/desktop_pet_widget.dart` - Widget 层

**关键代码**:

1. **Manager 层** - ValueNotifier + 双向同步
```dart
class DesktopPetManager {
  final ValueNotifier<Map<String, dynamic>> _petPreferencesNotifier =
      ValueNotifier<Map<String, dynamic>>({
    'opacity': 1.0,
    'animations_enabled': true,
    'interactions_enabled': true,
  });

  Future<void> updatePetPreferences(Map<String, dynamic> preferences) async {
    // 1. 更新运行时状态
    _petPreferencesNotifier.value = {
      ..._petPreferencesNotifier.value,
      ...preferences,
    };

    // 2. 同步到 GlobalConfig
    final globalConfig = ConfigManager.instance.globalConfig;
    final petConfig = globalConfig.features.desktopPet;
    final newPetConfig = petConfig.copyWith(
      opacity: preferences['opacity'] ?? petConfig.opacity,
      animationsEnabled: preferences['animations_enabled'] ?? petConfig.animationsEnabled,
      interactionsEnabled: preferences['interactions_enabled'] ?? petConfig.interactionsEnabled,
    );
    await ConfigManager.instance.updateGlobalConfig(
      globalConfig.copyWith(features: globalConfig.features.copyWith(desktopPet: newPetConfig))
    );

    // 3. 立即应用
    if (_isDesktopPetMode) {
      await _applyPetPreferences();
    }
  }
}
```

2. **Screen 层** - 监听配置变化
```dart
class _DesktopPetScreenState extends State<DesktopPetScreen> {
  Map<String, dynamic> _currentPetPreferences = {};

  @override
  void initState() {
    super.initState();
    _currentPetPreferences = widget.petManager.petPreferences;
    widget.petManager.petPreferencesNotifier.addListener(_onPetPreferencesChanged);
  }

  void _onPetPreferencesChanged() {
    if (mounted) {
      setState(() {
        _currentPetPreferences = widget.petManager.petPreferences;
      });
    }
  }

  @override
  void dispose() {
    widget.petManager.petPreferencesNotifier.removeListener(_onPetPreferencesChanged);
    super.dispose();
  }
}
```

3. **Widget 层** - didUpdateWidget 监听功能开关
```dart
class _DesktopPetWidgetState extends State<DesktopPetWidget> {
  @override
  void didUpdateWidget(DesktopPetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldAnimationsEnabled = oldWidget.preferences['animations_enabled'] ?? true;
    final newAnimationsEnabled = widget.preferences['animations_enabled'] ?? true;

    if (oldAnimationsEnabled != newAnimationsEnabled) {
      if (newAnimationsEnabled) {
        _breathingController!.repeat(reverse: true);
        _startRandomBlinking();
      } else {
        _breathingController!.stop();
        _blinkController!.stop();
        _breathingController!.reset();
        _blinkController!.reset();
      }
    }
  }
}
```

---

## 🎯 快速参考

| 配置类型 | 实现模式 | 关键方法 |
|---------|---------|---------|
| **UI 样式** | ValueNotifier | `build()` 重建 |
| **功能开关** | didUpdateWidget | 动画控制器重启 |
| **窗口 API** | 直接调用 | `_applyPreferences()` |
| **回调开关** | build 重建 | 重新设置回调 |
| **持久化** | 双向同步 | 同时更新两个系统 |

---

## 📖 相关文档

- [性能优化规范](./PERFORMANCE_OPTIMIZATION_RULES.md) - ValueNotifier 性能优化
- [代码风格规范](./CODE_STYLE_RULES.md) - Flutter 状态管理
- [插件配置规范](./PLUGIN_CONFIG_SPEC.md) - 配置文件管理

---

**版本**: v1.0.0
**最后更新**: 2026-01-24
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 遵循本规范，确保所有配置都能实时生效，提升用户体验！
