import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/desktop_pet_manager.dart';
import '../../core/services/platform_core.dart';
import '../../core/services/platform_logger.dart';
import '../../core/models/plugin_models.dart';
import '../../core/models/platform_models.dart';
import '../widgets/desktop_pet_widget.dart';

/// Desktop Pet主界面
class DesktopPetScreen extends StatefulWidget {
  final DesktopPetManager petManager;
  final PlatformCore platformCore;
  
  const DesktopPetScreen({
    super.key,
    required this.petManager,
    required this.platformCore,
  });

  @override
  State<DesktopPetScreen> createState() => _DesktopPetScreenState();
}

class _DesktopPetScreenState extends State<DesktopPetScreen> {
  bool _showContextMenu = false;
  bool _showSettings = false;
  List<PluginDescriptor> _availablePlugins = [];
  
  @override
  void initState() {
    super.initState();
    _loadAvailablePlugins();
  }

  Future<void> _loadAvailablePlugins() async {
    try {
      final plugins = await widget.platformCore.pluginManager.getAvailablePlugins();
      setState(() {
        _availablePlugins = plugins;
      });
    } catch (e) {
      PlatformLogger.instance.logError('Failed to load plugins', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if desktop pet is supported on this platform
    if (!DesktopPetManager.isSupported()) {
      return _buildUnsupportedPlatformUI(context);
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.1), // 半透明背景，让用户知道这是Desktop Pet模式
      body: Stack(
        children: [
          // 全屏点击区域，用于隐藏菜单
          GestureDetector(
            onTap: () {
              setState(() {
                _showContextMenu = false;
                _showSettings = false;
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          
          // 主要的Desktop Pet组件
          DesktopPetWidget(
            preferences: widget.petManager.petPreferences,
            onDoubleClick: _returnToFullApp,
            onRightClick: _toggleContextMenu,
          ),
          
          // 退出提示（只在刚进入时显示几秒钟）
          if (!_showContextMenu && !_showSettings)
            Positioned(
              top: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: 0.7,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '双击宠物返回 • 右键查看菜单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          
          // 右键菜单
          if (_showContextMenu)
            Positioned(
              top: 150,
              left: 50,
              child: DesktopPetContextMenu(
                quickActions: _availablePlugins.map((p) => p.name).toList(),
                onActionSelected: _launchPlugin,
                onOpenFullApp: _returnToFullApp,
                onSettings: _toggleSettings,
                onExitPetMode: _exitPetMode,
              ),
            ),
          
          // 设置面板
          if (_showSettings)
            Positioned(
              top: 50,
              right: 50,
              child: DesktopPetSettingsPanel(
                preferences: widget.petManager.petPreferences,
                onPreferencesChanged: _updatePreferences,
                onClose: _toggleSettings,
              ),
            ),
        ],
      ),
    );
  }

  /// Build UI for unsupported platforms (web, mobile)
  Widget _buildUnsupportedPlatformUI(BuildContext context) {
    final platformName = kIsWeb ? 'Web' : 'Mobile';
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Desktop Pet'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                kIsWeb ? Icons.web : Icons.phone_android,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Desktop Pet Not Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Desktop Pet functionality is not supported on $platformName platform. '
                'This feature requires a desktop environment with window management capabilities.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (kIsWeb) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Web Platform Limitations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Web browsers do not support:\n'
                        '• Desktop window management\n'
                        '• Always-on-top windows\n'
                        '• System tray integration\n'
                        '• Native desktop interactions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Main App'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _showPlatformInfo,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Platform Info'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleContextMenu() {
    setState(() {
      _showContextMenu = !_showContextMenu;
      if (_showContextMenu) {
        _showSettings = false; // 关闭设置面板
      }
    });
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
      if (_showSettings) {
        _showContextMenu = false; // 关闭右键菜单
      }
    });
  }

  Future<void> _returnToFullApp() async {
    try {
      await widget.petManager.transitionToFullApplication();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to return to full app', e);
    }
  }

  Future<void> _exitPetMode() async {
    try {
      await widget.petManager.disableDesktopPetMode();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to exit pet mode', e);
    }
  }

  Future<void> _launchPlugin(String pluginName) async {
    try {
      // 找到对应的插件
      final plugin = _availablePlugins.firstWhere(
        (p) => p.name == pluginName,
        orElse: () => throw Exception('Plugin not found: $pluginName'),
      );
      
      // 启动插件
      await widget.platformCore.pluginManager.loadPlugin(plugin);
      
      // 关闭菜单
      setState(() {
        _showContextMenu = false;
      });
      
      // 显示通知
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launched $pluginName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to launch plugin: $pluginName', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch $pluginName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await widget.petManager.updatePetPreferences(preferences);
    } catch (e) {
      PlatformLogger.instance.logError('Failed to update preferences', e);
    }
  }

  /// Show platform information dialog for non-web platforms
  void _showPlatformInfo() {
    if (kIsWeb) return; // Should not be called on web
    
    final capabilities = PlatformCapabilities.forNative();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platform Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Desktop Pet requires the following capabilities:'),
            const SizedBox(height: 12),
            _buildCapabilityItem('Desktop Environment', capabilities.supportsDesktopPet),
            _buildCapabilityItem('Window Management', capabilities.supportsAlwaysOnTop),
            _buildCapabilityItem('System Tray', capabilities.supportsSystemTray),
            _buildCapabilityItem('File System Access', capabilities.supportsFileSystem),
            const SizedBox(height: 12),
            const Text(
              'Your current platform may not support all these features. '
              'Desktop Pet works best on Windows, macOS, and Linux desktop environments.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String name, bool supported) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            supported ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: supported ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
}

/// Desktop Pet快速启动器
class DesktopPetLauncher {
  static Future<void> showPetMode(
    BuildContext context,
    DesktopPetManager petManager,
    PlatformCore platformCore,
  ) async {
    // Check platform support before launching
    if (!DesktopPetManager.isSupported()) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Launcher',
        'Platform does not support desktop pet functionality'
      );
      
      // Show a brief message and navigate to the unsupported screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb 
                ? 'Desktop Pet is not available on web platform'
                : 'Desktop Pet is not supported on this platform'
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DesktopPetScreen(
          petManager: petManager,
          platformCore: platformCore,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 淡入淡出动画
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        opaque: false, // 允许透明背景
      ),
    );
  }
}