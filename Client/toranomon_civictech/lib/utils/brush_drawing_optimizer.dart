import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/leonardo_ai/brush_state.dart';
import 'app_logger.dart';

/// ブラシ描画パフォーマンス最適化ユーティリティ
class BrushDrawingOptimizer {
  /// ストロークの最大点数（パフォーマンス制限）
  static const int maxPointsPerStroke = 1000;
  
  /// 点の間隔の最小距離（ピクセル）
  static const double minPointDistance = 2.0;
  
  /// 描画品質レベル
  static const int highQualityThreshold = 500; // 点数がこれ以下なら高品質
  static const int mediumQualityThreshold = 1000; // 点数がこれ以下なら中品質
  
  /// ストロークキャッシュ
  static final Map<String, ui.Path> _pathCache = {};
  static final Map<String, List<Offset>> _optimizedPointsCache = {};
  
  /// 最大キャッシュサイズ
  static const int maxCacheSize = 50;

  /// ストロークを最適化
  /// 
  /// [stroke] 最適化対象のストローク
  /// [canvasSize] キャンバスサイズ
  /// Returns 最適化されたストローク
  static BrushStroke optimizeStroke(BrushStroke stroke, Size canvasSize) {
    if (stroke.points.isEmpty) return stroke;
    
    try {
      // 点数が少ない場合はそのまま返す
      if (stroke.points.length <= 10) {
        return stroke;
      }
      
      // キャッシュキーを生成
      final cacheKey = _generateStrokeCacheKey(stroke);
      
      // キャッシュから取得を試行
      if (_optimizedPointsCache.containsKey(cacheKey)) {
        final cachedPoints = _optimizedPointsCache[cacheKey]!;
        return stroke.copyWith(points: cachedPoints);
      }
      
      // 点を最適化
      final optimizedPoints = _optimizePoints(stroke.points, canvasSize);
      
      // キャッシュに保存
      _cacheOptimizedPoints(cacheKey, optimizedPoints);
      
      AppLogger.d(
        'ストローク最適化: ${stroke.points.length} -> ${optimizedPoints.length} points',
      );
      
      return stroke.copyWith(points: optimizedPoints);
    } catch (e) {
      AppLogger.e('ストローク最適化でエラー: $e');
      return stroke;
    }
  }

  /// 複数のストロークを最適化
  /// 
  /// [strokes] 最適化対象のストロークリスト
  /// [canvasSize] キャンバスサイズ
  /// Returns 最適化されたストロークリスト
  static List<BrushStroke> optimizeStrokes(
    List<BrushStroke> strokes,
    Size canvasSize,
  ) {
    if (strokes.isEmpty) return strokes;
    
    try {
      final optimizedStrokes = <BrushStroke>[];
      
      for (final stroke in strokes) {
        final optimizedStroke = optimizeStroke(stroke, canvasSize);
        optimizedStrokes.add(optimizedStroke);
      }
      
      AppLogger.d('複数ストローク最適化完了: ${strokes.length} strokes');
      return optimizedStrokes;
    } catch (e) {
      AppLogger.e('複数ストローク最適化でエラー: $e');
      return strokes;
    }
  }

  /// 滑らかなパスを生成（最適化版）
  /// 
  /// [points] パスの点リスト
  /// [brushSize] ブラシサイズ
  /// Returns 最適化された滑らかなパス
  static ui.Path createOptimizedSmoothPath(
    List<Offset> points,
    double brushSize,
  ) {
    if (points.isEmpty) return ui.Path();
    
    try {
      // キャッシュキーを生成
      final cacheKey = _generatePathCacheKey(points, brushSize);
      
      // キャッシュから取得を試行
      if (_pathCache.containsKey(cacheKey)) {
        return _pathCache[cacheKey]!;
      }
      
      final path = ui.Path();
      
      if (points.length == 1) {
        // 単一点の場合は小さな円
        final radius = brushSize / 4;
        path.addOval(Rect.fromCircle(center: points.first, radius: radius));
      } else if (points.length == 2) {
        // 2点の場合は直線
        path.moveTo(points.first.dx, points.first.dy);
        path.lineTo(points.last.dx, points.last.dy);
      } else {
        // 3点以上の場合はベジェ曲線で滑らかに
        path.moveTo(points.first.dx, points.first.dy);
        
        // 品質レベルに応じて処理を調整
        if (points.length <= highQualityThreshold) {
          _createHighQualityPath(path, points);
        } else if (points.length <= mediumQualityThreshold) {
          _createMediumQualityPath(path, points);
        } else {
          _createLowQualityPath(path, points);
        }
      }
      
      // キャッシュに保存
      _cacheOptimizedPath(cacheKey, path);
      
      return path;
    } catch (e) {
      AppLogger.e('最適化パス生成でエラー: $e');
      // エラー時は基本的なパスを返す
      return _createBasicPath(points);
    }
  }

