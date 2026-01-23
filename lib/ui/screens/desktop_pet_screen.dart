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

  /// 打开设置页面回调
  final VoidCallback? onOpenSettings;

  const DesktopPetScreen({
    super.key,
    required this.petManager,
    required this.platformCore,
    this.onLaunchPlugin,
    this.onOpenSettings,
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
  
  // 原始宠物窗口大小（用于恢复）
  static const Size _petWindowSize = Size(120.0, 120.0);

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
      PlatformLogger.instance.logInfo('🎨 [UI层] 开始初始化窗口...');
      
      // 获取窗口信息
      _windowSize = await windowManager.getSize();
      _windowPosition = await windowManager.getPosition();
      final opacity = await windowManager.getOpacity();
      final isVisible = await windowManager.isVisible();
      
      PlatformLogger.instance.logInfo(
        '🎨 [UI层] 初始窗口状态:\n'
        '   尺寸: ${_windowSize.width}x${_windowSize.height}\n'
        '   位置: (${_windowPosition.dx}, ${_windowPosition.dy})\n'
        '   透明度: $opacity\n'
        '   可见性: $isVisible',
      );

      // 【优化】增加延迟时间，确保窗口透明设置完全生效，避免背景闪现
      // desktop_pet_manager 中已经有多个延迟（100ms + 50ms + 100ms + 50ms = 300ms）
      // 这里再等待 250ms，总共约 550ms，确保所有设置完全生效
      PlatformLogger.instance.logInfo('🎨 [UI层] 等待 250ms 确保窗口设置完全生效...');
      await Future.delayed(const Duration(milliseconds: 250));
      
      // 验证延迟后的窗口状态
      final finalSize = await windowManager.getSize();
      final finalOpacity = await windowManager.getOpacity();
      final finalVisible = await windowManager.isVisible();
      
      PlatformLogger.instance.logInfo(
        '🎨 [UI层] 延迟后窗口状态:\n'
        '   尺寸: ${finalSize.width}x${finalSize.height}\n'
        '   透明度: $finalOpacity\n'
        '   可见性: $finalVisible',
      );

      if (mounted) {
        PlatformLogger.instance.logInfo('🎨 [UI层] 设置 _isReady = true，开始显示内容');
        setState(() => _isReady = true);
        _fadeController.forward();
        
        PlatformLogger.instance.logInfo('🎨 [UI层] 淡入动画已启动');
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
  /// 返回菜单在**屏幕上的绝对位置**
  Offset _calculateMenuScreenPosition(Size screenSize) {
    // 宠物在窗口中心
    final petCenterX = _petWindowSize.width / 2;
    final petCenterY = _petWindowSize.height / 2;

    // 宠物在屏幕上的绝对位置
    final petScreenX = _windowPosition.dx + petCenterX;
    final petScreenY = _windowPosition.dy + petCenterY;

    // 判断宠物在屏幕的哪个象限
    final isLeft = petScreenX < screenSize.width / 2;
    final isTop = petScreenY < screenSize.height / 2;

    // 菜单在屏幕上的绝对位置
    double menuScreenX, menuScreenY;

    if (isLeft) {
      // 宠物在左边，菜单显示在右边
      menuScreenX = petScreenX + kPetSize / 2 + kMenuGap;
    } else {
      // 宠物在右边，菜单显示在左边
      menuScreenX = petScreenX - kPetSize / 2 - kMenuWidth - kMenuGap;
    }

    if (isTop) {
      // 宠物在上边，菜单显示在下边
      menuScreenY = petScreenY + kPetSize / 2 + kMenuGap;
    } else {
      // 宠物在下边，菜单显示在上边
      menuScreenY = petScreenY - kPetSize / 2 - kMenuGap - 200; // 菜单高度约200
    }

    // 确保菜单不超出屏幕边界
    if (menuScreenX < 0) menuScreenX = 10;
    if (menuScreenX > screenSize.width - kMenuWidth) {
      menuScreenX = screenSize.width - kMenuWidth - 10;
    }
    if (menuScreenY < 0) menuScreenY = 10;
    if (menuScreenY > screenSize.height - 200) {
      menuScreenY = screenSize.height - 210;
    }

    return Offset(menuScreenX, menuScreenY);
  }

  /// 显示右键菜单（扩大窗口）
  Future<void> _openContextMenu() async {
    PlatformLogger.instance.logInfo(
      '🍔 _openContextMenu 被调用，当前菜单状态: $_showContextMenu',
    );
    
    if (!DesktopPetManager.isSupported()) {
      PlatformLogger.instance.logInfo('🍔 平台不支持，返回');
      return;
    }

    try {
      // ✅ 简化方案：直接扩大窗口到足够显示菜单的大小
      // 菜单宽度 160，高度约 200，加上宠物 120x120，再加上边距
      const expandedWidth = 300.0;  // 足够显示宠物和菜单
      const expandedHeight = 250.0; // 足够显示宠物和菜单
      
      PlatformLogger.instance.logInfo(
        '🍔 扩大窗口以显示菜单\n'
        '   当前尺寸: ${_windowSize.width}x${_windowSize.height}\n'
        '   新尺寸: $expandedWidth x $expandedHeight\n'
        '   窗口位置: (${_windowPosition.dx}, ${_windowPosition.dy})',
      );
      
      // 扩大窗口
      await windowManager.setSize(const Size(expandedWidth, expandedHeight));
      _windowSize = const Size(expandedWidth, expandedHeight);
      
      setState(() {
        _showContextMenu = true;
      });
      
      PlatformLogger.instance.logInfo('🍔 菜单状态已设置为 true');
    } catch (e) {
      PlatformLogger.instance.logError('Failed to show context menu', e);
    }
  }

  /// 隐藏右键菜单（恢复窗口大小）
  Future<void> _closeContextMenu() async {
    PlatformLogger.instance.logInfo(
      '🍔 _closeContextMenu 被调用，当前菜单状态: $_showContextMenu',
    );
    
    if (!DesktopPetManager.isSupported()) {
      setState(() {
        _showContextMenu = false;
      });
      return;
    }

    try {
      setState(() {
        _showContextMenu = false;
      });
      
      // 恢复窗口到宠物大小
      if (_windowSize.width > _petWindowSize.width ||
          _windowSize.height > _petWindowSize.height) {
        PlatformLogger.instance.logInfo(
          '🍔 恢复窗口到宠物大小: ${_petWindowSize.width}x${_petWindowSize.height}',
        );
        
        await windowManager.setSize(_petWindowSize);
        _windowSize = _petWindowSize;
      }
    } catch (e) {
      PlatformLogger.instance.logError('Failed to hide context menu', e);
    }
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

    // ✅ 简化：菜单固定显示在宠物右侧
    const petLeft = 0.0;     // 宠物固定在左上角
    const petTop = 0.0;
    const menuLeft = 130.0;  // 菜单在宠物右侧（宠物120 + 间距10）
    const menuTop = 10.0;    // 顶部留一点边距

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

          // 宠物组件 - 固定在左上角，不使用 Center
          Positioned(
            left: petLeft,
            top: petTop,
            child: DesktopPetWidget(
              preferences: widget.petManager.petPreferences,
              onDoubleClick: _returnToFullApp,
              onRightClick: () {
                PlatformLogger.instance.logInfo(
                  '🍔 右键回调被调用，当前菜单状态: $_showContextMenu',
                );
                if (_showContextMenu) {
                  PlatformLogger.instance.logInfo('🍔 菜单已显示，调用 _closeContextMenu');
                  _closeContextMenu();
                } else {
                  PlatformLogger.instance.logInfo('🍔 菜单未显示，调用 _openContextMenu');
                  _openContextMenu();
                }
              },
            ),
          ),

          // 右键菜单 - 可以超越原始窗口范围显示
          if (_showContextMenu) ...[
            // 透明背景层 - 点击菜单外区域关闭菜单
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeContextMenu,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 菜单本身 - 固定显示在宠物右侧
            Positioned(
              left: menuLeft,
              top: menuTop,
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
        // 触发打开设置页面的回调
        widget.onOpenSettings?.call();
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
    await _closeContextMenu();

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
