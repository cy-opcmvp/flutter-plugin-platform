import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/models/platform_models.dart';
import '../../core/models/plugin_models.dart';
import '../../core/services/platform_core.dart';
import '../../core/services/plugin_launcher.dart';
import '../../core/services/desktop_pet_manager.dart';
import '../../core/extensions/context_extensions.dart';

import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_services.dart';
import 'desktop_pet_screen.dart';

/// Main platform interface that displays plugins and manages navigation
/// Implements requirements 1.1, 1.2, 1.5, 7.5
class MainPlatformScreen extends StatefulWidget {
  const MainPlatformScreen({super.key});

  @override
  State<MainPlatformScreen> createState() => _MainPlatformScreenState();
}

class _MainPlatformScreenState extends State<MainPlatformScreen> with TickerProviderStateMixin {
  late final PlatformCore _platformCore;
  PluginLauncher? _pluginLauncher;
  late final TabController _tabController;
  late final DesktopPetManager _desktopPetManager;
  
  OperationMode _currentMode = OperationMode.local;
  List<PluginDescriptor> _availablePlugins = [];
  List<IPlugin> _activePlugins = [];
  Set<String> _availableFeatures = {};
  PlatformInfo? _platformInfo;
  bool _isLoading = true;
  String? _error;
  
  // Plugin launching state
  IPlugin? _currentPlugin;
  Map<String, IPlugin> _backgroundPlugins = {};
  
