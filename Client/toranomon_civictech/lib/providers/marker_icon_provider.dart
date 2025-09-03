import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/models.dart';
import '../repositories/marker_icon_repository.dart';
import '../repositories/marker_icon_repository_impl.dart';
import '../utils/app_logger.dart';

part 'marker_icon_provider.g.dart';

/// マーカーアイコンの状態
class MarkerIconState {
  const MarkerIconState({
    required this.isLoading,
    required this.iconCache,
    this.error,
  });

  final bool isLoading;
  final Map<String, MarkerIconData> iconCache;
  final String? error;

  /// 初期状態
  static const initial = MarkerIconState(
    isLoading: false,
    iconCache: {},
  );

  /// コピーコンストラクタ
  MarkerIconState copyWith({
    bool? isLoading,
    Map<String, MarkerIconData>? iconCache,
    String? error,
  }) {
    return MarkerIconState(
      isLoading: isLoading ?? this.isLoading,
      iconCache: iconCache ?? this.iconCache,
      error: error ?? this.error,
    );
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkerIconState &&
        other.isLoading == isLoading &&
        _mapEquals(other.iconCache, iconCache) &&
        other.error == error;
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(isLoading, iconCache, error);

  /// マップの等価性比較のヘルパーメソッド
  bool _mapEquals(Map<String, MarkerIconData> a, Map<String, MarkerIconData> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// 文字列表現
  @override
  String toString() {
    return 'MarkerIconState(isLoading: $isLoading, cacheSize: ${iconCache.length}, error: $error)';
  }
}

/// マーカーアイコンリポジトリプロバイダー
@riverpod
MarkerIconRepository markerIconRepository(Ref ref) {
  return MarkerIconRepositoryImpl();
}

/// マーカーアイコン状態管理プロバイダー
@riverpod
class MarkerIconNotifier extends _$MarkerIconNotifier {
  MarkerIconRepository get _repository => ref.read(markerIconRepositoryProvider);

  @override
  MarkerIconState build() {
    return MarkerIconState.initial;
  }

  /// 投稿に対するアイコンを生成
  /// 
  /// [post] アイコンを生成する投稿
  Future<void> generateIconForPost(Post post) async {
    try {
      AppLogger.i('投稿のアイコン生成開始: ${post.id}');
      
      // 既にキャッシュに存在するかチェック
      final cached = await _repository.getCachedMarkerIcon(post.id);
      if (cached != null && cached.hasIcon) {
        AppLogger.i('キャッシュからアイコンを取得: ${post.id}');
        _updateIconCache(post.id, cached);
        return;
      }

      // ローディング状態を設定
      state = state.copyWith(isLoading: true, error: null);

      MarkerIconData iconData;

      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        // 画像からアイコンを生成
        final iconBytes = await _repository.generateMarkerIcon(post.imageUrl!);
        iconData = MarkerIconData(
          postId: post.id,
          imageUrl: post.imageUrl,
          croppedIconBytes: iconBytes,
        );
      } else {
        // 画像がない場合はデフォルトアイコン用のデータを作成
        iconData = MarkerIconData(postId: post.id);
      }

      // キャッシュに保存
      await _repository.cacheMarkerIcon(post.id, iconData);
      
      // 状態を更新
      _updateIconCache(post.id, iconData);
      
      AppLogger.i('投稿のアイコン生成完了: ${post.id}');
    } catch (e, stackTrace) {
      AppLogger.e('投稿のアイコン生成エラー: ${post.id}', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'アイコンの生成に失敗しました: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 複数投稿のアイコンを事前読み込み
  /// 
  /// [posts] アイコンを生成する投稿のリスト
  Future<void> preloadIcons(List<Post> posts) async {
    try {
      AppLogger.i('複数投稿のアイコン事前読み込み開始: ${posts.length}件');
      
      // ローディング状態を設定
      state = state.copyWith(isLoading: true, error: null);

      // リポジトリで一括生成
      final iconDataMap = await _repository.preloadIcons(posts);
      
      // 状態を更新
      final newIconCache = Map<String, MarkerIconData>.from(state.iconCache);
      newIconCache.addAll(iconDataMap);
      
      state = state.copyWith(
        isLoading: false,
        iconCache: newIconCache,
        error: null,
      );
      
      AppLogger.i('複数投稿のアイコン事前読み込み完了: ${iconDataMap.length}件');
    } catch (e, stackTrace) {
      AppLogger.e('複数投稿のアイコン事前読み込みエラー', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'アイコンの事前読み込みに失敗しました: ${e.toString()}',
      );
    }
  }

  /// 投稿のアイコンを取得
  /// 
  /// [postId] 投稿ID
  /// 戻り値: BitmapDescriptor（キャッシュにない場合はデフォルトアイコン）
  BitmapDescriptor getIconForPost(String postId) {
    final iconData = state.iconCache[postId];
    
    if (iconData != null && iconData.hasIcon) {
      // リポジトリからBitmapDescriptorを取得
      final repositoryImpl = _repository as MarkerIconRepositoryImpl;
      final cachedBitmap = repositoryImpl.getCachedBitmapDescriptor(postId);
      if (cachedBitmap != null) {
        return cachedBitmap;
      }
    }
    
    // デフォルトアイコンを返す
    return _repository.getDefaultMarkerIcon();
  }

  /// 特定の投稿のアイコンデータを取得
  /// 
  /// [postId] 投稿ID
  /// 戻り値: アイコンデータ（存在しない場合はnull）
  MarkerIconData? getIconDataForPost(String postId) {
    return state.iconCache[postId];
  }

  /// アイコンキャッシュをクリア
  /// 
  /// [postId] 削除する投稿ID（nullの場合は全てクリア）
  Future<void> clearIconCache([String? postId]) async {
    try {
      await _repository.clearIconCache(postId);
      
      if (postId != null) {
        // 特定のアイコンのみ削除
        final newIconCache = Map<String, MarkerIconData>.from(state.iconCache);
        newIconCache.remove(postId);
        state = state.copyWith(iconCache: newIconCache);
        AppLogger.i('特定のアイコンキャッシュをクリア: $postId');
      } else {
        // 全てのアイコンを削除
        state = state.copyWith(iconCache: {});
        AppLogger.i('全てのアイコンキャッシュをクリア');
      }
    } catch (e, stackTrace) {
      AppLogger.e('アイコンキャッシュクリアエラー', e, stackTrace);
    }
  }

  /// アイコンサイズを設定
  /// 
  /// [size] アイコンのサイズ（ピクセル）
  void setIconSize(int size) {
    _repository.setIconSize(size);
    AppLogger.i('アイコンサイズを設定: $size');
  }

  /// アイコンの品質を設定
  /// 
  /// [quality] 画像品質（0-100）
  void setIconQuality(int quality) {
    _repository.setIconQuality(quality);
    AppLogger.i('アイコン品質を設定: $quality');
  }

  /// 最大キャッシュサイズを設定
  /// 
  /// [maxCacheSize] 最大キャッシュサイズ（アイテム数）
  void setMaxCacheSize(int maxCacheSize) {
    _repository.setMaxCacheSize(maxCacheSize);
    AppLogger.i('最大キャッシュサイズを設定: $maxCacheSize');
  }

  /// アイコンキャッシュを更新
  void _updateIconCache(String postId, MarkerIconData iconData) {
    final newIconCache = Map<String, MarkerIconData>.from(state.iconCache);
    newIconCache[postId] = iconData;
    state = state.copyWith(iconCache: newIconCache);
  }

  /// エラー状態をクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// キャッシュ統計情報を取得
  Map<String, dynamic> getCacheStats() {
    final stats = {
      'totalCached': state.iconCache.length,
      'withIcons': state.iconCache.values.where((icon) => icon.hasIcon).length,
      'withoutIcons': state.iconCache.values.where((icon) => !icon.hasIcon).length,
      'isLoading': state.isLoading,
      'hasError': state.error != null,
    };
    
    AppLogger.i('アイコンキャッシュ統計: $stats');
    return stats;
  }
}

/// 特定の投稿のアイコンを取得するプロバイダー
@riverpod
BitmapDescriptor postMarkerIcon(Ref ref, String postId) {
  final markerIconNotifier = ref.watch(markerIconNotifierProvider.notifier);
  return markerIconNotifier.getIconForPost(postId);
}

/// 複数投稿のアイコンを一括取得するプロバイダー
@riverpod
Map<String, BitmapDescriptor> postsMarkerIcons(Ref ref, List<String> postIds) {
  final markerIconNotifier = ref.watch(markerIconNotifierProvider.notifier);
  final result = <String, BitmapDescriptor>{};
  
  for (final postId in postIds) {
    result[postId] = markerIconNotifier.getIconForPost(postId);
  }
  
  return result;
}