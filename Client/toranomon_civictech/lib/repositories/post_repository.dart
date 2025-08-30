import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';

/// 投稿のソート順
enum PostOrderBy {
  /// 作成日時昇順
  createdAtAsc,
  /// 作成日時降順
  createdAtDesc,
  /// タイトル昇順
  titleAsc,
  /// タイトル降順
  titleDesc,
}

/// ページネーション結果
class PostPaginationResult {
  const PostPaginationResult({
    required this.posts,
    required this.hasMore,
    required this.totalCount,
    required this.currentOffset,
    required this.limit,
  });

  final List<Post> posts;
  final bool hasMore;
  final int totalCount;
  final int currentOffset;
  final int limit;

  PostPaginationResult copyWith({
    List<Post>? posts,
    bool? hasMore,
    int? totalCount,
    int? currentOffset,
    int? limit,
  }) {
    return PostPaginationResult(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      currentOffset: currentOffset ?? this.currentOffset,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostPaginationResult &&
        other.posts == posts &&
        other.hasMore == hasMore &&
        other.totalCount == totalCount &&
        other.currentOffset == currentOffset &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(posts, hasMore, totalCount, currentOffset, limit);
}

/// 投稿リポジトリインターフェース
/// 
/// 投稿データのCRUD操作とルーム管理機能を提供するインターフェース
abstract class PostRepository {
  /// 指定された範囲内の投稿を取得
  /// 
  /// [bounds] 地図の表示範囲（オプション）
  /// [roomId] ルームID（オプション）
  /// [limit] 取得する投稿数の上限（デフォルト: 20）
  /// [offset] 取得開始位置（デフォルト: 0）
  /// [orderBy] ソート順（デフォルト: 作成日時降順）
  /// 戻り値: 投稿のリスト
  Future<List<Post>> getPosts({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    int offset = 0,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
  });

  /// 新しい投稿を作成
  /// 
  /// [request] 投稿作成リクエスト
  /// 戻り値: 作成された投稿
  Future<Post> createPost(CreatePostRequest request);

  /// 投稿を削除
  /// 
  /// [postId] 削除する投稿のID
  Future<void> deletePost(String postId);

  /// 投稿のリアルタイム更新ストリームを取得
  /// 
  /// [bounds] 地図の表示範囲（オプション）
  /// [roomId] ルームID（オプション）
  /// 戻り値: 投稿リストのストリーム
  Stream<List<Post>> getPostsStream({
    LatLngBounds? bounds,
    String? roomId,
  });

  /// 新しいルームIDを生成
  /// 
  /// 戻り値: 生成されたルームID
  Future<String> generateRoomId();

  /// ルームIDの有効性を検証
  /// 
  /// [roomId] 検証するルームID
  /// 戻り値: ルームIDが有効かどうか
  Future<bool> validateRoomId(String roomId);

  /// 指定されたルーム内の投稿を取得
  /// 
  /// [roomId] ルームID
  /// 戻り値: ルーム内の投稿リスト
  Future<List<Post>> getPostsInRoom(String roomId);

  /// 投稿をルームに追加
  /// 
  /// [roomId] ルームID
  /// [postId] 追加する投稿のID
  Future<void> addPostToRoom(String roomId, String postId);

  /// 投稿をルームから削除
  /// 
  /// [roomId] ルームID
  /// [postId] 削除する投稿のID
  Future<void> removePostFromRoom(String roomId, String postId);

  /// 投稿の詳細を取得
  /// 
  /// [postId] 投稿のID
  /// 戻り値: 投稿の詳細情報
  Future<Post?> getPostById(String postId);

  /// 投稿を更新
  /// 
  /// [post] 更新する投稿データ
  /// 戻り値: 更新された投稿
  Future<Post> updatePost(Post post);

  /// ページネーション対応の投稿取得
  /// 
  /// [bounds] 地図の表示範囲（オプション）
  /// [roomId] ルームID（オプション）
  /// [limit] 取得する投稿数の上限（デフォルト: 20）
  /// [offset] 取得開始位置（デフォルト: 0）
  /// [orderBy] ソート順（デフォルト: 作成日時降順）
  /// 戻り値: ページネーション結果
  Future<PostPaginationResult> getPostsPaginated({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    int offset = 0,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
  });
}