  StreamSubscription<PlatformEvent>? _platformEventSubscription;
  StreamSubscription<PluginEvent>? _pluginEventSubscription;
  StreamSubscription<PluginLaunchEvent>? _pluginLaunchSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _platformCore = PlatformCore();
    _desktopPetManager = DesktopPetManager();
    _initializePlatform();
  }

  /// Initialize the platform core and load initial data
  /// Requirement 1.1: Display main interface with available plugins
  Future<void> _initializePlatform() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize platform core
      await _platformCore.initialize();
      
      // Initialize desktop pet manager
      await _desktopPetManager.initialize();
      
      // Initialize plugin launcher
      _pluginLauncher = PluginLauncher(_platformCore.pluginManager);
      
      // Get platform information
      _platformInfo = _platformCore.platformInfo;
      _currentMode = _platformCore.currentMode;
      _availableFeatures = _platformCore.getAvailableFeatures();
      
      // Load available plugins
      await _loadPlugins();
      
      // Subscribe to platform events
      _platformEventSubscription = _platformCore.eventStream.listen(_handlePlatformEvent);
      _pluginEventSubscription = _platformCore.pluginManager.eventStream.listen(_handlePluginEvent);
      _pluginLaunchSubscription = _pluginLauncher?.eventStream.listen(_handlePluginLaunchEvent);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load available and active plugins from the plugin manager
  Future<void> _loadPlugins() async {
    try {
      final availablePlugins = await _platformCore.pluginManager.getAvailablePlugins();
      final activePlugins = _pluginLauncher?.getAllLoadedPlugins() ?? [];
      
      setState(() {
        _availablePlugins = availablePlugins;
        _activePlugins = activePlugins;
        _currentPlugin = _pluginLauncher?.currentPlugin;
        _backgroundPlugins = _pluginLauncher?.backgroundPlugins ?? {};
      });
    } catch (e) {
      // Handle error silently for now - plugins may not be available yet
    }
  }

  /// Handle platform-level events
  /// Requirement 7.5: Indicate current mode and available features
  void _handlePlatformEvent(PlatformEvent event) {
    if (event is OperationModeChangedEvent) {
      setState(() {
        _currentMode = event.newMode;
        _availableFeatures = _platformCore.getAvailableFeatures();
      });
      
      // Show mode change notification
      if (mounted) {
        final l10n = context.l10n;
        final modeName = event.newMode == OperationMode.online 
            ? l10n.mode_online 
            : l10n.mode_local;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mode_switchSuccess(modeName)),
            backgroundColor: event.newMode == OperationMode.online ? Colors.green : Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handle plugin-specific events
  void _handlePluginEvent(PluginEvent event) {
    switch (event.type) {
      case PluginEventType.loaded:
      case PluginEventType.unloaded:
      case PluginEventType.enabled:
      case PluginEventType.disabled:
        _loadPlugins();
        break;
      case PluginEventType.error:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.plugin_errorDetails(event.data?['error']?.toString() ?? context.l10n.error_unknown)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        break;
      case PluginEventType.stateChanged:
        _loadPlugins();
        break;
      default:
        // Handle other plugin events as needed
        break;
    }
  }

  /// Handle plugin launch events
  /// Requirement 1.2, 1.4: Plugin launching and switching feedback
  void _handlePluginLaunchEvent(PluginLaunchEvent event) {
    if (!mounted) return;

    final l10n = context.l10n;
    switch (event.type) {
      case PluginLaunchEventType.launched:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_launchSuccess(event.pluginId)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPlugins();
        break;
      case PluginLaunchEventType.switched:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_switchSuccess(event.pluginId)),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPlugins();
        break;
      case PluginLaunchEventType.closed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_closeSuccess(event.pluginId)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPlugins();
        break;
      case PluginLaunchEventType.paused:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_pauseSuccess(event.pluginId)),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPlugins();
        break;
      case PluginLaunchEventType.launchFailed:
      case PluginLaunchEventType.switchFailed:
      case PluginLaunchEventType.closeFailed:
      case PluginLaunchEventType.pauseFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_operationFailed(event.error ?? l10n.error_unknown)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  /// Switch between local and online operation modes
  /// Requirement 7.5: Mode switching functionality
  Future<void> _switchMode(OperationMode newMode) async {
    if (_currentMode == newMode) return;
    
    try {
      await _platformCore.switchMode(newMode);
      // Mode change will be handled by the platform event listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.mode_switchFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Toggle Desktop Pet mode
  /// Requirements 7.1, 7.3: Handle web platform limitations gracefully
  Future<void> _toggleDesktopPetMode() async {
    // 检查平台支持 - Requirements 7.1: Hide desktop pet UI controls on web platform
    if (!DesktopPetManager.isSupported()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pet_notSupported),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      if (_desktopPetManager.isDesktopPetMode) {
        await _desktopPetManager.transitionToFullApplication();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.pet_exitSuccess),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 显示Desktop Pet设置对话框
        final shouldEnable = await _showDesktopPetDialog();
        if (shouldEnable == true) {
          await _desktopPetManager.transitionToDesktopPet();
          
          // 导航到Desktop Pet屏幕 - Requirements 7.3: Handle navigation gracefully on unsupported platforms
          if (mounted && DesktopPetManager.isSupported()) {
            try {
              await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DesktopPetScreen(
                    petManager: _desktopPetManager,
                    platformCore: _platformCore,
                    onLaunchPlugin: _launchPlugin, // 传入插件启动回调
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
                  opaque: true, // 完全覆盖背景
                  fullscreenDialog: true, // 全屏对话框
                ),
              );
            } catch (navigationError) {
              // Requirements 7.3: Handle navigation errors gracefully
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.pet_navFailed(navigationError.toString())),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
            
            // 当从Desktop Pet屏幕返回时，更新状态
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
      
      // 更新UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Requirements 7.3: Graceful error handling for unsupported platforms
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pet_toggleFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 显示Desktop Pet设置对话框
  /// Requirements 7.1, 7.3: Provide user-friendly messages when features are unavailable
  Future<bool?> _showDesktopPetDialog() async {
    final l10n = context.l10n;
    // 检查平台支持 - Requirements 7.1: Handle web platform limitations
    if (!DesktopPetManager.isSupported()) {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(l10n.pet_notSupported),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pet_notSupportedDesc('Web')),
              const SizedBox(height: 16),
              Text(l10n.pet_platformInfoDesc),
              const SizedBox(height: 8),
              Text('• ${l10n.pet_capabilityDesktop}'),
              Text('• ${l10n.pet_capabilityWindow}'),
              const SizedBox(height: 16),
              Text(
                l10n.pet_platformNote,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.common_ok),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.pet_modeTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pet_modeDesc),
            const SizedBox(height: 16),
            Text(l10n.pet_features, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.pet_featureAlwaysOnTop),
            Text(l10n.pet_featureAnimations),
            Text(l10n.pet_featureQuickAccess),
            Text(l10n.pet_featureCustomize),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.pet_tip,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.button_enablePetMode),
          ),
        ],
      ),
    );
  }

  /// Launch a plugin within the application context
  /// Requirement 1.2: Launch plugins within application context
  Future<void> _launchPlugin(PluginDescriptor plugin) async {
    if (_pluginLauncher == null) return;
    
    try {
      // Use plugin launcher for sophisticated launching
      final loadedPlugin = await _pluginLauncher!.launchPlugin(plugin);
      
      // Navigate to plugin view
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _PluginViewScreen(
              plugin: loadedPlugin,
              pluginLauncher: _pluginLauncher!,
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
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

  /// Switch to an already loaded plugin
  /// Requirement 1.4: Plugin switching with state preservation
  Future<void> _switchToPlugin(String pluginId) async {
    if (_pluginLauncher == null) return;
    
    try {
      final plugin = await _pluginLauncher!.switchToPlugin(pluginId);
      
      // Navigate to plugin view
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _PluginViewScreen(
              plugin: plugin,
              pluginLauncher: _pluginLauncher!,
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.plugin_switchFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Toggle plugin enabled/disabled state
  Future<void> _togglePlugin(String pluginId, bool enabled) async {
    try {
      if (enabled) {
        await _platformCore.pluginManager.enablePlugin(pluginId);
      } else {
        await _platformCore.pluginManager.disablePlugin(pluginId);
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plugin_operationFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _platformEventSubscription?.cancel();
    _pluginEventSubscription?.cancel();
    _pluginLaunchSubscription?.cancel();
    _pluginLauncher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.platform_initializing),
            ],
          ),
        ),
      );
    }

    // Show error state with retry option
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.platform_error,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.error_platformInit(_error!),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializePlatform,
                child: Text(l10n.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    // Main platform interface
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Desktop Pet切换按钮 - 只在支持的平台上显示
          // Requirements 7.1: Hide desktop pet UI controls on web platform
          if (DesktopPetManager.isSupported())
            IconButton(
              icon: Icon(_desktopPetManager.isDesktopPetMode ? Icons.fullscreen_exit : Icons.pets),
              tooltip: _desktopPetManager.isDesktopPetMode ? l10n.button_exitPetMode : l10n.button_enablePetMode,
              onPressed: _toggleDesktopPetMode,
            ),
          _buildModeIndicator(),
        ],
      ),
      body: Column(
        children: [
          _buildFeatureAvailabilityBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPluginGrid(),
                _buildActivePluginsView(),
                _buildPlatformInfoView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildModeSwitchFab(),
    );
  }

  /// Build mode indicator showing current operation mode
  /// Requirement 7.5: Clearly indicate current mode
  Widget _buildModeIndicator() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isOnline = _currentMode == OperationMode.online;
    final modeName = isOnline ? l10n.mode_online : l10n.mode_local;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud : Icons.offline_bolt,
            size: 16,
            color: isOnline ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            modeName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOnline ? Colors.green : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build feature availability bar showing available features
  /// Requirement 7.5: Display available features to users
  Widget _buildFeatureAvailabilityBar() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final features = _availableFeatures.toList()..sort();
    
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.platform_availableFeatures,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: features.map((feature) => _buildFeatureChip(feature)).toList(),
          ),
        ],
      ),
    );
  }

  /// Build individual feature chip
  Widget _buildFeatureChip(String feature) {
    final theme = Theme.of(context);
    final displayName = feature.replaceAll('_', ' ').toUpperCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Build plugin grid view for plugin display and selection
  /// Requirement 1.1: Display available plugins
  Widget _buildPluginGrid() {
    final l10n = context.l10n;
    if (_availablePlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.platform_noPluginsAvailable,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.platform_installFromManagement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlugins,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _platformInfo?.type == PlatformType.mobile ? 2 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _availablePlugins.length,
        itemBuilder: (context, index) {
          final plugin = _availablePlugins[index];
          return _buildPluginTile(plugin);
        },
      ),
    );
  }

  /// Build individual plugin tile with selection capability
  /// Requirement 1.2: Plugin selection functionality
  Widget _buildPluginTile(PluginDescriptor plugin) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isEnabled = _platformCore.pluginManager.isPluginEnabled(plugin.id);
    final pluginTypeName = plugin.type == PluginType.tool ? l10n.plugin_typeTool : l10n.plugin_typeGame;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isEnabled ? () => _launchPlugin(plugin) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plugin icon and enable/disable toggle
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPluginTypeColor(plugin.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPluginTypeIcon(plugin.type),
                      color: _getPluginTypeColor(plugin.type),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) => _togglePlugin(plugin.id, value),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Plugin name
              Text(
                plugin.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Plugin version and type
              Text(
                'v${plugin.version} • $pluginTypeName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Plugin description
              if (plugin.metadata.containsKey('description')) ...[
                Text(
                  plugin.metadata['description'] as String,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              // Launch button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isEnabled ? () => _launchPlugin(plugin) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    isEnabled ? l10n.button_launch : l10n.plugin_statusDisabled,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build active plugins view
  Widget _buildActivePluginsView() {
    final l10n = context.l10n;
    if (_activePlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.platform_activePlugins,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.plugin_installFirst,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activePlugins.length,
      itemBuilder: (context, index) {
        final plugin = _activePlugins[index];
        return _buildActivePluginTile(plugin);
      },
    );
  }

  /// Build active plugin tile with management options
  /// Requirement 1.2, 1.4: Plugin switching and background management
  Widget _buildActivePluginTile(IPlugin plugin) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCurrentPlugin = _currentPlugin?.id == plugin.id;
    final isBackgroundPlugin = _backgroundPlugins.containsKey(plugin.id);
    
    String status;
    Color statusColor;
    if (isCurrentPlugin) {
      status = l10n.plugin_statusActive;
      statusColor = Colors.green;
    } else if (isBackgroundPlugin) {
      status = l10n.plugin_statusPaused;
      statusColor = Colors.orange;
    } else {
      status = l10n.plugin_statusActive;
      statusColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getPluginTypeColor(plugin.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPluginTypeIcon(plugin.type),
            color: _getPluginTypeColor(plugin.type),
            size: 20,
          ),
        ),
        title: Text(
          plugin.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text('v${plugin.version} • '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentPlugin) ...[
              IconButton(
                onPressed: () => _switchToPlugin(plugin.id),
                icon: const Icon(Icons.launch),
                tooltip: context.l10n.tooltip_switchPlugin,
              ),
            ],
            if (isCurrentPlugin) ...[
              IconButton(
                onPressed: () async {
                  await _pluginLauncher?.pauseCurrentPlugin();
                },
                icon: const Icon(Icons.pause),
                tooltip: context.l10n.tooltip_pausePlugin,
              ),
            ],
            IconButton(
              onPressed: () async {
                if (isCurrentPlugin) {
                  await _pluginLauncher?.closeCurrentPlugin();
                } else {
                  await _platformCore.pluginManager.unloadPlugin(plugin.id);
                }
              },
              icon: const Icon(Icons.stop),
              tooltip: context.l10n.tooltip_stopPlugin,
            ),
          ],
        ),
        onTap: () {
          if (!isCurrentPlugin) {
            _switchToPlugin(plugin.id);
          }
        },
      ),
    );
  }

  /// Build platform information view
  Widget _buildPlatformInfoView() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.platform_platformInfo,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context.l10n.info_platformType, _platformInfo?.type.name.toUpperCase() ?? context.l10n.info_unknown),
                  _buildInfoRow(context.l10n.info_version, _platformInfo?.version ?? context.l10n.info_unknown),
                  _buildInfoRow(context.l10n.info_currentMode, _currentMode.name.toUpperCase()),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.info_capabilities,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_platformInfo != null)
                    ..._platformInfo!.capabilities.entries.map(
                      (entry) => _buildCapabilityRow(entry.key, entry.value),
                    ),
                  // 添加Desktop Pet支持信息 - Requirements 7.1: Display platform capabilities
                  _buildCapabilityRow(context.l10n.capability_desktopPetSupport, DesktopPetManager.isSupported()),
                  _buildCapabilityRow(context.l10n.capability_alwaysOnTop, DesktopPetManager.isSupported()),
                  _buildCapabilityRow(context.l10n.capability_systemTray, DesktopPetManager.isSupported()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.info_statistics,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context.l10n.info_availablePlugins, '${_availablePlugins.length}'),
                  _buildInfoRow(context.l10n.info_activePlugins, '${_activePlugins.length}'),
                  _buildInfoRow(context.l10n.info_availableFeatures, '${_availableFeatures.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build information row for platform details
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build capability row showing platform capabilities
  Widget _buildCapabilityRow(String capability, dynamic value) {
    final theme = Theme.of(context);
    final displayName = capability.replaceAll('_', ' ').toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Icon(
            value == true ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: value == true ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  /// Build bottom navigation for cross-platform consistency
  /// Requirement 1.5: Consistent navigation and user experience
  Widget _buildBottomNavigation() {
    final l10n = context.l10n;
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(icon: const Icon(Icons.apps), text: l10n.nav_plugins),
        Tab(icon: const Icon(Icons.play_circle), text: l10n.nav_active),
        Tab(icon: const Icon(Icons.info), text: l10n.nav_info),
      ],
    );
  }

  /// Build floating action button for mode switching
  Widget _buildModeSwitchFab() {
    final l10n = context.l10n;
    final isOnline = _currentMode == OperationMode.online;
    final targetMode = isOnline ? l10n.mode_local : l10n.mode_online;
    
    return FloatingActionButton.extended(
      onPressed: () => _switchMode(
        isOnline ? OperationMode.local : OperationMode.online,
      ),
      icon: Icon(isOnline ? Icons.offline_bolt : Icons.cloud),
      label: Text(l10n.mode_switchSuccess(targetMode)),
      backgroundColor: isOnline ? Colors.blue : Colors.green,
    );
  }

  /// Get icon for plugin type
  IconData _getPluginTypeIcon(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Icons.build;
      case PluginType.game:
        return Icons.games;
    }
  }

  /// Get color for plugin type
  Color _getPluginTypeColor(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Colors.blue;
      case PluginType.game:
        return Colors.purple;
    }
  }
}

