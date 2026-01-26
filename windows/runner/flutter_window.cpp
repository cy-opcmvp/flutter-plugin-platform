#include "flutter_window.h"

#include <optional>
#include <thread>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <fstream>
#include <windowsx.h>  // 用于 GET_X_LPARAM 和 GET_Y_LPARAM

#include "flutter/generated_plugin_registrant.h"
#include "screenshot_plugin.h"
#include "native_screenshot_window.h"
#include "hotkey_manager.h"

// 用于同步存储原生窗口选择结果
static struct {
  bool completed = false;
  bool cancelled = false;
  int x = 0, y = 0, width = 0, height = 0;
} g_regionSelectionResult;

// 桌宠点击穿透 - 宠物图标区域（用于 WM_NCHITTEST 判断）
static struct {
  bool valid = false;
  int left = 0;
  int top = 0;
  int right = 0;
  int bottom = 0;
} g_petRegion;

// 文件日志函数
static void LogToFile(const char* message) {
  static std::ofstream logFile;
  static bool initialized = false;
  if (!initialized) {
    logFile.open("C:\\temp\\screenshot_flutter.log", std::ios::app);
    initialized = true;
  }
  if (logFile.is_open()) {
    logFile << message << std::endl;
    logFile.flush();
  }
}

// 日志输出宏
#define LOG_FLUTTER(msg) \
  do { \
    char buffer[512]; \
    sprintf_s(buffer, "[FlutterWindow] " msg "\n"); \
    OutputDebugStringA(buffer); \
    LogToFile(buffer); \
  } while (0)

