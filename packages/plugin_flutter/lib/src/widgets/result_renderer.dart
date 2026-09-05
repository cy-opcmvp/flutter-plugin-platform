/// 声明式结果渲染器。
///
/// 按 [ResultDescriptor] 渲染四类结果（text / table / image / fields）。
/// 图片因包内不得依赖 dart:io，默认渲染为结构化占位框（accent 描边 +
/// 等宽路径 + 说明文案）；宿主可注入 [ResultRenderer.bytesLoader] 按路径
/// 提供字节，注入后经 FutureBuilder 真实解码渲染，加载失败或返回空时
/// 回退占位框并提示错误。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../generated/plugin_flutter_l10n.dart';
import '../surface/declarative_result.dart';
import '../theme/tokens.dart';
import 'token_text_style.dart';

/// 声明式结果渲染器。
class ResultRenderer extends StatelessWidget {
  /// 创建渲染器。
  ///
  /// [bytesLoader] 为可选的图片字节加载器（按路径读取，返回 null 表示
  /// 无法加载）；未注入时图片结果维持占位框文案不变。
  const ResultRenderer({super.key, required this.descriptor, this.bytesLoader});

  /// 结果描述符。
  final ResultDescriptor descriptor;

  /// 可选的图片字节加载器（由宿主注入，包内不触碰文件系统）。
  final Future<Uint8List?> Function(String path)? bytesLoader;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return switch (descriptor) {
      TextResultDescriptor result => _buildText(context, tokens, result),
      TableResultDescriptor result => _buildTable(context, tokens, result),
      ImageResultDescriptor result => _buildImage(context, tokens, result),
      FieldsResultDescriptor result => _buildFields(context, tokens, result),
    };
  }

  Widget _buildText(
    BuildContext context,
    ThemeTokens tokens,
    TextResultDescriptor result,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.space3),
      decoration: BoxDecoration(
        color: tokens.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
      ),
      child: Text(result.text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildTable(
    BuildContext context,
    ThemeTokens tokens,
    TableResultDescriptor result,
  ) {
    final l10n = PluginFlutterL10n.of(context);
    if (result.rows.isEmpty) {
      return Text(
        l10n.resultTableEmpty,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: tokens.color.onSurfaceVariant),
      );
    }
    final List<Widget> children = <Widget>[
      Row(
        children: <Widget>[
          for (final String column in result.columns)
            Expanded(
              child: Text(
                column,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: buildTokenTextStyle(
                  tokens.typography.label,
                  familyChain: tokens.typography.family,
                  color: tokens.color.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      Container(
        height: tokens.shape.strokeHairline,
        color: tokens.color.outlineVariant,
      ),
      for (final List<String> row in result.rows) ...<Widget>[
        Row(
          children: <Widget>[
            for (final String cell in row)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: tokens.spacing.space2,
                  ),
                  child: Text(
                    cell,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
        Container(
          height: tokens.shape.strokeHairline,
          color: tokens.color.outlineVariant,
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildImage(
    BuildContext context,
    ThemeTokens tokens,
    ImageResultDescriptor result,
  ) {
    final Future<Uint8List?> Function(String path)? loader = bytesLoader;
    if (loader == null) {
      final l10n = PluginFlutterL10n.of(context);
      return _imageFrame(
        tokens: tokens,
        path: result.path,
        message: l10n.resultImageUnavailable(result.path),
      );
    }
    return _ImageResultView(descriptor: result, loader: loader);
  }

  Widget _buildFields(
    BuildContext context,
    ThemeTokens tokens,
    FieldsResultDescriptor result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final ResultField field in result.fields)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    field.label,
                    style: buildTokenTextStyle(
                      tokens.typography.label,
                      familyChain: tokens.typography.family,
                      color: tokens.color.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    field.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 图片结果的 accent 描边占位框（未注入加载器、加载中与加载失败共用）。
///
/// [message] 为空且 [busy] 为真时以进度圈替代说明文案行。
Widget _imageFrame({
  required ThemeTokens tokens,
  required String path,
  String? message,
  bool busy = false,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(tokens.spacing.space4),
    decoration: BoxDecoration(
      border: Border.all(
        color: tokens.color.primary,
        width: tokens.shape.strokeAccent,
      ),
      borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.image_outlined, color: tokens.color.onSurfaceVariant),
        SizedBox(width: tokens.spacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: buildTokenTextStyle(
                  tokens.typography.effectiveMonoLabel,
                  familyChain: tokens.typography.familyMono,
                  color: tokens.color.onSurface,
                ),
              ),
              SizedBox(height: tokens.spacing.space1),
              if (busy)
                const CircularProgressIndicator()
              else
                Text(
                  message ?? '',
                  style: buildTokenTextStyle(
                    tokens.typography.label,
                    familyChain: tokens.typography.family,
                    color: tokens.color.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 注入 [bytesLoader] 后的图片结果视图：按路径异步加载并真实解码。
class _ImageResultView extends StatefulWidget {
  const _ImageResultView({required this.descriptor, required this.loader});

  final ImageResultDescriptor descriptor;

  final Future<Uint8List?> Function(String path) loader;

  @override
  State<_ImageResultView> createState() => _ImageResultViewState();
}

class _ImageResultViewState extends State<_ImageResultView> {
  late Future<Uint8List?> _future;
  late String _path;

  @override
  void initState() {
    super.initState();
    _path = widget.descriptor.path;
    _future = widget.loader(_path);
  }

  @override
  void didUpdateWidget(_ImageResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.descriptor.path != _path) {
      _path = widget.descriptor.path;
      _future = widget.loader(_path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _imageFrame(tokens: tokens, path: _path, busy: true);
        }
        final Uint8List? bytes = snapshot.hasError ? null : snapshot.data;
        if (bytes == null) {
          final l10n = PluginFlutterL10n.of(context);
          return _imageFrame(
            tokens: tokens,
            path: _path,
            message: l10n.resultImageLoadFailed,
          );
        }
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.spacing.space4),
          decoration: BoxDecoration(
            border: Border.all(
              color: tokens.color.primary,
              width: tokens.shape.strokeAccent,
            ),
            borderRadius: BorderRadius.circular(tokens.shape.radiusSm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.shape.radiusXs),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
