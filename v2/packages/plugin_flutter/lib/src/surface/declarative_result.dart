/// 声明式结果模型：插件以数据描述执行结果，宿主负责渲染（规格 §9）。
///
/// [ResultDescriptor] 是封闭类型族（text / table / image / fields），
/// 支持fromJson/toJson 往返，便于跨进程传输与统一展示。
library;

/// 结果字段：标签 + 文本值（用于 fields 结果）。
final class ResultField {
  /// 创建结果字段；[label] 与 [value] 均非空白。
  ResultField({required String label, required String value})
    : label = _requireNonBlank(label, 'label'),
      value = _requireNonBlank(value, 'value');

  /// 字段标签。
  final String label;

  /// 字段文本值。
  final String value;

  /// 序列化为 JSON：`{"label", "value"}`。
  Map<String, Object?> toJson() {
    return <String, Object?>{'label': label, 'value': value};
  }

  /// 从 JSON 反序列化；结构非法抛 [FormatException]。
  factory ResultField.fromJson(Map<String, Object?> json) {
    return ResultField(
      label: _requireJsonField(json, 'label') as String,
      value: _requireJsonField(json, 'value') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultField && label == other.label && value == other.value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// 结果描述符的封闭类型族（text/table/image/fields）。
sealed class ResultDescriptor {
  const ResultDescriptor._();

  /// kind 标签：text/table/image/fields。
  String get kind;

  /// 序列化为 JSON；首个键固定为 `kind`。
  Map<String, Object?> toJson();

  /// 从 JSON 反序列化；未知 kind 抛 [FormatException]。
  factory ResultDescriptor.fromJson(Map<String, Object?> json) {
    final kind = _requireJsonField(json, 'kind') as String;
    switch (kind) {
      case 'text':
        return TextResultDescriptor(
          text: _requireJsonField(json, 'text') as String,
        );
      case 'table':
        final columns = _stringList(_requireJsonField(json, 'columns'));
        final rows = (_requireJsonField(json, 'rows') as List<Object?>)
            .map((row) => _stringList(row as List<Object?>))
            .toList();
        return TableResultDescriptor(columns: columns, rows: rows);
      case 'image':
        return ImageResultDescriptor(
          path: _requireJsonField(json, 'path') as String,
        );
      case 'fields':
        return FieldsResultDescriptor(
          fields: (_requireJsonField(json, 'fields') as List<Object?>)
              .map(
                (field) => ResultField.fromJson(field as Map<String, Object?>),
              )
              .toList(),
        );
      default:
        throw FormatException('Unknown result kind', kind);
    }
  }
}

/// 文本结果。
final class TextResultDescriptor extends ResultDescriptor {
  /// 创建文本结果；[text] 非空白。
  TextResultDescriptor({required String text})
    : text = _requireNonBlank(text, 'text'),
      super._();

  /// 结果文本，非空白。
  final String text;

  @override
  String get kind => 'text';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'kind': kind, 'text': text};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextResultDescriptor && text == other.text;

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// 表格结果：columns 非空，rows 允许为空。
final class TableResultDescriptor extends ResultDescriptor {
  /// 创建表格结果；[columns] 非空且不含空白项。
  TableResultDescriptor({
    required List<String> columns,
    required List<List<String>> rows,
  }) : columns = _requireColumns(columns),
       rows = _snapshotRows(rows),
       super._();

  /// 列标题，非空（只读快照）。
  final List<String> columns;

  /// 数据行，每行与 [columns] 等长（只读快照）。
  final List<List<String>> rows;

  @override
  String get kind => 'table';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind,
      'columns': List<String>.of(columns),
      'rows': rows.map((row) => List<String>.of(row)).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableResultDescriptor &&
          _listsEqual(columns, other.columns) &&
          _rowsEqual(rows, other.rows);

  @override
  int get hashCode =>
      Object.hash(runtimeType, Object.hashAll(columns), Object.hashAll(rows));
}

/// 图片结果：指向宿主可访问的本地路径。
final class ImageResultDescriptor extends ResultDescriptor {
  /// 创建图片结果；[path] 非空白。
  ImageResultDescriptor({required String path})
    : path = _requireNonBlank(path, 'path'),
      super._();

  /// 图片本地路径，非空白。
  final String path;

  @override
  String get kind => 'image';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'kind': kind, 'path': path};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageResultDescriptor && path == other.path;

  @override
  int get hashCode => Object.hash(runtimeType, path);
}

/// 字段列表结果。
final class FieldsResultDescriptor extends ResultDescriptor {
  /// 创建字段列表结果；[fields] 允许为空。
  FieldsResultDescriptor({required List<ResultField> fields})
    : fields = List<ResultField>.unmodifiable(fields),
      super._();

  /// 结果字段（只读快照）。
  final List<ResultField> fields;

  @override
  String get kind => 'fields';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldsResultDescriptor && _listsEqual(fields, other.fields);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(fields));
}

List<String> _requireColumns(List<String> columns) {
  if (columns.isEmpty || columns.any((value) => value.trim().isEmpty)) {
    throw ArgumentError.value(columns, 'columns', '必须为非空列标题列表');
  }

  return List<String>.unmodifiable(columns);
}

List<List<String>> _snapshotRows(List<List<String>> rows) {
  return List<List<String>>.unmodifiable(
    rows.map((row) => List<String>.unmodifiable(row)),
  );
}

bool _rowsEqual(List<List<String>> a, List<List<String>> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (!_listsEqual(a[i], b[i])) {
      return false;
    }
  }
  return true;
}

List<String> _stringList(Object? value) {
  return (value as List<Object?>).map((value) => value as String).toList();
}

String _requireNonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, '不能为空白');
  }

  return value;
}

Object? _requireJsonField(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) {
    throw FormatException('缺少必填 JSON 键', field);
  }

  return value;
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
