import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/services/desktop_pet_manager.dart';
import '../../core/services/platform_core.dart';
import '../../core/services/platform_logger.dart';
import '../../core/models/plugin_models.dart';
import '../../core/models/platform_models.dart';
import '../../core/extensions/context_extensions.dart';
import '../widgets/desktop_pet_widget.dart';

/// 宠物尺寸常量
const double kPetSize = 120.0;

/// 菜单宽度
const double kMenuWidth = 160.0;

/// 菜单与宠物的间距
const double kMenuGap = 8.0;

/// Desktop Pet主界面
class DesktopPetScreen extends StatefulWidget {
  final DesktopPetManager petManager;
  final PlatformCore platformCore;

  /// 插件启动回调 - 返回要启动的插件描述符
  final void Function(PluginDescriptor plugin)? onLaunchPlugin;

  const DesktopPetScreen({
    super.key,
    required this.petManager,
    required this.platformCore,
    this.onLaunchPlugin,
  });

  @override
  State<DesktopPetScreen> createState() => _DesktopPetScreenState();
}

class _DesktopPetScreenState extends State<DesktopPetScreen>
    with WindowListener, SingleTickerProviderStateMixin {
  bool _showContextMenu = false;
  bool _isReady = false; // 控制是否显示内容
  List<PluginDescriptor> _availablePlugins = [];

  // 窗口和宠物位置信息
  Size _windowSize = Size.zero;
  Offset _windowPosition = Offset.zero;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadAvailablePlugins();

    // 初始化淡入动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 延迟显示内容，确保窗口透明设置完成
    _initializeWindow();
  }

  Future<void> _initializeWindow() async {
    if (!DesktopPetManager.isSupported()) {
      setState(() => _isReady = true);
      return;
    }

    try {
      // 获取窗口信息
      _windowSize = await windowManager.getSize();
      _windowPosition = await windowManager.getPosition();

      // 短暂延迟确保窗口透明设置生效
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        setState(() => _isReady = true);
        _fadeController.forward();
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to initialize window', e);
      if (mounted) {
        setState(() => _isReady = true);
        _fadeController.forward();
      }
    }
  }

  @override
  void onWindowMove() {
    _updateWindowPosition();
  }

  Future<void> _updateWindowPosition() async {
    try {
      _windowPosition = await windowManager.getPosition();
      _windowSize = await windowManager.getSize();
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePlugins() async {
    try {
      final plugins = await widget.platformCore.pluginManager
          .getAvailablePlugins();
      setState(() {
        _availablePlugins = plugins;
      });
    } catch (e) {
      PlatformLogger.instance.logError('Failed to load plugins', e);
    }
  }

  /// 计算菜单位置 - 根据宠物在屏幕上的位置智能选择
  Offset _calculateMenuPosition(Size screenSize) {
    // 如果窗口大小未初始化，使用默认位置
    if (_windowSize.width < 50 || _windowSize.height < 50) {
      return const Offset(10.0, 10.0);
    }

    // 宠物在窗口中心
    final petCenterX = _windowSize.width / 2;
    final petCenterY = _windowSize.height / 2;

    // 宠物在屏幕上的绝对位置
    final petScreenX = _windowPosition.dx + petCenterX;
    final petScreenY = _windowPosition.dy + petCenterY;

    // 判断宠物在屏幕的哪个象限
    final isLeft = petScreenX < screenSize.width / 2;
    final isTop = petScreenY < screenSize.height / 2;

    // 菜单相对于窗口的位置
    double menuX, menuY;

    if (isLeft) {
      // 宠物在左边，菜单显示在右边
      menuX = petCenterX + kPetSize / 2 + kMenuGap;
    } else {
      // 宠物在右边，菜单显示在左边
      menuX = petCenterX - kPetSize / 2 - kMenuWidth - kMenuGap;
    }

    if (isTop) {
      // 宠物在上边，菜单显示在下边
      menuY = petCenterY + kPetSize / 2 + kMenuGap;
    } else {
      // 宠物在下边，菜单显示在上边
      menuY = petCenterY - kPetSize / 2 - kMenuGap - 150; // 菜单高度约150
    }

    // 确保菜单位置有效（不使用clamp避免参数问题）
    if (menuX < 4) menuX = 4;
    if (menuX > _windowSize.width - kMenuWidth - 4) {
      menuX = _windowSize.width - kMenuWidth - 4;
    }
    if (menuY < 4) menuY = 4;
    if (menuY > _windowSize.height - 150) {
      menuY = _windowSize.height - 150;
    }

    // 最终安全检查
    if (menuX < 0) menuX = 4;
    if (menuY < 0) menuY = 4;

    return Offset(menuX, menuY);
  }

  @override
  Widget build(BuildContext context) {
    // Check if desktop pet is supported on this platform
    if (!DesktopPetManager.isSupported()) {
      return _buildUnsupportedPlatformUI(context);
    }

    // 等待窗口初始化完成
    if (!_isReady) {
      return const SizedBox.shrink(); // 完全透明，不显示任何内容
    }

    final screenSize = MediaQuery.of(context).size;
    final menuPosition = _calculateMenuPosition(screenSize);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // 背景层 - 完全不接收鼠标事件，让其穿透到桌面
          // 使用 IgnorePointer 让所有鼠标事件穿透
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.transparent),
            ),
          ),

          // 宠物组件 - 居中显示并捕获事件
          Center(
            child: DesktopPetWidget(
              preferences: widget.petManager.petPreferences,
              onDoubleClick: _returnToFullApp,
              onRightClick: () {
                setState(() {
                  _showContextMenu = !_showContextMenu;
                });
              },
            ),
          ),

          // 右键菜单 - 智能定位（如果有菜单，显示一个透明背景层来捕获菜单外的点击）
          if (_showContextMenu) ...[
            // 透明背景层 - 点击菜单外区域关闭菜单
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showContextMenu = false;
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // 菜单本身
            Positioned(
              left: menuPosition.dx,
              top: menuPosition.dy,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                child: DesktopPetContextMenu(
                  quickActions: _availablePlugins
                      .map((p) => p.name)
                      .toList(),
                  onActionSelected: _launchPlugin,
                  onOpenFullApp: _returnToFullApp,
                  onSettings: _toggleSettings,
                  onExitPetMode: _exitPetMode,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build UI for unsupported platforms (web, mobile)
  Widget _buildUnsupportedPlatformUI(BuildContext context) {
    final platformName = kIsWeb ? 'Web' : 'Mobile';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.pet_title),
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
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.pet_notSupported,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.pet_notSupportedDesc(platformName),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                        l10n.pet_webLimitation,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.pet_webLimitationDesc,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
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
                    label: Text(l10n.pet_returnToApp),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _showPlatformInfo,
                      icon: const Icon(Icons.info_outline),
                      label: Text(l10n.pet_platformInfo),
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

  void _toggleSettings() {
    // 设置面板太大，不适合在宠物模式下显示
    // 返回完整应用模式后再打开设置
    _returnToFullAppWithSettings();
  }

  Future<void> _returnToFullAppWithSettings() async {
    try {
      await widget.petManager.transitionToFullApplication();
      if (mounted) {
        Navigator.of(context).pop();
        // 可以在这里触发打开设置的事件
      }
    } catch (e) {
      PlatformLogger.instance.logError(
        'Failed to return to full app for settings',
        e,
      );
    }
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
    // 关闭菜单
    setState(() {
      _showContextMenu = false;
    });

    try {
      // 找到对应的插件
      final plugin = _availablePlugins.firstWhere(
        (p) => p.name == pluginName,
        orElse: () => throw Exception('Plugin not found: $pluginName'),
      );

      // 先返回完整应用模式
      await widget.petManager.transitionToFullApplication();

      // 导航回主界面，并通过回调通知启动插件
      if (mounted) {
        Navigator.of(context).pop();
        // 通知主界面启动插件
        widget.onLaunchPlugin?.call(plugin);
      }
    } catch (e) {
      PlatformLogger.instance.logError(
        'Failed to launch plugin: $pluginName',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.plugin_launchFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show platform information dialog for non-web platforms
  void _showPlatformInfo() {
    if (kIsWeb) return; // Should not be called on web

    final capabilities = PlatformCapabilities.forNative();
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pet_platformInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pet_platformInfoDesc),
            const SizedBox(height: 12),
            _buildCapabilityItem(
              l10n.pet_capabilityDesktop,
              capabilities.supportsDesktopPet,
            ),
            _buildCapabilityItem(
              l10n.pet_capabilityWindow,
              capabilities.supportsAlwaysOnTop,
            ),
            _buildCapabilityItem(
              l10n.pet_capabilityTray,
              capabilities.supportsSystemTray,
            ),
            _buildCapabilityItem(
              l10n.pet_capabilityFileSystem,
              capabilities.supportsFileSystem,
            ),
            const SizedBox(height: 12),
            Text(l10n.pet_platformNote, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_ok),
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
  /// 启动宠物模式
  /// [onLaunchPlugin] 当用户从宠物模式选择启动插件时的回调
  static Future<void> showPetMode(
    BuildContext context,
    DesktopPetManager petManager,
    PlatformCore platformCore, {
    void Function(PluginDescriptor plugin)? onLaunchPlugin,
  }) async {
    // Check platform support before launching
    if (!DesktopPetManager.isSupported()) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Launcher',
        'Platform does not support desktop pet functionality',
      );

      // Show a brief message and navigate to the unsupported screen
      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb ? l10n.pet_webLimitation : l10n.pet_notSupported,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Still show the screen for unsupported platform UI
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DesktopPetScreen(
            petManager: petManager,
            platformCore: platformCore,
            onLaunchPlugin: onLaunchPlugin,
          ),
        ),
      );
      return;
    }

    try {
      // 检查是否已经在桌面宠物模式
      if (petManager.isDesktopPetMode) {
        // 如果已经在桌面宠物模式，直接显示屏幕，不再调用transitionToDesktopPet
        if (context.mounted) {
          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  DesktopPetScreen(
                    petManager: petManager,
                    platformCore: platformCore,
                    onLaunchPlugin: onLaunchPlugin,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              opaque: false,
            ),
          );
        }
        return;
      }

      // 启用桌面宠物模式 - 这会创建独立窗口并隐藏主窗口
      await petManager.transitionToDesktopPet();

      // 导航到桌面宠物屏幕
      if (context.mounted) {
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DesktopPetScreen(
                  petManager: petManager,
                  platformCore: platformCore,
                  onLaunchPlugin: onLaunchPlugin,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // 淡入动画
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            opaque: false, // 允许透明背景
          ),
        );

        // 当从桌面宠物屏幕返回时，确保恢复主窗口
        if (petManager.isDesktopPetMode) {
          await petManager.transitionToFullApplication();
        }
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to launch desktop pet mode', e);

      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pet_launchFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
