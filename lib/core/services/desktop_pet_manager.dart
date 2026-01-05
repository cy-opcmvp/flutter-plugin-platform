import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'platform_logger.dart';

// Conditional imports for platform detection
import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_web.dart' as platform_helper;

/// Desktop Pet管理器 - 支持所有桌面平台
class DesktopPetManager {
  static const MethodChannel _channel = MethodChannel('desktop_pet');
  
  bool _isInitialized = false;
  bool _isDesktopPetMode = false;
  bool _isAlwaysOnTop = false;
  
  // Desktop pet preferences
  final Map<String, dynamic> _petPreferences = {
    'position': {'x': 100.0, 'y': 100.0},
    'size': {'width': 200.0, 'height': 200.0},
    'opacity': 1.0,
    'animations_enabled': true,
    'interactions_enabled': true,
    'auto_hide': false,
    'theme': 'default',
  };

  /// 初始化Desktop Pet管理器
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 首先检查kIsWeb以确保web平台兼容性
    if (kIsWeb) {
      _isInitialized = true;
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Manager',
        'Web platform does not support desktop pet functionality'
      );
      return;
    }
    
    // 检查平台支持 - 如果不支持则优雅地跳过初始化
    if (!_isSupported) {
      _isInitialized = true;
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Manager',
        'Platform does not support desktop pet functionality'
      );
      return;
    }
    
    try {
      // 尝试初始化平台特定功能
      if (_isDesktopPlatform()) {
        await _initializePlatformSpecific();
      }
      
      // 加载用户偏好设置
      await _loadPetPreferences();
      
      _isInitialized = true;
      final platform = _getPlatformName();
      PlatformLogger.instance.logInfo('Desktop Pet Manager initialized for $platform');
    } catch (e) {
      // 即使平台特定功能失败，也允许基本功能
      _isInitialized = true;
      PlatformLogger.instance.logWarning('Desktop Pet Manager initialized with basic functionality: $e');
    }
  }

  /// 启用Desktop Pet模式
  Future<void> enableDesktopPetMode() async {
    if (!_isInitialized) await initialize();
    
    // Web平台直接返回，不执行任何操作
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Mode',
        'Web platform does not support desktop pet functionality'
      );
      return;
    }
    
    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Mode',
        'Platform does not support desktop pet functionality'
      );
      return;
    }
    
    try {
      // 尝试使用平台特定实现
      await _enablePlatformSpecificPetMode();
      
      _isDesktopPetMode = true;
      PlatformLogger.instance.logInfo('Desktop Pet mode enabled');
      
    } catch (e) {
      // 如果平台特定实现失败，使用基本实现
      PlatformLogger.instance.logWarning('Platform specific implementation failed, using basic mode: $e');
      _isDesktopPetMode = true;
    }
  }

  /// 禁用Desktop Pet模式
  Future<void> disableDesktopPetMode() async {
    if (!_isInitialized || !_isDesktopPetMode) return;
    
    // Web平台直接返回，不执行任何操作
    if (kIsWeb) {
      return;
    }
    
    // 检查平台支持
    if (!_isSupported) {
      return;
    }
    
    try {
      await _disablePlatformSpecificPetMode();
    } catch (e) {
      PlatformLogger.instance.logError('Desktop Pet Mode', e);
    }
    
    _isDesktopPetMode = false;
    _isAlwaysOnTop = false;
    PlatformLogger.instance.logInfo('Desktop Pet mode disabled');
  }

  /// 检查是否在Desktop Pet模式
  bool get isDesktopPetMode => _isDesktopPetMode;
  
  /// 检查窗口是否置顶
  bool get isAlwaysOnTop => _isAlwaysOnTop;
  
  /// 检查当前实例是否支持Desktop Pet功能
  bool get _isSupported => isSupported();

  /// 设置窗口置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isInitialized) return;
    
    // Web平台不支持窗口置顶功能
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Always On Top',
        'Web platform does not support window always-on-top'
      );
      return;
    }
    
    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Always On Top',
        'Platform does not support window always-on-top'
      );
      return;
    }
    
    try {
      await _channel.invokeMethod('setAlwaysOnTop', {'alwaysOnTop': alwaysOnTop});
      _isAlwaysOnTop = alwaysOnTop;
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to set always on top: $e');
      // 在不支持的平台上，仍然记录状态
      _isAlwaysOnTop = alwaysOnTop;
    }
  }

  /// 更新Pet偏好设置
  Future<void> updatePetPreferences(Map<String, dynamic> preferences) async {
    _petPreferences.addAll(preferences);
    await _savePetPreferences();
    
    // 如果在Pet模式下，应用更改
    if (_isDesktopPetMode) {
      await _applyPetPreferences();
    }
  }

  /// 获取当前偏好设置
  Map<String, dynamic> get petPreferences => Map.from(_petPreferences);

  /// 平滑过渡到Desktop Pet模式
  Future<void> transitionToDesktopPet() async {
    if (_isDesktopPetMode) return;
    
    // Web平台不支持Desktop Pet过渡
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Web platform does not support desktop pet transitions'
      );
      return;
    }
    
    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Platform does not support desktop pet transitions'
      );
      return;
    }
    
    try {
      // 尝试平滑过渡动画
      await _channel.invokeMethod('transitionToDesktopPet', {
        'duration': 500,
        'target_position': _petPreferences['position'],
        'target_size': _petPreferences['size'],
      });
      
      _isDesktopPetMode = true;
    } catch (e) {
      // 回退到基本模式 - 直接启用Desktop Pet模式
      PlatformLogger.instance.logWarning('Platform channel not available, using basic mode: $e');
      _isDesktopPetMode = true;
    }
  }

  /// 过渡回完整应用模式
  Future<void> transitionToFullApplication() async {
    if (!_isDesktopPetMode) return;
    
    // Web平台不支持Desktop Pet过渡
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Web platform does not support desktop pet transitions'
      );
      return;
    }
    
    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Platform does not support desktop pet transitions'
      );
      return;
    }
    
    try {
      await _channel.invokeMethod('transitionToFullApplication', {
        'duration': 500,
      });
      
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
    } catch (e) {
      // 回退到基本模式 - 直接禁用Desktop Pet模式
      PlatformLogger.instance.logWarning('Platform channel not available, using basic mode: $e');
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
    }
  }

  /// 检查Desktop Pet是否支持
  static bool isSupported() {
    // Web平台不支持Desktop Pet功能 - 首先检查kIsWeb
    if (kIsWeb) return false;
    
    // 所有桌面平台都支持基本的Desktop Pet功能
    return _isDesktopPlatform();
  }
  
  /// 检查是否为桌面平台（避免在web上调用Platform）
  static bool _isDesktopPlatform() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;
    
    // 使用安全的平台检测助手
    return platform_helper.isWindows || platform_helper.isMacOS || platform_helper.isLinux;
  }

  /// 获取平台特定功能支持情况
  Map<String, bool> getPlatformCapabilities() {
    // Web平台不支持任何桌面特定功能
    if (kIsWeb) {
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }
    
    // 不支持的平台不支持任何桌面特定功能
    if (!_isSupported) {
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }
    
    // 桌面平台功能支持
    try {
      return {
        'always_on_top': _isDesktopPlatform(),
        'transparency': _isWindowsOrMacOS(),
        'system_tray': _isWindowsOrLinux(),
        'smooth_animations': _isWindowsOrMacOS(),
        'drag_and_drop': _isDesktopPlatform(),
        'right_click_menu': _isDesktopPlatform(),
        'resize': _isDesktopPlatform(),
      };
    } catch (e) {
      // 如果平台检测失败，返回保守的功能集
      PlatformLogger.instance.logError('Platform Capabilities', e);
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }
  }
  
  /// 检查是否为Windows或macOS平台
  bool _isWindowsOrMacOS() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;
    
    // 使用安全的平台检测助手
    return platform_helper.isWindows || platform_helper.isMacOS;
  }
  
  /// 检查是否为Windows或Linux平台
  bool _isWindowsOrLinux() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;
    
    // 使用安全的平台检测助手
    return platform_helper.isWindows || platform_helper.isLinux;
  }
  
  /// 获取平台名称（Web安全）
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    
    // 使用安全的平台检测助手
    return platform_helper.operatingSystem;
  }

  // 私有方法

  Future<void> _initializePlatformSpecific() async {
    // Web平台跳过平台特定初始化
    if (kIsWeb) return;
    
    // 不支持的平台跳过平台特定初始化
    if (!_isSupported) return;
    
    try {
      await _channel.invokeMethod('initialize', {
        'platform': _getPlatformName(),
        'capabilities': getPlatformCapabilities(),
      });
    } catch (e) {
      // 平台特定初始化失败不影响基本功能
      PlatformLogger.instance.logWarning('Platform specific initialization failed: $e');
    }
  }

  Future<void> _enablePlatformSpecificPetMode() async {
    // Web平台跳过平台特定Pet模式
    if (kIsWeb) return;
    
    // 不支持的平台跳过平台特定Pet模式
    if (!_isSupported) return;
    
    await _channel.invokeMethod('enableDesktopPetMode', {
      'position': _petPreferences['position'],
      'size': _petPreferences['size'],
      'opacity': _petPreferences['opacity'],
      'alwaysOnTop': _petPreferences['always_on_top'] ?? true,
    });
  }

  Future<void> _disablePlatformSpecificPetMode() async {
    // Web平台跳过平台特定Pet模式
    if (kIsWeb) return;
    
    // 不支持的平台跳过平台特定Pet模式
    if (!_isSupported) return;
    
    await _channel.invokeMethod('disableDesktopPetMode');
  }

  Future<void> _applyPetPreferences() async {
    if (!_isDesktopPetMode) return;
    
    // Web平台跳过偏好设置应用
    if (kIsWeb) return;
    
    // 不支持的平台跳过偏好设置应用
    if (!_isSupported) return;
    
    try {
      await _channel.invokeMethod('updatePetSettings', {
        'position': _petPreferences['position'],
        'size': _petPreferences['size'],
        'opacity': _petPreferences['opacity'],
        'alwaysOnTop': _petPreferences['always_on_top'] ?? true,
      });
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to apply pet preferences: $e');
    }
  }

  Future<void> _loadPetPreferences() async {
    try {
      // 这里可以从本地存储加载偏好设置
      // 暂时使用默认值
      PlatformLogger.instance.logDebug('Loaded pet preferences: $_petPreferences');
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to load pet preferences: $e');
    }
  }

  Future<void> _savePetPreferences() async {
    try {
      // 这里可以保存偏好设置到本地存储
      PlatformLogger.instance.logDebug('Saved pet preferences: $_petPreferences');
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to save pet preferences: $e');
    }
  }
}