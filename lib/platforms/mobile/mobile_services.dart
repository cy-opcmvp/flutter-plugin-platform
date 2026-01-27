import 'package:flutter/services.dart';
import 'mobile_services_impl.dart';

/// Mobile-specific services interface
abstract class IMobileServices {
  /// Initialize mobile services
  Future<void> initialize();

  /// Handle device orientation changes
  Future<void> setPreferredOrientations(List<DeviceOrientation> orientations);

  /// Get current device orientation
  DeviceOrientation get currentOrientation;

  /// Stream of orientation changes
  Stream<DeviceOrientation> get orientationStream;

  /// Show mobile-specific notifications
  Future<void> showMobileNotification(MobileNotification notification);

  /// Request mobile permissions
  Future<bool> requestMobilePermission(MobilePermission permission);

  /// Check mobile permission status
  Future<bool> hasMobilePermission(MobilePermission permission);

  /// Handle mobile gestures
  void registerGestureHandler(MobileGestureHandler handler);

  /// Get device information
  Future<MobileDeviceInfo> getDeviceInfo();

  /// Handle app lifecycle changes
  void setAppLifecycleHandler(AppLifecycleHandler handler);
}

/// Mobile notification
class MobileNotification {
  final String title;
  final String body;
  final String? icon;
  final Map<String, dynamic>? data;

  const MobileNotification({
    required this.title,
    required this.body,
    this.icon,
    this.data,
  });
}

/// Mobile permissions
enum MobilePermission {
  camera,
  microphone,
  location,
  storage,
  notifications,
  contacts,
  calendar,
}

/// Mobile gesture handler
abstract class MobileGestureHandler {
  void onTap(TapDetails details);
  void onSwipe(SwipeDetails details);
  void onPinch(PinchDetails details);
  void onLongPress(LongPressDetails details);
}

/// Gesture details
class TapDetails {
  final Offset position;
  const TapDetails({required this.position});
}

class SwipeDetails {
  final Offset startPosition;
  final Offset endPosition;
  final SwipeDirection direction;
  const SwipeDetails({
    required this.startPosition,
    required this.endPosition,
    required this.direction,
  });
}

class PinchDetails {
  final double scale;
  final Offset center;
  const PinchDetails({required this.scale, required this.center});
}

class LongPressDetails {
  final Offset position;
  final Duration duration;
  const LongPressDetails({required this.position, required this.duration});
}

enum SwipeDirection { up, down, left, right }

/// Mobile device information
class MobileDeviceInfo {
  final String model;
  final String manufacturer;
  final String osVersion;
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;

  const MobileDeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
  });
}

/// App lifecycle handler
abstract class AppLifecycleHandler {
  void onResumed();
  void onPaused();
  void onInactive();
  void onDetached();
}

/// Factory for creating mobile services instances
class MobileServicesFactory {
  static IMobileServices create() {
    return MobileServicesImpl();
  }
}
