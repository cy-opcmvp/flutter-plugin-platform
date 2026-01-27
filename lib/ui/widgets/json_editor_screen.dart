library;

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/services/json_validator.dart';

/// JSON 编辑器界面
///
/// 用于编辑和验证 JSON 配置文件
class JsonEditorScreen extends StatefulWidget {
  /// 配置名称（用于显示）
  final String configName;

  /// 配置描述
  final String? configDescription;

  /// 当前 JSON 内容
  final String currentJson;

  /// Schema 定义（可选）
  final JsonSchema? schema;

  /// 默认 JSON 内容
  final String defaultJson;

  /// 示例 JSON 内容
  final String exampleJson;

  /// 保存回调
  final Future<bool> Function(String json) onSave;

  const JsonEditorScreen({
    super.key,
    required this.configName,
    this.configDescription,
    required this.currentJson,
    this.schema,
    required this.defaultJson,
    required this.exampleJson,
    required this.onSave,
  });

  @override
  State<JsonEditorScreen> createState() => _JsonEditorScreenState();
}

class _JsonEditorScreenState extends State<JsonEditorScreen> {
  late TextEditingController _controller;
  late ScrollController _scrollController;

  JsonValidationResult? _validationResult;
  bool _hasChanges = false;
  bool _isValidating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentJson);
    _scrollController = ScrollController();
    _validateJson();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final l10n = AppLocalizations.of(context)!;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.json_editor_discard_title),
            content: Text(l10n.json_editor_discard_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.json_editor_discard_confirm),
              ),
            ],
          ),
        );

        if (shouldPop ?? false && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.json_editor_title(widget.configName)),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          elevation: 0,
          actions: [
            // 格式化按钮
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: _formatJson,
              tooltip: l10n.json_editor_format,
            ),
            // 压缩按钮
            IconButton(
              icon: const Icon(Icons.compress),
              onPressed: _minifyJson,
              tooltip: l10n.json_editor_minify,
            ),
            // 重置按钮
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetToDefault,
              tooltip: l10n.json_editor_reset,
            ),
            // 示例按钮
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _loadExample,
              tooltip: l10n.json_editor_example,
            ),
            // 验证按钮
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _validateAndShowResult,
              tooltip: l10n.json_editor_validate,
            ),
          ],
        ),
        body: Column(
          children: [
            // 配置说明
            if (widget.configDescription != null)
              _buildDescriptionCard(context),

            // 验证状态栏
            _buildValidationBar(context),

            // JSON 编辑器
            Expanded(child: _buildEditor(context)),

            // 底部操作栏
            _buildBottomBar(context, l10n),
          ],
        ),
      ),
    );
  }

  /// 构建描述卡片
  Widget _buildDescriptionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.configDescription!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建验证状态栏
  Widget _buildValidationBar(BuildContext context) {
    final isValid = _validationResult?.isValid ?? false;
    final hasResult = _validationResult != null;

    if (!hasResult) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isValid
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            size: 20,
            color: isValid
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _validationResult!.errorMessage ??
                  (isValid ? 'Valid JSON' : 'Invalid JSON'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isValid
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 JSON 编辑器
  Widget _buildEditor(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        scrollController: _scrollController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        onChanged: _onJsonChanged,
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 变更提示
          if (_hasChanges)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.json_editor_unsaved_changes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 16),
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          const SizedBox(width: 8),
          // 保存按钮
          FilledButton(
            onPressed:
                _isValidating ||
                    _isSaving ||
                    !(_validationResult?.isValid ?? false)
                ? null
                : _saveJson,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.common_save),
          ),
        ],
      ),
    );
  }

  /// JSON 内容变化时
  void _onJsonChanged(String value) {
    setState(() {
      _hasChanges = value != widget.currentJson;
      // 延迟验证以提高性能
      Future.delayed(const Duration(milliseconds: 300), _validateJson);
    });
  }

  /// 验证 JSON
  Future<void> _validateJson() async {
    setState(() {
      _isValidating = true;
    });

    final jsonString = _controller.text;
    JsonValidationResult result;

    if (widget.schema != null) {
      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        result = JsonValidator.validateSchema(data, widget.schema!);
      } catch (e) {
        result = JsonValidator.validateJsonString(jsonString);
      }
    } else {
      result = JsonValidator.validateJsonString(jsonString);
    }

    if (mounted) {
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    }
  }

  /// 验证并显示结果
  void _validateAndShowResult() {
    _validateJson();
    if (_validationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validationResult.toString()),
          duration: const Duration(seconds: 3),
          backgroundColor: _validationResult!.isValid
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  /// 格式化 JSON
  void _formatJson() {
    final formatted = JsonValidator.formatJson(_controller.text);
    setState(() {
      _controller.text = formatted;
      _hasChanges = formatted != widget.currentJson;
    });
  }

  /// 压缩 JSON
  void _minifyJson() {
    final minified = JsonValidator.minifyJson(_controller.text);
    setState(() {
      _controller.text = minified;
      _hasChanges = minified == widget.currentJson;
    });
  }

  /// 重置为默认值
  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.json_editor_reset_confirm_title),
          content: Text(l10n.json_editor_reset_confirm_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _controller.text = widget.defaultJson;
                  _hasChanges = true;
                  _validateJson();
                });
                Navigator.of(context).pop();
              },
              child: Text(l10n.json_editor_reset_confirm),
            ),
          ],
        );
      },
    );
  }

  /// 加载示例
  void _loadExample() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.json_editor_example_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.json_editor_example_message),
              const SizedBox(height: 16),
              Text(
                l10n.json_editor_example_warning,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _controller.text = widget.exampleJson;
                  _hasChanges = true;
                  _validateJson();
                });
                Navigator.of(context).pop();
              },
              child: Text(l10n.json_editor_example_load),
            ),
          ],
        );
      },
    );
  }

  /// 保存 JSON
  Future<void> _saveJson() async {
    if (!(_validationResult?.isValid ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await widget.onSave(_controller.text);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true); // 返回 true 表示已保存
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.json_editor_save_failed,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 返回前确认
}
