// 覆盖场景清单（S1 批B焦点测试：文件名模板纯逻辑）：
// 1. 日期/时间段格式化（补零）；
// 2. 模板 token 展开：默认模板、{seq} 组合、{time} 组合；
// 3. 基名清理：非法字符逐个替换为下划线、控制字符替换、结尾点号与
//    尾部空白剔除、空/全非法回退 `screenshot`；
// 4. 同秒序号：同秒（含毫秒变体）递增、跨秒重置为 1。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/src/filename_template.dart';

void main() {
  group('formatFilenameDate / formatFilenameTime', () {
    test('按 yyyyMMdd 与 HHmmss 输出并补零', () {
      final DateTime time = DateTime(2026, 9, 6, 7, 8, 9);

      expect(formatFilenameDate(time), '20260906');
      expect(formatFilenameTime(time), '070809');
    });
  });

  group('expandFilenameTemplate', () {
    test('默认模板展开日期与时间段', () {
      final String name = expandFilenameTemplate(
        kScreenshotDefaultFilenameTemplate,
        now: DateTime(2026, 9, 6, 12, 34, 56),
        seq: 2,
      );

      expect(name, 'screenshot-20260906123456');
    });

    test('自定义模板组合 {date} 与 {seq}', () {
      final String name = expandFilenameTemplate(
        'shot-{date}-{seq}',
        now: DateTime(2026, 9, 6, 12, 34, 56),
        seq: 3,
      );

      expect(name, 'shot-20260906-3');
    });

    test('展开结果清理非法字符为下划线', () {
      final String name = expandFilenameTemplate(
        'a:b*c',
        now: DateTime(2026, 9, 6, 12, 34, 56),
        seq: 1,
      );

      expect(name, 'a_b_c');
    });
  });

  group('sanitizeFilenameBase', () {
    test('Windows 保留字符逐个替换为下划线', () {
      for (final String char in r'\/:*?"<>|'.split('')) {
        expect(sanitizeFilenameBase('a${char}b'), 'a_b');
      }
    });

    test('控制字符替换为下划线', () {
      expect(sanitizeFilenameBase('a\x01b'), 'a_b');
    });

    test('剔除结尾点号与尾部空白', () {
      expect(sanitizeFilenameBase(' name. .. '), 'name');
    });

    test('空与全非法输入回退 screenshot', () {
      expect(sanitizeFilenameBase(''), 'screenshot');
      expect(sanitizeFilenameBase('???'), 'screenshot');
    });
  });

  group('FilenameSequencer', () {
    test('同一秒内连续取号递增（毫秒变体不影响同秒判定）', () {
      final FilenameSequencer sequencer = FilenameSequencer();

      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0, 100)), 1);
      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0, 200)), 2);
      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0, 300)), 3);
    });

    test('跨秒取号重置为 1', () {
      final FilenameSequencer sequencer = FilenameSequencer();

      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0)), 1);
      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0)), 2);
      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 0)), 3);
      expect(sequencer.nextFor(DateTime(2026, 9, 6, 12, 0, 1)), 1);
    });
  });
}
