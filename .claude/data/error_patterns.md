# 错误模式知识库

**最后更新**: 2026-01-26
**总错误模式**: 2

---

## 🎯 使用说明

本文档记录项目中遇到的所有错误模式，用于：
1. 识别重复出现的错误
2. 分析是否需要优化编码规范
3. 提供预防措施和解决方案
4. 持续改进代码质量

---

## 📋 错误分类

### Windows 平台错误 🔴
**严重程度**: 严重（阻止编译）
**规范来源**: 平台开发最佳实践

### 模式 #001: GDI+ 编译错误（C3861）
**发现于对话**: #001
**发现时间**: 2026-01-26
**错误级别**: 🔴 严重

**错误示例**:
```cpp
// 编译错误输出
C3861: 'min': identifier not found
C3861: 'max': identifier not found
```

**错误原因**:
1. **NOMINMAX 宏定义冲突**: Windows SDK 的 `<windows.h>` 头文件定义了 `NOMINMAX` 宏，这会阻止 `min()` 和 `max()` 宏的定义
2. **GDI+ 需要 min/max**: GDI+ 头文件 `<gdiplus.h>` 需要使用 `min()` 和 `max()` 宏，但不会自动定义它们
3. **顺序问题**: 必须在包含 `<gdiplus.h>` **之前**定义 min/max 宏

**解决方案**:
```cpp
// ✅ 正确：在包含 gdiplus.h 之前定义 min/max 宏
#ifndef min
#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

#include <gdiplus.h>
```

**需要修复的文件**:
- `windows/runner/flutter_window.cpp`
- `windows/runner/screenshot_plugin.h`
- 任何其他使用 GDI+ 的文件

**调试步骤**:
1. 检查编译错误中是否有 C3861 错误
2. 确认错误发生在 `<gdiplus.h>` 相关的代码中
3. 在包含 `<gdiplus.h>` 之前添加 min/max 宏定义
4. 清理 CMake 缓存：`rm -rf build/windows/CMake`
5. 重新编译

**是否规范问题**: 否
**规范漏洞**: 无
**规范优化**: 无

**预防措施**:
- 在项目 Windows 平台开发规范中添加 GDI+ 使用指南
- 创建项目模板时包含 min/max 宏定义
- 在文档中记录常见的 Windows SDK 宏定义冲突

**相关规范**: 无（平台特定问题）

**状态**: ✅ 已解决

---

### Flutter 平台通道错误 🔴
**严重程度**: 严重（功能失效）
**规范来源**: Flutter 平台通道开发最佳实践

### 模式 #002: Uint8List 类型映射错误
**发现于对话**: #001
**发现时间**: 2026-01-26
**错误级别**: 🔴 严重

**错误示例**:
```dart
// Dart 端 - 直接传递 Uint8List
final result = await _clipboardMethodChannel.invokeMethod<bool>(
  'setImageToClipboard',
  fileBytes,  // Uint8List
);
```

```cpp
// C++ 端 - 错误的类型检查
const auto* byte_list = std::get_if<flutter::EncodableList>(call.arguments());
// ❌ byte_list 为 nullptr，因为 Uint8List 不是 EncodableList
```

**错误原因**:
1. **类型映射不匹配**: Dart 的 `Uint8List` 在 C++ 端被编码为 `std::vector<uint8_t>`，而不是 `EncodableList`
2. **EncodableList 的实际类型**: `EncodableList` 是 `std::vector<EncodableValue>`，用于异构数据列表
3. **Uint8List 是标准库类型**: `std::vector<uint8_t>` 是 C++ 标准库类型，Flutter 直接映射 Dart 的字节列表

**解决方案**:
```cpp
// ✅ 正确：检查 std::vector<uint8_t> 类型
const flutter::EncodableValue& args = *call.arguments();

// 方法1：尝试作为 EncodableList（用于普通列表）
const auto* list = std::get_if<flutter::EncodableList>(&args);
if (list) {
  // 处理 EncodableList
}

// 方法2：尝试作为 std::vector<uint8_t>（用于 Uint8List）
const auto* u8_list = std::get_if<std::vector<uint8_t>>(&args);
if (u8_list) {
  // 直接使用
  imageBytes = *u8_list;
}
```

**完整实现示例**:
```cpp
// flutter_window.cpp
} else if (call.method_name() == "setImageToClipboard") {
  if (!call.arguments()) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  const flutter::EncodableValue& args = *call.arguments();
  std::vector<uint8_t> imageBytes;

  // 尝试作为 EncodableList
  const auto* byte_list = std::get_if<flutter::EncodableList>(&args);
  if (byte_list) {
    LOG_FLUTTER("Arguments is EncodableList");
    // 转换每个元素
    for (const auto& item : *byte_list) {
      if (auto byte_value = std::get_if<int>(&item)) {
        imageBytes.push_back(static_cast<uint8_t>(*byte_value));
      }
    }
  } else {
    // 尝试作为 std::vector<uint8_t>
    const auto* u8_list = std::get_if<std::vector<uint8_t>>(&args);
    if (u8_list) {
      LOG_FLUTTER("Arguments is std::vector<uint8_t>");
      imageBytes = *u8_list;  // 直接复制
    } else {
      LOG_FLUTTER("Unknown argument type");
      result->Success(flutter::EncodableValue(false));
      return;
    }
  }

  // 继续处理 imageBytes...
}
```

