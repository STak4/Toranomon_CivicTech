import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/leonardo_ai/brush_state.dart';
import '../utils/brush_drawing_optimizer.dart';

/// ブラシ描画用のカスタムペインター
///
/// 背景画像、ブラシストローク、半透明黄色マスクの描画を行う
class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.backgroundImage,
    required this.strokes,
    required this.brushSize,
    required this.brushColor,
    this.showMask = true,
  });

  /// 背景画像
  final ui.Image backgroundImage;

  /// ブラシストロークのリスト
  final List<BrushStroke> strokes;

  /// 現在のブラシサイズ
  final double brushSize;

  /// ブラシの色
  final Color brushColor;

  /// マスクを表示するかどうか
  final bool showMask;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 背景画像を描画
    _drawBackgroundImage(canvas, size);

    // 2. ブラシストロークを描画（半透明黄色マスク）
    if (showMask) {
      _drawBrushStrokes(canvas, size);
    }
  }

  /// 背景画像を描画
  void _drawBackgroundImage(Canvas canvas, Size size) {
    final imageSize = Size(
      backgroundImage.width.toDouble(),
      backgroundImage.height.toDouble(),
    );

    // 画像をキャンバスサイズに合わせてスケール（アスペクト比を保持）
    final scale = _calculateScale(imageSize, size);
    final scaledSize = Size(imageSize.width * scale, imageSize.height * scale);

    // 中央に配置するためのオフセット
    final offset = Offset(
      (size.width - scaledSize.width) / 2,
      (size.height - scaledSize.height) / 2,
    );

    final destRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      scaledSize.width,
      scaledSize.height,
    );

    final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);

    // 背景画像を描画
    canvas.drawImageRect(
      backgroundImage,
      srcRect,
      destRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  /// 適切なスケール値を計算（アスペクト比を保持）
  double _calculateScale(Size imageSize, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    // 小さい方のスケールを使用してアスペクト比を保持
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// ブラシストロークを半透明黄色マスクとして描画
  void _drawBrushStrokes(Canvas canvas, Size size) {
    // 描画品質を動的に計算
    final totalPoints = strokes.fold<int>(
      0,
      (sum, stroke) => sum + stroke.points.length,
    );
    final quality = BrushDrawingOptimizer.calculateOptimalQuality(totalPoints, size);
    
    // ストロークを最適化
    final optimizedStrokes = BrushDrawingOptimizer.optimizeStrokes(strokes, size);
    
    for (final stroke in optimizedStrokes) {
      _drawOptimizedStroke(canvas, stroke, quality);
    }
  }

  /// 最適化されたストロークを描画
  void _drawOptimizedStroke(Canvas canvas, BrushStroke stroke, DrawingQuality quality) {
    if (stroke.points.isEmpty) return;

    final yellowColor = Colors.yellow.withValues(alpha: stroke.opacity * 255);
    
    if (stroke.points.length == 1) {
      // 単一点の場合は円を描画
      final circlePaint = Paint()
        ..color = yellowColor
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver
        ..isAntiAlias = quality != DrawingQuality.low;

      canvas.drawCircle(stroke.points.first, stroke.brushSize / 2, circlePaint);
    } else {
      // 最適化されたパスを使用
      final path = BrushDrawingOptimizer.createOptimizedSmoothPath(
        stroke.points,
        stroke.brushSize,
      );

      final paint = Paint()
        ..color = yellowColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver
        ..isAntiAlias = quality != DrawingQuality.low;

      canvas.drawPath(path, paint);

      // 高品質モードでは各点に円も描画
      if (quality == DrawingQuality.high) {
        final circlePaint = Paint()
          ..color = yellowColor
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.srcOver
          ..isAntiAlias = true;

        for (final point in stroke.points) {
          canvas.drawCircle(point, stroke.brushSize / 2, circlePaint);
        }
      }
    }
  }



  /// 画像の表示領域を取得
  Rect getImageDisplayRect(Size canvasSize) {
    final imageSize = Size(
      backgroundImage.width.toDouble(),
      backgroundImage.height.toDouble(),
    );

    final scale = _calculateScale(imageSize, canvasSize);
    final scaledSize = Size(imageSize.width * scale, imageSize.height * scale);

    final offset = Offset(
      (canvasSize.width - scaledSize.width) / 2,
      (canvasSize.height - scaledSize.height) / 2,
    );

    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      scaledSize.width,
      scaledSize.height,
    );
  }

  /// キャンバス座標を画像座標に変換
  Offset canvasToImageCoordinate(Offset canvasPoint, Size canvasSize) {
    final imageRect = getImageDisplayRect(canvasSize);

    // キャンバス座標が画像領域外の場合は最も近い点を返す
    final clampedPoint = Offset(
      canvasPoint.dx.clamp(imageRect.left, imageRect.right),
      canvasPoint.dy.clamp(imageRect.top, imageRect.bottom),
    );

    // 画像座標系に変換
    final relativeX = (clampedPoint.dx - imageRect.left) / imageRect.width;
    final relativeY = (clampedPoint.dy - imageRect.top) / imageRect.height;

    return Offset(
      relativeX * backgroundImage.width,
      relativeY * backgroundImage.height,
    );
  }

  /// 画像座標をキャンバス座標に変換
  Offset imageToCanvasCoordinate(Offset imagePoint, Size canvasSize) {
    final imageRect = getImageDisplayRect(canvasSize);

    final relativeX = imagePoint.dx / backgroundImage.width;
    final relativeY = imagePoint.dy / backgroundImage.height;

    return Offset(
      imageRect.left + relativeX * imageRect.width,
      imageRect.top + relativeY * imageRect.height,
    );
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return backgroundImage != oldDelegate.backgroundImage ||
        strokes != oldDelegate.strokes ||
        brushSize != oldDelegate.brushSize ||
        brushColor != oldDelegate.brushColor ||
        showMask != oldDelegate.showMask;
  }

  @override
  bool hitTest(Offset position) => true;
}
