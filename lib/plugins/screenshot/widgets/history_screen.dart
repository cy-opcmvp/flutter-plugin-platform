library;

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../models/screenshot_models.dart';
import '../models/screenshot_settings.dart';
import '../services/clipboard_service.dart';
import '../utils/history_grouper.dart';
import '../screenshot_plugin.dart';

/// 截图历史记录界面
///
/// 支持按时间段分组显示，每个分组独立折叠和懒加载
class ScreenshotHistoryScreen extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const ScreenshotHistoryScreen({super.key, required this.plugin});

  @override
  State<ScreenshotHistoryScreen> createState() =>
      _ScreenshotHistoryScreenState();
}

class _ScreenshotHistoryScreenState extends State<ScreenshotHistoryScreen> {
  /// 分组后的历史记录
  Future<Map<HistoryPeriod, List<ScreenshotRecord>>>? _groupedRecords;

  @override
  void initState() {
    super.initState();
    _loadGroupedRecords();
  }

  /// 加载并分组历史记录
  Future<void> _loadGroupedRecords() async {
    final allRecords = widget.plugin.screenshots;

    // 先过滤掉文件不存在的记录，再按时间段分组
    final grouped = await HistoryGrouper.groupAndFilter(allRecords);

    setState(() {
      _groupedRecords = Future.value(grouped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshot_history_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroupedRecords,
            tooltip: l10n.screenshot_history_refresh,
          ),
          // 清空所有按钮（如果有记录）
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClearAll,
            tooltip: l10n.screenshot_clear_history,
          ),
        ],
      ),
      body: FutureBuilder<Map<HistoryPeriod, List<ScreenshotRecord>>>(
        future: _groupedRecords,
        builder: (context, snapshot) {
          // 加载中
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 加载出错
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.screenshot_history_load_failed,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!;

          // 所有分组都为空
          if (groups.values.every((list) => list.isEmpty)) {
            return _buildEmptyState();
          }

          // 显示分组列表
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 今日
              if (groups[HistoryPeriod.today]!.isNotEmpty)
                _HistoryGroupSection(
                  period: HistoryPeriod.today,
                  groupName: l10n.screenshot_history_today,
                  allRecords: groups[HistoryPeriod.today]!,
                  onView: _viewScreenshot,
                  onDelete: _deleteScreenshot,
                ),

              // 三天内
              if (groups[HistoryPeriod.threeDays]!.isNotEmpty)
                _HistoryGroupSection(
                  period: HistoryPeriod.threeDays,
                  groupName: l10n.screenshot_history_three_days,
                  allRecords: groups[HistoryPeriod.threeDays]!,
                  onView: _viewScreenshot,
                  onDelete: _deleteScreenshot,
                ),

              // 一周内
              if (groups[HistoryPeriod.week]!.isNotEmpty)
                _HistoryGroupSection(
                  period: HistoryPeriod.week,
                  groupName: l10n.screenshot_history_this_week,
                  allRecords: groups[HistoryPeriod.week]!,
                  onView: _viewScreenshot,
                  onDelete: _deleteScreenshot,
                ),

              // 一周前
              if (groups[HistoryPeriod.older]!.isNotEmpty)
                _HistoryGroupSection(
                  period: HistoryPeriod.older,
                  groupName: l10n.screenshot_history_older,
                  allRecords: groups[HistoryPeriod.older]!,
                  onView: _viewScreenshot,
                  onDelete: _deleteScreenshot,
                ),
            ],
          );
        },
      ),
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
      // 重新加载数据
      _loadGroupedRecords();
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
                // 重新加载数据
                _loadGroupedRecords();
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

/// 历史记录分组组件
///
/// 独立管理每个时间段的展开/折叠状态和懒加载
class _HistoryGroupSection extends StatefulWidget {
  final HistoryPeriod period;
  final String groupName;
  final List<ScreenshotRecord> allRecords;
  final void Function(ScreenshotRecord) onView;
  final void Function(String) onDelete;

  const _HistoryGroupSection({
    required this.period,
    required this.groupName,
    required this.allRecords,
    required this.onView,
    required this.onDelete,
  });

