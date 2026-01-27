library;

import 'dart:ui';
import 'screenshot_models.dart';

/// 标注类型枚举
enum AnnotationType {
  /// 矩形
  rectangle,

  /// 箭头
  arrow,

  /// 文字
  text,

  /// 马赛克
  mosaic,

  /// 画笔（自由绘制）
  pen,
}

/// 标注基类
abstract class Annotation {
  /// 唯一标识符
  final String id;

  /// 标注类型
  final AnnotationType type;

  /// 创建时间
  final DateTime createdAt;

  /// 颜色
  final Color color;

  /// 线条宽度
  final double strokeWidth;

  Annotation({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.color,
    required this.strokeWidth,
  });

  /// 从 JSON 创建实例（工厂方法）
  factory Annotation.fromJson(Map<String, dynamic> json) {
    final type = AnnotationType.values.firstWhere(
      (e) => e.name == json['type'] as String,
      orElse: () => AnnotationType.pen,
    );

    switch (type) {
      case AnnotationType.rectangle:
        return RectangleAnnotation.fromJson(json);
      case AnnotationType.arrow:
        return ArrowAnnotation.fromJson(json);
      case AnnotationType.text:
        return TextAnnotation.fromJson(json);
      case AnnotationType.mosaic:
        return MosaicAnnotation.fromJson(json);
      case AnnotationType.pen:
        return PenAnnotation.fromJson(json);
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson();

  /// 验证标注是否有效
  bool isValid() => true;
}

/// 矩形标注
class RectangleAnnotation extends Annotation {
  /// 矩形区域
  final Rect rect;

  /// 是否填充
  final bool filled;

  RectangleAnnotation({
    required super.id,
    required this.rect,
    required super.color,
    required this.filled,
    super.strokeWidth = 2.0,
    DateTime? createdAt,
  }) : super(
         type: AnnotationType.rectangle,
         createdAt: createdAt ?? DateTime.now(),
       );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'filled': filled,
      ...rect.toJson(),
    };
  }

  factory RectangleAnnotation.fromJson(Map<String, dynamic> json) {
    return RectangleAnnotation(
      id: json['id'] as String,
      rect: Rect.fromJson(json),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      filled: json['filled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 箭头标注
class ArrowAnnotation extends Annotation {
  /// 起始点（相对于图片）
  final Offset start;

  /// 结束点（相对于图片）
  final Offset end;

  /// 箭头头部大小
  final double arrowSize;

  ArrowAnnotation({
    required super.id,
    required this.start,
    required this.end,
    required super.color,
    super.strokeWidth = 3.0,
    this.arrowSize = 10.0,
    DateTime? createdAt,
  }) : super(
         type: AnnotationType.arrow,
         createdAt: createdAt ?? DateTime.now(),
       );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'arrowSize': arrowSize,
      'start': {'dx': start.dx, 'dy': start.dy},
      'end': {'dx': end.dx, 'dy': end.dy},
    };
  }

  factory ArrowAnnotation.fromJson(Map<String, dynamic> json) {
    final startData = json['start'] as Map<String, dynamic>;
    final endData = json['end'] as Map<String, dynamic>;
    return ArrowAnnotation(
      id: json['id'] as String,
      start: Offset(
        (startData['dx'] as num).toDouble(),
        (startData['dy'] as num).toDouble(),
      ),
      end: Offset(
        (endData['dx'] as num).toDouble(),
        (endData['dy'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      arrowSize: (json['arrowSize'] as num?)?.toDouble() ?? 10.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 文字标注
class TextAnnotation extends Annotation {
  /// 文字内容
  final String text;

  /// 位置（相对于图片）
  final Offset position;

  /// 字体大小
  final double fontSize;

  /// 字体 family
  final String? fontFamily;

  /// 是否加粗
  final bool bold;

  /// 是否斜体
  final bool italic;

  /// 背景色（可选）
  final Color? backgroundColor;

  TextAnnotation({
    required super.id,
    required this.text,
    required this.position,
    required super.color,
    this.fontSize = 16.0,
    this.fontFamily,
    this.bold = false,
    this.italic = false,
    this.backgroundColor,
    DateTime? createdAt,
  }) : super(
         type: AnnotationType.text,
         createdAt: createdAt ?? DateTime.now(),
         strokeWidth: 0,
       );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'color': color.toARGB32(),
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'bold': bold,
      'italic': italic,
      'backgroundColor': backgroundColor?.toARGB32(),
    };
  }

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    final positionData = json['position'] as Map<String, dynamic>;
    return TextAnnotation(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Offset(
        (positionData['dx'] as num).toDouble(),
        (positionData['dy'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontFamily: json['fontFamily'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool isValid() => text.isNotEmpty;
}

/// 马赛克标注
class MosaicAnnotation extends Annotation {
  /// 马赛克区域
  final Rect rect;

  /// 马赛克块大小
  final double blockSize;

  MosaicAnnotation({
    required super.id,
    required this.rect,
    this.blockSize = 10.0,
    DateTime? createdAt,
  }) : super(
         type: AnnotationType.mosaic,
         createdAt: createdAt ?? DateTime.now(),
         color: const Color(0x00000000),
         strokeWidth: 0,
       );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'blockSize': blockSize,
      ...rect.toJson(),
    };
  }

  factory MosaicAnnotation.fromJson(Map<String, dynamic> json) {
    return MosaicAnnotation(
      id: json['id'] as String,
      rect: Rect.fromJson(json),
      blockSize: (json['blockSize'] as num?)?.toDouble() ?? 10.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 画笔标注（自由绘制）
class PenAnnotation extends Annotation {
  /// 路径点列表
  final List<Offset> points;

  /// 是否闭合路径
  final bool closed;

  PenAnnotation({
    required super.id,
    required this.points,
    required super.color,
    super.strokeWidth = 3.0,
    this.closed = false,
    DateTime? createdAt,
  }) : super(type: AnnotationType.pen, createdAt: createdAt ?? DateTime.now());

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'closed': closed,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory PenAnnotation.fromJson(Map<String, dynamic> json) {
    final pointsData = json['points'] as List;
    return PenAnnotation(
      id: json['id'] as String,
      points: pointsData
          .map(
            (p) => Offset(
              (p['dx'] as num).toDouble(),
              (p['dy'] as num).toDouble(),
            ),
          )
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      closed: json['closed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool isValid() => points.isNotEmpty;
}
