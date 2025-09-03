import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_logger.dart';
import 'room_provider.dart' show currentRoomIdProvider;

/// PostRepositoryのプロバイダー
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl();
});

/// 投稿状態管理クラス
class PostState {
  const PostState({
    required this.isLoading,
    required this.posts,
    this.currentRoomId,
    this.error,
    this.hasMore = true,
    this.totalCount = 0,
    this.currentOffset = 0,
    this.isLoadingMore = false,
  });

  final bool isLoading;
  final List<Post> posts;
  final String? currentRoomId;
  final String? error;
  final bool hasMore;
  final int totalCount;
  final int currentOffset;
  final bool isLoadingMore;

  PostState copyWith({
    bool? isLoading,
    List<Post>? posts,
    String? currentRoomId,
    String? error,
    bool? hasMore,
    int? totalCount,
    int? currentOffset,
    bool? isLoadingMore,
  }) {
    return PostState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      currentOffset: currentOffset ?? this.currentOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostState &&
        other.isLoading == isLoading &&
        other.posts == posts &&
        other.currentRoomId == currentRoomId &&
        other.error == error &&
        other.hasMore == hasMore &&
        other.totalCount == totalCount &&
        other.currentOffset == currentOffset &&
        other.isLoadingMore == isLoadingMore;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        posts,
        currentRoomId,
        error,
        hasMore,
        totalCount,
        currentOffset,
        isLoadingMore,
      );
}

/// 投稿状態管理プロバイダー
class PostNotifier extends StateNotifier<PostState> {
  final PostRepository _repository;

  PostNotifier(this._repository)
      : super(const PostState(
          isLoading: false,
          posts: [],
        ));

