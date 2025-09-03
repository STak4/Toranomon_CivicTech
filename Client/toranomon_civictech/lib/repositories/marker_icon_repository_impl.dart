import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/app_logger.dart';
import 'marker_icon_repository.dart';

/// マーカーアイコンリポジトリの実装
/// 
/// Advanced Markerで使用するアイコンの生成とキャッシュ機能を提供
class MarkerIconRepositoryImpl implements MarkerIconRepository {
  MarkerIconRepositoryImpl({
    int iconSize = 64,
    int iconQuality = 85,
    int maxCacheSize = 100,
  }) : _iconSize = iconSize,
       _iconQuality = iconQuality,
       _maxCacheSize = maxCacheSize;

  // 設定可能なパラメータ
  int _iconSize;
  int _iconQuality;
  int _maxCacheSize;

  // メモリキャッシュ
  final Map<String, MarkerIconData> _iconCache = {};
  final Map<String, BitmapDescriptor> _bitmapCache = {};

  // デフォルトマーカー（遅延初期化）
  BitmapDescriptor? _defaultMarker;

  @override
  Future<Uint8List?> generateMarkerIcon(String imageUrl) async {
    try {
      AppLogger.i('マーカーアイコン生成開始: $imageUrl');
      
      // 画像をダウンロード
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        AppLogger.w('画像のダウンロードに失敗: ${response.statusCode}');
        return null;
      }

      // 画像の中央部をトリミング
      final croppedBytes = await cropImageCenter(response.bodyBytes, _iconSize);
      if (croppedBytes == null) {
        AppLogger.w('画像のトリミングに失敗');
        return null;
      }

      AppLogger.i('マーカーアイコン生成完了');
      return croppedBytes;
    } catch (e, stackTrace) {
      AppLogger.e('マーカーアイコン生成エラー', e, stackTrace);
      return null;
    }
  }

  @override
  Future<Uint8List?> cropImageCenter(Uint8List imageBytes, int size) async {
    try {
      AppLogger.i('画像の中央部トリミング開始: サイズ $size');
      
      // 画像をデコード
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 正方形のトリミング領域を計算
      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;
      final cropSize = originalWidth < originalHeight ? originalWidth : originalHeight;
      
      final offsetX = (originalWidth - cropSize) ~/ 2;
      final offsetY = (originalHeight - cropSize) ~/ 2;

      // キャンバスを作成してトリミング
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 背景を透明に設定
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = Colors.transparent,
      );

      // 画像を描画（リサイズとトリミングを同時に実行）
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(
          offsetX.toDouble(),
          offsetY.toDouble(),
          cropSize.toDouble(),
          cropSize.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint(),
      );

      // 円形にクリップ（オプション）
      _drawCircularClip(canvas, size);

      // 画像をエンコード
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(size, size);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      
      originalImage.dispose();
      croppedImage.dispose();

      if (byteData == null) {
        AppLogger.w('画像のエンコードに失敗');
        return null;
      }

      AppLogger.i('画像の中央部トリミング完了');
      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      AppLogger.e('画像トリミングエラー', e, stackTrace);
      return null;
    }
  }

  /// 円形クリップを適用（マーカーアイコンを円形にする）
  void _drawCircularClip(Canvas canvas, int size) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    
    // 円形のクリップパスを作成
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    canvas.clipPath(clipPath);
  }

  @override
  Future<BitmapDescriptor> createAdvancedMarker(Uint8List iconBytes) async {
    try {
      AppLogger.i('Advanced Marker作成開始');
      
      // BitmapDescriptorを作成
      final bitmapDescriptor = BitmapDescriptor.bytes(iconBytes);
      
      AppLogger.i('Advanced Marker作成完了');
      return bitmapDescriptor;
    } catch (e, stackTrace) {
      AppLogger.e('Advanced Marker作成エラー', e, stackTrace);
      // エラー時はデフォルトマーカーを返す
      return getDefaultMarkerIcon();
    }
  }

  @override
  BitmapDescriptor getDefaultMarkerIcon() {
    _defaultMarker ??= BitmapDescriptor.defaultMarker;
    return _defaultMarker!;
  }

  @override
  Future<void> cacheMarkerIcon(String postId, MarkerIconData iconData) async {
    try {
      // キャッシュサイズ制限をチェック
      if (_iconCache.length >= _maxCacheSize) {
        _evictOldestCacheEntry();
      }

      _iconCache[postId] = iconData;
      
      // BitmapDescriptorもキャッシュ
      if (iconData.croppedIconBytes != null) {
        final bitmapDescriptor = await createAdvancedMarker(iconData.croppedIconBytes!);
        _bitmapCache[postId] = bitmapDescriptor;
      }

      AppLogger.i('マーカーアイコンをキャッシュに保存: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('アイコンキャッシュ保存エラー', e, stackTrace);
    }
  }

  @override
  Future<MarkerIconData?> getCachedMarkerIcon(String postId) async {
    final cachedIcon = _iconCache[postId];
    if (cachedIcon != null) {
      AppLogger.i('キャッシュからマーカーアイコンを取得: $postId');
    }
    return cachedIcon;
  }

  @override
  Future<void> clearIconCache([String? postId]) async {
    if (postId != null) {
      _iconCache.remove(postId);
      _bitmapCache.remove(postId);
      AppLogger.i('特定のアイコンキャッシュをクリア: $postId');
    } else {
      _iconCache.clear();
      _bitmapCache.clear();
      AppLogger.i('全てのアイコンキャッシュをクリア');
    }
  }

  @override
  Future<Map<String, MarkerIconData>> preloadIcons(List<Post> posts) async {
    final Map<String, MarkerIconData> result = {};
    
    AppLogger.i('複数投稿のアイコン事前生成開始: ${posts.length}件');
    
    // 並列処理で効率化
    final futures = posts.map((post) async {
      try {
        // キャッシュから確認
        final cached = await getCachedMarkerIcon(post.id);
        if (cached != null && cached.hasIcon) {
          result[post.id] = cached;
          return;
        }

        // 画像URLが存在する場合のみアイコン生成
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          final iconBytes = await generateMarkerIcon(post.imageUrl!);
          if (iconBytes != null) {
            final iconData = MarkerIconData(
              postId: post.id,
              imageUrl: post.imageUrl,
              croppedIconBytes: iconBytes,
            );
            
            // キャッシュに保存
            await cacheMarkerIcon(post.id, iconData);
            result[post.id] = iconData;
          } else {
            // アイコン生成に失敗した場合はデフォルトアイコン用のデータを作成
            final defaultIconData = MarkerIconData(
              postId: post.id,
              imageUrl: post.imageUrl,
            );
            result[post.id] = defaultIconData;
          }
        } else {
          // 画像がない場合はデフォルトアイコン用のデータを作成
          final defaultIconData = MarkerIconData(
            postId: post.id,
          );
          result[post.id] = defaultIconData;
        }
      } catch (e, stackTrace) {
        AppLogger.e('投稿 ${post.id} のアイコン生成エラー', e, stackTrace);
        // エラー時もデフォルトアイコン用のデータを作成
        result[post.id] = MarkerIconData(postId: post.id);
      }
    });

    await Future.wait(futures);
    
    AppLogger.i('複数投稿のアイコン事前生成完了: ${result.length}件');
    return result;
  }

  /// キャッシュされたBitmapDescriptorを取得
  BitmapDescriptor? getCachedBitmapDescriptor(String postId) {
    return _bitmapCache[postId];
  }

  /// 最も古いキャッシュエントリを削除
  void _evictOldestCacheEntry() {
    if (_iconCache.isNotEmpty) {
      final oldestKey = _iconCache.keys.first;
      _iconCache.remove(oldestKey);
      _bitmapCache.remove(oldestKey);
      AppLogger.i('古いキャッシュエントリを削除: $oldestKey');
    }
  }

  @override
  void setIconSize(int size) {
    _iconSize = size;
    AppLogger.i('アイコンサイズを設定: $size');
  }

  @override
  int getIconSize() => _iconSize;

  @override
  void setIconQuality(int quality) {
    _iconQuality = quality.clamp(0, 100);
    AppLogger.i('アイコン品質を設定: $_iconQuality');
  }

  @override
  void setMaxCacheSize(int maxCacheSize) {
    _maxCacheSize = maxCacheSize;
    AppLogger.i('最大キャッシュサイズを設定: $maxCacheSize');
    
    // 現在のキャッシュサイズが制限を超えている場合は調整
    while (_iconCache.length > _maxCacheSize) {
      _evictOldestCacheEntry();
    }
  }

  /// リソースのクリーンアップ
  void dispose() {
    clearIconCache();
    AppLogger.i('MarkerIconRepository リソースをクリーンアップ');
  }
}