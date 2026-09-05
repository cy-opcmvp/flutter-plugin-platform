/// 声明式表单渲染器。
///
/// 按 [FormDescriptor] 渲染五种字段（文本 / 数字 / 下拉 / 复选 / 开关组），
/// 提供必填校验与数字范围校验，校验通过后一次性回填报值。
/// 输入框形态随主题方向差异化（冻结美术文档「FormRenderer」条目）：
/// - warm_life：填充式输入框（亚麻底、无描边、聚焦出现主色焦点环）。
/// - precision_tools / dark_pro：hairline 描边式输入框，聚焦描边换主色。
library;

import 'package:flutter/material.dart';

import '../generated/plugin_flutter_l10n.dart';
import '../surface/declarative_form.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'token_text_style.dart';

/// 声明式表单渲染器。
class FormRenderer extends StatefulWidget {
  /// 创建渲染器；[onSubmit] 仅在校验全部通过后回调一次。
  const FormRenderer({
    super.key,
    required this.descriptor,
    required this.onSubmit,
  });

  /// 表单描述符。
  final FormDescriptor descriptor;

  /// 提交回调：键为字段 key，值为按字段类型回填（String/num/bool/List）。
  final ValueChanged<Map<String, Object?>> onSubmit;

  @override
  State<FormRenderer> createState() => _FormRendererState();
}