  /// 描画品質を動的に調整
  /// 
  /// [totalPoints] 総点数
  /// [canvasSize] キャンバスサイズ
  /// Returns 推奨品質レベル
  static DrawingQuality calculateOptimalQuality(
    int totalPoints,
    Size canvasSize,
  ) {
    try {
      // キャンバスサイズを考慮した調整
      final canvasArea = canvasSize.width * canvasSize.height;
      final normalizedArea = canvasArea / (1024 * 1024); // 1024x1024を基準
      
      // 正規化された点数を計算
      final normalizedPoints = totalPoints / normalizedArea;
      
      if (normalizedPoints <= highQualityThreshold) {
        return DrawingQuality.high;
      } else if (normalizedPoints <= mediumQualityThreshold) {
        return DrawingQuality.medium;
      } else {
        return DrawingQuality.low;
      }
    } catch (e) {
      AppLogger.e('品質計算でエラー: $e');
      return DrawingQuality.medium;
    }
  }

  /// 点を最適化（間引き処理）
  static List<Offset> _optimizePoints(List<Offset> points, Size canvasSize) {
    if (points.length <= 10) return points;
    
    final optimizedPoints = <Offset>[points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final last = optimizedPoints.last;
      
      // 最小距離チェック
      final distance = (current - last).distance;
      if (distance >= minPointDistance) {
        optimizedPoints.add(current);
      }
      
      // 最大点数制限
      if (optimizedPoints.length >= maxPointsPerStroke) {
        break;
      }
    }
    
    // 最後の点は必ず追加
    if (points.isNotEmpty && optimizedPoints.last != points.last) {
      optimizedPoints.add(points.last);
    }
    
    return optimizedPoints;
  }

  /// 高品質パスを作成
  static void _createHighQualityPath(ui.Path path, List<Offset> points) {
    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      final controlPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }
    
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }
  }

  /// 中品質パスを作成
  static void _createMediumQualityPath(ui.Path path, List<Offset> points) {
    // 2点おきに処理して負荷を軽減
    for (int i = 1; i < points.length - 1; i += 2) {
      final current = points[i];
      final next = points[math.min(i + 2, points.length - 1)];
      
      final controlPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }
    
    path.lineTo(points.last.dx, points.last.dy);
  }

  /// 低品質パスを作成
  static void _createLowQualityPath(ui.Path path, List<Offset> points) {
    // 直線で接続して負荷を最小化
    final step = math.max(1, points.length ~/ 20); // 最大20点に間引き
    
    for (int i = step; i < points.length; i += step) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    path.lineTo(points.last.dx, points.last.dy);
  }

  /// 基本的なパスを作成（エラー時のフォールバック）
  static ui.Path _createBasicPath(List<Offset> points) {
    final path = ui.Path();
    
    if (points.isEmpty) return path;
    
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    return path;
  }

  /// ストロークキャッシュキーを生成
  static String _generateStrokeCacheKey(BrushStroke stroke) {
    final pointsHash = stroke.points.length.hashCode ^
        stroke.points.first.hashCode ^
        stroke.points.last.hashCode;
    
    return 'stroke_${pointsHash}_${stroke.brushSize.hashCode}';
  }

  /// パスキャッシュキーを生成
  static String _generatePathCacheKey(List<Offset> points, double brushSize) {
    final pointsHash = points.length.hashCode ^
        points.first.hashCode ^
        points.last.hashCode;
    
    return 'path_${pointsHash}_${brushSize.hashCode}';
  }

  /// 最適化された点をキャッシュ
  static void _cacheOptimizedPoints(String key, List<Offset> points) {
    if (_optimizedPointsCache.length >= maxCacheSize) {
      // 古いキャッシュを削除
      final oldestKey = _optimizedPointsCache.keys.first;
      _optimizedPointsCache.remove(oldestKey);
    }
    
    _optimizedPointsCache[key] = points;
  }

  /// 最適化されたパスをキャッシュ
  static void _cacheOptimizedPath(String key, ui.Path path) {
    if (_pathCache.length >= maxCacheSize) {
      // 古いキャッシュを削除
      final oldestKey = _pathCache.keys.first;
      _pathCache.remove(oldestKey);
    }
    
    _pathCache[key] = path;
  }

  /// キャッシュをクリア
  static void clearCache() {
    try {
      AppLogger.d('ブラシ描画キャッシュをクリア');
      _pathCache.clear();
      _optimizedPointsCache.clear();
    } catch (e) {
      AppLogger.e('キャッシュクリアでエラー: $e');
    }
  }

  /// メモリ使用量を最適化（軽量化）
  static void optimizeMemoryUsage() {
    try {
      AppLogger.d('メモリ使用量最適化: 警告ログのみ出力（実際の最適化はコメントアウト）');
      
      // キャッシュサイズを半分に削減（コメントアウト）
      // final targetSize = maxCacheSize ~/ 2;
      
      // while (_pathCache.length > targetSize) {
      //   final oldestKey = _pathCache.keys.first;
      //   _pathCache.remove(oldestKey);
      // }
      
      // while (_optimizedPointsCache.length > targetSize) {
      //   final oldestKey = _optimizedPointsCache.keys.first;
      //   _optimizedPointsCache.remove(oldestKey);
      // }
      
      AppLogger.d('メモリ使用量最適化: 実際の処理はスキップ（頻繁な実行を防ぐため）');
    } catch (e) {
      AppLogger.e('メモリ最適化でエラー: $e');
    }
  }

  /// パフォーマンス統計を取得
  static Map<String, dynamic> getPerformanceStats() {
    try {
      return {
        'pathCacheSize': _pathCache.length,
        'pointsCacheSize': _optimizedPointsCache.length,
        'maxCacheSize': maxCacheSize,
        'cacheHitRate': _calculateCacheHitRate(),
        'memoryUsageEstimate': _estimateMemoryUsage(),
      };
    } catch (e) {
      AppLogger.e('パフォーマンス統計取得でエラー: $e');
      return {};
    }
  }

  /// キャッシュヒット率を計算（簡易版）
  static double _calculateCacheHitRate() {
    // 実際の実装では詳細な統計が必要
    return 0.8; // 仮の値
  }

  /// メモリ使用量を推定
  static int _estimateMemoryUsage() {
    try {
      // 各キャッシュエントリの推定サイズ
      const avgPathSize = 1024; // バイト
      const avgPointsSize = 512; // バイト
      
      final pathMemory = _pathCache.length * avgPathSize;
      final pointsMemory = _optimizedPointsCache.length * avgPointsSize;
      
      return pathMemory + pointsMemory;
    } catch (e) {
      AppLogger.e('メモリ使用量推定でエラー: $e');
      return 0;
    }
  }

  /// リソースクリーンアップ
  static void dispose() {
    clearCache();
  }
}

