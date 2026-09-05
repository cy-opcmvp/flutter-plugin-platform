/// 截图捕获控制器：编排 ScreenCapture 能力、编码分派与写文件缝，
/// 并按设置执行自动复制，持有捕获状态。
///
/// 控制器只依赖能力接口（[ScreenCapture]/[Clipboard]/[KnownFolders]）
/// 与注入的写文件函数，零 windows 包依赖、零 dart:io；宿主组装根
/// 负责注入真实现。剪贴板/已知目录能力未注入时自动复制视为不复制、
/// 已知目录解析回退插件数据目录。
library;

import 'dart:async';
import 'dart:ui' as ui show Rect;

import 'package:flutter/foundation.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'filename_template.dart';
import 'region_selection.dart';
import 'screenshot_codec.dart';
import 'screenshot_model.dart';

/// 写文件缝：宿主注入落盘实现（dart:io 只在宿主 app 层），按目录与
/// 文件名落盘并返回完整路径。
typedef ScreenshotFileSaver =
    Future<String> Function(Uint8List bytes, String dir, String filename);

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

/// 一次成功捕获的落盘明细（稳定键 + 原始值；展示文案由页面经载体映射）。
final class ScreenshotSaveDetails {
  /// 创建明细。
  const ScreenshotSaveDetails({
    required this.path,
    required this.width,
    required this.height,
    required this.copyKey,
  });

  /// 落盘完整路径。
  final String path;

  /// 图像宽度（像素）。
  final int width;

  /// 图像高度（像素）。
  final int height;

  /// 自动复制结果稳定键：none / image / path / failed。
  final String copyKey;
}

/// 截图捕获控制器。
final class CaptureController extends ChangeNotifier {
  /// 创建控制器；除 [screenCapture]/[saveFile]/[model] 外的能力注入均
  /// 可选：[clipboard] 缺省时自动复制不执行，[knownFolders] 缺省时
  /// 已知目录解析回退 [pluginDataDir]。
  CaptureController({
    required this.screenCapture,
    required this.saveFile,
    required this.model,
    this.clipboard,
    this.knownFolders,
    this.pluginDataDir,
  });

  /// 屏幕捕获能力接口（真实现或测试 fake）。
  final ScreenCapture screenCapture;

  /// 写文件缝。
  final ScreenshotFileSaver saveFile;

  /// 状态模型（读取保存设置）。
  final ScreenshotModel model;

  /// 剪贴板能力（自动复制用；缺省视为不复制）。
  final Clipboard? clipboard;

  /// 已知目录能力（{pictures}/{documents} 解析用；缺省回退插件数据目录）。
  final KnownFolders? knownFolders;

  /// 插件数据目录（{pluginData} 与回退目录）。
  final String? pluginDataDir;

  final FilenameSequencer _sequencer = FilenameSequencer();

  bool _capturing = false;

  PluginFailure? _lastFailure;

  ImageResultDescriptor? _lastResult;

  ScreenshotSaveDetails? _lastDetails;

  String? _lastSavedPath;

  bool _lastRegionCopied = false;

  /// 是否有捕获正在进行（用于防重入与按钮禁用）。
  bool get capturing => _capturing;

  /// 最近一次结构化失败（成功后清空）。
  PluginFailure? get lastFailure => _lastFailure;

  /// 最近一次成功产出的 image 结果描述符（页面预览用）。
  ImageResultDescriptor? get lastResult => _lastResult;

  /// 最近一次落盘明细（路径/尺寸/自动复制结果）。
  ScreenshotSaveDetails? get lastDetails => _lastDetails;

  /// 最近一次落盘的完整路径。
  String? get lastSavedPath => _lastSavedPath;

  /// 最近一次区域选择是否为「仅复制」且复制成功（页面提示用；新流程
  /// 开始时清空，保存/放弃/失败路径均为 false）。
  bool get lastRegionCopied => _lastRegionCopied;

