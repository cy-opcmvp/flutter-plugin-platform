library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../screenshot_plugin.dart';
import '../models/screenshot_models.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

/// 智能截图插件主界面
class ScreenshotMainWidget extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const ScreenshotMainWidget({super.key, required this.plugin});

  @override
  State<ScreenshotMainWidget> createState() => _ScreenshotMainWidgetState();
}

class _ScreenshotMainWidgetState extends State<ScreenshotMainWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plugin.name),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: '历史记录',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
            tooltip: '设置',
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 平台支持提示
              if (!widget.plugin.isAvailable) _buildUnsupportedWarning(context),

              // 快速操作区
              _buildQuickActions(context),

              const SizedBox(height: 16),

              // 最近截图
              _buildRecentScreenshots(context),

              const SizedBox(height: 16),

              // 统计信息
              _buildStatistics(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建平台不支持警告
  Widget _buildUnsupportedWarning(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '平台功能受限',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '此平台暂不完全支持截图功能。支持的平台：Windows、macOS、Linux',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建快速操作区
  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '快速操作',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickActionTile(
                  icon: Icons.crop_square,
                  title: '区域截图',
                  subtitle: 'Ctrl+Shift+A',
                  onTap: widget.plugin.isAvailable ? _startRegionCapture : null,
                ),
                _QuickActionTile(
                  icon: Icons.fullscreen,
                  title: '全屏截图',
                  subtitle: 'Ctrl+Shift+F',
                  onTap: widget.plugin.isAvailable ? _captureFullScreen : null,
                ),
                _QuickActionTile(
                  icon: Icons.window,
                  title: '窗口截图',
                  subtitle: 'Ctrl+Shift+W',
                  onTap: widget.plugin.isAvailable ? _showWindowList : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建最近截图区
  Widget _buildRecentScreenshots(BuildContext context) {
    final screenshots = widget.plugin.screenshots;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近截图',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (screenshots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.screenshot_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无截图记录',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上方按钮开始截图',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: screenshots.length > 10 ? 10 : screenshots.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final record = screenshots[index];
                  return _ScreenshotListItem(
                    record: record,
                    onTap: () => _viewScreenshot(record),
                    onDelete: () => _deleteScreenshot(record.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息区
  Widget _buildStatistics(BuildContext context) {
    final screenshots = widget.plugin.screenshots;
    final totalSize = screenshots.fold<int>(
      0,
      (sum, record) => sum + record.fileSize,
    );
    final todayCount = screenshots.where((record) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return record.createdAt.isAfter(today);
    }).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '统计信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatisticItem(
                  label: '总截图数',
                  value: screenshots.length.toString(),
                  icon: Icons.photo_library,
                ),
                _StatisticItem(
                  label: '今日截图',
                  value: todayCount.toString(),
                  icon: Icons.today,
                ),
                _StatisticItem(
                  label: '占用空间',
                  value: _formatFileSize(totalSize),
                  icon: Icons.storage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 开始区域截图
  void _startRegionCapture() async {
    debugPrint('===== 开始区域截图 =====');

    try {
      // 使用原生窗口进行区域选择（桌面级）
      debugPrint('调用 showNativeRegionCapture...');
      final success = await widget.plugin.showNativeRegionCapture();
      debugPrint('showNativeRegionCapture 返回: $success');

      if (!success) {
        debugPrint('无法打开原生截图窗口');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.screenshot_native_window_failed),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      debugPrint('原生窗口已显示，开始轮询结果...');
      // 轮询获取选择结果
      _pollForResult();
    } catch (e) {
      debugPrint('区域截图异常: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_region_failed(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 轮询获取区域选择结果
  void _pollForResult() async {
    const maxPolls = 300; // 最多轮询 30 秒（每 100ms 一次）
    int polls = 0;

    debugPrint('开始轮询，最多 $maxPolls 次...');

    while (polls < maxPolls) {
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await widget.plugin.getRegionSelectionResult();
      polls++;

      // 每 10 次轮询打印一次日志
      if (polls % 10 == 0) {
        debugPrint('轮询第 $polls 次，result = $result');
      }

      if (result != null) {
        debugPrint(
          '收到选择结果: ${result.x}, ${result.y}, ${result.width}x${result.height}',
        );
        // 用户选择了区域
        final rect = result.toRect();
        debugPrint('开始捕获区域: $rect');
        await widget.plugin.captureRegion(rect);
        debugPrint('区域捕获完成');
        return;
      }

      // 注意：如果用户取消，result 也会是 null
      // 我们可以通过多次连续返回 null 来判断取消（原生窗口会设置 completed 标志）
      // 但当前实现无法区分"还未完成"和"已取消"
      // 简单的做法是设置超时时间
    }

    // 超时，假设用户取消了
    debugPrint('===== 区域截图超时，假设用户取消 =====');
  }

  /// 捕获全屏截图
  void _captureFullScreen() async {
    try {
      await widget.plugin.captureFullScreen();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_fullscreen_failed(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 显示窗口列表
  void _showWindowList() async {
    try {
      final windows = await widget.plugin.getAvailableWindows();
      if (!mounted) return;

      if (windows.isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_window_not_available),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 显示窗口选择对话框
      final selectedWindowId = await showDialog<String>(
        context: context,
        builder: (context) => _WindowListDialog(windows: windows),
      );

      if (selectedWindowId != null) {
        await widget.plugin.captureWindow(selectedWindowId);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_window_failed(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 查看截图
  void _viewScreenshot(ScreenshotRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ScreenshotPreviewScreen(
          record: record,
          onDelete: () async {
            await widget.plugin.deleteScreenshot(record.id);
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  /// 删除截图
  void _deleteScreenshot(String screenshotId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.screenshot_confirmDelete),
        content: Text(l10n.screenshot_confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              await widget.plugin.deleteScreenshot(screenshotId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
  }

  /// 显示历史记录
  void _showHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScreenshotHistoryScreen(plugin: widget.plugin),
      ),
    );
  }

  /// 显示设置
  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScreenshotSettingsScreen(plugin: widget.plugin),
      ),
    );
  }
}

/// 快速操作按钮
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: onTap != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: onTap == null
              ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: onTap != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onTap != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onTap != null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 截图列表项
class _ScreenshotListItem extends StatelessWidget {
  final ScreenshotRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScreenshotListItem({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.image),
      title: Text(
        _formatDate(record.createdAt),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${record.formattedFileSize} • ${_getTypeName(record.type)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
        tooltip: '删除',
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTypeName(ScreenshotType type) {
    switch (type) {
      case ScreenshotType.fullScreen:
        return '全屏';
      case ScreenshotType.region:
        return '区域';
      case ScreenshotType.window:
        return '窗口';
    }
  }
}

/// 统计项
class _StatisticItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatisticItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 窗口列表对话框
class _WindowListDialog extends StatelessWidget {
  final List<WindowInfo> windows;

  const _WindowListDialog({required this.windows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_select_window),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: windows.length,
          itemBuilder: (context, index) {
            final window = windows[index];
            return ListTile(
              leading: _buildWindowIcon(window),
              title: Text(window.title),
              subtitle: window.appName != null ? Text(window.appName!) : null,
              onTap: () => Navigator.of(context).pop(window.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }

  /// 构建窗口图标
  Widget _buildWindowIcon(WindowInfo window) {
    if (window.icon != null && window.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          window.icon!,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.window, size: 32);
          },
        ),
      );
    }
    return const Icon(Icons.window, size: 32);
  }
}

/// 截图预览界面
class _ScreenshotPreviewScreen extends StatefulWidget {
  final ScreenshotRecord record;
  final VoidCallback? onDelete;

  const _ScreenshotPreviewScreen({required this.record, this.onDelete});

  @override
  State<_ScreenshotPreviewScreen> createState() =>
      _ScreenshotPreviewScreenState();
}

class _ScreenshotPreviewScreenState extends State<_ScreenshotPreviewScreen> {
  bool _isLoading = true;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.record.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.screenshot_file_not_exists)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.screenshot_image_load_failed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(_formatDate(widget.record.createdAt)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.common_close,
        ),
        actions: [
          if (_imageBytes != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: '复制到剪贴板',
            ),
          if (_imageBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImage,
              tooltip: '分享',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: l10n.common_delete,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 图片预览
          _buildBody(),

          // 底部关闭按钮（更明显）
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: Text(l10n.screenshot_close_preview),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('加载中...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    if (_imageBytes == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('无法加载图片', style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '无法加载图片',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    if (_imageBytes == null) return;

    try {
      // 将图片复制到剪贴板需要额外的剪贴板服务
      // 这里我们使用一个简化的方式：保存到临时文件
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/screenshot.png');
      await tempFile.writeAsBytes(_imageBytes!);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.screenshot_saved_to_temp),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.screenshot_copy_failed}: $e')),
        );
      }
    }
  }

  Future<void> _shareImage() async {
    if (_imageBytes == null) return;

    // TODO: 实现分享功能
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.screenshot_share_not_implemented),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.screenshot_confirmDelete),
        content: Text(l10n.screenshot_confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 关闭对话框
              widget.onDelete?.call();
              if (mounted) {
                Navigator.of(context).pop(); // 关闭预览界面
              }
            },
            child: Text(l10n.common_delete),
          ),
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
}