#define LOG_FLUTTER_FMT(msg, ...) \
  do { \
    char buffer[512]; \
    sprintf_s(buffer, sizeof(buffer), "[FlutterWindow] " msg "\n", __VA_ARGS__); \
    OutputDebugStringA(buffer); \
    LogToFile(buffer); \
  } while (0)

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

  // Register screenshot event channel for region selection feedback
  RegisterScreenshotEventChannel();

  // Register hotkey event channel
  RegisterHotkeyEventChannel();

  // Register screenshot method channel
  auto screenshot_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.example.screenshot/screenshot",
          &flutter::StandardMethodCodec::GetInstance());

  screenshot_channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleScreenshotMethodCall(call, std::move(result));
      });

  // Register hotkey method channel
  auto hotkey_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.example.screenshot/hotkey",
          &flutter::StandardMethodCodec::GetInstance());

  hotkey_channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleHotkeyMethodCall(call, std::move(result));
      });

  // Register desktop pet method channel
  auto desktop_pet_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "desktop_pet",
          &flutter::StandardMethodCodec::GetInstance());

  desktop_pet_channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleDesktopPetMethodCall(call, std::move(result));
      });

  // Register clipboard method channel
  auto clipboard_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.example.screenshot/clipboard",
          &flutter::StandardMethodCodec::GetInstance());

  clipboard_channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleClipboardMethodCall(call, std::move(result));
      });

  // Initialize hotkey manager
  hotkey_manager_ = std::make_unique<HotkeyManager>();
  hotkey_manager_->SetCallback([this](const std::string& actionId) {
    OnHotkeyPressed(actionId);
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
  // 在进入/退出调整大小模式时，不让 Flutter 处理这些消息
  // 这可以防止 Flutter 的内部状态导致鼠标卡住
  if (message == WM_ENTERSIZEMOVE || message == WM_EXITSIZEMOVE) {
    if (message == WM_EXITSIZEMOVE) {
      LOG_FLUTTER("WM_EXITSIZEMOVE - Forcing mouse state reset");
      // 强制释放鼠标捕获（无论是否被我们持有）
      ReleaseCapture();
      // 发送鼠标移动消息来刷新鼠标状态
      POINT pt;
      GetCursorPos(&pt);
      PostMessage(hwnd, WM_MOUSEMOVE, 0, MAKELPARAM(pt.x, pt.y));
    }
    // 直接传递给默认处理，不让 Flutter 处理
    return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  }

  // Log mouse-related events for debugging
  switch (message) {
    case WM_LBUTTONDOWN:
      LOG_FLUTTER("WM_LBUTTONDOWN - Left mouse button DOWN");
      break;
    case WM_LBUTTONUP:
      LOG_FLUTTER("WM_LBUTTONUP - Left mouse button UP");
      break;
    case WM_RBUTTONDOWN:
      LOG_FLUTTER("WM_RBUTTONDOWN - Right mouse button DOWN");
      break;
    case WM_RBUTTONUP:
      LOG_FLUTTER("WM_RBUTTONUP - Right mouse button UP");
      break;
    case WM_NCLBUTTONDOWN:
      LOG_FLUTTER("WM_NCLBUTTONDOWN - Non-client area left button DOWN");
      break;
    case WM_NCLBUTTONUP:
      LOG_FLUTTER("WM_NCLBUTTONUP - Non-client area left button UP");
      break;
    case WM_MOUSEMOVE:
      // Don't log every mouse move to avoid spam
      break;
    case WM_CAPTURECHANGED:
      LOG_FLUTTER("WM_CAPTURECHANGED - Mouse capture changed");
      break;
    case WM_ENTERSIZEMOVE:
      LOG_FLUTTER("WM_ENTERSIZEMOVE - Entering size move");
      break;
    case WM_EXITSIZEMOVE:
      LOG_FLUTTER("WM_EXITSIZEMOVE - Exiting size move");
      break;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      LOG_FLUTTER_FMT("Flutter handled message: %u, result: %lld", message, (long long)*result);
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_HOTKEY:
      if (hotkey_manager_) {
        hotkey_manager_->HandleHotkeyMessage(wparam, lparam);
      }
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterScreenshotEventChannel() {
  // 暂时禁用 EventChannel 实现由于 API 不匹配
  // TODO: 找到正确的 Flutter Windows EventChannel API 并实现
  // 使用全局变量 g_screenshot_event_sink 存储事件 sink（通过 MethodChannel 反向调用）
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
      std::vector<WindowInfo> windows = EnumerateWindows();

      flutter::EncodableList windowList;
      for (const auto& window : windows) {
        flutter::EncodableMap windowMap;
        windowMap[flutter::EncodableValue("title")] = flutter::EncodableValue(window.title);
        windowMap[flutter::EncodableValue("id")] = flutter::EncodableValue(window.id);

        // Add app name if available
        if (!window.appName.empty()) {
          windowMap[flutter::EncodableValue("appName")] = flutter::EncodableValue(window.appName);
        }

        // Add icon if available
        if (!window.icon.empty()) {
          flutter::EncodableList iconData(window.icon.begin(), window.icon.end());
          windowMap[flutter::EncodableValue("icon")] = flutter::EncodableValue(iconData);
        }

        windowList.push_back(flutter::EncodableValue(windowMap));
      }

      result->Success(flutter::EncodableValue(windowList));
    } catch (const std::exception& e) {
      result->Error("ENUM_ERROR", e.what());
    }
  } else if (method == "showNativeRegionCapture") {
    LOG_FLUTTER("showNativeRegionCapture called");

    try {
      // 重置全局结果
      g_regionSelectionResult.completed = false;
      g_regionSelectionResult.cancelled = false;
      LOG_FLUTTER("Reset result structure");

      // 在后台线程中显示原生截图窗口
      LOG_FLUTTER("Starting background thread for native window...");
      std::thread([&result]() {
        LOG_FLUTTER("Native window thread started");

        NativeScreenshotWindow window;
        bool showResult = window.Show(
          [](int x, int y, int width, int height) {
            // 区域选择完成 - 存储结果
            LOG_FLUTTER_FMT("Region selected: (%d,%d) %dx%d", x, y, width, height);
            g_regionSelectionResult.completed = true;
            g_regionSelectionResult.cancelled = false;
            g_regionSelectionResult.x = x;
            g_regionSelectionResult.y = y;
            g_regionSelectionResult.width = width;
            g_regionSelectionResult.height = height;
          },
          []() {
            // 用户取消
            LOG_FLUTTER("Region capture cancelled by user");
            g_regionSelectionResult.completed = true;
            g_regionSelectionResult.cancelled = true;
          }
        );

        LOG_FLUTTER_FMT("Native window Show() returned: %s", showResult ? "true" : "false");

        // 等待窗口关闭和结果
        // 注意：窗口的消息循环会阻塞在这里，直到用户完成选择或取消
        LOG_FLUTTER("Native window thread exiting");
      }).detach();

      LOG_FLUTTER("Background thread detached, returning success to Flutter");
      // 由于窗口在后台线程运行，立即返回成功
      // Flutter 端需要轮询或使用其他机制来获取结果
      result->Success(flutter::EncodableValue(true));

    } catch (const std::exception& e) {
      LOG_FLUTTER_FMT("Exception in showNativeRegionCapture: %s", e.what());
      result->Error("WINDOW_ERROR", e.what());
    }
  } else if (method == "getRegionSelectionResult") {
    LOG_FLUTTER_FMT("getRegionSelectionResult called: completed=%d, cancelled=%d",
                     g_regionSelectionResult.completed, g_regionSelectionResult.cancelled);

    // 获取区域选择结果（用于轮询）
    if (g_regionSelectionResult.completed) {
      if (g_regionSelectionResult.cancelled) {
        // 用户取消
        LOG_FLUTTER("Returning cancelled result");
        result->Success(flutter::EncodableValue());
      } else {
        // 用户选择了区域
        LOG_FLUTTER_FMT("Returning selected region: (%d,%d) %dx%d",
                         g_regionSelectionResult.x, g_regionSelectionResult.y,
                         g_regionSelectionResult.width, g_regionSelectionResult.height);
        flutter::EncodableMap resultMap;
        resultMap[flutter::EncodableValue("x")] =
            flutter::EncodableValue(g_regionSelectionResult.x);
        resultMap[flutter::EncodableValue("y")] =
            flutter::EncodableValue(g_regionSelectionResult.y);
        resultMap[flutter::EncodableValue("width")] =
            flutter::EncodableValue(g_regionSelectionResult.width);
        resultMap[flutter::EncodableValue("height")] =
            flutter::EncodableValue(g_regionSelectionResult.height);
        result->Success(flutter::EncodableValue(resultMap));
      }
    } else {
      // 还未完成，返回 null
      LOG_FLUTTER("Result not ready, returning null");
      result->Success(flutter::EncodableValue());
    }
  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::RegisterHotkeyEventChannel() {
  // 暂时禁用 EventChannel 实现由于 API 不匹配
  // TODO: 找到正确的 Flutter Windows EventChannel API 并实现
  // 使用全局变量或通过 MethodChannel 反向调用
  LOG_FLUTTER("Hotkey event channel registered (placeholder)");
}

void FlutterWindow::HandleHotkeyMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  LOG_FLUTTER_FMT("Hotkey method called: %s", call.method_name().c_str());

  const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());

  if (call.method_name() == "registerHotkey") {
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    auto actionIdIt = arguments->find(flutter::EncodableValue("actionId"));
    auto shortcutIt = arguments->find(flutter::EncodableValue("shortcut"));

    if (actionIdIt == arguments->end() || shortcutIt == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing actionId or shortcut");
      return;
    }

    const auto* actionIdStr = std::get_if<std::string>(&actionIdIt->second);
    const auto* shortcutStr = std::get_if<std::string>(&shortcutIt->second);

    if (!actionIdStr || !shortcutStr) {
      result->Error("INVALID_ARGUMENTS", "Invalid actionId or shortcut type");
      return;
    }

    LOG_FLUTTER_FMT("Registering hotkey: %s -> %s", actionIdStr->c_str(), shortcutStr->c_str());

    bool success = hotkey_manager_->RegisterHotkey(*actionIdStr, *shortcutStr);
    result->Success(flutter::EncodableValue(success));

  } else if (call.method_name() == "unregisterHotkey") {
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    auto actionIdIt = arguments->find(flutter::EncodableValue("actionId"));
    if (actionIdIt == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing actionId");
      return;
    }

    const auto* actionIdStr = std::get_if<std::string>(&actionIdIt->second);
    if (!actionIdStr) {
      result->Error("INVALID_ARGUMENTS", "Invalid actionId type");
      return;
    }

    LOG_FLUTTER_FMT("Unregistering hotkey: %s", actionIdStr->c_str());

    bool success = hotkey_manager_->UnregisterHotkey(*actionIdStr);
    result->Success(flutter::EncodableValue(success));

  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::OnHotkeyPressed(const std::string& actionId) {
  LOG_FLUTTER_FMT("Hotkey pressed: %s", actionId.c_str());

  // 直接在原生端处理热键事件，不通过 EventChannel
  if (actionId == "regionCapture") {
    // 触发区域截图
    std::thread([this]() {
      LOG_FLUTTER("Triggering region capture from hotkey");

      NativeScreenshotWindow window;
      bool success = window.Show(
          [](int x, int y, int width, int height) {
            LOG_FLUTTER_FMT("Region selected from hotkey: (%d,%d) %dx%d", x, y, width, height);
            // 保存选择结果
            g_regionSelectionResult.completed = true;
            g_regionSelectionResult.cancelled = false;
            g_regionSelectionResult.x = x;
            g_regionSelectionResult.y = y;
            g_regionSelectionResult.width = width;
            g_regionSelectionResult.height = height;
          },
          []() {
            LOG_FLUTTER("Region capture cancelled from hotkey");
            g_regionSelectionResult.completed = true;
            g_regionSelectionResult.cancelled = true;
          }
      );

      if (!success) {
        LOG_FLUTTER("Failed to show native region capture window from hotkey");
      }
    }).detach();

  } else if (actionId == "fullScreenCapture") {
    // 触发全屏截图
    LOG_FLUTTER("Triggering full screen capture from hotkey");
    // TODO: 实现全屏截图功能

  } else if (actionId == "windowCapture") {
    // 触发窗口截图
    LOG_FLUTTER("Triggering window capture from hotkey");
    // TODO: 实现窗口截图功能

  } else {
    LOG_FLUTTER_FMT("Unknown hotkey action: %s", actionId.c_str());
  }
}

void FlutterWindow::RegisterDesktopPetMethodChannel() {
  // Desktop pet method channel is already registered in OnCreate
  LOG_FLUTTER("Desktop pet method channel registered");
}

void FlutterWindow::HandleDesktopPetMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  LOG_FLUTTER_FMT("Desktop pet method called: %s", call.method_name().c_str());

  const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());

  if (call.method_name() == "updatePetRegion") {
    // 更新宠物图标区域（用于 WM_NCHITTEST 判断）
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    auto leftIt = arguments->find(flutter::EncodableValue("left"));
    auto topIt = arguments->find(flutter::EncodableValue("top"));
    auto rightIt = arguments->find(flutter::EncodableValue("right"));
    auto bottomIt = arguments->find(flutter::EncodableValue("bottom"));

    if (leftIt == arguments->end() || topIt == arguments->end() ||
        rightIt == arguments->end() || bottomIt == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing region coordinates");
      return;
    }

    const auto* leftInt = std::get_if<int>(&leftIt->second);
    const auto* topInt = std::get_if<int>(&topIt->second);
    const auto* rightInt = std::get_if<int>(&rightIt->second);
    const auto* bottomInt = std::get_if<int>(&bottomIt->second);

    if (!leftInt || !topInt || !rightInt || !bottomInt) {
      result->Error("INVALID_ARGUMENTS", "Invalid coordinate type, expected int");
      return;
    }

    // 更新全局宠物区域
    g_petRegion.valid = true;
    g_petRegion.left = *leftInt;
    g_petRegion.top = *topInt;
    g_petRegion.right = *rightInt;
    g_petRegion.bottom = *bottomInt;

    LOG_FLUTTER_FMT("Pet region updated: (%d,%d) to (%d,%d)",
                     g_petRegion.left, g_petRegion.top,
                     g_petRegion.right, g_petRegion.bottom);

    result->Success(flutter::EncodableValue(true));

  } else if (call.method_name() == "setClickThrough") {
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    auto enabledIt = arguments->find(flutter::EncodableValue("enabled"));
    if (enabledIt == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing 'enabled' parameter");
      return;
    }

    const auto* enabledBool = std::get_if<bool>(&enabledIt->second);
    if (!enabledBool) {
      result->Error("INVALID_ARGUMENTS", "Invalid 'enabled' type, expected bool");
      return;
    }

    bool enabled = *enabledBool;
    HWND hwnd = GetHandle();

    if (enabled) {
      // 启用点击穿透 - 设置整个窗口为可点击区域
      // 实际的点击穿透由 Flutter 层的 IgnorePointer 处理
      LOG_FLUTTER("Click-through mode enabled (handled by Flutter layer)");

      // 确保窗口区域设置为整个窗口（不做裁剪）
      SetWindowRgn(hwnd, NULL, TRUE);
    } else {
      // 禁用点击穿透 - 同样设置为整个窗口
      LOG_FLUTTER("Click-through disabled");
      SetWindowRgn(hwnd, NULL, TRUE);
    }

    result->Success(flutter::EncodableValue(true));

  } else if (call.method_name() == "setIgnoreMouseEvents") {
    // macOS 兼容方法 - 在 Windows 上等同于 setClickThrough
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "No arguments provided");
      return;
    }

    auto ignoreIt = arguments->find(flutter::EncodableValue("ignore"));
    if (ignoreIt == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing 'ignore' parameter");
      return;
    }

    const auto* ignoreBool = std::get_if<bool>(&ignoreIt->second);
    if (!ignoreBool) {
      result->Error("INVALID_ARGUMENTS", "Invalid 'ignore' type, expected bool");
      return;
    }

    bool ignore = *ignoreBool;
    HWND hwnd = GetHandle();

    if (ignore) {
      LOG_FLUTTER("Ignoring mouse events (click-through)");
      LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
      exStyle |= WS_EX_TRANSPARENT | WS_EX_LAYERED;
      SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);
      SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
      SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    } else {
      LOG_FLUTTER("Accepting mouse events");
      LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
      exStyle &= ~WS_EX_TRANSPARENT;
      SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);
      SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    }

    result->Success(flutter::EncodableValue(true));

  } else {
    LOG_FLUTTER_FMT("Unknown desktop pet method: %s", call.method_name().c_str());
    result->NotImplemented();
  }
}

