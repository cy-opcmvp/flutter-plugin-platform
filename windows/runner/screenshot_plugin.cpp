#include "screenshot_plugin.h"

// This namespace is required for Windows GDI+ and screen capture
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <gdiplus.h>
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
    auto* windows = reinterpret_cast<std::vector<std::tuple<std::string, std::string>>*>(lParam);

    // Get window title
    WCHAR title[256];
    GetWindowTextW(hwnd, title, 256);

    // Skip windows without titles
    if (wcslen(title) == 0) {
        return TRUE;
    }

    // Skip invisible windows
    if (!IsWindowVisible(hwnd)) {
        return TRUE;
    }

    // Get window ID as string
    WCHAR className[256];
    GetClassNameW(hwnd, className, 256);

    char windowId[64];
    sprintf_s(windowId, "%p", hwnd);

    // Convert title to UTF-8
    int titleLen = WideCharToMultiByte(CP_UTF8, 0, title, -1, NULL, 0, NULL, NULL);
    std::string titleUtf8(titleLen, 0);
    WideCharToMultiByte(CP_UTF8, 0, title, -1, &titleUtf8[0], titleLen, NULL, NULL);

    // Store window info
    windows->push_back(std::make_tuple(titleUtf8, std::string(windowId)));

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
    // Get window dimensions
    RECT rect;
    GetWindowRect(hwnd, &rect);
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;

    // Create device context
    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);
    HDC hdcWindow = GetWindowDC(hwnd);

    // Create bitmap
    HBITMAP hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
    HBITMAP hOldBitmap = (HBITMAP)SelectObject(hdcMem, hBitmap);

    // Copy window to bitmap
    BitBlt(hdcMem, 0, 0, width, height, hdcWindow, 0, 0, SRCCOPY);

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
    ReleaseDC(hwnd, hdcWindow);
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
std::vector<std::tuple<std::string, std::string>> EnumerateWindows() {
    std::vector<std::tuple<std::string, std::string>> windows;
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&windows));
    return windows;
}

// Convert HWND from string
HWND HwndFromString(const std::string& str) {
    HWND hwnd;
    sscanf_s(str.c_str(), "%p", &hwnd);
    return hwnd;
}
