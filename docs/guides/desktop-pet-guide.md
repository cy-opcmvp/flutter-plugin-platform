# Desktop Pet 功能指南

## 概述

Desktop Pet是插件平台的特色功能，允许应用以小窗口形式常驻桌面，提供快速访问和交互功能。

## 功能特性

### 1. 基本功能
- **常驻桌面**: 小窗口形式显示在桌面上
- **置顶显示**: 始终保持在其他窗口之上
- **拖拽移动**: 可以拖拽到桌面任意位置
- **大小调整**: 支持调整窗口大小
- **透明度控制**: 可调整窗口透明度

### 2. 交互功能
- **快速启动**: 双击启动完整应用
- **插件快捷方式**: 右键菜单快速启动插件
- **状态显示**: 显示系统状态和通知
- **动画效果**: 支持各种动画和特效

### 3. 个性化设置
- **主题切换**: 多种外观主题
- **行为设置**: 自定义交互行为
- **位置记忆**: 记住上次位置
- **自动隐藏**: 支持自动隐藏功能

## 启用条件

Desktop Pet功能现在在所有桌面平台上都可用：

### 1. 支持的平台
- ✅ **Windows** - 完整功能支持
- ✅ **macOS** - 完整功能支持  
- ✅ **Linux** - 完整功能支持
- ❌ **Web** - 不支持（浏览器限制）
- ❌ **Mobile** - 不适用

### 2. 功能级别
- **基础功能**: 所有桌面平台都支持
- **高级功能**: 根据平台能力自动启用
  - 窗口置顶: Windows/macOS/Linux
  - 透明度控制: Windows/macOS
  - 系统托盘: Windows/Linux
  - 平滑动画: Windows/macOS

### 3. Steam增强功能（可选）
- 当检测到Steam环境时，提供额外功能
- Steam Workshop集成
- Steam成就系统
- 云端设置同步

## 使用方法

### 1. 启用Desktop Pet模式

```dart
// 通用Desktop Pet管理器
final petManager = DesktopPetManager();
await petManager.initialize();
await petManager.enableDesktopPetMode();

// 检查平台支持
if (DesktopPetManager.isSupported()) {
  print('Desktop Pet is supported on this platform');
}
```

### 2. 配置Desktop Pet

```dart
// 设置位置和大小
await petManager.updatePetPreferences({
  'position': {'x': 100.0, 'y': 100.0},
  'size': {'width': 200.0, 'height': 200.0},
  'opacity': 0.9,
  'animations_enabled': true,
  'theme': 'cute',
});

// 获取平台能力
final capabilities = petManager.getPlatformCapabilities();
print('Always on top supported: ${capabilities['always_on_top']}');
```

### 3. 切换模式

```dart
// 平滑过渡到Desktop Pet模式
await petManager.transitionToDesktopPet();

// 切换回完整应用
await petManager.transitionToFullApplication();

// 检查当前状态
if (petManager.isDesktopPetMode) {
  print('Currently in Desktop Pet mode');
}
```

## Desktop Pet UI组件

### 1. 基础Pet窗口
```dart
class DesktopPetWidget extends StatefulWidget {
  final VoidCallback? onDoubleClick;
  final VoidCallback? onRightClick;
  
  @override
  _DesktopPetWidgetState createState() => _DesktopPetWidgetState();
}

class _DesktopPetWidgetState extends State<DesktopPetWidget> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleClick,
      onSecondaryTap: widget.onRightClick,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.pets,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

### 2. 右键菜单
```dart
class DesktopPetContextMenu extends StatelessWidget {
  final List<PluginDescriptor> availablePlugins;
  final Function(String) onPluginLaunch;
  final VoidCallback onOpenFullApp;
  final VoidCallback onSettings;
  final VoidCallback onExit;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('Open Full App'),
            onTap: onOpenFullApp,
          ),
          Divider(),
          ...availablePlugins.map((plugin) => ListTile(
            leading: Icon(_getPluginIcon(plugin.type)),
            title: Text(plugin.name),
            onTap: () => onPluginLaunch(plugin.id),
          )),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: onSettings,
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Exit Pet Mode'),
            onTap: onExit,
          ),
        ],
      ),
    );
  }
  
  IconData _getPluginIcon(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Icons.build;
      case PluginType.game:
        return Icons.games;
    }
  }
}
```

### 3. 设置面板
```dart
class DesktopPetSettingsPanel extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onPreferencesChanged;
  
  @override
  _DesktopPetSettingsPanelState createState() => _DesktopPetSettingsPanelState();
}