  /// 执行一次主屏全屏捕获并落盘。
  ///
  /// 失败路径结构化透传能力层 [PluginFailure]（`capture.failed`）；编码
  /// 失败折算为 `capture.encode_failed`；写文件缝抛异常时折算为
  /// `reason=saveError` 的同类失败。自动复制失败不吞掉落盘结果，仅在
  /// 明细中标记 `failed`。
  Future<void> capture() async {
    if (_capturing) {
      return;
    }
    _capturing = true;
    _lastFailure = null;
    _lastResult = null;
    _lastDetails = null;
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

  /// 区域截图闭环（S1 批C）：全屏底图捕获 → 注入的 overlay 选择器框选
  /// → 依据动作二次捕获选区 → 落盘 + 自动复制（save）或仅复制（copy）。
  ///
  /// - 选择器返回 null（ESC/关闭 overlay）→ 放弃，状态保持干净；
  /// - 动作 [ScreenRegionAction.discard] → 同放弃（不二次捕获）；
  /// - 动作 [ScreenRegionAction.copy] → 二次捕获后写剪贴板，置
  ///   [lastRegionCopied]；不落盘，结果/明细保持 null；
  /// - 动作 [ScreenRegionAction.save] → 二次捕获选区后走批次 B 的
  ///   编码/模板/落盘/自动复制链路。
  ///
  /// 二次捕获输入选区的**逻辑**坐标：捕获实现内部按 DPR 换算物理像素
  /// （`captureRegion` 语义，F4-04），overlay 物理矩形仅作展示与断言。
  /// 底图捕获或二次捕获失败均结构化透传能力层 [PluginFailure]。
  Future<void> captureWithRegionSelector(RegionSelector selector) async {
    if (_capturing) {
      return;
    }
    _capturing = true;
    _lastFailure = null;
    _lastResult = null;
    _lastDetails = null;
    _lastSavedPath = null;
    _lastRegionCopied = false;
    notifyListeners();
    try {
      final CaptureResult base = await screenCapture.captureRegion(
        kFullscreenRegion,
      );
      final PluginFailure? baseFailure = base.failure;
      if (baseFailure != null) {
        _lastFailure = baseFailure;
        return;
      }
      final Uint8List baseBytes = base.bytes!;
      final (int, int)? baseSize = screenshotPngDimensions(baseBytes);
      // 底图像素尺寸 Rect（dart:ui 坐标系，与 overlay 视口同源；规格参数
      // 命名沿用 imageLogicalSize；控制器无 DPR 语境，overlay 以自身视口
      // 与该尺寸换算缩放比）。
      final ui.Rect imageSize = ui.Rect.fromLTWH(
        0,
        0,
        baseSize?.$1.toDouble() ?? 0,
        baseSize?.$2.toDouble() ?? 0,
      );
      final ScreenRegion? region = await selector(baseBytes, imageSize);
      if (region == null || region.action == ScreenRegionAction.discard) {
        return;
      }
      // 区域二次捕获：overlay 逻辑坐标即 captureRegion 的输入坐标系，
      // 逐字段拷贝为能力矩形（两 Rect 类型不互通）。
      final ui.Rect logical = region.logicalRect;
      final CaptureResult outcome = await screenCapture.captureRegion(
        Rect(
          left: logical.left,
          top: logical.top,
          width: logical.width,
          height: logical.height,
        ),
      );
      final PluginFailure? failure = outcome.failure;
      if (failure != null) {
        _lastFailure = failure;
        return;
      }
      final Uint8List regionBytes = outcome.bytes!;
      if (region.action == ScreenRegionAction.copy) {
        final Clipboard? clipboard = this.clipboard;
        if (clipboard == null) {
          _lastFailure = PluginFailure(
            kScreenshotFailureCode,
            '剪贴板能力未注入，无法复制选区',
            <String, Object?>{'reason': 'clipboardUnavailable'},
          );
          return;
        }
        final bool copied = await clipboard
            .writeImage(regionBytes)
            .then((_) => true)
            .onError((_, _) => false);
        _lastRegionCopied = copied;
        if (!copied) {
          _lastFailure = PluginFailure(
            kScreenshotFailureCode,
            '选区复制失败',
            <String, Object?>{'reason': 'copyError'},
          );
        }
        return;
      }
      await _saveAndRecord(regionBytes);
    } finally {
      _capturing = false;
      notifyListeners();
    }
  }

  /// 编码 → 目录解析 → 模板展开落盘 → 自动复制 → 记录结果。
  Future<void> _saveAndRecord(Uint8List pngBytes) async {
    final ScreenshotSettings settings = model.settings;
    final DateTime now = DateTime.now();
    final Uint8List encoded;
    try {
      encoded = encodeScreenshotBytes(
        pngBytes,
        settings.format,
        settings.jpegQuality,
      );
    } on PluginFailure catch (error) {
      _lastFailure = error;
      return;
    }
    final String filename =
        '${expandFilenameTemplate(settings.filenameTemplate, now: now, seq: _sequencer.nextFor(now))}.${screenshotExtensionForFormat(settings.format)}';
    final String dir = _resolveSaveDir(settings.saveDir);
    final String path;
    try {
      path = await saveFile(encoded, dir, filename);
    } on Exception catch (error) {
      _lastFailure = PluginFailure(
        kScreenshotFailureCode,
        '截图保存失败：$error',
        <String, Object?>{'reason': 'saveError'},
      );
      return;
    }
    final String copyKey = await _autoCopy(settings.autoCopy, pngBytes, path);
    final (int, int)? size = screenshotPngDimensions(pngBytes);
    _lastSavedPath = path;
    _lastResult = ImageResultDescriptor(path: path);
    _lastDetails = ScreenshotSaveDetails(
      path: path,
      width: size?.$1 ?? 0,
      height: size?.$2 ?? 0,
      copyKey: copyKey,
    );
  }

  /// 解析保存目录稳定键为实际目录；已知目录解析失败或能力未注入时
  /// 回退插件数据目录（仍缺省为空串，交由写文件缝决定相对落点）。
  String _resolveSaveDir(String saveDirKey) {
    final String? pluginData = pluginDataDir;
    return switch (saveDirKey) {
      '{pictures}' => knownFolders?.pictures() ?? pluginData ?? '',
      '{documents}' => knownFolders?.documents() ?? pluginData ?? '',
      _ => pluginData ?? '',
    };
  }

  /// 执行自动复制并返回结果稳定键（none/image/path/failed）。
  ///
  /// 剪贴板能力未注入时视为不复制；复制失败不影响落盘结果。
  Future<String> _autoCopy(String autoCopy, Uint8List pngBytes, String path) {
    final Clipboard? clipboard = this.clipboard;
    if (clipboard == null || autoCopy == 'none') {
      return Future<String>.value('none');
    }
    final Future<void> write = autoCopy == 'path'
        ? clipboard.writeFiles(<String>[path])
        : clipboard.writeImage(pngBytes);
    return write.then((_) => autoCopy).onError((_, _) => 'failed');
  }
}
