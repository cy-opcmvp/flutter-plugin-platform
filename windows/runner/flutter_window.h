#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/encodable_value.h>
#include <flutter/event_sink.h>

#include <memory>

#include "win32_window.h"
#include "hotkey_manager.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Screenshot event sink for communicating region selection back to Flutter
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> screenshot_event_sink_;

  // Hotkey event sink for communicating hotkey events back to Flutter
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> hotkey_event_sink_;

  // Hotkey manager instance
  std::unique_ptr<HotkeyManager> hotkey_manager_;

  // Handle screenshot method calls from Flutter
  void HandleScreenshotMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Handle hotkey method calls from Flutter
  void HandleHotkeyMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Handle screenshot event channel registration
  void RegisterScreenshotEventChannel();

  // Handle hotkey event channel registration
  void RegisterHotkeyEventChannel();

  // Hotkey callback function
  void OnHotkeyPressed(const std::string& actionId);

  // Handle desktop pet method calls from Flutter
  void HandleDesktopPetMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Register desktop pet method channel
  void RegisterDesktopPetMethodChannel();

  // Handle clipboard method calls from Flutter
  void HandleClipboardMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