class _DesktopPetSettingsPanelState extends State<DesktopPetSettingsPanel> {
  late Map<String, dynamic> _preferences;
  
  @override
  void initState() {
    super.initState();
    _preferences = Map.from(widget.preferences);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Desktop Pet Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            
            // 透明度设置
            Row(
              children: [
                Text('Opacity:'),
                Expanded(
                  child: Slider(
                    value: _preferences['opacity'],
                    onChanged: (value) {
                      setState(() {
                        _preferences['opacity'] = value;
                      });
                      widget.onPreferencesChanged(_preferences);
                    },
                  ),
                ),
                Text('${(_preferences['opacity'] * 100).round()}%'),
              ],
            ),
            
            // 动画开关
            SwitchListTile(
              title: Text('Enable Animations'),
              value: _preferences['animations_enabled'],
              onChanged: (value) {
                setState(() {
                  _preferences['animations_enabled'] = value;
                });
                widget.onPreferencesChanged(_preferences);
              },
            ),
            
            // 交互开关
            SwitchListTile(
              title: Text('Enable Interactions'),
              value: _preferences['interactions_enabled'],
              onChanged: (value) {
                setState(() {
                  _preferences['interactions_enabled'] = value;
                });
                widget.onPreferencesChanged(_preferences);
              },
            ),
            
            // 自动隐藏
            SwitchListTile(
              title: Text('Auto Hide'),
              value: _preferences['auto_hide'],
              onChanged: (value) {
                setState(() {
                  _preferences['auto_hide'] = value;
                });
                widget.onPreferencesChanged(_preferences);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## 平台特定实现

### Windows实现
```cpp
// windows/runner/desktop_pet_manager.cpp
class DesktopPetManager {
public:
    void EnableDesktopPetMode(HWND hwnd, const PetConfig& config) {
        // 设置窗口样式为工具窗口
        SetWindowLong(hwnd, GWL_EXSTYLE, 
            GetWindowLong(hwnd, GWL_EXSTYLE) | WS_EX_TOOLWINDOW);
        
        // 设置置顶
        SetWindowPos(hwnd, HWND_TOPMOST, 
            config.x, config.y, config.width, config.height,
            SWP_SHOWWINDOW);
        
        // 设置透明度
        SetLayeredWindowAttributes(hwnd, 0, 
            (BYTE)(config.opacity * 255), LWA_ALPHA);
    }
    
    void DisableDesktopPetMode(HWND hwnd) {
        // 恢复正常窗口样式
        SetWindowLong(hwnd, GWL_EXSTYLE, 
            GetWindowLong(hwnd, GWL_EXSTYLE) & ~WS_EX_TOOLWINDOW);
        
        // 取消置顶
        SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE);
    }
};
```

### macOS实现
```swift
// macos/Runner/DesktopPetManager.swift
class DesktopPetManager {
    func enableDesktopPetMode(window: NSWindow, config: PetConfig) {
        // 设置窗口级别
        window.level = .floating
        
        // 设置窗口样式
        window.styleMask = [.borderless, .resizable]
        
        // 设置透明度
        window.alphaValue = config.opacity
        
        // 设置位置
        window.setFrame(NSRect(x: config.x, y: config.y, 
                              width: config.width, height: config.height), 
                       display: true)
    }
    
    func disableDesktopPetMode(window: NSWindow) {
        // 恢复正常级别
        window.level = .normal
        
        // 恢复窗口样式
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        
        // 恢复透明度
        window.alphaValue = 1.0
    }
}
```

## 使用场景

### 1. 快速工具访问
- 计算器快速启动
- 便签快速记录
- 时钟和提醒

### 2. 系统监控
- CPU/内存使用率
- 网络状态显示
- 电池电量（笔记本）

### 3. 娱乐功能
- 桌面宠物动画
- 小游戏快速启动
- 音乐播放控制

## 开发建议

1. **性能优化**: Desktop Pet应该轻量级，避免占用过多系统资源
2. **用户体验**: 提供直观的交互方式和清晰的视觉反馈
3. **兼容性**: 确保在不同操作系统上都能正常工作
4. **可定制性**: 允许用户自定义外观和行为
5. **隐私保护**: 不要在Pet模式下收集敏感信息

Desktop Pet功能为用户提供了一种全新的桌面交互体验，让插件平台真正成为桌面的一部分！