/// Screen for displaying a running plugin
/// Requirement 1.2: Plugin launching within application context
/// Requirement 1.4: Plugin switching with state preservation
class _PluginViewScreen extends StatefulWidget {
  final IPlugin plugin;
  final PluginLauncher pluginLauncher;
  final VoidCallback onBack;

  const _PluginViewScreen({
    required this.plugin,
    required this.pluginLauncher,
    required this.onBack,
  });

  @override
  State<_PluginViewScreen> createState() => _PluginViewScreenState();
}

class _PluginViewScreenState extends State<_PluginViewScreen> {
  late IPlugin _currentPlugin;
  StreamSubscription<PluginLaunchEvent>? _launchEventSubscription;

  @override
  void initState() {
    super.initState();
    _currentPlugin = widget.plugin;
    
    // Listen for plugin switching events
    _launchEventSubscription = widget.pluginLauncher.eventStream.listen((event) {
      if (event.type == PluginLaunchEventType.switched && mounted) {
        final newPlugin = widget.pluginLauncher.currentPlugin;
        if (newPlugin != null && newPlugin.id != _currentPlugin.id) {
          setState(() {
            _currentPlugin = newPlugin;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _launchEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPlugins = widget.pluginLauncher.backgroundPlugins;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlugin.name),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          // Plugin switcher dropdown
          if (backgroundPlugins.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              tooltip: context.l10n.tooltip_switchMode,
              onSelected: (pluginId) async {
                try {
                  await widget.pluginLauncher.switchToPlugin(pluginId);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to switch plugin: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) {
                return backgroundPlugins.entries.map((entry) {
                  final plugin = entry.value;
                  return PopupMenuItem<String>(
                    value: plugin.id,
                    child: ListTile(
                      leading: Icon(_getPluginTypeIcon(plugin.type)),
                      title: Text(plugin.name),
                      subtitle: Text('v${plugin.version}'),
                      dense: true,
                    ),
                  );
                }).toList();
              },
            ),
          // Move to background button
          IconButton(
            onPressed: () async {
              try {
                await widget.pluginLauncher.pauseCurrentPlugin();
                widget.onBack();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to pause plugin: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.pause),
            tooltip: context.l10n.tooltip_pauseMode,
          ),
          // Plugin info button
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_currentPlugin.name),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Version: ${_currentPlugin.version}'),
                      Text('Type: ${_currentPlugin.type.name.toUpperCase()}'),
                      Text('ID: ${_currentPlugin.id}'),
                      const SizedBox(height: 8),
                      Text('Background Plugins: ${backgroundPlugins.length}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.common_close),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: _currentPlugin.buildUI(context),
    );
  }

  /// Get icon for plugin type
  IconData _getPluginTypeIcon(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Icons.build;
      case PluginType.game:
        return Icons.games;
    }
  }
}