  @override
  State<_HistoryGroupSection> createState() => _HistoryGroupSectionState();
}

class _HistoryGroupSectionState extends State<_HistoryGroupSection> {
  /// 是否展开
  bool _isExpanded = false;

  /// 当前可见的记录（懒加载）
  final List<ScreenshotRecord> _visibleRecords = [];

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 每次加载的图片数量（3 行 × 3 列 = 9 张）
  static const int _pageSize = 9;

  /// 是否正在加载
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动，触发懒加载
  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 当滚动到距离底部 200px 时加载更多
    if (maxScroll - currentScroll < 200 && _hasMore) {
      _loadMore();
    }
  }

  /// 是否还有更多可加载
  bool get _hasMore => _visibleRecords.length < widget.allRecords.length;

  /// 加载更多记录
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    // 模拟异步加载（实际上数据已在内存中）
    await Future.delayed(const Duration(milliseconds: 100));

    final start = _visibleRecords.length;
    final end = math.min(start + _pageSize, widget.allRecords.length);

    setState(() {
      _visibleRecords.addAll(widget.allRecords.sublist(start, end));
      _isLoading = false;
    });
  }

  /// 切换展开/折叠状态
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      // 首次展开时加载数据
      if (_isExpanded && _visibleRecords.isEmpty) {
        _loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          // 分组标题栏
          ListTile(
            title: Text(
              widget.groupName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${widget.allRecords.length} ${l10n.screenshot_history_items}',
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: _toggleExpanded,
          ),

          // 分组内容（可折叠）
          if (_isExpanded)
            SizedBox(
              height: 400, // 限制高度，避免一次性渲染太多
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: _visibleRecords.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // 加载更多指示器
                  if (index == _visibleRecords.length && _hasMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // 正常的缩略图
                  final record = _visibleRecords[index];
                  return _ScreenshotThumbnail(
                    record: record,
                    onTap: () => widget.onView(record),
                    onDelete: () => widget.onDelete(record.id),
                  );
                },
              ),
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
    final file = File(record.filePath);

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
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 文件名
          Text(
            record.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 时间和大小
          Text(
            '${_formatDate(context, record.createdAt)} • ${record.formattedFileSize}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return l10n.screenshot_recent;
    } else if (diff.inHours < 1) {
      return l10n.screenshot_minutes_ago(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return l10n.screenshot_hours_ago(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.screenshot_days_ago(diff.inDays);
    } else {
      return l10n.screenshot_date_format(date.month, date.day);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.common_back,
          ),
        ),
        title: Text(
          widget.record.fileName,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 复制路径
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _copyFilePath,
            tooltip: l10n.screenshot_copy_path,
          ),
          // 复制图片
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyImage,
            tooltip: l10n.screenshot_copy_image,
          ),
          // 详细信息
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: l10n.common_details,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.screenshot_info_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(l10n.screenshot_info_path, widget.record.filePath),
            _buildInfoRow(
              l10n.screenshot_info_size,
              widget.record.formattedFileSize,
            ),
            _buildInfoRow(
              l10n.screenshot_info_type,
              _getTypeName(widget.record.type),
            ),
            _buildInfoRow(
              l10n.screenshot_info_created,
              widget.record.createdAt.toString(),
            ),
            if (widget.record.dimensions != null)
              _buildInfoRow(
                l10n.screenshot_info_dimensions,
                widget.record.dimensions!,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  /// 复制文件路径到剪贴板
  void _copyFilePath() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Clipboard.setData(ClipboardData(text: widget.record.filePath));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_path_copied),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.screenshot_copy_failed}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 复制图片到剪贴板
  void _copyImage() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final file = File(widget.record.filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.screenshot_file_not_exists),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 读取图片数据
      final imageBytes = await file.readAsBytes();

      // 使用 ClipboardService 复制图片到剪贴板
      final clipboardService = ClipboardService();
      final success = await clipboardService.copyContent(
        widget.record.filePath,
        contentType: ClipboardContentType.image,
        imageBytes: imageBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.screenshot_image_copied
                  : l10n.screenshot_copy_failed,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.screenshot_copy_failed}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
