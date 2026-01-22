import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'platform_logger.dart';

/// 桌面宠物菜单管理器 - 管理独立的菜单窗口
class DesktopPetMenuManager {
  static DesktopPetMenuManager? _instance;
  static DesktopPetMenuManager get instance {
    _instance ??= DesktopPetMenuManager._();
    return _instance!;
  }

  DesktopPetMenuManager._();

  bool _isMenuVisible = false;
  Offset? _menuPosition;

  /// 菜单是否可见
  bool get isMenuVisible => _isMenuVisible;

  /// 显示菜单（在指定的屏幕坐标）
  Future<void> showMenu({
    required Offset screenPosition,
    required Size menuSize,
  }) async {
    try {
      if (_isMenuVisible) {
        await hideMenu();
      }

      PlatformLogger.instance.logInfo(
        '🍔 显示菜单窗口\n'
        '   屏幕位置: (${screenPosition.dx}, ${screenPosition.dy})\n'
        '   菜单尺寸: ${menuSize.width}x${menuSize.height}',
      );

      _menuPosition = screenPosition;
      _isMenuVisible = true;

      // TODO: 这里需要创建一个新的 Flutter 窗口实例
      // 由于 Flutter 的限制，我们需要使用不同的方法
      // 方案1: 使用 window_manager 创建子窗口（需要原生支持）
      // 方案2: 临时扩大主窗口来显示菜单（简单但不完美）
      // 方案3: 使用原生平台代码创建真正的子窗口

      // 当前实现：方案2 - 临时扩大窗口
      await _expandWindowForMenu(screenPosition, menuSize);
    } catch (e) {
      PlatformLogger.instance.logError('Failed to show menu', e);
    }
  }

  /// 隐藏菜单
  Future<void> hideMenu() async {
    if (!_isMenuVisible) return;

    try {
      PlatformLogger.instance.logInfo('🍔 隐藏菜单窗口');

      _isMenuVisible = false;
      _menuPosition = null;

      // 恢复窗口到宠物大小
      await _restorePetWindow();
    } catch (e) {
      PlatformLogger.instance.logError('Failed to hide menu', e);
    }
  }

  /// 临时扩大窗口以显示菜单
  Future<void> _expandWindowForMenu(
    Offset screenPosition,
    Size menuSize,
  ) async {
    // 获取当前窗口位置和大小
    final currentPosition = await windowManager.getPosition();
    final currentSize = await windowManager.getSize();

    // 计算菜单相对于窗口的位置
    final menuRelativeX = screenPosition.dx - currentPosition.dx;
    final menuRelativeY = screenPosition.dy - currentPosition.dy;

    // 计算需要的窗口大小（包含宠物和菜单）
    final requiredWidth = menuRelativeX + menuSize.width + 10;
    final requiredHeight = menuRelativeY + menuSize.height + 10;

    final newWidth = requiredWidth > currentSize.width
        ? requiredWidth
        : currentSize.width;
    final newHeight = requiredHeight > currentSize.height
        ? requiredHeight
        : currentSize.height;

    if (newWidth > currentSize.width || newHeight > currentSize.height) {
      PlatformLogger.instance.logInfo(
        '🍔 扩大窗口以显示菜单\n'
        '   当前尺寸: ${currentSize.width}x${currentSize.height}\n'
        '   新尺寸: $newWidth x $newHeight',
      );

      await windowManager.setSize(Size(newWidth, newHeight));
    }
  }

  /// 恢复宠物窗口大小
  Future<void> _restorePetWindow() async {
    const petSize = Size(120.0, 120.0);

    PlatformLogger.instance.logInfo(
      '🍔 恢复窗口到宠物大小: ${petSize.width}x${petSize.height}',
    );

    await windowManager.setSize(petSize);
  }
}