**调试技巧**:
```cpp
// 添加日志查看类型索引
LOG_FLUTTER_FMT("Argument type index: %zu", args.index());

// 常见索引值（依赖于 EncodableValue 的定义顺序）：
// 0 = std::monostate
// 1 = bool
// 2 = int
// 3 = int64
// 4 = double
// 5 = std::string
// 6 = EncodableList
// 7 = EncodableMap
// 8 = std::vector<uint8_t>  (可能的位置)
```

**Dart 端的正确调用方式**:
```dart
// ✅ 方法1：直接传递 Uint8List
await methodChannel.invokeMethod('setImageToClipboard', imageBytes);

// ✅ 方法2：包装在列表中（如果需要传递多个参数）
await methodChannel.invokeMethod('setMultipleData', [imageBytes, metadata]);
```

**是否规范问题**: 否
**规范漏洞**: Flutter 官方文档中关于平台通道类型映射的说明不够详细
**规范优化**: 可以在项目文档中添加平台通道类型映射参考表

**预防措施**:
1. **添加类型检查宏**:
   ```cpp
   #define LOG_ARGUMENT_TYPE(args) \
     LOG_FLUTTER_FMT("Argument type: index=%zu", args.index())
   ```

2. **使用类型辅助函数**:
   ```cpp
   bool isUint8List(const flutter::EncodableValue& value) {
     return std::holds_alternative<std::vector<uint8_t>>(value);
   }
   ```

3. **文档化常见映射**:
   - `Uint8List` → `std::vector<uint8_t>`
   - `IntList` → `std::vector<int>`
   - `List<String>` → `std::vector<EncodableValue>` 其中每个是 `std::string`
   - `Map<String, dynamic>` → `EncodableMap` (即 `std::map<std::string, EncodableValue>`)
   - `String` → `std::string`

**相关规范**: 无（Flutter 平台特定问题）

**状态**: ✅ 已解决

---

## 🔍 调试技巧知识库

### 技巧 #001: 添加详细的平台通道日志
**发现于对话**: #001
**用途**: 调试平台通道参数传递问题

**实现方法**:
```cpp
// 1. 记录方法调用
LOG_FLUTTER("Method called: " << call.method_name());

// 2. 记录参数类型
if (call.arguments()) {
  const auto& args = *call.arguments();
  LOG_FLUTTER_FMT("Argument type index: %zu", args.index());

  // 记录类型名称
  if (std::holds_alternative<std::string>(args)) {
    LOG_FLUTTER("Type: std::string");
  } else if (std::holds_alternative<std::vector<uint8_t>>(args)) {
    LOG_FLUTTER("Type: std::vector<uint8_t>");
  } else if (std::holds_alternative<flutter::EncodableList>(args)) {
    LOG_FLUTTER("Type: EncodableList");
  }
}

// 3. 记录关键步骤
LOG_FLUTTER("Step 1: Creating stream");
LOG_FLUTTER("Step 2: Loading bitmap");
LOG_FLUTTER_FMT("Step 3: Bitmap size: %d x %d", width, height);

// 4. 记录错误信息
LOG_FLUTTER_FMT("Failed: error=0x%X", GetLastError());
```

**日志输出位置**:
- Windows: 使用 `LogToFile()` 输出到文件（如 `C:\temp\screenshot_flutter.log`）
- 或使用 `OutputDebugString()` 输出到调试器
- 或同时使用两者

**查看日志**:
```bash
# 方法1：查看日志文件
cat C:/temp/screenshot_flutter.log

# 方法2：使用 DebugView（Sysinternals）实时查看
# 方法3：使用 Visual Studio 的输出窗口
```

---

## 📊 统计信息

- **总错误模式**: 2
- **严重错误**: 2
- **中等错误**: 0
- **轻微错误**: 0
- **已优化规范**: 0
- **待优化规范**: 0

---

## 🔗 相关资源

- [对话管理规则](../rules/CONVERSATION_MANAGEMENT_RULES.md)
- [文件组织规范](../rules/FILE_ORGANIZATION_RULES.md)
- [代码风格规范](../rules/CODE_STYLE_RULES.md)
- [错误处理规范](../rules/ERROR_HANDLING_RULES.md)
- [Flutter 平台通道](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [GDI+ 文档](https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-classic-gdi--reference)
