import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';

/// マーカーアイコンリポジトリインターフェース
/// 
/// Advanced Markerで使用するアイコンの生成とキャッシュ機能を提供するインターフェース
abstract class MarkerIconRepository {
  /// 投稿の画像からマーカーアイコンを生成
  /// 
  /// [imageUrl] 画像のURL
  /// 戻り値: 生成されたアイコンのバイトデータ（失敗時はnull）
  Future<Uint8List?> generateMarkerIcon(String imageUrl);

  /// 画像の中央部をトリミング
  /// 
  /// [imageBytes] 元画像のバイトデータ
  /// [size] トリミング後のサイズ（正方形）
  /// 戻り値: トリミングされた画像のバイトデータ（失敗時はnull）
  Future<Uint8List?> cropImageCenter(Uint8List imageBytes, int size);

  /// Advanced Markerを作成
  /// 
  /// [iconBytes] アイコンのバイトデータ
  /// 戻り値: Advanced Marker用のBitmapDescriptor
  Future<BitmapDescriptor> createAdvancedMarker(Uint8List iconBytes);

  /// デフォルトのマーカーアイコンを取得
  /// 
  /// 戻り値: デフォルトマーカーのBitmapDescriptor
  BitmapDescriptor getDefaultMarkerIcon();

  /// マーカーアイコンをキャッシュに保存
  /// 
  /// [postId] 投稿ID
  /// [iconData] アイコンデータ
  Future<void> cacheMarkerIcon(String postId, MarkerIconData iconData);

  /// キャッシュからマーカーアイコンを取得
  /// 
  /// [postId] 投稿ID
  /// 戻り値: キャッシュされたアイコンデータ（存在しない場合はnull）
  Future<MarkerIconData?> getCachedMarkerIcon(String postId);

  /// キャッシュをクリア
  /// 
  /// [postId] 削除する投稿ID（nullの場合は全てクリア）
  Future<void> clearIconCache([String? postId]);

  /// 複数の投稿のアイコンを事前生成
  /// 
  /// [posts] アイコンを生成する投稿のリスト
  /// 戻り値: 生成されたアイコンデータのマップ（投稿ID -> アイコンデータ）
  Future<Map<String, MarkerIconData>> preloadIcons(List<Post> posts);

  /// アイコンサイズを設定
  /// 
  /// [size] アイコンのサイズ（ピクセル）
  void setIconSize(int size);

  /// 現在のアイコンサイズを取得
  /// 
  /// 戻り値: 現在のアイコンサイズ
  int getIconSize();

  /// アイコンの品質を設定
  /// 
  /// [quality] 画像品質（0-100）
  void setIconQuality(int quality);

  /// キャッシュサイズの制限を設定
  /// 
  /// [maxCacheSize] 最大キャッシュサイズ（アイテム数）
  void setMaxCacheSize(int maxCacheSize);
}