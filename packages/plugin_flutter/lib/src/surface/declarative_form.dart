/// 声明式表单模型：插件以数据描述表单，宿主负责渲染（规格 §9）。
///
/// [FormFieldSpec] 是封闭类型族（textField / numberField / selectField /
/// checkboxField / toggleGroup），每个字段规格均含 key、label、必填与默认值；
/// [FormDescriptor] 组合标题与字段列表，并保证字段 key 唯一。
library;

/// 表单描述符：标题 + 有序字段列表。
final class FormDescriptor {
  /// 创建表单描述符；[title] 非空白，[fields] 的 key 必须唯一。
  FormDescriptor({required String title, required List<FormFieldSpec> fields})
    : title = _requireNonBlank(title, 'title'),
      fields = _snapshotFields(fields);

  /// 表单标题，非空白。
  final String title;

  /// 按声明顺序排列的字段规格（只读快照）。
  final List<FormFieldSpec> fields;

  /// 序列化为 JSON：`{"title", "fields"}`。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }

  /// 从 JSON 反序列化；结构非法抛 [FormatException]。
  factory FormDescriptor.fromJson(Map<String, Object?> json) {
    final title = _requireJsonField(json, 'title') as String;
    final rawFields = _requireJsonField(json, 'fields') as List<Object?>;
    return FormDescriptor(
      title: title,
      fields: rawFields
          .map(
            (field) =>
                FormFieldSpec.fromJson(_requireJsonObject(field, 'fields[]')),
          )
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormDescriptor &&
          title == other.title &&
          _listsEqual(fields, other.fields);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(fields));
}

/// 表单字段规格的封闭类型族（textField/numberField/selectField/
/// checkboxField/toggleGroup）。
sealed class FormFieldSpec {
  FormFieldSpec._({
    required String key,
    required String label,
    required this.isRequired,
  }) : key = _requireNonBlank(key, 'key'),
       label = _requireNonBlank(label, 'label');

  /// 字段标识；同一表单内唯一。
  final String key;

  /// 展示标签，非空白。
  final String label;

  /// 是否必填。
  final bool isRequired;

  /// kind 标签：textField/numberField/selectField/checkboxField/toggleGroup。
  String get kind;

  /// 序列化为 JSON；首个键固定为 `kind`。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind,
      'key': key,
      'label': label,
      'required': isRequired,
    };
  }

  /// 从 JSON 反序列化；未知 kind 或缺失必填键抛 [FormatException]。
  factory FormFieldSpec.fromJson(Map<String, Object?> json) {
    final kind = _requireJsonField(json, 'kind') as String;
    final key = _requireJsonField(json, 'key') as String;
    final label = _requireJsonField(json, 'label') as String;
    final isRequired = (json['required'] as bool?) ?? false;
    switch (kind) {
      case 'textField':
        return TextFieldSpec(
          key: key,
          label: label,
          isRequired: isRequired,
          defaultValue: json['defaultValue'] as String?,
          placeholder: json['placeholder'] as String?,
        );
      case 'numberField':
        return NumberFieldSpec(
          key: key,
          label: label,
          isRequired: isRequired,
          defaultValue: json['defaultValue'] as num?,
          min: json['min'] as num?,
          max: json['max'] as num?,
        );
      case 'selectField':
        return SelectFieldSpec(
          key: key,
          label: label,
          isRequired: isRequired,
          options: _stringList(_requireJsonField(json, 'options')),
          defaultValue: json['defaultValue'] as String?,
        );
      case 'checkboxField':
        return CheckboxFieldSpec(
          key: key,
          label: label,
          isRequired: isRequired,
          defaultValue: (json['defaultValue'] as bool?) ?? false,
        );
      case 'toggleGroup':
        return ToggleGroupSpec(
          key: key,
          label: label,
          isRequired: isRequired,
          options: _stringList(_requireJsonField(json, 'options')),
          defaultValue:
              (json['defaultValue'] as List<Object?>?)
                  ?.map((value) => value as String)
                  .toList() ??
              const <String>[],
        );
      default:
        throw FormatException('Unknown form field kind', kind);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormFieldSpec &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired;

  @override
  int get hashCode => Object.hash(runtimeType, key, label, isRequired);
}

/// 单行文本字段。
final class TextFieldSpec extends FormFieldSpec {
  /// 创建文本字段；[defaultValue] 为默认文本，[placeholder] 为占位提示。
  TextFieldSpec({
    required super.key,
    required super.label,
    super.isRequired = false,
    this.defaultValue,
    this.placeholder,
  }) : super._();

  /// 默认文本。
  final String? defaultValue;

  /// 输入占位提示。
  final String? placeholder;

  @override
  String get kind => 'textField';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (placeholder != null) 'placeholder': placeholder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextFieldSpec &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue &&
          placeholder == other.placeholder;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    label,
    isRequired,
    defaultValue,
    placeholder,
  );
}