class _FormRendererState extends State<FormRenderer> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, String?> _errors = <String, String?>{};
  final Map<String, String?> _selectValues = <String, String?>{};
  final Map<String, bool> _checkboxValues = <String, bool>{};
  final Map<String, Set<String>> _toggleValues = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(covariant FormRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.descriptor != widget.descriptor) {
      _seed();
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 按描述符播种默认值。
  void _seed() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _errors.clear();
    _selectValues.clear();
    _checkboxValues.clear();
    _toggleValues.clear();
    for (final FormFieldSpec field in widget.descriptor.fields) {
      switch (field) {
        case TextFieldSpec spec:
          _controllers[spec.key] = TextEditingController(
            text: spec.defaultValue ?? '',
          );
        case NumberFieldSpec spec:
          _controllers[spec.key] = TextEditingController(
            text: spec.defaultValue?.toString() ?? '',
          );
        case SelectFieldSpec spec:
          _selectValues[spec.key] = spec.defaultValue ?? spec.options.first;
        case CheckboxFieldSpec spec:
          _checkboxValues[spec.key] = spec.defaultValue;
        case ToggleGroupSpec spec:
          _toggleValues[spec.key] = Set<String>.from(spec.defaultValue);
      }
    }
  }

  void _handleSubmit() {
    final l10n = PluginFlutterL10n.of(context);
    final values = <String, Object?>{};
    final errors = <String, String?>{};
    for (final FormFieldSpec field in widget.descriptor.fields) {
      switch (field) {
        case TextFieldSpec spec:
          final String text = _controllers[spec.key]!.text.trim();
          if (text.isEmpty && spec.isRequired) {
            errors[spec.key] = l10n.formRequiredError;
          } else {
            values[spec.key] = text;
          }
        case NumberFieldSpec spec:
          _validateNumber(spec, l10n, values, errors);
        case SelectFieldSpec spec:
          final String? picked = _selectValues[spec.key];
          if ((picked == null || picked.isEmpty) && spec.isRequired) {
            errors[spec.key] = l10n.formRequiredError;
          } else {
            values[spec.key] = picked;
          }
        case CheckboxFieldSpec spec:
          final bool checked = _checkboxValues[spec.key] ?? spec.defaultValue;
          // 必填复选按「必须勾选」处理（如同意条款）。
          if (spec.isRequired && !checked) {
            errors[spec.key] = l10n.formRequiredError;
          } else {
            values[spec.key] = checked;
          }
        case ToggleGroupSpec spec:
          final List<String> selected = List<String>.from(
            _toggleValues[spec.key] ?? const <String>{},
          );
          if (spec.isRequired && selected.isEmpty) {
            errors[spec.key] = l10n.formRequiredError;
          } else {
            values[spec.key] = selected;
          }
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isEmpty) {
      widget.onSubmit(Map<String, Object?>.unmodifiable(values));
    }
  }

  /// 数字字段校验：空值看必填；非空解析 + 范围三态错误。
  void _validateNumber(
    NumberFieldSpec spec,
    PluginFlutterL10n l10n,
    Map<String, Object?> values,
    Map<String, String?> errors,
  ) {
    final String raw = _controllers[spec.key]!.text.trim();
    if (raw.isEmpty) {
      if (spec.isRequired) {
        errors[spec.key] = l10n.formRequiredError;
      } else {
        values[spec.key] = null;
      }
      return;
    }
    final num? parsed = num.tryParse(raw);
    if (parsed == null) {
      errors[spec.key] = l10n.formInvalidNumber;
      return;
    }
    final num? min = spec.min;
    final num? max = spec.max;
    if (min != null && max != null) {
      if (parsed < min || parsed > max) {
        errors[spec.key] = l10n.formNumberRange(min.toString(), max.toString());
        return;
      }
    } else if (min != null && parsed < min) {
      errors[spec.key] = l10n.formNumberMin(min.toString());
      return;
    } else if (max != null && parsed > max) {
      errors[spec.key] = l10n.formNumberMax(max.toString());
      return;
    }
    values[spec.key] = parsed;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = PluginFlutterL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(descriptorTitle(), style: theme.textTheme.titleLarge),
        SizedBox(height: ThemeTokens.of(context).spacing.space3),
        for (final FormFieldSpec field in widget.descriptor.fields) ...<Widget>[
          _buildField(context, field),
          SizedBox(height: ThemeTokens.of(context).spacing.space3),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _handleSubmit,
            child: Text(l10n.formSubmit),
          ),
        ),
      ],
    );
  }

  String descriptorTitle() => widget.descriptor.title;

  Widget _buildField(BuildContext context, FormFieldSpec field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _fieldLabel(context, field),
        SizedBox(height: ThemeTokens.of(context).spacing.space1),
        switch (field) {
          TextFieldSpec spec => _buildTextField(context, spec),
          NumberFieldSpec spec => _buildNumberField(context, spec),
          SelectFieldSpec spec => _buildSelectField(context, spec),
          CheckboxFieldSpec spec => _buildCheckboxField(context, spec),
          ToggleGroupSpec spec => _buildToggleGroup(context, spec),
        },
        if (_errorOf(field.key) != null && _usesDecorationError(field))
          _errorText(context, _errorOf(field.key)!),
      ],
    );
  }

  String? _errorOf(String key) => _errors[key];

  /// 复选与开关组的错误不走 InputDecoration，需要手动展示。
  bool _usesDecorationError(FormFieldSpec field) =>
      field is CheckboxFieldSpec || field is ToggleGroupSpec;

  Widget _fieldLabel(BuildContext context, FormFieldSpec field) {
    final ThemeData theme = Theme.of(context);
    final l10n = PluginFlutterL10n.of(context);
    final tokens = ThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(field.label, style: theme.textTheme.titleSmall)),
        if (field.isRequired) ...<Widget>[
          SizedBox(width: tokens.spacing.space1),
          Text(
            l10n.formRequiredMark,
            style: buildTokenTextStyle(
              tokens.typography.label,
              familyChain: tokens.typography.family,
              color: tokens.color.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(BuildContext context, TextFieldSpec spec) {
    return TextFormField(
      controller: _controllers[spec.key],
      decoration: _inputDecoration(
        context,
        errorText: _errorOf(spec.key),
      ).copyWith(hintText: spec.placeholder),
    );
  }

  Widget _buildNumberField(BuildContext context, NumberFieldSpec spec) {
    return TextFormField(
      controller: _controllers[spec.key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(context, errorText: _errorOf(spec.key)),
    );
  }

  Widget _buildSelectField(BuildContext context, SelectFieldSpec spec) {
    return DropdownButtonFormField<String>(
      initialValue: _selectValues[spec.key],
      items: <DropdownMenuItem<String>>[
        for (final String option in spec.options)
          DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: (String? value) {
        setState(() => _selectValues[spec.key] = value);
      },
      decoration: _inputDecoration(context, errorText: _errorOf(spec.key)),
    );
  }

  Widget _buildCheckboxField(BuildContext context, CheckboxFieldSpec spec) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _checkboxValues[spec.key] ?? spec.defaultValue,
      onChanged: (bool? value) {
        setState(() => _checkboxValues[spec.key] = value ?? false);
      },
      title: Text(spec.label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildToggleGroup(BuildContext context, ToggleGroupSpec spec) {
    final Set<String> selected =
        _toggleValues[spec.key] ?? Set<String>.from(spec.defaultValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String option in spec.options)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: selected.contains(option),
            onChanged: (bool value) {
              setState(() {
                final Set<String> next = Set<String>.from(selected);
                if (value) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
                _toggleValues[spec.key] = next;
              });
            },
            title: Text(option, style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    );
  }

  Widget _errorText(BuildContext context, String message) {
    final tokens = ThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.space1),
      child: Text(
        message,
        style: buildTokenTextStyle(
          tokens.typography.label,
          familyChain: tokens.typography.family,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  /// 按方向构建输入框装饰：warm_life 填充式，其余描边式。
  InputDecoration _inputDecoration(BuildContext context, {String? errorText}) {
    final tokens = ThemeTokens.of(context);
    final colors = tokens.color;
    final shape = tokens.shape;
    final BorderRadius radius = BorderRadius.circular(shape.radiusSm);
    final OutlineInputBorder border;
    final OutlineInputBorder focusedBorder;
    switch (tokens.preset) {
      case AppThemePreset.warmLife:
        // 亚麻底填充、无描边；聚焦出现主色焦点环。
        final OutlineInputBorder invisible = OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        );
        border = invisible;
        focusedBorder = OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colors.primary,
            width: shape.strokeFocus,
          ),
        );
        return InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.surfaceVariant,
          errorText: errorText,
          border: border,
          enabledBorder: invisible,
          focusedBorder: focusedBorder,
        );
      case AppThemePreset.precisionTools:
      case AppThemePreset.darkPro:
        border = OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colors.outlineVariant,
            width: shape.strokeHairline,
          ),
        );
        focusedBorder = OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colors.primary,
            width: shape.strokeFocus,
          ),
        );
        return InputDecoration(
          isDense: true,
          errorText: errorText,
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
        );
    }
  }
}
