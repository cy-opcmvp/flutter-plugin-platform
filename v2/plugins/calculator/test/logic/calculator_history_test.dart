// 覆盖场景清单（计划 F4-03 Step 3，相似断言合并）：
// 1. add 插入最新在前并返回不可变快照。
// 2. 超出 maxEntries 裁掉最旧条目。
// 3. add/clear 委托 store.save（含裁剪后的最终列表）。
// 4. 构造时经 store.load 恢复既有条目。
// 5. CalculatorHistoryEntry 的 ==/hashCode 一致性。
// 6. clear 清空全部条目。
library;

import 'package:calculator/src/logic/calculator_history.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录式内存 store：捕获 save 调用与最终列表。
class _RecordingStore implements CalculatorHistoryStore {
  final List<CalculatorHistoryEntry> _saved = <CalculatorHistoryEntry>[];
  List<CalculatorHistoryEntry> initial = const <CalculatorHistoryEntry>[];
  int saveCalls = 0;

  @override
  List<CalculatorHistoryEntry> load() =>
      List<CalculatorHistoryEntry>.unmodifiable(initial);

  @override
  void save(List<CalculatorHistoryEntry> entries) {
    saveCalls++;
    _saved
      ..clear()
      ..addAll(entries);
  }
}

void main() {
  CalculatorHistoryEntry entry(String expression, double value) {
    return CalculatorHistoryEntry(expression: expression, value: value);
  }

  group('CalculatorHistoryEntry', () {
    test('相同表达式与数值的条目相等且哈希一致', () {
      expect(entry('1+1', 2), entry('1+1', 2));
      expect(entry('1+1', 2).hashCode, entry('1+1', 2).hashCode);
      expect(entry('1+1', 2), isNot(entry('2+2', 4)));
    });
  });

  group('CalculatorHistory', () {
    test('add 插入最新在前且 entries 为不可变快照', () {
      final CalculatorHistory history = CalculatorHistory();
      history.add(entry('1+2', 3));
      history.add(entry('2*3', 6));

      expect(history.entries.first.value, 6);
      expect(history.entries.length, 2);
      expect(() => history.entries.add(entry('9', 9)), throwsUnsupportedError);
    });

    test('超出 maxEntries 裁掉最旧条目', () {
      final CalculatorHistory history = CalculatorHistory(maxEntries: 2);
      history.add(entry('1', 1));
      history.add(entry('2', 2));
      history.add(entry('3', 3));

      expect(
        history.entries.map((CalculatorHistoryEntry e) => e.value),
        <double>[3, 2],
      );
    });

    test('add 与 clear 均委托 store.save 持久化', () {
      final _RecordingStore store = _RecordingStore();
      final CalculatorHistory history = CalculatorHistory(
        maxEntries: 2,
        store: store,
      );

      history.add(entry('1', 1));
      history.add(entry('2', 2));
      history.add(entry('3', 3));
      expect(store.saveCalls, 3);
      expect(store._saved.map((CalculatorHistoryEntry e) => e.value), <double>[
        3,
        2,
      ]);

      history.clear();
      expect(store.saveCalls, 4);
      expect(store._saved, isEmpty);
      expect(history.entries, isEmpty);
    });

    test('构造时经 store.load 恢复既有条目', () {
      final _RecordingStore store = _RecordingStore()
        ..initial = <CalculatorHistoryEntry>[entry('4*4', 16)];
      final CalculatorHistory history = CalculatorHistory(store: store);

      expect(history.entries.single, entry('4*4', 16));
    });
  });
}
