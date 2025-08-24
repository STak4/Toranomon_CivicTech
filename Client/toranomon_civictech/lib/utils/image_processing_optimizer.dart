import 'dart:io';
import 'dart:math' as math;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';
import 'resource_manager.dart';

/// 画像処理最適化ユーティリティクラス
/// 
/// メモリ効率的な画像処理、リサイズ、圧縮機能を提供
class ImageProcessingOptimizer {
  /// 表示用画像の最大サイズ
  static const int maxDisplaySize = 1024;
  
  /// アップロード用画像の最大サイズ
  static const int maxUploadSize = 1536;
  
  /// マスク生成用画像の最大サイズ
  static const int maxMaskSize = 512;
  
  /// メモリ使用量の警告閾値（MB）
  static const int memoryWarningThreshold = 500;
  
  /// 画像処理用のIsolateプール
  static final Map<String, Isolate> _isolatePool = {};
  
  /// 一時ファイルのキャッシュ
  static final Map<String, File> _tempFileCache = {};

  /// 表示用に最適化された画像を生成
  /// 
  /// [imageFile] 元画像ファイル
  /// [maxSize] 最大サイズ（デフォルト: maxDisplaySize）
  /// [quality] JPEG品質（1-100、デフォルト: 85）
  /// Returns 最適化された画像ファイル
  static Future<File> optimizeForDisplay({
    required File imageFile,
    int? maxSize,
    int quality = 85,
  }) async {
    final targetSize = maxSize ?? maxDisplaySize;
    final cacheKey = 'display_${imageFile.path}_${targetSize}_$quality';
    
    // キャッシュから取得を試行
    if (_tempFileCache.containsKey(cacheKey)) {
      final cachedFile = _tempFileCache[cacheKey]!;
      if (await cachedFile.exists()) {
        AppLogger.d('表示用画像をキャッシュから取得: ${cachedFile.path}');
        return cachedFile;
      } else {
        _tempFileCache.remove(cacheKey);
      }
    }
    
    try {
      AppLogger.i('表示用画像最適化開始: ${imageFile.path}');
      _logMemoryUsage('表示用画像最適化開始前');
      
      // Isolateで画像処理を実行
      final optimizedFile = await _processImageInIsolate(
        imageFile,
        targetSize,
        quality,
        ImageProcessingType.display,
      );
      
      // キャッシュに保存
      _tempFileCache[cacheKey] = optimizedFile;
      
      // リソースマネージャーに登録
      ResourceManager.instance.registerTempFile(optimizedFile);
      
      _logMemoryUsage('表示用画像最適化完了後');
      AppLogger.i('表示用画像最適化完了: ${optimizedFile.path}');
      
      return optimizedFile;
    } catch (e, stackTrace) {
      AppLogger.e('表示用画像最適化でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// アップロード用に最適化された画像を生成
  /// 
  /// [imageFile] 元画像ファイル
  /// [maxSize] 最大サイズ（デフォルト: maxUploadSize）
  /// [quality] JPEG品質（1-100、デフォルト: 90）
  /// Returns 最適化された画像ファイル
  static Future<File> optimizeForUpload({
    required File imageFile,
    int? maxSize,
    int quality = 90,
  }) async {
    final targetSize = maxSize ?? maxUploadSize;
    final cacheKey = 'upload_${imageFile.path}_${targetSize}_$quality';
    
    // キャッシュから取得を試行
    if (_tempFileCache.containsKey(cacheKey)) {
      final cachedFile = _tempFileCache[cacheKey]!;
      if (await cachedFile.exists()) {
        AppLogger.d('アップロード用画像をキャッシュから取得: ${cachedFile.path}');
        return cachedFile;
      } else {
        _tempFileCache.remove(cacheKey);
      }
    }
    
    try {
      AppLogger.i('アップロード用画像最適化開始: ${imageFile.path}');
      _logMemoryUsage('アップロード用画像最適化開始前');
      
      // Isolateで画像処理を実行
      final optimizedFile = await _processImageInIsolate(
        imageFile,
        targetSize,
        quality,
        ImageProcessingType.upload,
      );
      
      // キャッシュに保存
      _tempFileCache[cacheKey] = optimizedFile;
      
      // リソースマネージャーに登録
      ResourceManager.instance.registerTempFile(optimizedFile);
      
      _logMemoryUsage('アップロード用画像最適化完了後');
      AppLogger.i('アップロード用画像最適化完了: ${optimizedFile.path}');
      
      return optimizedFile;
    } catch (e, stackTrace) {
      AppLogger.e('アップロード用画像最適化でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// マスク生成用に最適化された画像サイズを取得
  /// 
  /// [originalSize] 元画像のサイズ
  /// [maxSize] 最大サイズ（デフォルト: maxMaskSize）
  /// Returns 最適化されたサイズ
  static Size optimizeForMaskGeneration({
    required Size originalSize,
    int? maxSize,
  }) {
    final targetSize = maxSize ?? maxMaskSize;
    
    // アスペクト比を保持しながらサイズを調整
    final scale = math.min(
      targetSize / originalSize.width,
      targetSize / originalSize.height,
    );
    
    if (scale >= 1.0) {
      // 元画像が小さい場合はそのまま使用
      return originalSize;
    }
    
    final newWidth = (originalSize.width * scale).round();
    final newHeight = (originalSize.height * scale).round();
    
    // 8の倍数に調整（Canvas Inpainting要件）
    final alignedWidth = _alignToMultiple(newWidth, 8);
    final alignedHeight = _alignToMultiple(newHeight, 8);
    
    return Size(alignedWidth.toDouble(), alignedHeight.toDouble());
  }

  /// Isolateで画像処理を実行
  static Future<File> _processImageInIsolate(
    File imageFile,
    int maxSize,
    int quality,
    ImageProcessingType type,
  ) async {
    final receivePort = ReceivePort();
    
    try {
      // Isolateを起動
      final isolate = await Isolate.spawn(
        _imageProcessingIsolateEntry,
        _ImageProcessingParams(
          sendPort: receivePort.sendPort,
          imagePath: imageFile.path,
          maxSize: maxSize,
          quality: quality,
          type: type,
        ),
      );
      
      // 結果を待機
      final result = await receivePort.first as _ImageProcessingResult;
      
      // Isolateを終了
      isolate.kill();
      
      if (result.error != null) {
        throw Exception(result.error);
      }
      
      return File(result.outputPath!);
    } catch (e) {
      receivePort.close();
      rethrow;
    }
  }

  /// Isolateエントリーポイント
  static void _imageProcessingIsolateEntry(_ImageProcessingParams params) {
    try {
      // 画像を読み込み
      final imageFile = File(params.imagePath);
      final imageBytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        params.sendPort.send(_ImageProcessingResult(
          error: '画像のデコードに失敗しました',
        ));
        return;
      }
      
      // リサイズ後のサイズを計算
      final resizedSize = _calculateOptimalSize(
        image.width,
        image.height,
        params.maxSize,
        params.type,
      );
      
      // 画像をリサイズ
      final resizedImage = img.copyResize(
        image,
        width: resizedSize.width.toInt(),
        height: resizedSize.height.toInt(),
        interpolation: img.Interpolation.cubic,
      );
      
      // 品質を調整
      int adjustedQuality = params.quality;
      if (params.type == ImageProcessingType.display) {
        // 表示用は品質を下げてファイルサイズを削減
        adjustedQuality = math.min(params.quality, 85);
      }
      
      // JPEG形式でエンコード
      final jpegBytes = img.encodeJpg(resizedImage, quality: adjustedQuality);
      
      // 一時ファイルに保存
      final tempDir = Directory.systemTemp;
      final outputFile = File(
        '${tempDir.path}/optimized_${params.type.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      outputFile.writeAsBytesSync(jpegBytes);
      
      params.sendPort.send(_ImageProcessingResult(
        outputPath: outputFile.path,
      ));
    } catch (e) {
      params.sendPort.send(_ImageProcessingResult(
        error: e.toString(),
      ));
    }
  }

  /// 最適なサイズを計算
  static Size _calculateOptimalSize(
    int width,
    int height,
    int maxSize,
    ImageProcessingType type,
  ) {
    // アスペクト比を保持しながら最大サイズに収める
    double scale = 1.0;
    
    if (width > maxSize || height > maxSize) {
      final scaleX = maxSize / width;
      final scaleY = maxSize / height;
      scale = math.min(scaleX, scaleY);
    }
    
    // スケールを適用
    int newWidth = (width * scale).round();
    int newHeight = (height * scale).round();
    
    // タイプに応じた調整
    switch (type) {
      case ImageProcessingType.upload:
        // アップロード用は8の倍数に調整
        newWidth = _alignToMultiple(newWidth, 8);
        newHeight = _alignToMultiple(newHeight, 8);
        // 最小サイズを確保
        newWidth = math.max(newWidth, 512);
        newHeight = math.max(newHeight, 512);
        break;
      case ImageProcessingType.display:
        // 表示用は4の倍数に調整（軽量化）
        newWidth = _alignToMultiple(newWidth, 4);
        newHeight = _alignToMultiple(newHeight, 4);
        break;
      case ImageProcessingType.mask:
        // マスク用は8の倍数に調整
        newWidth = _alignToMultiple(newWidth, 8);
        newHeight = _alignToMultiple(newHeight, 8);
        break;
    }
    
    return Size(newWidth.toDouble(), newHeight.toDouble());
  }

  /// 指定された倍数に調整
  static int _alignToMultiple(int value, int multiple) {
    return (value / multiple).round() * multiple;
  }

  /// メモリ使用量をログ出力
  static void _logMemoryUsage(String context) {
    if (kDebugMode) {
      // デバッグモードでのみメモリ使用量を監視
      final info = ProcessInfo.currentRss;
      final memoryMB = info / (1024 * 1024);
      
      AppLogger.d('$context - メモリ使用量: ${memoryMB.toStringAsFixed(1)} MB');
      
      if (memoryMB > memoryWarningThreshold) {
        AppLogger.w('メモリ使用量が警告閾値を超えています: ${memoryMB.toStringAsFixed(1)} MB');
      }
    }
  }

  /// 一時ファイルキャッシュをクリア
  static Future<void> clearTempFileCache() async {
    try {
      AppLogger.i('一時ファイルキャッシュクリア開始');
      
      for (final entry in _tempFileCache.entries) {
        try {
          if (await entry.value.exists()) {
            await entry.value.delete();
            AppLogger.d('一時ファイル削除: ${entry.value.path}');
          }
        } catch (e) {
          AppLogger.w('一時ファイル削除でエラー: ${entry.value.path} - $e');
        }
      }
      
      _tempFileCache.clear();
      AppLogger.i('一時ファイルキャッシュクリア完了');
    } catch (e, stackTrace) {
      AppLogger.e('一時ファイルキャッシュクリアでエラー: $e', stackTrace);
    }
  }

  /// 古い一時ファイルを削除
  static Future<void> cleanupOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File && file.path.contains('optimized_')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          // 1時間以上古いファイルを削除
          if (age.inHours >= 1) {
            try {
              await file.delete();
              AppLogger.d('古い一時ファイル削除: ${file.path}');
            } catch (e) {
              AppLogger.w('古い一時ファイル削除でエラー: ${file.path} - $e');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('古い一時ファイルクリーンアップでエラー: $e', stackTrace);
    }
  }

  /// リソースクリーンアップ
  static Future<void> dispose() async {
    await clearTempFileCache();
    
    // Isolateプールをクリーンアップ
    for (final isolate in _isolatePool.values) {
      isolate.kill();
    }
    _isolatePool.clear();
  }
}

/// 画像処理タイプ
enum ImageProcessingType {
  display,
  upload,
  mask,
}

/// 画像処理パラメータ
class _ImageProcessingParams {
  const _ImageProcessingParams({
    required this.sendPort,
    required this.imagePath,
    required this.maxSize,
    required this.quality,
    required this.type,
  });

  final SendPort sendPort;
  final String imagePath;
  final int maxSize;
  final int quality;
  final ImageProcessingType type;
}

/// 画像処理結果
class _ImageProcessingResult {
  const _ImageProcessingResult({
    this.outputPath,
    this.error,
  });

  final String? outputPath;
  final String? error;
}