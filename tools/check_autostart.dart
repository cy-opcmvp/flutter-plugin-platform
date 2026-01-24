/// 开机自启诊断工具
/// 运行方式: dart tools/check_autostart.dart

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

void main() {
  print('========================================');
  print('开机自启功能诊断工具');
  print('========================================\n');

  if (!Platform.isWindows) {
    print('[错误] 此工具仅支持 Windows 平台');
    return;
  }

  // 1. 检查注册表
  print('[1] 检查注册表中的开机自启项...');
  final registryPath = r'Software\Microsoft\Windows\CurrentVersion\Run';
  final appName = 'PluginPlatform';

  final hKeyPtr = calloc<win32.HKEY>();
  final result = win32.RegOpenKeyEx(
    win32.HKEY_CURRENT_USER,
    TEXT(registryPath),
    0,
    win32.KEY_READ,
    hKeyPtr,
  );

  if (result == win32.ERROR_SUCCESS) {
    final hKey = hKeyPtr.value;

    // 读取值的大小
    final dataSizePtr = calloc<Uint32>();
    final dataTypePtr = calloc<Uint32>();

    final result2 = win32.RegGetValue(
      hKey,
      nullptr.cast<Utf16>(),
      TEXT(appName),
      win32.RRF_RT_REG_SZ,
      dataTypePtr.cast<Uint32>(),
      nullptr,
      dataSizePtr.cast<Uint32>(),
    );

    if (result2 == win32.ERROR_SUCCESS) {
      final dataSize = dataSizePtr.value;
      final pathPtr = calloc<Uint16>(dataSize ~/ 2);

      win32.RegGetValue(
        hKey,
        nullptr.cast<Utf16>(),
        TEXT(appName),
        win32.RRF_RT_REG_SZ,
        dataTypePtr.cast<Uint32>(),
        pathPtr.cast(),
        dataSizePtr.cast<Uint32>(),
      );

      final path = pathPtr.cast<Utf16>().toDartString(length: dataSize ~/ 2);
      print('[✓] 找到注册表项');
      print('    应用名称: $appName');
      print('    注册表路径: HKCU\\$registryPath');
      print('    可执行文件路径: $path');

      // 检查文件是否存在
      if (File(path).existsSync()) {
        print('    [✓] 可执行文件存在');
      } else {
        print('    [×] 可执行文件不存在');
      }

      calloc.free(pathPtr);
    } else {
      print('[×] 未找到注册表项');
      print('    提示: 需要在应用中启用开机自启功能');
    }

    win32.RegCloseKey(hKey);
    calloc.free(dataSizePtr);
    calloc.free(dataTypePtr);
    calloc.free(hKeyPtr);
  } else {
    print('[×] 无法打开注册表');
    print('    错误代码: $result');
    calloc.free(hKeyPtr);
  }

  print('');

  // 2. 当前可执行文件路径
  print('[2] 当前运行的可执行文件路径:');
  print('    ${Platform.resolvedExecutable}');
  print('');

  // 3. 常见问题说明
  print('[3] 开发模式下的常见问题:');
  print('    ✓ 注册表中保存的路径指向临时构建目录');
  print('    ✓ 每次 flutter clean 后路径会变化');
  print('    ✓ Debug 版本的 exe 路径不稳定');
  print('');

  print('========================================');
  print('建议：');
  print('========================================\n');

  print('开发阶段测试：');
  print('  1. 启用开机自启功能');
  print('  2. 运行此工具检查注册表状态');
  print('  3. 确认路径正确且文件存在');
  print('  4. 每次重新编译后需要重新设置\n');

  print('生产环境部署：');
  print('  1. 构建发布版本：flutter build windows --release');
  print('  2. 安装后重新启用开机自启');
  print('  3. 发布版本的路径是稳定的\n');
}

Pointer<Utf16> TEXT(String s) {
  return s.toNativeUtf16();
}

final nullptr = Pointer<Void>.fromAddress(0);
