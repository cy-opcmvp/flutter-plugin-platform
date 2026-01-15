#include "flutter_window.h"

#include <optional>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "screenshot_plugin.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  // Initialize GDI+ for screenshot functionality
  InitializeGDIPlus();

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Register screenshot method channel
  auto screenshot_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.example.screenshot/screenshot",
          &flutter::StandardMethodCodec::GetInstance());

  screenshot_channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleScreenshotMethodCall(call, std::move(result));
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  // Shutdown GDI+
  ShutdownGDIPlus();

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::HandleScreenshotMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  if (method == "captureFullScreen") {
    try {
      std::vector<uint8_t> imageData = CaptureFullScreen();

      // Convert to Flutter byte data
      flutter::EncodableList dataList(imageData.begin(), imageData.end());
      result->Success(flutter::EncodableValue(dataList));
    } catch (const std::exception& e) {
      result->Error("CAPTURE_ERROR", e.what());
    }
  } else if (method == "captureRegion") {
    try {
      const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!arguments) {
        result->Error("INVALID_ARGUMENTS", "Expected map of arguments");
        return;
      }

      auto x_it = arguments->find(flutter::EncodableValue("x"));
      auto y_it = arguments->find(flutter::EncodableValue("y"));
      auto width_it = arguments->find(flutter::EncodableValue("width"));
      auto height_it = arguments->find(flutter::EncodableValue("height"));

      if (x_it == arguments->end() || y_it == arguments->end() ||
          width_it == arguments->end() || height_it == arguments->end()) {
        result->Error("INVALID_ARGUMENTS", "Missing required parameters");
        return;
      }

      int x = std::get<int>(x_it->second);
      int y = std::get<int>(y_it->second);
      int width = std::get<int>(width_it->second);
      int height = std::get<int>(height_it->second);

      std::vector<uint8_t> imageData = CaptureRegion(x, y, width, height);

      flutter::EncodableList dataList(imageData.begin(), imageData.end());
      result->Success(flutter::EncodableValue(dataList));
    } catch (const std::exception& e) {
      result->Error("CAPTURE_ERROR", e.what());
    }
  } else if (method == "captureWindow") {
    try {
      const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!arguments) {
        result->Error("INVALID_ARGUMENTS", "Expected map of arguments");
        return;
      }

      auto windowId_it = arguments->find(flutter::EncodableValue("windowId"));
      if (windowId_it == arguments->end()) {
        result->Error("INVALID_ARGUMENTS", "Missing windowId parameter");
        return;
      }

      std::string windowId = std::get<std::string>(windowId_it->second);
      HWND hwnd = HwndFromString(windowId);

      std::vector<uint8_t> imageData = CaptureWindow(hwnd);

      flutter::EncodableList dataList(imageData.begin(), imageData.end());
      result->Success(flutter::EncodableValue(dataList));
    } catch (const std::exception& e) {
      result->Error("CAPTURE_ERROR", e.what());
    }
  } else if (method == "getAvailableWindows") {
    try {
      std::vector<std::tuple<std::string, std::string>> windows = EnumerateWindows();

      flutter::EncodableList windowList;
      for (const auto& window : windows) {
        flutter::EncodableMap windowMap;
        windowMap[flutter::EncodableValue("title")] = flutter::EncodableValue(std::get<0>(window));
        windowMap[flutter::EncodableValue("id")] = flutter::EncodableValue(std::get<1>(window));
        windowList.push_back(flutter::EncodableValue(windowMap));
      }

      result->Success(flutter::EncodableValue(windowList));
    } catch (const std::exception& e) {
      result->Error("ENUM_ERROR", e.what());
    }
  } else {
    result->NotImplemented();
  }
}
