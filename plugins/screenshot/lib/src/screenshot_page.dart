/// 截图页面 surface：捕获按钮 + 保存提示 + 结构化失败 + 结果区。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'capture_controller.dart';
import 'screenshot_manifest.dart';
import 'screenshot_strings.dart';

/// 截图页面提供方（builtin 实现，宿主组装根注册）。
final class ScreenshotPageProvider implements PluginPageProvider {
  /// 创建页面提供方；[bytesLoader] 由宿主注入以真实解码截图文件。
  const ScreenshotPageProvider({
    required this.controller,
    required this.stringsResolver,
    required this.bytesLoader,
  });

  /// 捕获控制器。
  final CaptureController controller;

  /// 文案解析器。
  final ScreenshotStringsResolver stringsResolver;

  /// 图片字节加载器（按路径读取截图文件；包内不触碰文件系统）。
  final Future<Uint8List?> Function(String path) bytesLoader;

  @override
  PluginId get pluginId => PluginId.parse(kScreenshotPluginId);

  @override
  Widget buildPage(BuildContext context) {
    return _ScreenshotPageView(
      controller: controller,
      stringsResolver: stringsResolver,
      bytesLoader: bytesLoader,
    );
  }
}

/// 截图页面视图：ListenableBuilder 订阅控制器状态。
final class _ScreenshotPageView extends StatelessWidget {
  const _ScreenshotPageView({
    required this.controller,
    required this.stringsResolver,
    required this.bytesLoader,
  });

  final CaptureController controller;

  final ScreenshotStringsResolver stringsResolver;

  final Future<Uint8List?> Function(String path) bytesLoader;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = ThemeTokens.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final ScreenshotStrings strings = stringsResolver(context);
        final PluginFailure? failure = controller.lastFailure;
        final ImageResultDescriptor? result = controller.lastResult;
        final String? savedPath = controller.lastSavedPath;
        return SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacing.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (result != null) ...<Widget>[
                SizedBox(height: tokens.spacing.space4),
                Text(
                  strings.resultTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: tokens.spacing.space2),
                ResultRenderer(descriptor: result, bytesLoader: bytesLoader),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 状态提示行（保存成功 / 捕获失败共用）。
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
