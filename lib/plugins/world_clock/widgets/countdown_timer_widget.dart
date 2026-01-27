import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../models/world_clock_models.dart';

/// 倒计时定时器显示组件
class CountdownTimerWidget extends StatefulWidget {
  final CountdownTimer countdownTimer;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final bool enableAnimations;

  const CountdownTimerWidget({
    super.key,
    required this.countdownTimer,
    this.onDelete,
    this.onComplete,
    this.enableAnimations = true,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with TickerProviderStateMixin {
  Timer? _updateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 每秒更新一次
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});

        // 检查是否完成
        if (widget.countdownTimer.remainingTime == Duration.zero &&
            !widget.countdownTimer.isCompleted) {
          widget.countdownTimer.isCompleted = true;
          widget.onComplete?.call();
        }

        // 如果即将完成，开始脉冲动画
        if (widget.countdownTimer.isAlmostComplete &&
            !widget.countdownTimer.isCompleted &&
            widget.enableAnimations) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.countdownTimer.isCompleted;
    final isAlmostComplete = widget.countdownTimer.isAlmostComplete;
    final remainingTime = widget.countdownTimer.remainingTime;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale =
            (isAlmostComplete && !isCompleted && widget.enableAnimations)
            ? _pulseAnimation.value
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _getGradient(theme, isCompleted, isAlmostComplete),
              boxShadow: [
                BoxShadow(
                  color: _getShadowColor(
                    theme,
                    isCompleted,
                    isAlmostComplete,
                  ).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getBorderColor(theme, isCompleted, isAlmostComplete),
                  width: 1.5,
                ),
                color: theme.cardColor.withValues(alpha: 0.95),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // 标题和操作按钮
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _getIconGradientColors(
                                theme,
                                isCompleted,
                                isAlmostComplete,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getIconGradientColors(
                                  theme,
                                  isCompleted,
                                  isAlmostComplete,
                                )[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getTimerIcon(isCompleted, isAlmostComplete),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.countdownTimer.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                  : _getTimeColor(
                                      theme,
                                      isCompleted,
                                      isAlmostComplete,
                                    ),
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (widget.onDelete != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showDeleteConfirmation(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: theme.colorScheme.error,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 倒计时显示
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.countdownTimer.formattedRemainingTime,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: _getTimeColor(
                                    theme,
                                    isCompleted,
                                    isAlmostComplete,
                                  ),
                                  fontSize: 42,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    theme,
                                    isCompleted,
                                    isAlmostComplete,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(isCompleted, remainingTime),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _getStatusColor(
                                      theme,
                                      isCompleted,
                                      isAlmostComplete,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 圆形进度指示器
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 背景圆
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.dividerColor.withValues(alpha: 0.1),
                                ),
                              ),
                              // 进度圆
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: isCompleted
                                      ? 1.0
                                      : _calculateProgress(),
                                  strokeWidth: 6,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(
                                      theme,
                                      isCompleted,
                                      isAlmostComplete,
                                    ),
                                  ),
                                ),
                              ),
                              // 中心图标
                              Center(
                                child: Icon(
                                  _getCenterIcon(isCompleted, isAlmostComplete),
                                  size: 28,
                                  color: _getProgressColor(
                                    theme,
                                    isCompleted,
                                    isAlmostComplete,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTimeColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.primaryColor;
  }

  Color _getStatusColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey;
  }

  Color _getProgressColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.primaryColor;
  }

  String _getStatusText(bool isCompleted, Duration remainingTime) {
    if (isCompleted) {
      return 'Completed';
    } else if (remainingTime.inMinutes < 1) {
      return 'Almost complete!';
    } else if (remainingTime.inHours < 1) {
      return '${remainingTime.inMinutes} minutes remaining';
    } else if (remainingTime.inDays < 1) {
      return '${remainingTime.inHours} hours ${remainingTime.inMinutes % 60} minutes remaining';
    } else {
      return '${remainingTime.inDays} days ${remainingTime.inHours % 24} hours remaining';
    }
  }

  Color? _getCardColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    // 不再使用，保留以防万一
    return null;
  }

  LinearGradient _getGradient(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)],
      );
    } else if (isAlmostComplete) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.withValues(alpha: 0.05),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.primaryColor.withValues(alpha: 0.1),
        theme.primaryColor.withValues(alpha: 0.02),
      ],
    );
  }

  Color _getShadowColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) return Colors.green;
    if (isAlmostComplete) return Colors.orange;
    return theme.primaryColor;
  }

  Color _getBorderColor(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) return Colors.green.withValues(alpha: 0.5);
    if (isAlmostComplete) return Colors.orange.withValues(alpha: 0.5);
    return theme.primaryColor.withValues(alpha: 0.3);
  }

  List<Color> _getIconGradientColors(
    ThemeData theme,
    bool isCompleted,
    bool isAlmostComplete,
  ) {
    if (isCompleted) {
      return [Colors.green.shade400, Colors.green.shade600];
    } else if (isAlmostComplete) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    }
    return [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)];
  }

  IconData _getTimerIcon(bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) return Icons.check_circle;
    if (isAlmostComplete) return Icons.timer;
    return Icons.timer_outlined;
  }

  IconData _getCenterIcon(bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) return Icons.check;
    if (isAlmostComplete) return Icons.notifications_active;
    return Icons.schedule;
  }

  double _calculateProgress() {
    // 这里需要原始持续时间来计算进度
    // 由于模型中没有存储原始持续时间，我们使用一个简化的计算
    final remaining = widget.countdownTimer.remainingTime;
    if (remaining == Duration.zero) return 1.0;

    // 假设最大倒计时为24小时，这是一个简化的实现
    const maxDuration = Duration(hours: 24);
    final elapsed = maxDuration - remaining;
    return elapsed.inMilliseconds / maxDuration.inMilliseconds;
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.world_clock_confirm_delete),
        content: Text(
          l10n.world_clock_confirm_delete_countdown_message(
            widget.countdownTimer.title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
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
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
  }
}

/// 紧凑型倒计时组件
class CompactCountdownWidget extends StatefulWidget {
  final CountdownTimer countdownTimer;
  final VoidCallback? onTap;

  const CompactCountdownWidget({
    super.key,
    required this.countdownTimer,
    this.onTap,
  });

  @override
  State<CompactCountdownWidget> createState() => _CompactCountdownWidgetState();
}

class _CompactCountdownWidgetState extends State<CompactCountdownWidget> {
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
    final isCompleted = widget.countdownTimer.isCompleted;
    final isAlmostComplete = widget.countdownTimer.isAlmostComplete;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 状态图标
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isAlmostComplete
                    ? Colors.orange
                    : theme.primaryColor,
              ),
            ),

            const SizedBox(width: 12),

            // 标题和时间
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.countdownTimer.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.countdownTimer.formattedRemainingTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: isCompleted
                          ? Colors.green
                          : isAlmostComplete
                          ? Colors.orange
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // 完成状态
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else if (isAlmostComplete)
              const Icon(Icons.warning, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}
