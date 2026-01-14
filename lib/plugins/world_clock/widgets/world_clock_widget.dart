import 'dart:async';
import 'package:flutter/material.dart';
import '../models/world_clock_models.dart';

/// 世界时钟显示组件
class WorldClockWidget extends StatefulWidget {
  final WorldClockItem worldClock;
  final VoidCallback? onDelete;
  final bool showSeconds;

  const WorldClockWidget({
    Key? key,
    required this.worldClock,
    this.onDelete,
    this.showSeconds = true,
  }) : super(key: key);

  @override
  State<WorldClockWidget> createState() => _WorldClockWidgetState();
}

class _WorldClockWidgetState extends State<WorldClockWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 每秒更新一次时间显示
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDefault = widget.worldClock.isDefault;
    final time = widget.worldClock.currentTime;
    
    // 格式化时间显示
    final timeStr = widget.showSeconds 
        ? widget.worldClock.formattedTime 
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: isDefault ? 3.0 : 1.0,
      color: isDefault ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 城市信息
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.worldClock.cityName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '默认',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.worldClock.timeZone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // 时间显示
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDefault ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.worldClock.formattedDate,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // 操作按钮
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context),
                tooltip: '删除时钟',
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${widget.worldClock.cityName} 的时钟吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 紧凑型世界时钟组件（用于列表显示）
class CompactWorldClockWidget extends StatefulWidget {
  final WorldClockItem worldClock;
  final VoidCallback? onTap;

  const CompactWorldClockWidget({
    Key? key,
    required this.worldClock,
    this.onTap,
  }) : super(key: key);

  @override
  State<CompactWorldClockWidget> createState() => _CompactWorldClockWidgetState();
}

class _CompactWorldClockWidgetState extends State<CompactWorldClockWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.worldClock.cityName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.worldClock.timeZone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            Text(
              widget.worldClock.formattedTime,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 大型时钟显示组件（用于主要显示）
class LargeClockWidget extends StatefulWidget {
  final WorldClockItem worldClock;
  final bool showSeconds;

  const LargeClockWidget({
    Key? key,
    required this.worldClock,
    this.showSeconds = true,
  }) : super(key: key);

  @override
  State<LargeClockWidget> createState() => _LargeClockWidgetState();
}

class _LargeClockWidgetState extends State<LargeClockWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = widget.worldClock.currentTime;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 城市名称
          Text(
            widget.worldClock.cityName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 时区信息
          Text(
            widget.worldClock.timeZone,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 大时钟显示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              if (widget.showSeconds) ...[
                Text(
                  ':${time.second.toString().padLeft(2, '0')}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.normal,
                    color: theme.primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 日期显示
          Text(
            widget.worldClock.formattedDate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.titleMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}