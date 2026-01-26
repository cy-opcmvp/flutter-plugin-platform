// This namespace is required for Windows GDI+ and screen capture
// NOMINMAX must be defined before any Windows headers
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include "screenshot_plugin.h"
#include <shellapi.h>
#include <comdef.h>
#include <algorithm>
#include <vector>
#include <string>

#undef NOMINMAX

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "shell32.lib")

using namespace Gdiplus;

// Global GDI+ token
ULONG_PTR gdiplusToken;

// Initialize GDI+
void InitializeGDIPlus() {
    GdiplusStartupInput gdiplusStartupInput;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
}

// Shutdown GDI+
void ShutdownGDIPlus() {
    GdiplusShutdown(gdiplusToken);
}

// Callback function for enumerating windows
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    auto* windows = reinterpret_cast<std::vector<WindowInfo>*>(lParam);

    // Skip invisible windows
    if (!IsWindowVisible(hwnd)) {
        return TRUE;
    }

    // Skip minimized windows
    if (IsIconic(hwnd)) {
        return TRUE;
    }

    // Get window title
    WCHAR title[256];
    GetWindowTextW(hwnd, title, 256);

    // Skip windows without titles
    if (wcslen(title) == 0) {
        return TRUE;
    }

    // 清理窗口标题：移除所有特殊字符
    // 先移除末尾的空白字符和控制字符
    size_t titleLen = wcslen(title);
    while (titleLen > 0) {
      wchar_t lastChar = title[titleLen - 1];
      if (iswspace(lastChar) || iswcntrl(lastChar)) {
        title[titleLen - 1] = L'\0';
        titleLen--;
      } else {
        break;
      }
    }

    // 移除标题中的所有特殊字符（□、■、▪、▫、─、│等）
    int writePos = 0;
    for (int readPos = 0; title[readPos] != L'\0'; readPos++) {
      wchar_t ch = title[readPos];
      // 保留正常字符，移除特殊字符
      if (ch != L'□' && ch != L'■' && ch != L'▪' && ch != L'▫' &&
          ch != L'─' && ch != L'│' && !iswcntrl(ch)) {
        title[writePos++] = ch;
      }
    }
    title[writePos] = L'\0';

    // 再次检查标题是否为空（清理后可能变空）
    if (wcslen(title) == 0) {
      return TRUE;
    }


    // Skip special window classes (like tooltips, menus, etc.)
    WCHAR className[256];
    GetClassNameW(hwnd, className, 256);

    // Filter out system windows
    if (wcscmp(className, L"Shell_TrayWnd") == 0 ||  // Taskbar
        wcscmp(className, L"Progman") == 0 ||        // Desktop
        wcscmp(className, L"WorkerW") == 0 ||         // Desktop background
        wcscmp(className, L"DV2ControlHost") == 0 ||  // Some overlay windows
        wcscmp(className, L"MsgrSinkWindowClass") == 0) {  // Messenger windows
        return TRUE;
    }

    // Check if window has a reasonable size (too small windows are usually UI elements)
    RECT rect;
    GetWindowRect(hwnd, &rect);
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;

    if (width < 100 || height < 50) {
        return TRUE;
    }

    // Get window ID as string
    char windowId[64];
    sprintf_s(windowId, "%p", hwnd);

    // Convert title to UTF-8
    int titleUtf8Len = WideCharToMultiByte(CP_UTF8, 0, title, -1, NULL, 0, NULL, NULL);
    std::string titleUtf8(titleUtf8Len, 0);
    WideCharToMultiByte(CP_UTF8, 0, title, -1, &titleUtf8[0], titleUtf8Len, NULL, NULL);

    // Get application name from class name or process
    std::string appName;
    DWORD processId = 0;
    GetWindowThreadProcessId(hwnd, &processId);
    if (processId != 0) {
        HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
        if (hProcess != NULL) {
            WCHAR processName[MAX_PATH];
            DWORD size = MAX_PATH;
            if (QueryFullProcessImageNameW(hProcess, 0, processName, &size)) {
                // Extract just the filename without extension
                std::wstring processPath = processName;
                size_t lastSlash = processPath.find_last_of(L"\\/");
                if (lastSlash != std::wstring::npos) {
                    std::wstring fileName = processPath.substr(lastSlash + 1);
                    size_t dotPos = fileName.find_last_of(L'.');
                    if (dotPos != std::wstring::npos) {
                        fileName = fileName.substr(0, dotPos);
                    }
                    // Convert to UTF-8
                    int nameLen = WideCharToMultiByte(CP_UTF8, 0, fileName.c_str(), -1, NULL, 0, NULL, NULL);
                    appName.resize(nameLen, 0);
                    WideCharToMultiByte(CP_UTF8, 0, fileName.c_str(), -1, &appName[0], nameLen, NULL, NULL);
                }
            }
            CloseHandle(hProcess);
        }
    }

    // Get window icon
    std::vector<uint8_t> iconData;
    HICON hIcon = (HICON)SendMessage(hwnd, WM_GETICON, ICON_SMALL, 0);
    if (hIcon == NULL) {
        hIcon = (HICON)GetClassLongPtr(hwnd, GCLP_HICONSM);
    }
    if (hIcon == NULL) {
        hIcon = (HICON)SendMessage(hwnd, WM_GETICON, ICON_BIG, 0);
    }
    if (hIcon == NULL) {
        hIcon = (HICON)GetClassLongPtr(hwnd, GCLP_HICON);
    }

    if (hIcon != NULL) {
        // Extract icon to PNG
        ICONINFO iconInfo;
        if (GetIconInfo(hIcon, &iconInfo)) {
            BITMAP bm;
            GetObject(iconInfo.hbmColor, sizeof(BITMAP), &bm);

            // Create GDI+ bitmap from icon
            Bitmap* gdiBitmap = Bitmap::FromHICON(hIcon);
            if (gdiBitmap != nullptr) {
                // Create IStream
                IStream* stream = NULL;
                CreateStreamOnHGlobal(NULL, TRUE, &stream);

                // Save to PNG format
                CLSID pngClsid;
                if (GetEncoderClsid(L"image/png", &pngClsid) >= 0) {
                    Gdiplus::Status status = gdiBitmap->Save(stream, &pngClsid);
                    if (status == Gdiplus::Ok) {
                        // Get stream size
                        STATSTG statstg;
                        stream->Stat(&statstg, STATFLAG_NONAME);

                        // Read stream data
                        LARGE_INTEGER pos;
                        pos.QuadPart = 0;
                        stream->Seek(pos, STREAM_SEEK_SET, NULL);

                        iconData.resize(statstg.cbSize.LowPart);
                        ULONG bytesRead;
                        stream->Read(iconData.data(), statstg.cbSize.LowPart, &bytesRead);
                    }
                }

                stream->Release();
                delete gdiBitmap;
            }

            if (iconInfo.hbmColor != NULL) DeleteObject(iconInfo.hbmColor);
            if (iconInfo.hbmMask != NULL) DeleteObject(iconInfo.hbmMask);
        }
    }

    // Store window info
    WindowInfo info;
    info.title = titleUtf8;
    info.id = std::string(windowId);
    info.appName = appName;
    info.icon = iconData;
    windows->push_back(info);

    return TRUE;
}

