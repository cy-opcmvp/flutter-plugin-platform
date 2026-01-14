import 'dart:async';
import 'package:flutter/material.dart';
import '../models/world_clock_models.dart';

/// 倒计时定时器显示组件
class CountdownTimerWidget extends StatefulWidget {
  final CountdownTimer countdownTimer;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final bool enableAnimations;

  const CountdownTimerWidget({
    Key? key,
    required this.countdownTimer,
    this.onDelete,
    this.onComplete,
    this.enableAnimations = true,
  }) : super(key: key);

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
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

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
        final scale = (isAlmostComplete && !isCompleted && widget.enableAnimations) 
            ? _pulseAnimation.value 
            : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            elevation: isCompleted ? 1.0 : 2.0,
            color: _getCardColor(theme, isCompleted, isAlmostComplete),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 标题和操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.countdownTimer.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isCompleted 
                                ? theme.textTheme.titleMedium?.color?.withOpacity(0.6)
                                : null,
                            decoration: isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '已完成',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _showDeleteConfirmation(context),
                          tooltip: '删除倒计时',
                          iconSize: 20,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 倒计时显示
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.countdownTimer.formattedRemainingTime,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: _getTimeColor(theme, isCompleted, isAlmostComplete),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusText(isCompleted, remainingTime),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(theme, isCompleted, isAlmostComplete),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 圆形进度指示器
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: isCompleted ? 1.0 : _calculateProgress(),
                              strokeWidth: 4,
                              backgroundColor: theme.dividerColor.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(theme, isCompleted, isAlmostComplete),
                              ),
                            ),
                            Center(
                              child: Icon(
                                isCompleted 
                                    ? Icons.check_circle
                                    : isAlmostComplete 
                                        ? Icons.warning
                                        : Icons.timer,
                                color: _getProgressColor(theme, isCompleted, isAlmostComplete),
                                size: 24,
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
        );
      },
    );
  }

  Color? _getCardColor(ThemeData theme, bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) {
      return Colors.green.withOpacity(0.1);
    } else if (isAlmostComplete) {
      return Colors.orange.withOpacity(0.1);
    }
    return null;
  }

  Color _getTimeColor(ThemeData theme, bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.primaryColor;
  }

  Color _getStatusColor(ThemeData theme, bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey;
  }

  Color _getProgressColor(ThemeData theme, bool isCompleted, bool isAlmostComplete) {
    if (isCompleted) {
      return Colors.green;
    } else if (isAlmostComplete) {
      return Colors.orange;
    }
    return theme.primaryColor;
  }

  String _getStatusText(bool isCompleted, Duration remainingTime) {
    if (isCompleted) {
      return '倒计时已完成';
    } else if (remainingTime.inMinutes < 1) {
      return '即将完成！';
    } else if (remainingTime.inHours < 1) {
      return '剩余 ${remainingTime.inMinutes} 分钟';
    } else if (remainingTime.inDays < 1) {
      return '剩余 ${remainingTime.inHours} 小时 ${remainingTime.inMinutes % 60} 分钟';
    } else {
      return '剩余 ${remainingTime.inDays} 天 ${remainingTime.inHours % 24} 小时';
    }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除倒计时 "${widget.countdownTimer.title}" 吗？'),
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

/// 紧凑型倒计时组件
class CompactCountdownWidget extends StatefulWidget {
  final CountdownTimer countdownTimer;
  final VoidCallback? onTap;

  const CompactCountdownWidget({
    Key? key,
    required this.countdownTimer,
    this.onTap,
  }) : super(key: key);

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
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
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
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              )
            else if (isAlmostComplete)
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}