void FlutterWindow::HandleClipboardMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  LOG_FLUTTER_FMT("Clipboard method called: %s", call.method_name().c_str());

  if (call.method_name() == "getImageFromClipboard") {
    // 从剪贴板获取图片
    if (!OpenClipboard(nullptr)) {
      LOG_FLUTTER("Failed to open clipboard");
      result->Success(flutter::EncodableValue());
      return;
    }

    HANDLE hData = GetClipboardData(CF_DIB);
    if (!hData) {
      LOG_FLUTTER("No image data in clipboard");
      CloseClipboard();
      result->Success(flutter::EncodableValue());
      return;
    }

    // 获取 DIB 数据
    LPBITMAPINFO lpbi = (LPBITMAPINFO)GlobalLock(hData);
    if (!lpbi) {
      LOG_FLUTTER("Failed to lock clipboard data");
      CloseClipboard();
      result->Success(flutter::EncodableValue());
      return;
    }

    // 计算图像大小
    BITMAPINFOHEADER& bih = lpbi->bmiHeader;
    int width = bih.biWidth;
    int height = abs(bih.biHeight);
    int bitCount = bih.biBitCount;
    int bytesPerPixel = bitCount / 8;
    int rowSize = ((width * bitCount + 31) / 32) * 4; // 对齐到 4 字节
    int imageSize = rowSize * height;

    // 创建字节缓冲区
    std::vector<uint8_t> imageData;
    imageData.reserve(sizeof(BITMAPINFOHEADER) + imageSize);

    // 添加 BITMAPINFOHEADER
    uint8_t* headerBytes = reinterpret_cast<uint8_t*>(&bih);
    imageData.insert(imageData.end(), headerBytes, headerBytes + sizeof(BITMAPINFOHEADER));

    // 添加像素数据
    uint8_t* pixels = reinterpret_cast<uint8_t*>(lpbi) + sizeof(BITMAPINFOHEADER);
    if (bih.biHeight > 0) {
      // 自下而上的 DIB, 需要翻转
      for (int y = height - 1; y >= 0; y--) {
        imageData.insert(imageData.end(), pixels + y * rowSize, pixels + (y + 1) * rowSize);
      }
    } else {
      // 自上而下的 DIB
      imageData.insert(imageData.end(), pixels, pixels + imageSize);
    }

    GlobalUnlock(hData);
    CloseClipboard();

    LOG_FLUTTER_FMT("Retrieved image from clipboard: %dx%d, %d bytes", width, height, imageData.size());

    flutter::EncodableList dataList(imageData.begin(), imageData.end());
    result->Success(flutter::EncodableValue(dataList));

  } else if (call.method_name() == "hasImage") {
    // 检查剪贴板是否有图片
    if (!OpenClipboard(nullptr)) {
      LOG_FLUTTER("Failed to open clipboard for check");
      result->Success(flutter::EncodableValue(false));
      return;
    }

    bool hasImage = IsClipboardFormatAvailable(CF_DIB) != 0;
    CloseClipboard();

    LOG_FLUTTER_FMT("Clipboard has image: %s", hasImage ? "true" : "false");
    result->Success(flutter::EncodableValue(hasImage));

  } else if (call.method_name() == "clearClipboard") {
    // 清空剪贴板
    if (!OpenClipboard(nullptr)) {
      LOG_FLUTTER("Failed to open clipboard for clear");
      result->Success(flutter::EncodableValue(false));
      return;
    }

    BOOL success = EmptyClipboard();
    CloseClipboard();

    LOG_FLUTTER_FMT("Clipboard cleared: %s", success ? "success" : "failed");
    result->Success(flutter::EncodableValue(success));

  } else {
    LOG_FLUTTER_FMT("Unknown clipboard method: %s", call.method_name().c_str());
    result->NotImplemented();
  }
}
