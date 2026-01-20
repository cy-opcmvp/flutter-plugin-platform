library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../models/screenshot_models.dart';
import '../screenshot_plugin.dart';

/// 截图历史记录界面
class ScreenshotHistoryScreen extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const ScreenshotHistoryScreen({super.key, required this.plugin});

  @override
  State<ScreenshotHistoryScreen> createState() =>
      _ScreenshotHistoryScreenState();
}

class _ScreenshotHistoryScreenState extends State<ScreenshotHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final screenshots = widget.plugin.screenshots;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshot_history_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          if (screenshots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmClearAll,
              tooltip: l10n.screenshot_clear_history,
            ),
        ],
      ),
      body: screenshots.isEmpty
          ? _buildEmptyState()
          : _buildHistoryGrid(screenshots),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.screenshot_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.screenshot_no_records,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.screenshot_history_hint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建历史记录网格
  Widget _buildHistoryGrid(List<ScreenshotRecord> screenshots) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 9,
      ),
      itemCount: screenshots.length,
      itemBuilder: (context, index) {
        final record = screenshots[index];
        return _ScreenshotThumbnail(
          record: record,
          onTap: () => _viewScreenshot(record),
          onDelete: () => _deleteScreenshot(record.id),
        );
      },
    );
  }

  /// 查看截图
  void _viewScreenshot(ScreenshotRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ScreenshotPreviewScreen(record: record),
      ),
    );
  }

  /// 删除截图
  void _deleteScreenshot(String screenshotId) async {
    await widget.plugin.deleteScreenshot(screenshotId);
    if (mounted) {
      setState(() {});
    }
  }

  /// 确认清空所有历史
  void _confirmClearAll() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.screenshot_confirm_clear_history),
        content: Text(l10n.screenshot_confirm_clear_history_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              await widget.plugin.clearHistory();
              if (mounted) {
                Navigator.of(context).pop();
                setState(() {});
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.screenshot_clear),
          ),
        ],
      ),
    );
  }
}

/// 截图缩略图
class _ScreenshotThumbnail extends StatelessWidget {
  final ScreenshotRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScreenshotThumbnail({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 缩略图
            _buildThumbnail(context),

            // 信息覆盖层
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInfoOverlay(context),
            ),

            // 删除按钮
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(4),
                ),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    // 检查文件是否存在
    final file = File(record.filePath);
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    // 显示缩略图
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getTypeIcon(record.type), size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatDate(record.createdAt),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record.formattedFileSize,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ScreenshotType type) {
    switch (type) {
      case ScreenshotType.fullScreen:
        return Icons.fullscreen;
      case ScreenshotType.region:
        return Icons.crop_square;
      case ScreenshotType.window:
        return Icons.window;
    }
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return l10n.screenshot_recent;
    } else if (diff.inHours < 1) {
      return l10n.screenshot_minutes_ago.replaceAll(
        '{minutes}',
        '${diff.inMinutes}',
      );
    } else if (diff.inDays < 1) {
      return l10n.screenshot_hours_ago.replaceAll('{hours}', '${diff.inHours}');
    } else if (diff.inDays < 7) {
      return l10n.screenshot_days_ago.replaceAll('{days}', '${diff.inDays}');
    } else {
      return l10n.screenshot_date_format
          .replaceAll('{month}', '${date.month}')
          .replaceAll('{day}', '${date.day}');
    }
  }
}

/// 截图预览界面
class _ScreenshotPreviewScreen extends StatefulWidget {
  final ScreenshotRecord record;

  const _ScreenshotPreviewScreen({required this.record});

  @override
  State<_ScreenshotPreviewScreen> createState() =>
      _ScreenshotPreviewScreenState();
}

class _ScreenshotPreviewScreenState extends State<_ScreenshotPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(_formatDate(widget.record.createdAt)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: '详细信息',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(widget.record.filePath);
    if (!file.existsSync()) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '文件不存在',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            widget.record.filePath,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '无法加载图片',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ],
        );
      },
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('截图信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('文件路径', widget.record.filePath),
            _buildInfoRow('文件大小', widget.record.formattedFileSize),
            _buildInfoRow('截图类型', _getTypeName(widget.record.type)),
            _buildInfoRow('创建时间', widget.record.createdAt.toString()),
            if (widget.record.dimensions != null)
              _buildInfoRow('图片尺寸', widget.record.dimensions!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  String _getTypeName(ScreenshotType type) {
    switch (type) {
      case ScreenshotType.fullScreen:
        return '全屏截图';
      case ScreenshotType.region:
        return '区域截图';
      case ScreenshotType.window:
        return '窗口截图';
    }
  }
}
