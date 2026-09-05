/// 计算器历史记录（纯 Dart、零 Flutter、零 dart:io）。
///
/// [CalculatorHistory] 持有不可变条目快照，写入时裁剪到容量上限并委托
/// 注入的 [CalculatorHistoryStore] 持久化；默认内存实现仅存会话内状态。
library;

/// 单条历史记录（表达式与求值结果）。
final class CalculatorHistoryEntry {
  /// 以表达式与结果构造条目。
  const CalculatorHistoryEntry({required this.expression, required this.value});

  /// 求值时的表达式原文。
  final String expression;

  /// 求值结果数值。
  final double value;

  @override
  bool operator ==(Object other) {
    return other is CalculatorHistoryEntry &&
        other.expression == expression &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(expression, value);
}

/// 历史持久化接口（由宿主或测试注入，插件内零平台依赖）。
abstract class CalculatorHistoryStore {
  /// 加载持久化的条目列表；无持久化数据时返回空表。
  List<CalculatorHistoryEntry> load();

  /// 以给定的完整列表覆盖保存。
  void save(List<CalculatorHistoryEntry> entries);
}

/// 默认内存实现：仅保存于当前实例，进程结束即丢失。
class InMemoryCalculatorHistoryStore implements CalculatorHistoryStore {
  final List<CalculatorHistoryEntry> _entries = <CalculatorHistoryEntry>[];

  @override
  List<CalculatorHistoryEntry> load() {
    return List<CalculatorHistoryEntry>.unmodifiable(_entries);
  }

  @override
  void save(List<CalculatorHistoryEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
  }
}

/// 历史记录门面：容量裁剪 + 注入持久化。
class CalculatorHistory {
  /// 以容量上限与持久化实现构造；缺省内存实现。
  CalculatorHistory({this.maxEntries = 50, CalculatorHistoryStore? store})
    : _store = store ?? InMemoryCalculatorHistoryStore() {
    _entries.addAll(_store.load());
  }

  /// 保留的最大条目数（超出时裁掉最旧条目）。
  final int maxEntries;

  final CalculatorHistoryStore _store;
  final List<CalculatorHistoryEntry> _entries = <CalculatorHistoryEntry>[];

  /// 当前条目的不可变快照（最新在前）。
  List<CalculatorHistoryEntry> get entries =>
      List<CalculatorHistoryEntry>.unmodifiable(_entries);

  /// 新增一条记录（插入到最前），裁剪并持久化。
  void add(CalculatorHistoryEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    _store.save(_entries);
  }

  /// 清空全部记录并持久化。
  void clear() {
    _entries.clear();
    _store.save(_entries);
  }
}