// Capture full screen
std::vector<uint8_t> CaptureFullScreen() {
    // Get screen dimensions
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    // Create device context
    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);

    // Create bitmap
    HBITMAP hBitmap = CreateCompatibleBitmap(hdcScreen, screenWidth, screenHeight);
    HBITMAP hOldBitmap = (HBITMAP)SelectObject(hdcMem, hBitmap);

    // Copy screen to bitmap
    BitBlt(hdcMem, 0, 0, screenWidth, screenHeight, hdcScreen, 0, 0, SRCCOPY);

    // Select old bitmap back
    SelectObject(hdcMem, hOldBitmap);

    // Convert to GDI+ bitmap - use Bitmap constructor with width, height, and pixel data
    BITMAP bitmapInfo;
    GetObject(hBitmap, sizeof(BITMAP), &bitmapInfo);

    Bitmap* gdiBitmap = new Bitmap(bitmapInfo.bmWidth, bitmapInfo.bmHeight, PixelFormat32bppARGB);

    // Get bitmap data
    BitmapData bitmapData;
    Rect rect(0, 0, bitmapInfo.bmWidth, bitmapInfo.bmHeight);
    Gdiplus::Status status = gdiBitmap->LockBits(&rect, ImageLockModeWrite, PixelFormat32bppARGB, &bitmapData);

    if (status == Gdiplus::Ok) {
        // Get the bitmap bits from the HBITMAP
        BYTE* pBits = (BYTE*)bitmapInfo.bmBits;
        if (pBits == NULL) {
            // If bmBits is NULL, we need to use GetDIBits
            BITMAPINFO bmi = {};
            bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
            bmi.bmiHeader.biWidth = bitmapInfo.bmWidth;
            bmi.bmiHeader.biHeight = -bitmapInfo.bmHeight;  // Negative for top-down DIB
            bmi.bmiHeader.biPlanes = 1;
            bmi.bmiHeader.biBitCount = 32;
            bmi.bmiHeader.biCompression = BI_RGB;

            GetDIBits(hdcScreen, hBitmap, 0, bitmapInfo.bmHeight,
                     (BYTE*)bitmapData.Scan0, &bmi, DIB_RGB_COLORS);
        } else {
            // Copy the bitmap data
            memcpy(bitmapData.Scan0, pBits, bitmapData.Stride * bitmapInfo.bmHeight);
        }

        gdiBitmap->UnlockBits(&bitmapData);
    }

    // Create IStream
    IStream* stream = NULL;
    CreateStreamOnHGlobal(NULL, TRUE, &stream);

    // Save to PNG format
    CLSID pngClsid;
    GetEncoderClsid(L"image/png", &pngClsid);
    status = gdiBitmap->Save(stream, &pngClsid);

    std::vector<uint8_t> result;

    if (status == Gdiplus::Ok) {
        // Get stream size
        STATSTG statstg;
        stream->Stat(&statstg, STATFLAG_NONAME);

        // Read stream data
        LARGE_INTEGER pos;
        pos.QuadPart = 0;
        stream->Seek(pos, STREAM_SEEK_SET, NULL);

        result.resize(statstg.cbSize.LowPart);
        ULONG bytesRead;
        stream->Read(result.data(), statstg.cbSize.LowPart, &bytesRead);
    }

    // Cleanup
    stream->Release();
    delete gdiBitmap;
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcScreen);

    return result;
}

