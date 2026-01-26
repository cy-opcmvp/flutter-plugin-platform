library;

import 'dart:io';
import '../models/screenshot_models.dart';

/// 历史记录分组辅助类
///
/// 负责将历史记录按时间段分组，并过滤掉文件不存在的记录
class HistoryGrouper {
  /// 按时间段分组历史记录
  ///
  /// 返回一个 Map，key 为时间段，value 为该时间段的所有记录
  static Map<HistoryPeriod, List<ScreenshotRecord>> groupByPeriod(
    List<ScreenshotRecord> records,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <HistoryPeriod, List<ScreenshotRecord>>{
      HistoryPeriod.today: [],
      HistoryPeriod.threeDays: [],
      HistoryPeriod.week: [],
      HistoryPeriod.older: [],
    };

    for (final record in records) {
      if (record.createdAt.isAfter(today)) {
        groups[HistoryPeriod.today]!.add(record);
      } else if (record.createdAt.isAfter(threeDaysAgo)) {
        groups[HistoryPeriod.threeDays]!.add(record);
      } else if (record.createdAt.isAfter(weekAgo)) {
        groups[HistoryPeriod.week]!.add(record);
      } else {
        groups[HistoryPeriod.older]!.add(record);
      }
    }

    return groups;
  }

  /// 过滤掉文件不存在的记录
  ///
  /// 异步检查每条记录的文件是否存在，返回存在的记录列表
  static Future<List<ScreenshotRecord>> filterExistingFiles(
    List<ScreenshotRecord> records,
  ) async {
    final existing = <ScreenshotRecord>[];

    for (final record in records) {
      try {
        final file = File(record.filePath);
        if (await file.exists()) {
          existing.add(record);
        }
      } catch (e) {
        // 忽略文件访问错误，视为文件不存在
        continue;
      }
    }

    return existing;
  }

  /// 获取时间段的显示名称
  ///
  /// 需要传入 AppLocalizations 以支持国际化
  static String getPeriodDisplayName(
    HistoryPeriod period,
    dynamic l10n, // AppLocalizations
  ) {
    switch (period) {
      case HistoryPeriod.today:
        return l10n.screenshot_history_today as String;
      case HistoryPeriod.threeDays:
        return l10n.screenshot_history_three_days as String;
      case HistoryPeriod.week:
        return l10n.screenshot_history_this_week as String;
      case HistoryPeriod.older:
        return l10n.screenshot_history_older as String;
    }
  }

  /// 按时间分组（包含文件存在性检查）
  ///
  /// 这是一个便捷方法，一次性完成分组和过滤
  static Future<Map<HistoryPeriod, List<ScreenshotRecord>>> groupAndFilter(
    List<ScreenshotRecord> records,
  ) async {
    // 先过滤掉文件不存在的记录
    final existingRecords = await filterExistingFiles(records);

    // 再按时间段分组
    return groupByPeriod(existingRecords);
  }
}