/// 描画品質レベル
enum DrawingQuality {
  high,
  medium,
  low,
}

/// 最適化されたカスタムペインター
class OptimizedCanvasPainter extends CustomPainter {
  const OptimizedCanvasPainter({
    required this.backgroundImage,
    required this.strokes,
    required this.brushSize,
    required this.brushColor,
    this.showMask = true,
    this.quality = DrawingQuality.high,
  });

  final ui.Image backgroundImage;
  final List<BrushStroke> strokes;
  final double brushSize;
  final Color brushColor;
  final bool showMask;
  final DrawingQuality quality;

  @override
  void paint(Canvas canvas, Size size) {
    // 背景画像を描画
    _drawBackgroundImage(canvas, size);

    // 最適化されたブラシストロークを描画
    if (showMask) {
      _drawOptimizedBrushStrokes(canvas, size);
    }
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    final imageSize = Size(
      backgroundImage.width.toDouble(),
      backgroundImage.height.toDouble(),
    );

    final scale = _calculateScale(imageSize, size);
    final scaledSize = Size(imageSize.width * scale, imageSize.height * scale);

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

    // フィルター品質を動的に調整
    final filterQuality = quality == DrawingQuality.high
        ? FilterQuality.high
        : quality == DrawingQuality.medium
            ? FilterQuality.medium
            : FilterQuality.low;

    canvas.drawImageRect(
      backgroundImage,
      srcRect,
      destRect,
      Paint()..filterQuality = filterQuality,
    );
  }

  void _drawOptimizedBrushStrokes(Canvas canvas, Size size) {
    // ストロークを最適化
    final optimizedStrokes = BrushDrawingOptimizer.optimizeStrokes(strokes, size);
    
    for (final stroke in optimizedStrokes) {
      _drawOptimizedStroke(canvas, stroke);
    }
  }

  void _drawOptimizedStroke(Canvas canvas, BrushStroke stroke) {
    if (stroke.points.isEmpty) return;

    final yellowColor = Colors.yellow.withValues(alpha: stroke.opacity * 255);
    
    if (stroke.points.length == 1) {
      // 単一点の場合は円を描画
      final circlePaint = Paint()
        ..color = yellowColor
        ..style = PaintingStyle.fill
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
        ..isAntiAlias = quality != DrawingQuality.low;

      canvas.drawPath(path, paint);

      // 高品質モードでは各点に円も描画
      if (quality == DrawingQuality.high) {
        final circlePaint = Paint()
          ..color = yellowColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        for (final point in stroke.points) {
          canvas.drawCircle(point, stroke.brushSize / 2, circlePaint);
        }
      }
    }
  }

  double _calculateScale(Size imageSize, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  @override
  bool shouldRepaint(OptimizedCanvasPainter oldDelegate) {
    return backgroundImage != oldDelegate.backgroundImage ||
        strokes != oldDelegate.strokes ||
        brushSize != oldDelegate.brushSize ||
        brushColor != oldDelegate.brushColor ||
        showMask != oldDelegate.showMask ||
        quality != oldDelegate.quality;
  }
}