import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../core/interfaces/i_external_plugin.dart';
import '../../core/models/external_plugin_models.dart';

/// Routes input events to external plugins
/// Implements requirement 5.5 for input routing and event management
class PluginInputRouter extends StatefulWidget {
  final IExternalPlugin plugin;
  final Widget child;
  final bool captureKeyboard;
  final bool captureMouse;
  final bool captureTouch;
  final Function(InputEvent)? onInputEvent;

  const PluginInputRouter({
    super.key,
    required this.plugin,
    required this.child,
    this.captureKeyboard = true,
    this.captureMouse = true,
    this.captureTouch = true,
    this.onInputEvent,
  });

  @override
  State<PluginInputRouter> createState() => _PluginInputRouterState();
}

class _PluginInputRouterState extends State<PluginInputRouter> {
  final FocusNode _focusNode = FocusNode();
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isActive = _focusNode.hasFocus;
    });
  }

  /// Handle keyboard events
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.captureKeyboard || !_isActive) {
      return KeyEventResult.ignored;
    }

    final inputEvent = KeyboardInputEvent(
      type: _getKeyEventType(event),
      key: event.logicalKey,
      character: event.character,
      modifiers: _getKeyModifiers(event),
      timestamp: DateTime.now(),
    );

    _routeInputEvent(inputEvent);
    widget.onInputEvent?.call(inputEvent);

    // Return handled to consume the event for plugin-specific keys
    return _shouldConsumeKeyEvent(event)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  /// Handle pointer events (mouse, touch)
  void _handlePointerEvent(PointerEvent event) {
    if (!_isActive) return;

    InputEvent? inputEvent;

    if (event is PointerDownEvent) {
      if (widget.captureMouse && event.kind == PointerDeviceKind.mouse) {
        inputEvent = MouseInputEvent(
          type: MouseEventType.down,
          button: _getMouseButton(event.buttons),
          position: event.localPosition,
          globalPosition: event.position,
          modifiers: _getPointerModifiers(event),
          timestamp: DateTime.now(),
        );
      } else if (widget.captureTouch && event.kind == PointerDeviceKind.touch) {
        inputEvent = TouchInputEvent(
          type: TouchEventType.down,
          pointerId: event.pointer,
          position: event.localPosition,
          globalPosition: event.position,
          pressure: event.pressure,
          timestamp: DateTime.now(),
        );
      }
    } else if (event is PointerUpEvent) {
      if (widget.captureMouse && event.kind == PointerDeviceKind.mouse) {
        inputEvent = MouseInputEvent(
          type: MouseEventType.up,
          button: _getMouseButton(event.buttons),
          position: event.localPosition,
          globalPosition: event.position,
          modifiers: _getPointerModifiers(event),
          timestamp: DateTime.now(),
        );
      } else if (widget.captureTouch && event.kind == PointerDeviceKind.touch) {
        inputEvent = TouchInputEvent(
          type: TouchEventType.up,
          pointerId: event.pointer,
          position: event.localPosition,
          globalPosition: event.position,
          pressure: event.pressure,
          timestamp: DateTime.now(),
        );
      }
    } else if (event is PointerMoveEvent) {
      if (widget.captureMouse && event.kind == PointerDeviceKind.mouse) {
        inputEvent = MouseInputEvent(
          type: MouseEventType.move,
          button: _getMouseButton(event.buttons),
          position: event.localPosition,
          globalPosition: event.position,
          modifiers: _getPointerModifiers(event),
          timestamp: DateTime.now(),
        );
      } else if (widget.captureTouch && event.kind == PointerDeviceKind.touch) {
        inputEvent = TouchInputEvent(
          type: TouchEventType.move,
          pointerId: event.pointer,
          position: event.localPosition,
          globalPosition: event.position,
          pressure: event.pressure,
          timestamp: DateTime.now(),
        );
      }
    } else if (event is PointerSignalEvent && widget.captureMouse) {
      // Handle scroll events through PointerSignalEvent
      if (event is PointerScrollEvent) {
        inputEvent = ScrollInputEvent(
          scrollDelta: event.scrollDelta,
          position: event.localPosition,
          globalPosition: event.position,
          modifiers: _getPointerModifiers(event),
          timestamp: DateTime.now(),
        );
      }
    }

    if (inputEvent != null) {
      _routeInputEvent(inputEvent);
      widget.onInputEvent?.call(inputEvent);
    }
  }

  /// Route input event to plugin via IPC
  void _routeInputEvent(InputEvent event) {
    if (!widget.plugin.isConnected) return;

    widget.plugin.sendMessage(
      IPCMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: 'input_event',
        sourceId: 'host',
        targetId: widget.plugin.id,
        payload: event.toJson(),
      ),
    );
  }

  /// Get key event type
  KeyEventType _getKeyEventType(KeyEvent event) {
    if (event is KeyDownEvent) return KeyEventType.down;
    if (event is KeyUpEvent) return KeyEventType.up;
    if (event is KeyRepeatEvent) return KeyEventType.repeat;
    return KeyEventType.down;
  }

  /// Get key modifiers
  Set<KeyModifier> _getKeyModifiers(KeyEvent event) {
    final modifiers = <KeyModifier>{};

    if (HardwareKeyboard.instance.isControlPressed) {
      modifiers.add(KeyModifier.control);
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      modifiers.add(KeyModifier.shift);
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      modifiers.add(KeyModifier.alt);
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      modifiers.add(KeyModifier.meta);
    }

    return modifiers;
  }

  /// Get pointer modifiers
  Set<KeyModifier> _getPointerModifiers(PointerEvent event) {
    final modifiers = <KeyModifier>{};

    if (HardwareKeyboard.instance.isControlPressed) {
      modifiers.add(KeyModifier.control);
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      modifiers.add(KeyModifier.shift);
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      modifiers.add(KeyModifier.alt);
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      modifiers.add(KeyModifier.meta);
    }

    return modifiers;
  }

  /// Get mouse button from buttons bitmask
  MouseButton _getMouseButton(int buttons) {
    if (buttons & 1 != 0) return MouseButton.left; // Primary button
    if (buttons & 2 != 0) return MouseButton.right; // Secondary button
    if (buttons & 4 != 0) return MouseButton.middle; // Middle button
    return MouseButton.none;
  }

  /// Check if key event should be consumed by plugin
  bool _shouldConsumeKeyEvent(KeyEvent event) {
    // Let plugin handle specific key combinations
    final supportedInputMethods =
        widget.plugin.manifest.uiIntegration.supportedInputMethods;

    if (!supportedInputMethods.contains('keyboard')) {
      return false;
    }

    // Consume function keys and plugin-specific shortcuts
    final keyLabel = event.logicalKey.keyLabel;
    if (keyLabel.startsWith('F') && keyLabel.length <= 3) {
      return true;
    }

    // Consume Ctrl+key combinations for plugin shortcuts
    if (HardwareKeyboard.instance.isControlPressed) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        onPointerDown: _handlePointerEvent,
        onPointerUp: _handlePointerEvent,
        onPointerMove: _handlePointerEvent,
        onPointerSignal: (event) {
          _handlePointerEvent(event);
        },
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Container(
            decoration: _isActive
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Base class for input events
abstract class InputEvent {
  final DateTime timestamp;

  const InputEvent({required this.timestamp});

  Map<String, dynamic> toJson();
}

/// Keyboard input event
class KeyboardInputEvent extends InputEvent {
  final KeyEventType type;
  final LogicalKeyboardKey key;
  final String? character;
  final Set<KeyModifier> modifiers;

  const KeyboardInputEvent({
    required this.type,
    required this.key,
    this.character,
    required this.modifiers,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'eventType': 'keyboard',
      'type': type.name,
      'keyId': key.keyId,
      'keyLabel': key.keyLabel,
      'character': character,
      'modifiers': modifiers.map((m) => m.name).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Mouse input event
class MouseInputEvent extends InputEvent {
  final MouseEventType type;
  final MouseButton button;
  final Offset position;
  final Offset globalPosition;
  final Set<KeyModifier> modifiers;

  const MouseInputEvent({
    required this.type,
    required this.button,
    required this.position,
    required this.globalPosition,
    required this.modifiers,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'eventType': 'mouse',
      'type': type.name,
      'button': button.name,
      'x': position.dx,
      'y': position.dy,
      'globalX': globalPosition.dx,
      'globalY': globalPosition.dy,
      'modifiers': modifiers.map((m) => m.name).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Touch input event
class TouchInputEvent extends InputEvent {
  final TouchEventType type;
  final int pointerId;
  final Offset position;
  final Offset globalPosition;
  final double pressure;

  const TouchInputEvent({
    required this.type,
    required this.pointerId,
    required this.position,
    required this.globalPosition,
    required this.pressure,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'eventType': 'touch',
      'type': type.name,
      'pointerId': pointerId,
      'x': position.dx,
      'y': position.dy,
      'globalX': globalPosition.dx,
      'globalY': globalPosition.dy,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Scroll input event
class ScrollInputEvent extends InputEvent {
  final Offset scrollDelta;
  final Offset position;
  final Offset globalPosition;
  final Set<KeyModifier> modifiers;

  const ScrollInputEvent({
    required this.scrollDelta,
    required this.position,
    required this.globalPosition,
    required this.modifiers,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'eventType': 'scroll',
      'deltaX': scrollDelta.dx,
      'deltaY': scrollDelta.dy,
      'x': position.dx,
      'y': position.dy,
      'globalX': globalPosition.dx,
      'globalY': globalPosition.dy,
      'modifiers': modifiers.map((m) => m.name).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Key event types
enum KeyEventType { down, up, repeat }

/// Mouse event types
enum MouseEventType { down, up, move, enter, exit }

/// Touch event types
enum TouchEventType { down, up, move, cancel }

/// Mouse buttons
enum MouseButton { none, left, right, middle, back, forward }

/// Key modifiers
enum KeyModifier { control, shift, alt, meta }

/// Input router configuration
class InputRouterConfig {
  final bool enableKeyboardCapture;
  final bool enableMouseCapture;
  final bool enableTouchCapture;
  final bool enableScrollCapture;
  final Set<LogicalKeyboardKey> capturedKeys;
  final Set<MouseButton> capturedButtons;
  final Duration debounceDelay;

  const InputRouterConfig({
    this.enableKeyboardCapture = true,
    this.enableMouseCapture = true,
    this.enableTouchCapture = true,
    this.enableScrollCapture = true,
    this.capturedKeys = const {},
    this.capturedButtons = const {},
    this.debounceDelay = const Duration(milliseconds: 16),
  });

  factory InputRouterConfig.fromManifest(PluginManifest manifest) {
    final supportedInputMethods = manifest.uiIntegration.supportedInputMethods;

    return InputRouterConfig(
      enableKeyboardCapture: supportedInputMethods.contains('keyboard'),
      enableMouseCapture: supportedInputMethods.contains('mouse'),
      enableTouchCapture: supportedInputMethods.contains('touch'),
      enableScrollCapture: supportedInputMethods.contains('scroll'),
    );
  }
}

/// Input event delegation system
class InputEventDelegator {
  static final InputEventDelegator _instance = InputEventDelegator._internal();
  factory InputEventDelegator() => _instance;
  InputEventDelegator._internal();

  final Map<String, List<Function(InputEvent)>> _eventHandlers = {};

  /// Register input event handler for plugin
  void registerHandler(String pluginId, Function(InputEvent) handler) {
    _eventHandlers.putIfAbsent(pluginId, () => []).add(handler);
  }

  /// Unregister input event handler for plugin
  void unregisterHandler(String pluginId, Function(InputEvent) handler) {
    _eventHandlers[pluginId]?.remove(handler);
    if (_eventHandlers[pluginId]?.isEmpty == true) {
      _eventHandlers.remove(pluginId);
    }
  }

  /// Delegate input event to registered handlers
  void delegateEvent(String pluginId, InputEvent event) {
    final handlers = _eventHandlers[pluginId];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler(event);
        } catch (e) {
          // Log error but continue with other handlers
          debugPrint('Error in input event handler for plugin $pluginId: $e');
        }
      }
    }
  }

  /// Clear all handlers for plugin
  void clearHandlers(String pluginId) {
    _eventHandlers.remove(pluginId);
  }

  /// Clear all handlers
  void clearAllHandlers() {
    _eventHandlers.clear();
  }
}
