import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/leonardo_ai/brush_state.dart';
import '../utils/app_logger.dart';

/// マスク画像生成ユーティリティクラス
///
/// ブラシストロークから白黒マスク画像を生成し、JPEG形式でエンコードする
class MaskImageGenerator {
  /// ブラシストロークから白黒マスク画像を生成
  ///
  /// [strokes] ブラシストロークのリスト
  /// [canvasSize] キャンバスのサイズ
  /// [imageSize] 実際の画像のサイズ（オプション）
  /// [quality] JPEG品質（1-100、デフォルト: 90）
  static Future<Uint8List> generateMaskFromStrokes({
    required List<BrushStroke> strokes,
    required Size canvasSize,
    Size? imageSize,
    int quality = 90,
  }) async {
    try {
      AppLogger.d(
        'マスク画像生成開始: strokes=${strokes.length}, canvasSize=$canvasSize',
      );

      // 実際の画像サイズが指定されていない場合はキャンバスサイズを使用
      final targetSize = imageSize ?? canvasSize;
      final width = targetSize.width.toInt();
      final height = targetSize.height.toInt();

      // 画像を作成（黒背景）
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(0, 0, 0)); // 黒で初期化

      // スケール比を計算（キャンバス座標を画像座標に変換するため）
      final scaleX = targetSize.width / canvasSize.width;
      final scaleY = targetSize.height / canvasSize.height;

      // 各ストロークを白で描画
      for (final stroke in strokes) {
        await _drawStrokeOnImage(image, stroke, scaleX, scaleY);
      }

      // JPEG形式でエンコード
      final jpegBytes = img.encodeJpg(image, quality: quality);

      AppLogger.d('マスク画像生成完了: size=${jpegBytes.length} bytes');
      return Uint8List.fromList(jpegBytes);
    } catch (e, stackTrace) {
      AppLogger.e('マスク画像生成でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// ストロークを画像に描画
  static Future<void> _drawStrokeOnImage(
    img.Image image,
    BrushStroke stroke,
    double scaleX,
    double scaleY,
  ) async {
    if (stroke.points.isEmpty) return;

    final scaledBrushSize = stroke.brushSize * math.min(scaleX, scaleY);

    if (stroke.points.length == 1) {
      // 単一点の場合は円を描画
      final scaledPoint = Offset(
        stroke.points.first.dx * scaleX,
        stroke.points.first.dy * scaleY,
      );
      _drawCircleOnImage(image, scaledPoint, scaledBrushSize / 2);
    } else {
      // 複数点の場合は線を描画
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final start = Offset(
          stroke.points[i].dx * scaleX,
          stroke.points[i].dy * scaleY,
        );
        final end = Offset(
          stroke.points[i + 1].dx * scaleX,
          stroke.points[i + 1].dy * scaleY,
        );

        _drawLineOnImage(image, start, end, scaledBrushSize);
      }

      // 各点にも円を描画してより滑らかにする
      for (final point in stroke.points) {
        final scaledPoint = Offset(point.dx * scaleX, point.dy * scaleY);
        _drawCircleOnImage(image, scaledPoint, scaledBrushSize / 2);
      }
    }
  }

  /// 線を画像に描画
  static void _drawLineOnImage(
    img.Image image,
    Offset start,
    Offset end,
    double brushSize,
  ) {
    final radius = brushSize / 2;
    final distance = (end - start).distance;
    final steps = (distance / 2).ceil().clamp(1, 1000); // 最大ステップ数を制限

    for (int step = 0; step <= steps; step++) {
      final t = steps > 0 ? step / steps : 0.0;
      final point = Offset.lerp(start, end, t)!;
      _drawCircleOnImage(image, point, radius);
    }
  }

  /// 円を画像に描画（アンチエイリアシング付き）
  static void _drawCircleOnImage(
    img.Image image,
    Offset center,
    double radius,
  ) {
    final centerX = center.dx;
    final centerY = center.dy;
    // Calculate bounding box for the circle

    // 円の境界ボックスを計算
    final minX = (centerX - radius).floor().clamp(0, image.width - 1);
    final maxX = (centerX + radius).ceil().clamp(0, image.width - 1);
    final minY = (centerY - radius).floor().clamp(0, image.height - 1);
    final maxY = (centerY + radius).ceil().clamp(0, image.height - 1);

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance <= radius) {
          // アンチエイリアシングのための透明度計算
          double alpha = 1.0;
          if (distance > radius - 1) {
            alpha = radius - distance;
            alpha = alpha.clamp(0.0, 1.0);
          }

          // 既存のピクセル値と合成
          final existingPixel = image.getPixel(x, y);
          final existingAlpha = existingPixel.a / 255.0;
          final newAlpha = math.min(1.0, existingAlpha + alpha);

          // 白色で描画
          final newColor = img.ColorRgba8(
            255, // R
            255, // G
            255, // B
            (newAlpha * 255).round(), // A
          );

          image.setPixel(x, y, newColor);
        }
      }
    }
  }

  /// 空のマスク画像を生成（全て黒）
  ///
  /// [canvasSize] キャンバスのサイズ
  /// [quality] JPEG品質（1-100、デフォルト: 90）
  static Future<Uint8List> generateEmptyMask(
    Size canvasSize, {
    int quality = 90,
  }) async {
    try {
      AppLogger.d('空のマスク画像生成: canvasSize=$canvasSize');

      final width = canvasSize.width.toInt();
      final height = canvasSize.height.toInt();

      // 黒い画像を作成
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(0, 0, 0)); // 黒で塗りつぶし

      // JPEG形式でエンコード
      final jpegBytes = img.encodeJpg(image, quality: quality);

      AppLogger.d('空のマスク画像生成完了: size=${jpegBytes.length} bytes');
      return Uint8List.fromList(jpegBytes);
    } catch (e, stackTrace) {
      AppLogger.e('空のマスク画像生成でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// Canvas座標系から画像座標系に変換
  static Offset canvasToImageCoordinate(
    Offset canvasPoint,
    Size canvasSize,
    Size imageSize,
  ) {
    final scaleX = imageSize.width / canvasSize.width;
    final scaleY = imageSize.height / canvasSize.height;

    return Offset(canvasPoint.dx * scaleX, canvasPoint.dy * scaleY);
  }

  /// 画像座標系からCanvas座標系に変換
  static Offset imageToCanvasCoordinate(
    Offset imagePoint,
    Size imageSize,
    Size canvasSize,
  ) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;

    return Offset(imagePoint.dx * scaleX, imagePoint.dy * scaleY);
  }

  /// マスク画像をプレビュー用のUIImageに変換
  static Future<ui.Image> createPreviewImage({
    required List<BrushStroke> strokes,
    required Size canvasSize,
    Color maskColor = Colors.yellow,
    double opacity = 0.5,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 透明な背景
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.transparent,
      );

      // ストロークを描画
      for (final stroke in strokes) {
        _drawStrokeOnCanvas(
          canvas,
          stroke,
          maskColor.withValues(alpha: opacity * 255),
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );

      picture.dispose();
      return image;
    } catch (e, stackTrace) {
      AppLogger.e('プレビュー画像生成でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// ストロークをCanvasに描画
  static void _drawStrokeOnCanvas(
    Canvas canvas,
    BrushStroke stroke,
    Color color,
  ) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.brushSize
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      // 単一点の場合は円を描画
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(stroke.points.first, stroke.brushSize / 2, circlePaint);
    } else {
      // 複数点の場合はパスを描画
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);

      // 各点にも円を描画
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in stroke.points) {
        canvas.drawCircle(point, stroke.brushSize / 2, circlePaint);
      }
    }
  }
}
