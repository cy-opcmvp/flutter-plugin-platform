/// 截图页面 surface：捕获按钮（全屏/区域）+ 热键绑定 + 保存提示 +
/// 结构化失败 + 结果区。
///
/// 热键生命周期（S1 批C）：initState/postFrame 按当前 combo 注册，
/// 模型变更（设置页改 combo）时重绑，dispose 反绑；[hotkeyBinder]/
/// [hotkeyUnbinder] 未注入（或注册失败）时页面按钮仍可用。
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'capture_controller.dart';
import 'region_selection.dart';
import 'screenshot_manifest.dart';
import 'screenshot_strings.dart';

/// 截图页面提供方（builtin 实现，宿主组装根注册）。
final class ScreenshotPageProvider implements PluginPageProvider {
  /// 创建页面提供方；[bytesLoader] 由宿主注入以真实解码截图文件；
  /// [regionSelector] 为宿主 overlay 选择缝（区域截图必需，缺省时
  /// 区域按钮退化为全屏捕获前的失败提示）；[hotkeyBinder]/
  /// [hotkeyUnbinder] 为宿主全局热键缝（缺省时页面不绑定热键）。
  const ScreenshotPageProvider({
    required this.controller,
    required this.stringsResolver,
    required this.bytesLoader,
    required this.regionSelector,
    this.hotkeyBinder,
    this.hotkeyUnbinder,
  });

  /// 捕获控制器。
  final CaptureController controller;

  /// 文案解析器。
  final ScreenshotStringsResolver stringsResolver;

  /// 图片字节加载器（按路径读取截图文件；包内不触碰文件系统）。
  final Future<Uint8List?> Function(String path) bytesLoader;

  /// 区域选择缝（宿主 overlay；区域截图流程入口）。
  final RegionSelector regionSelector;

  /// 全局热键绑定缝（注册失败返回 false）。
  final HotkeyBinder? hotkeyBinder;

  /// 全局热键解绑缝。
  final HotkeyUnbinder? hotkeyUnbinder;

  @override
  PluginId get pluginId => PluginId.parse(kScreenshotPluginId);

  @override
  Widget buildPage(BuildContext context) {
    return _ScreenshotPageView(
      controller: controller,
      stringsResolver: stringsResolver,
      bytesLoader: bytesLoader,
      regionSelector: regionSelector,
      hotkeyBinder: hotkeyBinder,
      hotkeyUnbinder: hotkeyUnbinder,
    );
  }
}

/// 截图页面视图：ListenableBuilder 订阅控制器状态；Stateful 承载热键
/// 绑定生命周期。
final class _ScreenshotPageView extends StatefulWidget {
  const _ScreenshotPageView({
    required this.controller,
    required this.stringsResolver,
    required this.bytesLoader,
    required this.regionSelector,
    this.hotkeyBinder,
    this.hotkeyUnbinder,
  });

  final CaptureController controller;

  final ScreenshotStringsResolver stringsResolver;

  final Future<Uint8List?> Function(String path) bytesLoader;

  final RegionSelector regionSelector;

  final HotkeyBinder? hotkeyBinder;

  final HotkeyUnbinder? hotkeyUnbinder;

  @override
  State<_ScreenshotPageView> createState() => _ScreenshotPageViewState();
}

class _ScreenshotPageViewState extends State<_ScreenshotPageView> {
  /// 当前已绑定的 combo（null 表示未绑定或绑定失败）。
  String? _boundCombo;

