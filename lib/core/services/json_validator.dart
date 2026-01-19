library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// JSON 校验结果
class JsonValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? errorLine;
  final int? errorColumn;
  final String? errorPath;

  const JsonValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorLine,
    this.errorColumn,
    this.errorPath,
  });

  /// 成功
  factory JsonValidationResult.success() {
    return const JsonValidationResult(isValid: true);
  }

  /// 失败
  factory JsonValidationResult.failure({
    required String message,
    int? line,
    int? column,
    String? path,
  }) {
    return JsonValidationResult(
      isValid: false,
      errorMessage: message,
      errorLine: line,
      errorColumn: column,
      errorPath: path,
    );
  }

  @override
  String toString() {
    if (isValid) return 'Valid JSON';
    final location = errorLine != null ? ' (line $errorLine, column $errorColumn)' : '';
    final path = errorPath != null ? ' at $errorPath' : '';
    return 'Validation Error: $errorMessage$path$location';
  }
}

/// JSON Schema 定义
class JsonSchema {
  final String type;
  final String? description;
  final Map<String, JsonSchema>? properties;
  final JsonSchema? items;
  final bool? additionalProperties;
  final dynamic defaultValue;
  final List<dynamic>? enumValues;
  final num? minimum;
  final num? maximum;
  final bool? required;

  const JsonSchema({
    required this.type,
    this.description,
    this.properties,
    this.items,
    this.additionalProperties,
    this.defaultValue,
    this.enumValues,
    this.minimum,
    this.maximum,
    this.required,
  });

  /// 从 JSON 创建 Schema
  factory JsonSchema.fromJson(Map<String, dynamic> json) {
    return JsonSchema(
      type: json['type'] as String,
      description: json['description'] as String?,
      properties: json['properties'] != null
          ? (json['properties'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, JsonSchema.fromJson(value as Map<String, dynamic>)),
            )
          : null,
      items: json['items'] != null
          ? JsonSchema.fromJson(json['items'] as Map<String, dynamic>)
          : null,
      additionalProperties: json['additionalProperties'] as bool?,
      defaultValue: json['default'],
      enumValues: json['enum'] as List<dynamic>?,
      minimum: json['minimum'] as num?,
      maximum: json['maximum'] as num?,
      required: json['required'] as bool?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (description != null) json['description'] = description;
    if (properties != null) {
      json['properties'] = properties!.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (items != null) json['items'] = items!.toJson();
    if (additionalProperties != null) json['additionalProperties'] = additionalProperties;
    if (defaultValue != null) json['default'] = defaultValue;
    if (enumValues != null) json['enum'] = enumValues;
    if (minimum != null) json['minimum'] = minimum;
    if (maximum != null) json['maximum'] = maximum;
    if (required != null) json['required'] = required;
    return json;
  }
}

/// JSON 校验服务
class JsonValidator {
  /// 校验 JSON 字符串格式
  static JsonValidationResult validateJsonString(String jsonString) {
    try {
      // 尝试解析 JSON
      jsonDecode(jsonString);
      return JsonValidationResult.success();
    } on FormatException catch (e) {
      // 尝试提取错误位置
      final message = e.message;
      int? line, column;

      // 格式: "FormatException: Unexpected character..."
      if (message.contains('line')) {
        final match = RegExp(r'line (\d+)').firstMatch(message);
        if (match != null) {
          line = int.tryParse(match.group(1) ?? '');
        }
      }
      if (message.contains('column')) {
        final match = RegExp(r'column (\d+)').firstMatch(message);
        if (match != null) {
          column = int.tryParse(match.group(1) ?? '');
        }
      }

      return JsonValidationResult.failure(
        message: message.replaceAll('FormatException: ', ''),
        line: line,
        column: column,
      );
    } catch (e) {
      return JsonValidationResult.failure(
        message: e.toString(),
      );
    }
  }

  /// 根据 Schema 校验 JSON 数据
  static JsonValidationResult validateSchema(
    dynamic data,
    JsonSchema schema, {
    String path = '',
  }) {
    // 检查类型
    if (!_validateType(data, schema.type)) {
      return JsonValidationResult.failure(
        message: 'Expected type ${schema.type}, but got ${data.runtimeType}',
        path: path,
      );
    }

    // 检查枚举值
    if (schema.enumValues != null && !schema.enumValues!.contains(data)) {
      return JsonValidationResult.failure(
        message: 'Value must be one of: ${schema.enumValues!.join(", ")}',
        path: path,
      );
    }

    // 检查数值范围
    if (data is num) {
      if (schema.minimum != null && data < schema.minimum!) {
        return JsonValidationResult.failure(
          message: 'Value must be >= $schema.minimum',
          path: path,
        );
      }
      if (schema.maximum != null && data > schema.maximum!) {
        return JsonValidationResult.failure(
          message: 'Value must be <= $schema.maximum',
          path: path,
        );
      }
    }

    // 检查对象属性
    if (schema.type == 'object' && schema.properties != null) {
      if (data is! Map<String, dynamic>) {
        return JsonValidationResult.failure(
          message: 'Expected object, but got ${data.runtimeType}',
          path: path,
        );
      }

      for (final entry in schema.properties!.entries) {
        final key = entry.key;
        final propSchema = entry.value;

        if (data.containsKey(key)) {
          final result = validateSchema(
            data[key],
            propSchema,
            path: path.isEmpty ? key : '$path.$key',
          );
          if (!result.isValid) return result;
        } else if (propSchema.required == true) {
          return JsonValidationResult.failure(
            message: 'Missing required property: $key',
            path: path,
          );
        }
      }

      // 检查额外属性
      if (schema.additionalProperties == false) {
        for (final key in data.keys) {
          if (!schema.properties!.containsKey(key)) {
            return JsonValidationResult.failure(
              message: 'Unexpected property: $key',
              path: path,
            );
          }
        }
      }
    }

    // 检查数组项
    if (schema.type == 'array' && schema.items != null) {
      if (data is! List) {
        return JsonValidationResult.failure(
          message: 'Expected array, but got ${data.runtimeType}',
          path: path,
        );
      }

      for (int i = 0; i < data.length; i++) {
        final result = validateSchema(
          data[i],
          schema.items!,
          path: '${path}[$i]',
        );
        if (!result.isValid) return result;
      }
    }

    return JsonValidationResult.success();
  }

  /// 检查类型是否匹配
  static bool _validateType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'string':
        return value is String;
      case 'number':
      case 'integer':
        return value is num;
      case 'boolean':
        return value is bool;
      case 'object':
        return value is Map<String, dynamic>;
      case 'array':
        return value is List;
      default:
        return true;
    }
  }

  /// 格式化 JSON 字符串（美化输出）
  static String formatJson(String jsonString) {
    try {
      final dynamic data = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return jsonString; // 返回原字符串如果格式化失败
    }
  }

  /// 压缩 JSON 字符串（移除空格和换行）
  static String minifyJson(String jsonString) {
    try {
      final dynamic data = jsonDecode(jsonString);
      const encoder = JsonEncoder();
      return encoder.convert(data);
    } catch (e) {
      return jsonString;
    }
  }
}
