import 'package:flutter/material.dart';

/// ブラシストロークを表すデータモデル（Freezed不使用版）
class BrushStroke {
  const BrushStroke({
    required this.points,
    required this.brushSize,
    required this.color,
    required this.opacity,
  });

  /// ストロークの座標点リスト
  final List<Offset> points;
  
  /// ブラシサイズ
  final double brushSize;
  
  /// ブラシの色
  final Color color;
  
  /// 透明度 (0.0 - 1.0)
  final double opacity;

  /// copyWithメソッド
  BrushStroke copyWith({
    List<Offset>? points,
    double? brushSize,
    Color? color,
    double? opacity,
  }) {
    return BrushStroke(
      points: points ?? this.points,
      brushSize: brushSize ?? this.brushSize,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrushStroke &&
        other.points.length == points.length &&
        other.brushSize == brushSize &&
        other.color == color &&
        other.opacity == opacity;
  }

  @override
  int get hashCode {
    return Object.hash(points.length, brushSize, color, opacity);
  }

  @override
  String toString() {
    return 'BrushStroke(points: ${points.length} points, brushSize: $brushSize, color: $color, opacity: $opacity)';
  }
}

/// ブラシ描画の状態を管理するデータモデル（Freezed不使用版）
class BrushState {
  const BrushState({
    this.brushSize = 20.0,
    this.strokes = const [],
    this.brushColor = Colors.yellow,
    this.opacity = 0.5,
  });

  /// 現在のブラシサイズ
  final double brushSize;
  
  /// 描画されたストロークのリスト
  final List<BrushStroke> strokes;
  
  /// ブラシの色
  final Color brushColor;
  
  /// ブラシの透明度 (0.0 - 1.0)
  final double opacity;

  /// copyWithメソッド
  BrushState copyWith({
    double? brushSize,
    List<BrushStroke>? strokes,
    Color? brushColor,
    double? opacity,
  }) {
    return BrushState(
      brushSize: brushSize ?? this.brushSize,
      strokes: strokes ?? this.strokes,
      brushColor: brushColor ?? this.brushColor,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrushState &&
        other.brushSize == brushSize &&
        other.strokes.length == strokes.length &&
        other.brushColor == brushColor &&
        other.opacity == opacity;
  }

  @override
  int get hashCode {
    return Object.hash(brushSize, strokes.length, brushColor, opacity);
  }

  @override
  String toString() {
    return 'BrushState(brushSize: $brushSize, strokes: ${strokes.length} strokes, brushColor: $brushColor, opacity: $opacity)';
  }
}