/// 数值字段（含可选范围，min/max 均为含边界）。
final class NumberFieldSpec extends FormFieldSpec {
  /// 创建数值字段。
  NumberFieldSpec({
    required super.key,
    required super.label,
    super.isRequired = false,
    this.defaultValue,
    this.min,
    this.max,
  }) : super._();

  /// 默认数值。
  final num? defaultValue;

  /// 最小值下界（含）。
  final num? min;

  /// 最大值上界（含）。
  final num? max;

  @override
  String get kind => 'numberField';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberFieldSpec &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode =>
      Object.hash(runtimeType, key, label, isRequired, defaultValue, min, max);
}

/// 单选下拉字段：options 非空。
final class SelectFieldSpec extends FormFieldSpec {
  /// 创建下拉字段；[options] 非空且不含空白项，[defaultValue] 为默认选中项。
  SelectFieldSpec({
    required super.key,
    required super.label,
    super.isRequired = false,
    required List<String> options,
    this.defaultValue,
  }) : options = _requireOptions(options),
       super._();

  /// 可选项，非空且不含空白项（只读快照）。
  final List<String> options;

  /// 默认选中项。
  final String? defaultValue;

  @override
  String get kind => 'selectField';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      'options': List<String>.of(options),
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectFieldSpec &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired &&
          _listsEqual(options, other.options) &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    label,
    isRequired,
    Object.hashAll(options),
    defaultValue,
  );
}

/// 复选字段（布尔）。
final class CheckboxFieldSpec extends FormFieldSpec {
  /// 创建复选字段；[defaultValue] 为默认勾选状态。
  CheckboxFieldSpec({
    required super.key,
    required super.label,
    super.isRequired = false,
    this.defaultValue = false,
  }) : super._();

  /// 默认勾选状态。
  final bool defaultValue;

  @override
  String get kind => 'checkboxField';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{...super.toJson(), 'defaultValue': defaultValue};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckboxFieldSpec &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode =>
      Object.hash(runtimeType, key, label, isRequired, defaultValue);
}

/// 多选开关组：options 非空，defaultValue 为选中项子集。
final class ToggleGroupSpec extends FormFieldSpec {
  /// 创建开关组；[options] 非空且不含空白项，[defaultValue] 为默认选中项。
  ToggleGroupSpec({
    required super.key,
    required super.label,
    super.isRequired = false,
    required List<String> options,
    List<String> defaultValue = const <String>[],
  }) : options = _requireOptions(options),
       defaultValue = List<String>.unmodifiable(defaultValue),
       super._();

  /// 可选项，非空且不含空白项（只读快照）。
  final List<String> options;

  /// 默认选中的选项。
  final List<String> defaultValue;

  @override
  String get kind => 'toggleGroup';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      'options': List<String>.of(options),
      'defaultValue': List<String>.of(defaultValue),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleGroupSpec &&
          key == other.key &&
          label == other.label &&
          isRequired == other.isRequired &&
          _listsEqual(options, other.options) &&
          _listsEqual(defaultValue, other.defaultValue);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    label,
    isRequired,
    Object.hashAll(options),
    Object.hashAll(defaultValue),
  );
}

List<String> _requireOptions(List<String> options) {
  if (options.isEmpty || options.any((value) => value.trim().isEmpty)) {
    throw ArgumentError.value(options, 'options', '必须为非空选项列表');
  }

  return List<String>.unmodifiable(options);
}

List<String> _stringList(Object? value) {
  return (value as List<Object?>).map((value) => value as String).toList();
}

List<FormFieldSpec> _snapshotFields(List<FormFieldSpec> fields) {
  final seen = <String>{};
  if (fields.any((field) => !seen.add(field.key))) {
    throw ArgumentError.value(fields, 'fields', '字段 key 必须唯一');
  }

  return List<FormFieldSpec>.unmodifiable(fields);
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

Map<String, Object?> _requireJsonObject(Object? value, String field) {
  if (value is! Map<String, Object?>) {
    throw FormatException('期望 JSON 对象', field);
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
