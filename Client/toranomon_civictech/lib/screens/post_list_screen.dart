import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/post_provider.dart';
import '../providers/room_provider.dart' show currentRoomIdProvider;
import '../utils/app_logger.dart';

/// 投稿一覧画面
/// 
/// スクロール可能な投稿リストを表示し、プルトゥリフレッシュ機能を提供
class PostListScreen extends ConsumerStatefulWidget {
  const PostListScreen({super.key});

  @override
  ConsumerState<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends ConsumerState<PostListScreen> {
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

  @override
  void initState() {
    super.initState();
    
    // 画面表示時のログ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.i('投稿一覧画面が表示されました');
      _loadInitialPosts();
    });

    // 無限スクロール用のリスナー設定
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 初期投稿データの読み込み
  void _loadInitialPosts() {
    final currentRoomId = ref.read(currentRoomIdProvider);
    ref.read(postProvider.notifier).loadPostsPaginated(
      roomId: currentRoomId,
      refresh: false,
    );
  }

  /// スクロール時の処理（無限スクロール用）
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      // 80%スクロールしたら追加データを読み込み
      _loadMorePosts();
    }
  }

  /// 追加投稿データの読み込み
  void _loadMorePosts() {
    final currentRoomId = ref.read(currentRoomIdProvider);
    ref.read(postProvider.notifier).loadMorePosts(roomId: currentRoomId);
  }

  /// プルトゥリフレッシュ処理
  Future<void> _onRefresh() async {
    try {
      AppLogger.i('投稿一覧のリフレッシュ開始');
      
      final currentRoomId = ref.read(currentRoomIdProvider);
      await ref.read(postProvider.notifier).loadPostsPaginated(
        roomId: currentRoomId,
        refresh: true,
      );
      
      AppLogger.i('投稿一覧のリフレッシュ完了');
    } catch (e, stackTrace) {
      AppLogger.e('投稿一覧のリフレッシュに失敗', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リフレッシュに失敗しました: $e')),
        );
      }
    }
  }

  /// 投稿タップ時の処理
  void _onPostTap(Post post) {
    AppLogger.i('投稿がタップされました - postId: ${post.id}');
    
    // 投稿詳細表示または地図遷移
    showDialog(
      context: context,
      builder: (context) => _PostDetailDialog(post: post),
    );
  }

  /// 地図で表示ボタンの処理
  void _showOnMap(Post post) {
    AppLogger.i('地図で表示 - postId: ${post.id}');
    
    // 地図画面に遷移して該当の投稿位置を表示
    context.goNamed('map', extra: {
      'centerLatitude': post.latitude,
      'centerLongitude': post.longitude,
      'focusPostId': post.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postProvider);
    final currentRoomId = ref.watch(currentRoomIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿一覧'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppLogger.i('投稿一覧画面から戻る');
            context.pop();
          },
        ),
        actions: [
          // 現在のルーム情報表示
          if (currentRoomId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Chip(
                  label: Text(
                    'ルーム: $currentRoomId',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
          // リフレッシュボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: postState.isLoading ? null : _onRefresh,
          ),
        ],
      ),
      body: _buildBody(postState),
    );
  }

  Widget _buildBody(PostState postState) {
    if (postState.isLoading && postState.posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('投稿を読み込み中...'),
          ],
        ),
      );
    }

    if (postState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              postState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (postState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '投稿がありません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('地図画面から投稿を作成してみましょう'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                AppLogger.i('地図画面への遷移');
                context.goNamed('map');
              },
              child: const Text('地図画面へ'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: postState.posts.length + (postState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // ローディングインジケーター（追加読み込み中）
          if (index >= postState.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('追加の投稿を読み込み中...'),
                  ],
                ),
              ),
            );
          }

          final post = postState.posts[index];
          return _PostListItem(
            post: post,
            onTap: () => _onPostTap(post),
            onShowOnMap: () => _showOnMap(post),
            dateFormat: _dateFormat,
          );
        },
      ),
    );
  }
}

/// 投稿リストアイテムウィジェット
class _PostListItem extends StatelessWidget {
  const _PostListItem({
    required this.post,
    required this.onTap,
    required this.onShowOnMap,
    required this.dateFormat,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onShowOnMap;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分（タイトルと時間）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 画像とコンテンツ部分
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 投稿画像
                  if (post.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.broken_image),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // テキストコンテンツ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 説明文
                        Text(
                          post.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // 位置情報とAnchor ID
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${post.latitude.toStringAsFixed(4)}, ${post.longitude.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (post.anchorId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.anchor,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Anchor: ${post.anchorId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // アクションボタン
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onShowOnMap,
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('地図で表示'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 投稿詳細ダイアログ
class _PostDetailDialog extends StatelessWidget {
  const _PostDetailDialog({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // コンテンツ
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 画像
                    if (post.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48),
                                    SizedBox(height: 8),
                                    Text('画像を読み込めませんでした'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 説明文
                    Text(
                      '説明',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // 詳細情報
                    _buildDetailRow(
                      context,
                      '作成日時',
                      dateFormat.format(post.createdAt),
                      Icons.schedule,
                    ),
                    _buildDetailRow(
                      context,
                      '位置情報',
                      '${post.latitude.toStringAsFixed(6)}, ${post.longitude.toStringAsFixed(6)}',
                      Icons.location_on,
                    ),
                    if (post.anchorId.isNotEmpty)
                      _buildDetailRow(
                        context,
                        'Anchor ID',
                        post.anchorId,
                        Icons.anchor,
                      ),
                    _buildDetailRow(
                      context,
                      'ルームID',
                      post.roomId,
                      Icons.room,
                    ),
                    if (post.author != null)
                      _buildDetailRow(
                        context,
                        '作成者',
                        post.author!.displayName ?? post.author!.email,
                        Icons.person,
                      ),
                  ],
                ),
              ),
            ),

            // アクションボタン
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.goNamed('map', extra: {
                          'centerLatitude': post.latitude,
                          'centerLongitude': post.longitude,
                          'focusPostId': post.id,
                        });
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('地図で表示'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}