// Helper function to get encoder CLSID
int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
    UINT  num = 0;          // number of image encoders
    UINT  size = 0;         // size of the image encoder array in bytes

    ImageCodecInfo* pImageCodecInfo = NULL;

    GetImageEncodersSize(&num, &size);
    if(size == 0)
        return -1;  // Failure

    pImageCodecInfo = (ImageCodecInfo*)(malloc(size));
    if(pImageCodecInfo == NULL)
        return -1;  // Failure

    GetImageEncoders(num, size, pImageCodecInfo);

    for(UINT j = 0; j < num; ++j) {
        if( wcscmp(pImageCodecInfo[j].MimeType, format) == 0 ) {
            *pClsid = pImageCodecInfo[j].Clsid;
            free(pImageCodecInfo);
            return j;  // Success
        }
    }

    free(pImageCodecInfo);
    return -1;  // Failure
}

// Capture specific window
std::vector<uint8_t> CaptureWindow(HWND hwnd) {
    // Check if window is valid
    if (!IsWindow(hwnd)) {
        return std::vector<uint8_t>();
    }

    // Get window dimensions
    RECT rect;
    GetWindowRect(hwnd, &rect);
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;

    // Validate dimensions
    if (width <= 0 || height <= 0) {
        return std::vector<uint8_t>();
    }

    // Create device contexts
    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);

    // Create bitmap
    HBITMAP hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
    HBITMAP hOldBitmap = (HBITMAP)SelectObject(hdcMem, hBitmap);

    // Fill background with white (not black)
    RECT bgRect = {0, 0, width, height};
    FillRect(hdcMem, &bgRect, (HBRUSH)GetStockObject(WHITE_BRUSH));

    // Method 1: Try PrintWindow with different flags
    BOOL success = FALSE;

    // Try PW_RENDERFULLCONTENT (for Windows 8.1+, captures hardware-accelerated content)
    #ifdef PW_RENDERFULLCONTENT
    success = PrintWindow(hwnd, hdcMem, PW_RENDERFULLCONTENT);
    #endif

    // Try standard PrintWindow if PW_RENDERFULLCONTENT failed or not available
    if (!success) {
        success = PrintWindow(hwnd, hdcMem, 0);
    }

    // Method 2: If PrintWindow failed, use window DC
    if (!success) {
        HDC hdcWindow = GetWindowDC(hwnd);
        if (hdcWindow != NULL) {
            // Get client area dimensions
            RECT clientRect;
            GetClientRect(hwnd, &clientRect);

            // Center the client area in the bitmap
            int clientWidth = clientRect.right - clientRect.left;
            int clientHeight = clientRect.bottom - clientRect.top;
            int offsetX = (width - clientWidth) / 2;
            int offsetY = (height - clientHeight) / 2;

            // Clear the bitmap area first
            RECT clearRect = {0, 0, width, height};
            FillRect(hdcMem, &clearRect, (HBRUSH)GetStockObject(WHITE_BRUSH));

            // Copy from window DC (client area only)
            BitBlt(hdcMem, offsetX, offsetY, clientWidth, clientHeight,
                   hdcWindow, 0, 0, SRCCOPY);

            ReleaseDC(hwnd, hdcWindow);
            success = TRUE;
        }
    }

    // Method 3: Last resort - capture from screen DC (desktop)
    if (!success) {
        // Ensure window is visible and not minimized
        if (IsIconic(hwnd)) {
            ShowWindow(hwnd, SW_RESTORE);
        }

        // Bring window to top without stealing focus
        SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

        // Update window
        UpdateWindow(hwnd);

        // Small delay to let window paint
        Sleep(100);

        // Clear bitmap first
        RECT clearRect = {0, 0, width, height};
        FillRect(hdcMem, &clearRect, (HBRUSH)GetStockObject(WHITE_BRUSH));

        // Capture from screen (desktop)
        BitBlt(hdcMem, 0, 0, width, height, hdcScreen, rect.left, rect.top, SRCCOPY);
        success = TRUE;
    }

    // Select old bitmap back
    SelectObject(hdcMem, hOldBitmap);

    // Convert to GDI+ bitmap
    BITMAP bitmapInfo;
    GetObject(hBitmap, sizeof(BITMAP), &bitmapInfo);

    Bitmap* gdiBitmap = new Bitmap(bitmapInfo.bmWidth, bitmapInfo.bmHeight, PixelFormat32bppARGB);

    // Get bitmap data
    BitmapData bitmapData;
    Rect gdiRect(0, 0, bitmapInfo.bmWidth, bitmapInfo.bmHeight);
    Gdiplus::Status status = gdiBitmap->LockBits(&gdiRect, ImageLockModeWrite, PixelFormat32bppARGB, &bitmapData);

    if (status == Gdiplus::Ok) {
        BITMAPINFO bmi = {};
        bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
        bmi.bmiHeader.biWidth = bitmapInfo.bmWidth;
        bmi.bmiHeader.biHeight = -bitmapInfo.bmHeight;
        bmi.bmiHeader.biPlanes = 1;
        bmi.bmiHeader.biBitCount = 32;
        bmi.bmiHeader.biCompression = BI_RGB;

        GetDIBits(hdcScreen, hBitmap, 0, bitmapInfo.bmHeight,
                 (BYTE*)bitmapData.Scan0, &bmi, DIB_RGB_COLORS);

        gdiBitmap->UnlockBits(&bitmapData);
    }

    // Create IStream
    IStream* stream = NULL;
    CreateStreamOnHGlobal(NULL, TRUE, &stream);

    // Save to PNG format
    CLSID pngClsid;
    GetEncoderClsid(L"image/png", &pngClsid);
    status = gdiBitmap->Save(stream, &pngClsid);

    std::vector<uint8_t> result;

    if (status == Gdiplus::Ok) {
        // Get stream size
        STATSTG statstg;
        stream->Stat(&statstg, STATFLAG_NONAME);

        // Read stream data
        LARGE_INTEGER pos;
        pos.QuadPart = 0;
        stream->Seek(pos, STREAM_SEEK_SET, NULL);

        result.resize(statstg.cbSize.LowPart);
        ULONG bytesRead;
        stream->Read(result.data(), statstg.cbSize.LowPart, &bytesRead);
    }

    // Cleanup
    stream->Release();
    delete gdiBitmap;
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcScreen);

    return result;
}

