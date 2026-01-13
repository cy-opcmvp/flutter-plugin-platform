import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math' as math;
import '../../core/services/platform_environment.dart';
import '../../core/models/platform_models.dart';
import '../../core/extensions/context_extensions.dart';

/// Desktop Pet Widget - 桌面宠物组件
class DesktopPetWidget extends StatefulWidget {
  final VoidCallback? onDoubleClick;
  final VoidCallback? onRightClick;
  final Map<String, dynamic> preferences;
  
  const DesktopPetWidget({
    super.key,
    this.onDoubleClick,
    this.onRightClick,
    this.preferences = const {},
  });

  @override
  State<DesktopPetWidget> createState() => _DesktopPetWidgetState();
}

class _DesktopPetWidgetState extends State<DesktopPetWidget> 
    with TickerProviderStateMixin, WindowListener {
  AnimationController? _breathingController;
  AnimationController? _blinkController;
  Animation<double>? _breathingAnimation;
  Animation<double>? _blinkAnimation;
  
  bool _isHovered = false;
  bool _isDragging = false;
  

  
  // Platform capabilities
  late PlatformCapabilities _platformCapabilities;

  @override
  void initState() {
    super.initState();
    
    // Initialize platform capabilities
    _platformCapabilities = PlatformEnvironment.instance.isWeb 
        ? PlatformCapabilities.forWeb() 
        : PlatformCapabilities.forNative();
    
    // Check if desktop pet is supported on this platform
    if (!_platformCapabilities.supportsDesktopPet) {
      // On unsupported platforms (like web), provide fallback behavior
      return;
    }
    
    // 添加窗口监听器以支持拖拽
    windowManager.addListener(this);
    
    // 呼吸动画
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _breathingController!,
      curve: Curves.easeInOut,
    ));
    
    // 眨眼动画
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController!,
      curve: Curves.easeInOut,
    ));
    
    // 启动动画
    if (_isAnimationsEnabled && _breathingController != null) {
      _breathingController!.repeat(reverse: true);
      _startRandomBlinking();
    }
  }

  bool get _isAnimationsEnabled => 
      widget.preferences['animations_enabled'] ?? true;
  
  bool get _isInteractionsEnabled => 
      widget.preferences['interactions_enabled'] ?? true;
  
  double get _opacity => widget.preferences['opacity'] ?? 1.0;

  void _startRandomBlinking() {
    // Only start blinking if desktop pet is supported
    if (!_platformCapabilities.supportsDesktopPet) {
      return;
    }
    
    Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (mounted && _isAnimationsEnabled && _blinkController != null) {
        _blinkController!.forward().then((_) {
          _blinkController!.reverse().then((_) {
            _startRandomBlinking();
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If desktop pet is not supported on this platform, show fallback UI
    if (!_platformCapabilities.supportsDesktopPet) {
      return _buildWebFallbackWidget(context);
    }
    
    return Opacity(
      opacity: _opacity,
      child: GestureDetector(
        onDoubleTap: _isInteractionsEnabled ? widget.onDoubleClick : null,
        onSecondaryTap: _isInteractionsEnabled ? widget.onRightClick : null,
        onPanStart: _isInteractionsEnabled ? (details) {
          setState(() {
            _isDragging = true;
          });
          // 使用原生窗口拖拽 - 这是最流畅的方式
          windowManager.startDragging();
        } : null,
        onPanEnd: _isInteractionsEnabled ? (_) {
          setState(() {
            _isDragging = false;
          });
        } : null,
        child: MouseRegion(
          cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          onEnter: (_) {
            if (_isInteractionsEnabled) {
              setState(() {
                _isHovered = true;
              });
            }
          },
          onExit: (_) {
            if (_isInteractionsEnabled) {
              setState(() {
                _isHovered = false;
              });
            }
          },
          child: _breathingAnimation != null && _blinkAnimation != null 
              ? AnimatedBuilder(
                  animation: Listenable.merge([_breathingAnimation!, _blinkAnimation!]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isAnimationsEnabled ? _breathingAnimation!.value : 1.0,
                      child: _buildPetContainer(),
                    );
                  },
                )
              : _buildPetContainer(),
        ),
      ),
    );
  }
  
  /// Builds the main pet container widget
  Widget _buildPetContainer() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getMainColor().withValues(alpha: 0.9),
            _getSecondaryColor().withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getMainColor().withValues(alpha: 0.4),
            blurRadius: _isHovered ? 25 : 15,
            spreadRadius: _isHovered ? 8 : 3,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 主体图标
          Icon(
            Icons.pets,
            color: Colors.white,
            size: _isDragging ? 35 : 40,
          ),
          
          // 眼睛
          if (_isAnimationsEnabled && _blinkAnimation != null)
            Positioned(
              top: 35,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEye(),
                  const SizedBox(width: 8),
                  _buildEye(),
                ],
              ),
            ),
          
          // 状态指示器
          if (_isDragging)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Builder(
                  builder: (context) => Text(
                    context.l10n.pet_moving,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

  }
  
  /// Builds a fallback widget for platforms that don't support desktop pets (like web)
  Widget _buildWebFallbackWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.pet_notSupported,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.pet_notSupportedDesc('Web'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onDoubleClick,
                child: Text(context.l10n.pet_openMainApp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEye() {
    return AnimatedBuilder(
      animation: _blinkAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scaleY: _blinkAnimation!.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Color _getMainColor() {
    if (_isDragging) return Colors.orange;
    if (_isHovered) return Colors.green;
    return Colors.blue;
  }

  Color _getSecondaryColor() {
    if (_isDragging) return Colors.deepOrange;
    if (_isHovered) return Colors.lightGreen;
    return Colors.purple;
  }

  @override
  void dispose() {
    // Only dispose controllers if they were initialized (desktop pet supported)
    if (_platformCapabilities.supportsDesktopPet) {
      windowManager.removeListener(this);
      _breathingController?.dispose();
      _blinkController?.dispose();
    }
    super.dispose();
  }
}

/// Desktop Pet 右键菜单 - 紧凑版本适合小窗口
class DesktopPetContextMenu extends StatelessWidget {
  final List<String> quickActions;
  final Function(String) onActionSelected;
  final VoidCallback onOpenFullApp;
  final VoidCallback onSettings;
  final VoidCallback onExitPetMode;
  
  const DesktopPetContextMenu({
    super.key,
    required this.quickActions,
    required this.onActionSelected,
    required this.onOpenFullApp,
    required this.onSettings,
    required this.onExitPetMode,
  });

  @override
  Widget build(BuildContext context) {
    // Check platform capabilities
    final platformCapabilities = PlatformEnvironment.instance.isWeb 
        ? PlatformCapabilities.forWeb() 
        : PlatformCapabilities.forNative();
    
    // If desktop pet is not supported, show simplified menu
    if (!platformCapabilities.supportsDesktopPet) {
      return Card(
        elevation: 8,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactMenuItem(
                context: context,
                icon: Icons.info_outline,
                label: context.l10n.pet_notAvailable,
                onTap: null,
              ),
              const Divider(height: 1),
              _buildCompactMenuItem(
                context: context,
                icon: Icons.open_in_new,
                label: context.l10n.pet_openFullApp,
                onTap: onOpenFullApp,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 8,
      child: Container(
        width: 160, // 更紧凑的宽度
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快速操作 - 打开完整应用
            _buildCompactMenuItem(
              context: context,
              icon: Icons.open_in_new,
              label: context.l10n.pet_openFullApp,
              onTap: onOpenFullApp,
            ),
            
            if (quickActions.isNotEmpty) ...[
              const Divider(height: 1),
              // 只显示前3个插件，避免菜单过长
              ...quickActions.take(3).map((action) => _buildCompactMenuItem(
                context: context,
                icon: _getActionIcon(action),
                label: action,
                onTap: () => onActionSelected(action),
              )),
            ],
            
            const Divider(height: 1),
            
            // 设置 - 会返回完整应用
            _buildCompactMenuItem(
              context: context,
              icon: Icons.settings,
              label: context.l10n.pet_settings,
              onTap: onSettings,
            ),
            
            // 退出宠物模式
            _buildCompactMenuItem(
              context: context,
              icon: Icons.exit_to_app,
              label: context.l10n.pet_exitMode,
              onTap: onExitPetMode,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: onTap == null ? Colors.grey : null),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: onTap == null ? Colors.grey : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'calculator':
        return Icons.calculate;
      case 'notes':
      case 'note taking':
        return Icons.note;
      case 'puzzle':
      case 'puzzle game':
        return Icons.extension;
      default:
        return Icons.apps;
    }
  }
}

/// Desktop Pet 设置面板
class DesktopPetSettingsPanel extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onPreferencesChanged;
  final VoidCallback onClose;
  
  const DesktopPetSettingsPanel({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
    required this.onClose,
  });

  @override
  State<DesktopPetSettingsPanel> createState() => _DesktopPetSettingsPanelState();
}

class _DesktopPetSettingsPanelState extends State<DesktopPetSettingsPanel> {
  late Map<String, dynamic> _preferences;
  late PlatformCapabilities _platformCapabilities;
  
  @override
  void initState() {
    super.initState();
    _preferences = Map.from(widget.preferences);
    _platformCapabilities = PlatformEnvironment.instance.isWeb 
        ? PlatformCapabilities.forWeb() 
        : PlatformCapabilities.forNative();
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      _preferences[key] = value;
    });
    widget.onPreferencesChanged(_preferences);
  }

  @override
  Widget build(BuildContext context) {
    // If desktop pet is not supported, show platform limitation message
    if (!_platformCapabilities.supportsDesktopPet) {
      return Card(
        elevation: 12,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.pet_settingsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    iconSize: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                context.l10n.pet_notSupported,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                context.l10n.pet_notSupportedDesc('Web'),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      child: Text(context.l10n.common_close),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 12,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.pets),
                const SizedBox(width: 8),
                Text(
                  context.l10n.pet_settingsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  iconSize: 20,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 透明度设置
            Row(
              children: [
                const Icon(Icons.opacity, size: 20),
                const SizedBox(width: 8),
                Text(context.l10n.pet_opacity),
                const Spacer(),
                Text('${((_preferences['opacity'] ?? 1.0) * 100).round()}%'),
              ],
            ),
            Slider(
              value: _preferences['opacity'] ?? 1.0,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              onChanged: (value) => _updatePreference('opacity', value),
            ),
            
            const SizedBox(height: 8),
            
            // 动画开关
            CheckboxListTile(
              secondary: const Icon(Icons.animation, size: 20),
              title: Text(context.l10n.pet_enableAnimations),
              subtitle: Text(context.l10n.pet_animationsSubtitle),
              value: _preferences['animations_enabled'] ?? true,
              onChanged: (value) => _updatePreference('animations_enabled', value ?? false),
              dense: true,
            ),
            
            // 交互开关
            CheckboxListTile(
              secondary: const Icon(Icons.touch_app, size: 20),
              title: Text(context.l10n.pet_enableInteractions),
              subtitle: Text(context.l10n.pet_interactionsSubtitle),
              value: _preferences['interactions_enabled'] ?? true,
              onChanged: (value) => _updatePreference('interactions_enabled', value ?? false),
              dense: true,
            ),
            
            // 自动隐藏
            CheckboxListTile(
              secondary: const Icon(Icons.visibility_off, size: 20),
              title: Text(context.l10n.pet_autoHide),
              subtitle: Text(context.l10n.pet_autoHideSubtitle),
              value: _preferences['auto_hide'] ?? false,
              onChanged: (value) => _updatePreference('auto_hide', value ?? false),
              dense: true,
            ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 重置为默认设置
                      final defaultPrefs = {
                        'opacity': 1.0,
                        'animations_enabled': true,
                        'interactions_enabled': true,
                        'auto_hide': false,
                      };
                      setState(() {
                        _preferences = defaultPrefs;
                      });
                      widget.onPreferencesChanged(defaultPrefs);
                    },
                    child: Text(context.l10n.pet_reset),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    child: Text(context.l10n.pet_done),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}