  @override
  void initState() {
    super.initState();
    widget.controller.model.addListener(_onModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_rebindHotkey());
      }
    });
  }

  @override
  void dispose() {
    widget.controller.model.removeListener(_onModelChanged);
    unawaited(_unbindHotkey());
    super.dispose();
  }

  /// 模型变更（设置页改 combo 或恢复持久化值）时重绑热键。
  void _onModelChanged() {
    if (mounted) {
      unawaited(_rebindHotkey());
    }
  }

  /// 按 combo 注册全局热键：先解绑旧的再绑新的；注册失败时置空绑定
  /// 并给出提示（不阻断页面）。
  Future<void> _rebindHotkey() async {
    final HotkeyBinder? binder = widget.hotkeyBinder;
    final String combo = widget.controller.model.settings.hotkeyCombo;
    if (binder == null) {
      _boundCombo = null;
      return;
    }
    if (_boundCombo != null && _boundCombo == combo) {
      return;
    }
    await _unbindHotkey();
    final bool ok = await binder(combo, _onHotkeyFired);
    if (!mounted) {
      return;
    }
    setState(() {
      _boundCombo = ok ? combo : null;
    });
  }

  /// 热键触发：进入区域截图闭环（捕获中防重入）。
  void _onHotkeyFired() {
    if (mounted && !widget.controller.capturing) {
      unawaited(
        widget.controller.captureWithRegionSelector(widget.regionSelector),
      );
    }
  }

  /// 反绑当前 combo（幂等）。
  Future<void> _unbindHotkey() async {
    final HotkeyUnbinder? unbinder = widget.hotkeyUnbinder;
    final String? bound = _boundCombo;
    _boundCombo = null;
    if (unbinder == null || bound == null) {
      return;
    }
    await unbinder(bound);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = ThemeTokens.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final CaptureController controller = widget.controller;
        final ScreenshotStrings strings = widget.stringsResolver(context);
        final PluginFailure? failure = controller.lastFailure;
        final ImageResultDescriptor? result = controller.lastResult;
        final ScreenshotSaveDetails? details = controller.lastDetails;
        final String? savedPath = controller.lastSavedPath;
        return SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacing.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: tokens.spacing.space3,
                runSpacing: tokens.spacing.space2,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: controller.capturing
                        ? null
                        : () => controller.capture(),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      controller.capturing
                          ? strings.capturing
                          : strings.captureButton,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.capturing
                        ? null
                        : () => controller.captureWithRegionSelector(
                            widget.regionSelector),
                    icon: const Icon(Icons.crop_free_outlined),
                    label: Text(strings.regionButton),
                  ),
                ],
              ),
              if (controller.lastRegionCopied)
                _hintLine(
                  context,
                  tokens,
                  strings.regionCopiedHint,
                  color: tokens.color.primary,
                ),
              if (savedPath != null)
                _hintLine(
                  context,
                  tokens,
                  strings.savedHint(savedPath),
                  color: tokens.color.primary,
                ),
              if (failure != null)
                _hintLine(
                  context,
                  tokens,
                  '${strings.failureTitle}：${failure.message}',
                  color: tokens.color.error,
                ),
              if (_boundCombo == null && widget.hotkeyBinder != null)
                _hintLine(
                  context,
                  tokens,
                  '${strings.hotkeyFailedHint}${widget.controller.model.settings.hotkeyCombo}',
                  color: tokens.color.error,
                ),
              if (result != null) ...<Widget>[
                SizedBox(height: tokens.spacing.space4),
                Text(
                  strings.resultTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: tokens.spacing.space2),
                ResultRenderer(
                  descriptor: result,
                  bytesLoader: widget.bytesLoader,
                ),
              ],
              if (details != null)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.space2),
                  child: ResultRenderer(
                    descriptor: _buildDetailsDescriptor(details, strings),
                    bytesLoader: widget.bytesLoader,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 落盘明细 → fields 结果描述符（路径/尺寸/自动复制）。
  FieldsResultDescriptor _buildDetailsDescriptor(
    ScreenshotSaveDetails details,
    ScreenshotStrings strings,
  ) {
    return FieldsResultDescriptor(
      fields: <ResultField>[
        ResultField(label: strings.fieldPath, value: details.path),
        ResultField(
          label: strings.fieldSize,
          value: '${details.width}×${details.height}',
        ),
        ResultField(
          label: strings.fieldCopied,
          value: screenshotCopyStatusLabel(strings, details.copyKey),
        ),
      ],
    );
  }

  /// 状态提示行（保存成功 / 失败提示共用）。
  Widget _hintLine(
    BuildContext context,
    ThemeTokens tokens,
    String text, {
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.space3),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}