// Capture screen region
std::vector<uint8_t> CaptureRegion(int x, int y, int width, int height) {
    // Create device context
    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);

    // Create bitmap
    HBITMAP hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
    HBITMAP hOldBitmap = (HBITMAP)SelectObject(hdcMem, hBitmap);

    // Copy region to bitmap
    BitBlt(hdcMem, 0, 0, width, height, hdcScreen, x, y, SRCCOPY);

    // Select old bitmap back
    SelectObject(hdcMem, hOldBitmap);

    // Convert to GDI+ bitmap
    BITMAP bitmapInfo;
    GetObject(hBitmap, sizeof(BITMAP), &bitmapInfo);

    Bitmap* gdiBitmap = new Bitmap(bitmapInfo.bmWidth, bitmapInfo.bmHeight, PixelFormat32bppARGB);

    // Get bitmap data
    BitmapData bitmapData;
    Rect rect(0, 0, bitmapInfo.bmWidth, bitmapInfo.bmHeight);
    Gdiplus::Status status = gdiBitmap->LockBits(&rect, ImageLockModeWrite, PixelFormat32bppARGB, &bitmapData);

    if (status == Gdiplus::Ok) {
        BITMAPINFO bmi = {};
        bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
        bmi.bmiHeader.biWidth = bitmapInfo.bmWidth;
        bmi.bmiHeader.biHeight = -bitmapInfo.bmHeight;
        bmi.bmiHeader.biPlanes = 1;
        bmi.bmiHeader.biBitCount = 32;
        bmi.bmiHeader.biCompression = BI_RGB;

        GetDIBits(hdcScreen, hBitmap, 0, bitmapInfo.bmHeight,
                 (BYTE*)bitmapData.Scan0, &bmi, DIB_RGB_COLORS);

        gdiBitmap->UnlockBits(&bitmapData);
    }

    // Create IStream
    IStream* stream = NULL;
    CreateStreamOnHGlobal(NULL, TRUE, &stream);

    // Save to PNG format
    CLSID pngClsid;
    GetEncoderClsid(L"image/png", &pngClsid);
    status = gdiBitmap->Save(stream, &pngClsid);

    std::vector<uint8_t> result;

    if (status == Gdiplus::Ok) {
        // Get stream size
        STATSTG statstg;
        stream->Stat(&statstg, STATFLAG_NONAME);

        // Read stream data
        LARGE_INTEGER pos;
        pos.QuadPart = 0;
        stream->Seek(pos, STREAM_SEEK_SET, NULL);

        result.resize(statstg.cbSize.LowPart);
        ULONG bytesRead;
        stream->Read(result.data(), statstg.cbSize.LowPart, &bytesRead);
    }

    // Cleanup
    stream->Release();
    delete gdiBitmap;
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcScreen);

    return result;
}

// Enumerate all windows
std::vector<WindowInfo> EnumerateWindows() {
    std::vector<WindowInfo> windows;
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&windows));
    return windows;
}

// Convert HWND from string
HWND HwndFromString(const std::string& str) {
    HWND hwnd;
    sscanf_s(str.c_str(), "%p", &hwnd);
    return hwnd;
}
