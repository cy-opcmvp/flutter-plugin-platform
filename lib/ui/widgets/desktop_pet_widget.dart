import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/services/platform_environment.dart';
import '../../core/models/platform_models.dart';

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
    with TickerProviderStateMixin {
  AnimationController? _breathingController;
  AnimationController? _blinkController;
  Animation<double>? _breathingAnimation;
  Animation<double>? _blinkAnimation;
  
  bool _isHovered = false;
  bool _isDragging = false;
  
  // 位置状态
  double _positionX = 0.0;
  double _positionY = 0.0;
  
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
    
    // 初始化位置
    final position = widget.preferences['position'] as Map<String, dynamic>? ?? {'x': 100.0, 'y': 100.0};
    _positionX = (position['x'] as num?)?.toDouble() ?? 100.0;
    _positionY = (position['y'] as num?)?.toDouble() ?? 100.0;
    
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
    
    return Positioned(
      left: _positionX,
      top: _positionY,
      child: Opacity(
        opacity: _opacity,
        child: GestureDetector(
          onDoubleTap: _isInteractionsEnabled ? widget.onDoubleClick : null,
          onSecondaryTap: _isInteractionsEnabled ? widget.onRightClick : null,
          onPanStart: _isInteractionsEnabled ? (_) {
            setState(() {
              _isDragging = true;
            });
          } : null,
          onPanUpdate: _isInteractionsEnabled ? (details) {
            setState(() {
              _positionX += details.delta.dx;
              _positionY += details.delta.dy;
              
              // 确保不会拖拽到屏幕外
              final screenSize = MediaQuery.of(context).size;
              _positionX = _positionX.clamp(0.0, screenSize.width - 120);
              _positionY = _positionY.clamp(0.0, screenSize.height - 120);
            });
          } : null,
          onPanEnd: _isInteractionsEnabled ? (_) {
            setState(() {
              _isDragging = false;
            });
          } : null,
          child: MouseRegion(
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
                child: const Text(
                  'Moving...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
              const Text(
                'Desktop Pet Not Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desktop pet functionality is not supported on this platform. '
                'This feature is available on desktop platforms (Windows, macOS, Linux).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onDoubleClick,
                child: const Text('Open Main App'),
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
      _breathingController?.dispose();
      _blinkController?.dispose();
    }
    super.dispose();
  }
}

/// Desktop Pet 右键菜单
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
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, size: 20),
                title: const Text('Desktop Pet Unavailable'),
                subtitle: const Text('Not supported on this platform'),
                dense: true,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.open_in_new, size: 20),
                title: const Text('Open Full App'),
                dense: true,
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
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快速操作
            ListTile(
              leading: const Icon(Icons.open_in_new, size: 20),
              title: const Text('Open Full App'),
              dense: true,
              onTap: onOpenFullApp,
            ),
            
            if (quickActions.isNotEmpty) ...[
              const Divider(height: 1),
              ...quickActions.map((action) => ListTile(
                leading: Icon(_getActionIcon(action), size: 20),
                title: Text(action),
                dense: true,
                onTap: () => onActionSelected(action),
              )),
            ],
            
            const Divider(height: 1),
            
            // 设置和退出
            ListTile(
              leading: const Icon(Icons.settings, size: 20),
              title: const Text('Pet Settings'),
              dense: true,
              onTap: onSettings,
            ),
            
            ListTile(
              leading: const Icon(Icons.exit_to_app, size: 20),
              title: const Text('Exit Pet Mode'),
              dense: true,
              onTap: onExitPetMode,
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
                  const Text(
                    'Desktop Pet Settings',
                    style: TextStyle(
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
              
              const Text(
                'Desktop Pet Not Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Desktop pet functionality is not supported on this platform. '
                'This feature requires a desktop environment and is available on '
                'Windows, macOS, and Linux platforms.',
                style: TextStyle(
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
                      child: const Text('Close'),
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
                const Text(
                  'Desktop Pet Settings',
                  style: TextStyle(
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
                const Text('Opacity:'),
                const Spacer(),
                Text('${(_preferences['opacity'] * 100).round()}%'),
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
              title: const Text('Enable Animations'),
              subtitle: const Text('Breathing and blinking effects'),
              value: _preferences['animations_enabled'] ?? true,
              onChanged: (value) => _updatePreference('animations_enabled', value ?? false),
              dense: true,
            ),
            
            // 交互开关
            CheckboxListTile(
              secondary: const Icon(Icons.touch_app, size: 20),
              title: const Text('Enable Interactions'),
              subtitle: const Text('Click and drag interactions'),
              value: _preferences['interactions_enabled'] ?? true,
              onChanged: (value) => _updatePreference('interactions_enabled', value ?? false),
              dense: true,
            ),
            
            // 自动隐藏
            CheckboxListTile(
              secondary: const Icon(Icons.visibility_off, size: 20),
              title: const Text('Auto Hide'),
              subtitle: const Text('Hide when not in use'),
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
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    child: const Text('Done'),
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