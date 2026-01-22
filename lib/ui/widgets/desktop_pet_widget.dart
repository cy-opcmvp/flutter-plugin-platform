import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../core/services/platform_environment.dart';
import '../../core/services/desktop_pet_click_through_service.dart';
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

  // 使用 ValueNotifier 管理高频状态，提升性能
  final ValueNotifier<bool> _isHovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isWaitingForDrag = ValueNotifier<bool>(false);

  Timer? _dragTimeoutTimer;
  Timer? _dragEndCheckTimer;

  // 双击检测
  int? _lastTapTime;
  static const int _doubleTapInterval = 300; // 毫秒

  // 拖拽检测
  Offset? _dragStartPosition;
  static const double _dragStartDistance = 0.0; // 像素

  // 拖拽结束检测
  Offset? _lastWindowPosition;
  static const Duration _dragEndCheckDelay = Duration(milliseconds: 500);
  static const double _dragEndPositionThreshold = 2.0; // 像素

  // Platform capabilities
  late PlatformCapabilities _platformCapabilities;

  // 点击穿透相关
  final GlobalKey _petIconKey = GlobalKey();
  final DesktopPetClickThroughService _clickThroughService =
      DesktopPetClickThroughService.instance;

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

    // 添加窗口监听器
    windowManager.addListener(this);

    // 呼吸动画
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _breathingController!, curve: Curves.easeInOut),
    );

    // 眨眼动画
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
    );

    // 启动动画
    if (_isAnimationsEnabled && _breathingController != null) {
      _breathingController!.repeat(reverse: true);
      _startRandomBlinking();
    }

    // 初始化点击穿透 - 在第一帧后更新宠物区域
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePetRegion();
    });
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

  /// 更新宠物图标区域到原生层（用于 WM_NCHITTEST 判断）
  void _updatePetRegion() {
    if (!_platformCapabilities.supportsDesktopPet) {
      return;
    }

    try {
      final RenderBox? renderBox =
          _petIconKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        return;
      }

      // 获取宠物图标的大小
      final size = renderBox.size;

      // 窗口大小固定为 200x200，宠物图标在中心，大小为 120x120
      // 计算窗口客户区坐标
      final left = (200 - size.width) / 2;
      final top = (200 - size.height) / 2;
      final right = left + size.width;
      final bottom = top + size.height;

      // 通过 MethodChannel 传递给原生层
      _clickThroughService.updatePetRegion(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  Widget build(BuildContext context) {
    // If desktop pet is not supported on this platform, show fallback UI
    if (!_platformCapabilities.supportsDesktopPet) {
      return _buildWebFallbackWidget(context);
    }

    return Opacity(
      opacity: _opacity,
      child: Listener(
        onPointerDown: _isInteractionsEnabled ? _handlePointerDown : null,
        onPointerMove: _isInteractionsEnabled ? _handlePointerMove : null,
        onPointerUp: _isInteractionsEnabled ? _handlePointerUp : null,
        onPointerSignal: (event) {},
        behavior: HitTestBehavior.opaque,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isDragging,
          builder: (context, isDragging, _) {
            return MouseRegion(
              cursor: isDragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              onEnter: (_) {
                if (_isInteractionsEnabled) {
                  _isHovered.value = true;
                }
              },
              onExit: (_) {
                if (_isInteractionsEnabled) {
                  _isHovered.value = false;
                }
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovered,
                builder: (context, isHovered, _) {
                  return _breathingAnimation != null && _blinkAnimation != null
                      ? AnimatedBuilder(
                          animation: Listenable.merge([
                            _breathingAnimation!,
                            _blinkAnimation!,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isAnimationsEnabled
                                  ? _breathingAnimation!.value
                                  : 1.0,
                              child: _buildPetContainer(isHovered, isDragging),
                            );
                          },
                        )
                      : _buildPetContainer(isHovered, isDragging);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the main pet container widget
  Widget _buildPetContainer(bool isHovered, bool isDragging) {
    return Container(
      key: _petIconKey, // 用于获取宠物图标位置
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getMainColor(isHovered, isDragging).withValues(alpha: 0.9),
            _getSecondaryColor(isHovered, isDragging).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 主体图标
          Icon(Icons.pets, color: Colors.white, size: isDragging ? 35 : 40),

          // 眼睛
          if (_isAnimationsEnabled && _blinkAnimation != null)
            Positioned(
              top: 35,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_buildEye(), const SizedBox(width: 8), _buildEye()],
              ),
            ),

          // 状态指示器
          if (isDragging)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Builder(
                  builder: (context) => Text(
                    context.l10n.pet_moving,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
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
              const Icon(Icons.info_outline, size: 48, color: Colors.blue),
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
                style: const TextStyle(color: Colors.grey),
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

  Color _getMainColor(bool isHovered, bool isDragging) {
    if (isDragging) return Colors.orange;
    if (isHovered) return Colors.green;
    return Colors.blue;
  }

  Color _getSecondaryColor(bool isHovered, bool isDragging) {
    if (isDragging) return Colors.deepOrange;
    if (isHovered) return Colors.lightGreen;
    return Colors.purple;
  }

  // ===== 宠物事件处理方法 =====

  /// 处理指针按下事件
  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 检测是否是右键（buttons == 2）
    if (event.kind == PointerDeviceKind.mouse && event.buttons == 2) {
      // 右键点击
      widget.onRightClick?.call();
      return;
    }

    // 只处理左键（buttons == 1）的拖拽和双击
    if (event.buttons != 1) {
      return;
    }

    // 双击检测
    if (_lastTapTime != null && now - _lastTapTime! < _doubleTapInterval) {
      // 双击成功
      widget.onDoubleClick?.call();
      _lastTapTime = null;
      return;
    }
    _lastTapTime = now;

    // 拖拽开始：记录起始位置
    _dragStartPosition = event.position;
    _isDragging.value = true;
    _isHovered.value = false;
    _isWaitingForDrag.value = true;

    // 启动超时定时器（1000ms后自动取消拖拽）
    _dragTimeoutTimer?.cancel();
    _dragTimeoutTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_isWaitingForDrag.value && _isDragging.value && mounted) {
        _isWaitingForDrag.value = false;
        _isDragging.value = false;
        _isHovered.value = true;
      }
    });
  }

  /// 处理指针移动事件
  void _handlePointerMove(PointerMoveEvent event) {
    // 如果在等待拖拽期间，检测移动距离
    if (_isWaitingForDrag.value && _dragStartPosition != null) {
      final delta = event.position - _dragStartPosition!;
      if (delta.distance > _dragStartDistance) {
        // 移动距离超过阈值，开始拖拽
        _dragTimeoutTimer?.cancel();
        _isWaitingForDrag.value = false;
        _startDragging();
      }
    }
  }

  /// 处理指针抬起事件
  void _handlePointerUp(PointerUpEvent event) {
    _dragTimeoutTimer?.cancel();

    _isWaitingForDrag.value = false;
    _dragStartPosition = null;

    if (_isDragging.value) {
      _isDragging.value = false;
      _isHovered.value = true;

      // 更新宠物区域
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePetRegion();
      });
    }
  }

  /// 开始拖拽：调用原生拖拽API
  void _startDragging() async {
    try {
      // 获取当前窗口位置作为初始位置
      _lastWindowPosition = await windowManager.getPosition();

      // 启动原生拖拽
      windowManager.startDragging();

      // 启动拖拽结束检测定时器
      _startDragEndCheck();
    } catch (e) {
      // 静默处理错误
    }
  }

  /// 启动拖拽结束检测
  void _startDragEndCheck() {
    _dragEndCheckTimer?.cancel();
    _dragEndCheckTimer = Timer(_dragEndCheckDelay, () {
      if (mounted && _isDragging.value) {
        _checkDragEnd();
      }
    });
  }

  /// 检查拖拽是否结束
  Future<void> _checkDragEnd() async {
    try {
      final currentPosition = await windowManager.getPosition();

      // 如果位置与上次位置相比变化小于阈值，认为拖拽结束
      if (_lastWindowPosition != null) {
        final deltaX = (currentPosition.dx - _lastWindowPosition!.dx).abs();
        final deltaY = (currentPosition.dy - _lastWindowPosition!.dy).abs();

        if (deltaX < _dragEndPositionThreshold &&
            deltaY < _dragEndPositionThreshold) {
          // 位置不再变化，拖拽结束
          _endDragging();
          return;
        }
      }

      // 更新位置并继续检测
      _lastWindowPosition = currentPosition;
      _startDragEndCheck();
    } catch (e) {
      // 出错时也结束拖拽
      _endDragging();
    }
  }

  /// 结束拖拽
  void _endDragging() {
    _dragEndCheckTimer?.cancel();
    _dragTimeoutTimer?.cancel();

    if (_isDragging.value) {
      _isDragging.value = false;
      _isHovered.value = true;
      _isWaitingForDrag.value = false;

      // 更新宠物区域
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePetRegion();
      });
    }
  }

  // ===== WindowListener 回调 =====

  @override
  void onWindowMove() {
    // 窗口移动时更新位置记录
    if (_isDragging.value) {
      windowManager.getPosition().then((position) {
        _lastWindowPosition = position;
      });
    }
  }

  @override
  void dispose() {
    // 释放 ValueNotifier
    _isHovered.dispose();
    _isDragging.dispose();
    _isWaitingForDrag.dispose();

    // 取消定时器
    _dragTimeoutTimer?.cancel();
    _dragEndCheckTimer?.cancel();

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
        elevation: 2,
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
      elevation: 2,
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
              ...quickActions
                  .take(3)
                  .map(
                    (action) => _buildCompactMenuItem(
                      context: context,
                      icon: _getActionIcon(action),
                      label: action,
                      onTap: () => onActionSelected(action),
                    ),
                  ),
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
  State<DesktopPetSettingsPanel> createState() =>
      _DesktopPetSettingsPanelState();
}

class _DesktopPetSettingsPanelState extends State<DesktopPetSettingsPanel> {
  late final ValueNotifier<Map<String, dynamic>> _preferences;
  late PlatformCapabilities _platformCapabilities;

  @override
  void initState() {
    super.initState();
    _preferences = ValueNotifier<Map<String, dynamic>>(
      Map.from(widget.preferences),
    );
    _platformCapabilities = PlatformEnvironment.instance.isWeb
        ? PlatformCapabilities.forWeb()
        : PlatformCapabilities.forNative();
  }

  void _updatePreference(String key, dynamic value) {
    _preferences.value = {..._preferences.value, key: value};
    widget.onPreferencesChanged(_preferences.value);
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
                style: const TextStyle(color: Colors.grey),
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

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _preferences,
      builder: (context, preferences, _) {
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
                    Text('${((preferences['opacity'] ?? 1.0) * 100).round()}%'),
                  ],
                ),
                Slider(
                  value: preferences['opacity'] ?? 1.0,
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
                  value: preferences['animations_enabled'] ?? true,
                  onChanged: (value) =>
                      _updatePreference('animations_enabled', value ?? false),
                  dense: true,
                ),

                // 交互开关
                CheckboxListTile(
                  secondary: const Icon(Icons.touch_app, size: 20),
                  title: Text(context.l10n.pet_enableInteractions),
                  subtitle: Text(context.l10n.pet_interactionsSubtitle),
                  value: preferences['interactions_enabled'] ?? true,
                  onChanged: (value) =>
                      _updatePreference('interactions_enabled', value ?? false),
                  dense: true,
                ),

                // 自动隐藏
                CheckboxListTile(
                  secondary: const Icon(Icons.visibility_off, size: 20),
                  title: Text(context.l10n.pet_autoHide),
                  subtitle: Text(context.l10n.pet_autoHideSubtitle),
                  value: preferences['auto_hide'] ?? false,
                  onChanged: (value) =>
                      _updatePreference('auto_hide', value ?? false),
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
                          _preferences.value = defaultPrefs;
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
      },
    );
  }
}
