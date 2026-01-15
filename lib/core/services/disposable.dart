/// Interface for objects that need to be disposed
///
/// Objects that implement this interface should release all resources
/// (streams, controllers, native objects, etc.) in their [dispose] method.
library;

/// Interface for disposable objects
///
/// This interface should be implemented by any object that holds resources
/// that need to be explicitly released, such as:
/// - Stream controllers
/// - Timer instances
/// - Platform-specific resources
/// - Native object handles
///
/// Example implementation:
/// ```dart
/// class MyService implements Disposable {
///   final StreamController<String> _controller = StreamController.broadcast();
///
///   @override
///   Future<void> dispose() async {
///     await _controller.close();
///   }
/// }
/// ```
abstract class Disposable {
  /// Dispose of resources held by this object
  ///
  /// This method should:
  /// - Close all stream controllers
  /// - Cancel all timers and subscriptions
  /// - Release any native resources
  /// - Clear any caches or large data structures
  ///
  /// After calling this method, the object should be in a state where
  /// it can be safely garbage collected.
  ///
  /// This method should be idempotent - calling it multiple times should
  /// have no additional side effects.
  Future<void> dispose();
}