  /// 投稿を読み込み
  Future<void> loadPosts({
    LatLngBounds? bounds,
    String? roomId,
  }) async {
    try {
      AppLogger.i('投稿読み込み開始 - roomId: $roomId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final posts = await _repository.getPosts(
        bounds: bounds,
        roomId: roomId,
      );
      
      state = state.copyWith(
        isLoading: false,
        posts: posts,
        currentRoomId: roomId,
      );
      
      AppLogger.i('投稿読み込み完了 - 件数: ${posts.length}');
    } catch (e, stackTrace) {
      AppLogger.e('投稿読み込みに失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 投稿を作成
  Future<Post?> createPost(CreatePostRequest request) async {
    try {
      AppLogger.i('投稿作成開始 - title: ${request.title}');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final post = await _repository.createPost(request);
      
      // 現在の投稿リストに新しい投稿を追加
      final updatedPosts = [post, ...state.posts];
      
      state = state.copyWith(
        isLoading: false,
        posts: updatedPosts,
      );
      
      AppLogger.i('投稿作成完了 - id: ${post.id}');
      return post;
    } catch (e, stackTrace) {
      AppLogger.e('投稿作成に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 投稿を削除
  Future<bool> deletePost(String postId) async {
    try {
      AppLogger.i('投稿削除開始 - id: $postId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      await _repository.deletePost(postId);
      
      // 現在の投稿リストから削除
      final updatedPosts = state.posts.where((post) => post.id != postId).toList();
      
      state = state.copyWith(
        isLoading: false,
        posts: updatedPosts,
      );
      
      AppLogger.i('投稿削除完了 - id: $postId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('投稿削除に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// ページネーション対応の投稿読み込み
  Future<void> loadPostsPaginated({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
    bool refresh = false,
  }) async {
    try {
      AppLogger.i('ページネーション投稿読み込み開始 - roomId: $roomId, refresh: $refresh');
      
      if (refresh) {
        // リフレッシュの場合は最初から読み込み
        state = state.copyWith(
          isLoading: true,
          error: null,
          currentOffset: 0,
          hasMore: true,
        );
        
        final result = await _repository.getPostsPaginated(
          bounds: bounds,
          roomId: roomId,
          limit: limit,
          offset: 0,
          orderBy: orderBy,
        );
        
        state = state.copyWith(
          isLoading: false,
          posts: result.posts,
          currentRoomId: roomId,
          hasMore: result.hasMore,
          totalCount: result.totalCount,
          currentOffset: result.posts.length,
        );
      } else {
        // 初回読み込み
        state = state.copyWith(isLoading: true, error: null);
        
        final result = await _repository.getPostsPaginated(
          bounds: bounds,
          roomId: roomId,
          limit: limit,
          offset: 0,
          orderBy: orderBy,
        );
        
        state = state.copyWith(
          isLoading: false,
          posts: result.posts,
          currentRoomId: roomId,
          hasMore: result.hasMore,
          totalCount: result.totalCount,
          currentOffset: result.posts.length,
        );
      }
      
      AppLogger.i('ページネーション投稿読み込み完了 - 件数: ${state.posts.length}');
    } catch (e, stackTrace) {
      AppLogger.e('ページネーション投稿読み込みに失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 追加の投稿を読み込み（無限スクロール用）
  Future<void> loadMorePosts({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
  }) async {
    // 既に読み込み中または追加データがない場合はスキップ
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    try {
      AppLogger.i('追加投稿読み込み開始 - offset: ${state.currentOffset}');
      
      state = state.copyWith(isLoadingMore: true, error: null);
      
      final result = await _repository.getPostsPaginated(
        bounds: bounds,
        roomId: roomId,
        limit: limit,
        offset: state.currentOffset,
        orderBy: orderBy,
      );
      
      // 既存の投稿リストに追加
      final updatedPosts = [...state.posts, ...result.posts];
      
      state = state.copyWith(
        isLoadingMore: false,
        posts: updatedPosts,
        hasMore: result.hasMore,
        totalCount: result.totalCount,
        currentOffset: state.currentOffset + result.posts.length,
      );
      
      AppLogger.i('追加投稿読み込み完了 - 追加件数: ${result.posts.length}, 総件数: ${updatedPosts.length}');
    } catch (e, stackTrace) {
      AppLogger.e('追加投稿読み込みに失敗', e, stackTrace);
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// ルームIDを生成して共有
  Future<String?> generateAndShareRoom() async {
    try {
      AppLogger.i('ルーム生成開始');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final roomId = await _repository.generateRoomId();
      
      state = state.copyWith(
        isLoading: false,
        currentRoomId: roomId,
      );
      
      AppLogger.i('ルーム生成完了 - id: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム生成に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// ルームに参加
  Future<bool> joinRoom(String roomId) async {
    try {
      AppLogger.i('ルーム参加開始 - id: $roomId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // ルームIDの有効性を検証
      final isValid = await _repository.validateRoomId(roomId);
      if (!isValid) {
        state = state.copyWith(
          isLoading: false,
          error: '無効なルームIDです',
        );
        return false;
      }
      
      // ルーム内の投稿を読み込み
      final posts = await _repository.getPostsInRoom(roomId);
      
      state = state.copyWith(
        isLoading: false,
        posts: posts,
        currentRoomId: roomId,
      );
      
      AppLogger.i('ルーム参加完了 - id: $roomId, 投稿数: ${posts.length}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム参加に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 現在のルームを設定
  void setCurrentRoom(String? roomId) {
    AppLogger.i('現在のルーム設定 - id: $roomId');
    state = state.copyWith(currentRoomId: roomId);
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 投稿リストをクリア
  void clearPosts() {
    AppLogger.i('投稿リストをクリア');
    state = state.copyWith(posts: []);
  }

  /// 投稿を更新
  Future<bool> updatePost(Post post) async {
    try {
      AppLogger.i('投稿更新開始 - id: ${post.id}');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedPost = await _repository.updatePost(post);
      
      // 現在の投稿リストを更新
      final updatedPosts = state.posts.map((p) {
        return p.id == updatedPost.id ? updatedPost : p;
      }).toList();
      
      state = state.copyWith(
        isLoading: false,
        posts: updatedPosts,
      );
      
      AppLogger.i('投稿更新完了 - id: ${post.id}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('投稿更新に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 投稿詳細を取得
  Future<Post?> getPostById(String postId) async {
    try {
      AppLogger.i('投稿詳細取得開始 - id: $postId');
      
      final post = await _repository.getPostById(postId);
      
      AppLogger.i('投稿詳細取得完了 - id: $postId');
      return post;
    } catch (e, stackTrace) {
      AppLogger.e('投稿詳細取得に失敗', e, stackTrace);
      return null;
    }
  }
}

/// 投稿状態管理プロバイダー
final postProvider = StateNotifierProvider<PostNotifier, PostState>((ref) {
  final repository = ref.read(postRepositoryProvider);
  return PostNotifier(repository);
});

/// 投稿ストリームプロバイダー
final postsStreamProvider = StreamProvider.family<List<Post>, PostStreamParams>((ref, params) {
  final repository = ref.read(postRepositoryProvider);
  return repository.getPostsStream(
    bounds: params.bounds,
    roomId: params.roomId,
  );
});

/// 投稿ストリームのパラメータ
class PostStreamParams {
  const PostStreamParams({
    this.bounds,
    this.roomId,
  });

  final LatLngBounds? bounds;
  final String? roomId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostStreamParams &&
        other.bounds == bounds &&
        other.roomId == roomId;
  }

  @override
  int get hashCode => Object.hash(bounds, roomId);
}

/// 特定のルーム内の投稿を取得するプロバイダー
final roomPostsProvider = FutureProvider.family<List<Post>, String>((ref, roomId) async {
  final repository = ref.read(postRepositoryProvider);
  return repository.getPostsInRoom(roomId);
});

/// ルームID検証プロバイダー
final roomValidationProvider = FutureProvider.family<bool, String>((ref, roomId) async {
  final repository = ref.read(postRepositoryProvider);
  return repository.validateRoomId(roomId);
});

/// リアルタイム投稿更新管理クラス
class PostStreamNotifier extends StateNotifier<PostStreamState> {
  final PostRepository _repository;
  
  PostStreamNotifier(this._repository)
      : super(const PostStreamState(
          isListening: false,
          posts: [],
        ));

  /// リアルタイム更新を開始
  void startListening({
    LatLngBounds? bounds,
    String? roomId,
  }) {
    try {
      AppLogger.i('リアルタイム投稿更新開始 - roomId: $roomId');
      
      state = state.copyWith(
        isListening: true,
        currentBounds: bounds,
        currentRoomId: roomId,
        error: null,
      );

      // ストリームを監視
      _repository.getPostsStream(bounds: bounds, roomId: roomId).listen(
        (posts) {
          if (mounted) {
            state = state.copyWith(
              posts: posts,
              lastUpdated: DateTime.now(),
            );
            AppLogger.i('リアルタイム投稿更新 - 件数: ${posts.length}');
          }
        },
        onError: (error, stackTrace) {
          AppLogger.e('リアルタイム投稿更新エラー', error, stackTrace);
          if (mounted) {
            state = state.copyWith(
              error: error.toString(),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.e('リアルタイム投稿更新開始に失敗', e, stackTrace);
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
      );
    }
  }

  /// リアルタイム更新を停止
  void stopListening() {
    AppLogger.i('リアルタイム投稿更新停止');
    state = state.copyWith(
      isListening: false,
      currentBounds: null,
      currentRoomId: null,
    );
  }

  /// 範囲を更新
  void updateBounds(LatLngBounds? bounds) {
    if (state.isListening && bounds != state.currentBounds) {
      AppLogger.i('投稿取得範囲更新');
      startListening(bounds: bounds, roomId: state.currentRoomId);
    }
  }

  /// ルームを変更
  void changeRoom(String? roomId) {
    if (state.isListening && roomId != state.currentRoomId) {
      AppLogger.i('投稿取得ルーム変更 - roomId: $roomId');
      startListening(bounds: state.currentBounds, roomId: roomId);
    }
  }
}

/// リアルタイム投稿ストリーム状態
class PostStreamState {
  const PostStreamState({
    required this.isListening,
    required this.posts,
    this.currentBounds,
    this.currentRoomId,
    this.lastUpdated,
    this.error,
  });

  final bool isListening;
  final List<Post> posts;
  final LatLngBounds? currentBounds;
  final String? currentRoomId;
  final DateTime? lastUpdated;
  final String? error;

  PostStreamState copyWith({
    bool? isListening,
    List<Post>? posts,
    LatLngBounds? currentBounds,
    String? currentRoomId,
    DateTime? lastUpdated,
    String? error,
  }) {
    return PostStreamState(
      isListening: isListening ?? this.isListening,
      posts: posts ?? this.posts,
      currentBounds: currentBounds ?? this.currentBounds,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostStreamState &&
        other.isListening == isListening &&
        other.posts == posts &&
        other.currentBounds == currentBounds &&
        other.currentRoomId == currentRoomId &&
        other.lastUpdated == lastUpdated &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        isListening,
        posts,
        currentBounds,
        currentRoomId,
        lastUpdated,
        error,
      );
}

/// リアルタイム投稿ストリーム管理プロバイダー
final postStreamProvider = StateNotifierProvider<PostStreamNotifier, PostStreamState>((ref) {
  final repository = ref.read(postRepositoryProvider);
  return PostStreamNotifier(repository);
});

/// ルーム管理状態クラス
class RoomState {
  const RoomState({
    required this.isLoading,
    this.currentRoomId,
    this.generatedRoomIds,
    this.joinedRoomIds,
    this.error,
  });

  final bool isLoading;
  final String? currentRoomId;
  final List<String>? generatedRoomIds;
  final List<String>? joinedRoomIds;
  final String? error;

  RoomState copyWith({
    bool? isLoading,
    String? currentRoomId,
    List<String>? generatedRoomIds,
    List<String>? joinedRoomIds,
    String? error,
  }) {
    return RoomState(
      isLoading: isLoading ?? this.isLoading,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      generatedRoomIds: generatedRoomIds ?? this.generatedRoomIds,
      joinedRoomIds: joinedRoomIds ?? this.joinedRoomIds,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomState &&
        other.isLoading == isLoading &&
        other.currentRoomId == currentRoomId &&
        other.generatedRoomIds == generatedRoomIds &&
        other.joinedRoomIds == joinedRoomIds &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        currentRoomId,
        generatedRoomIds,
        joinedRoomIds,
        error,
      );
}

/// ルーム管理クラス
class RoomNotifier extends StateNotifier<RoomState> {
  final PostRepository _repository;

  RoomNotifier(this._repository)
      : super(const RoomState(
          isLoading: false,
          generatedRoomIds: [],
          joinedRoomIds: [],
        ));

  /// 新しいルームを生成
  Future<String?> generateRoom() async {
    try {
      AppLogger.i('ルーム生成開始');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final roomId = await _repository.generateRoomId();
      
      // 生成したルームIDを履歴に追加
      final updatedGenerated = <String>[...(state.generatedRoomIds ?? []), roomId];
      
      state = state.copyWith(
        isLoading: false,
        currentRoomId: roomId,
        generatedRoomIds: updatedGenerated,
      );
      
      AppLogger.i('ルーム生成完了 - id: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム生成に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// ルームに参加
  Future<bool> joinRoom(String roomId) async {
    try {
      AppLogger.i('ルーム参加開始 - id: $roomId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // ルームIDの有効性を検証
      final isValid = await _repository.validateRoomId(roomId);
      if (!isValid) {
        state = state.copyWith(
          isLoading: false,
          error: '無効なルームIDです',
        );
        return false;
      }
      
      // 参加したルームIDを履歴に追加
      final updatedJoined = <String>[...(state.joinedRoomIds ?? [])];
      if (!updatedJoined.contains(roomId)) {
        updatedJoined.add(roomId);
      }
      
      state = state.copyWith(
        isLoading: false,
        currentRoomId: roomId,
        joinedRoomIds: updatedJoined,
      );
      
      AppLogger.i('ルーム参加完了 - id: $roomId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム参加に失敗', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 現在のルームを設定
  void setCurrentRoom(String? roomId) {
    AppLogger.i('現在のルーム設定 - id: $roomId');
    state = state.copyWith(currentRoomId: roomId);
  }

  /// ルーム履歴をクリア
  void clearRoomHistory() {
    AppLogger.i('ルーム履歴をクリア');
    state = state.copyWith(
      generatedRoomIds: [],
      joinedRoomIds: [],
    );
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// ルーム管理プロバイダー
final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final repository = ref.read(postRepositoryProvider);
  return RoomNotifier(repository);
});

/// 投稿統計プロバイダー
final postStatsProvider = Provider<PostStats>((ref) {
  final posts = ref.watch(postProvider).posts;
  final roomId = ref.watch(currentRoomIdProvider);
  
  return PostStats(
    totalPosts: posts.length,
    postsInCurrentRoom: roomId != null 
        ? posts.where((post) => post.roomId == roomId).length 
        : 0,
    postsWithImages: posts.where((post) => post.imageUrl != null).length,
    postsWithoutImages: posts.where((post) => post.imageUrl == null).length,
  );
});

/// 投稿統計データクラス
class PostStats {
  const PostStats({
    required this.totalPosts,
    required this.postsInCurrentRoom,
    required this.postsWithImages,
    required this.postsWithoutImages,
  });

  final int totalPosts;
  final int postsInCurrentRoom;
  final int postsWithImages;
  final int postsWithoutImages;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostStats &&
        other.totalPosts == totalPosts &&
        other.postsInCurrentRoom == postsInCurrentRoom &&
        other.postsWithImages == postsWithImages &&
        other.postsWithoutImages == postsWithoutImages;
  }

  @override
  int get hashCode => Object.hash(
        totalPosts,
        postsInCurrentRoom,
        postsWithImages,
        postsWithoutImages,
      );
}