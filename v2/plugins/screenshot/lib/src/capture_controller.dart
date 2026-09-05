/// 截图捕获控制器：编排 ScreenCapture 能力与写文件缝，持有捕获状态。
///
/// 控制器只依赖能力接口（[ScreenCapture]）与注入的写文件函数，
/// 零 windows 包依赖、零 dart:io；宿主组装根负责注入真实现。
library;

import 'package:flutter/foundation.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'screenshot_model.dart';

/// 写文件缝：宿主注入落盘实现（dart:io 只在宿主 app 层），返回完整路径。
typedef ScreenshotFileSaver =
    Future<String> Function(Uint8List bytes, String filename);

/// 主屏全屏捕获请求矩形（超大宽高由捕获实现裁剪到主屏边界）。
// Rect 构造函数含校验逻辑，无法声明为 const。
final Rect kFullscreenRegion = Rect(
  left: 0,
  top: 0,
  width: 100000,
  height: 100000,
);

/// 捕获进行中的结构化失败码（与能力层透传保持一致）。
const String kScreenshotFailureCode = 'capture.failed';

/// 截图捕获控制器。
final class CaptureController extends ChangeNotifier {
  /// 创建控制器；[screenCapture]/[saveFile]/[model] 均由宿主组装根注入。
  CaptureController({
    required this.screenCapture,
    required this.saveFile,
    required this.model,
  });

  /// 屏幕捕获能力接口（真实现或测试 fake）。
  final ScreenCapture screenCapture;

  /// 写文件缝。
  final ScreenshotFileSaver saveFile;

  /// 状态模型（读取设置中的文件名前缀）。
  final ScreenshotModel model;

  bool _capturing = false;

  PluginFailure? _lastFailure;

  ImageResultDescriptor? _lastResult;

  String? _lastSavedPath;

  /// 是否有捕获正在进行（用于防重入与按钮禁用）。
  bool get capturing => _capturing;

  /// 最近一次结构化失败（成功后清空）。
  PluginFailure? get lastFailure => _lastFailure;

  /// 最近一次成功产出的 image 结果描述符。
  ImageResultDescriptor? get lastResult => _lastResult;

  /// 最近一次落盘的完整路径。
  String? get lastSavedPath => _lastSavedPath;

  /// 执行一次主屏全屏捕获并落盘。
  ///
  /// 失败路径结构化透传能力层 [PluginFailure]（`capture.failed`）；
  /// 写文件缝抛异常时折算为 `reason=saveError` 的同类失败。
  Future<void> capture() async {
    if (_capturing) {
      return;
    }
    _capturing = true;
    _lastFailure = null;
    _lastResult = null;
    _lastSavedPath = null;
    notifyListeners();
    try {
      final CaptureResult outcome = await screenCapture.captureRegion(
        kFullscreenRegion,
      );
      final PluginFailure? failure = outcome.failure;
      if (failure != null) {
        _lastFailure = failure;
        return;
      }
      await _saveAndRecord(outcome.bytes!);
    } finally {
      _capturing = false;
      notifyListeners();
    }
  }

  /// 落盘并记录结果；写文件异常折算为结构化失败。
  Future<void> _saveAndRecord(Uint8List bytes) async {
    final String filename = _buildFilename();
    try {
      final String path = await saveFile(bytes, filename);
      _lastSavedPath = path;
      _lastResult = ImageResultDescriptor(path: path);
    } on Exception catch (error) {
      _lastFailure = PluginFailure(
        kScreenshotFailureCode,
        '截图保存失败：$error',
        <String, Object?>{'reason': 'saveError'},
      );
    }
  }

  /// 按设置前缀与当前时间生成文件名（`{prefix}-{yyyyMMdd-HHmmss}.png`）。
  String _buildFilename() {
    final DateTime now = DateTime.now();
    final String stamp = _formatTimestamp(now);
    return '${model.settings.filenamePrefix.trim()}-$stamp.png';
  }

  /// 手写时间戳格式化（避免 ISO 字符串中的冒号进入文件名）。
  String _formatTimestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}'
        '-${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
