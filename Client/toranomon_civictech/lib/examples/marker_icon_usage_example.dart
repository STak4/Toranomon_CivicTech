import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../providers/marker_icon_provider.dart';

/// マーカーアイコン機能の使用例
/// 
/// この例では、MarkerIconProviderを使用してAdvanced Markerアイコンを
/// 生成し、地図上に表示する方法を示します。
class MarkerIconUsageExample extends ConsumerWidget {
  const MarkerIconUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markerIconState = ref.watch(markerIconNotifierProvider);
    final markerIconNotifier = ref.read(markerIconNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マーカーアイコン使用例'),
      ),
      body: Column(
        children: [
          // 状態表示
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ローディング中: ${markerIconState.isLoading}'),
                Text('キャッシュサイズ: ${markerIconState.iconCache.length}'),
                if (markerIconState.error != null)
                  Text(
                    'エラー: ${markerIconState.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          
          // 操作ボタン
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _generateSampleIcon(markerIconNotifier),
                child: const Text('サンプルアイコン生成'),
              ),
              ElevatedButton(
                onPressed: () => _preloadMultipleIcons(markerIconNotifier),
                child: const Text('複数アイコン事前読み込み'),
              ),
              ElevatedButton(
                onPressed: () => markerIconNotifier.clearIconCache(),
                child: const Text('キャッシュクリア'),
              ),
              ElevatedButton(
                onPressed: () => _showCacheStats(context, markerIconNotifier),
                child: const Text('統計表示'),
              ),
            ],
          ),
          
          // アイコン一覧表示
          Expanded(
            child: ListView.builder(
              itemCount: markerIconState.iconCache.length,
              itemBuilder: (context, index) {
                final entry = markerIconState.iconCache.entries.elementAt(index);
                final postId = entry.key;
                final iconData = entry.value;
                
                return ListTile(
                  leading: iconData.hasIcon
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.image, size: 20),
                        )
                      : const Icon(Icons.location_on),
                  title: Text('投稿ID: $postId'),
                  subtitle: Text(
                    iconData.hasIcon 
                        ? 'カスタムアイコン' 
                        : 'デフォルトアイコン',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => markerIconNotifier.clearIconCache(postId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// サンプルアイコンを生成
  void _generateSampleIcon(MarkerIconNotifier notifier) {
    final samplePost = Post(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user123',
      title: 'サンプル投稿',
      description: 'これはサンプルの投稿です',
      imageUrl: 'https://picsum.photos/200/200', // ランダム画像
      latitude: 35.6762,
      longitude: 139.6503,
      anchorId: 'anchor123',
      roomId: 'room123',
      createdAt: DateTime.now(),
    );
    
    notifier.generateIconForPost(samplePost);
  }

  /// 複数のアイコンを事前読み込み
  void _preloadMultipleIcons(MarkerIconNotifier notifier) {
    final samplePosts = List.generate(5, (index) {
      return Post(
        id: 'batch_${DateTime.now().millisecondsSinceEpoch}_$index',
        userId: 'user$index',
        title: 'バッチ投稿 $index',
        description: 'これはバッチ処理の投稿です',
        imageUrl: 'https://picsum.photos/200/200?random=$index',
        latitude: 35.6762 + (index * 0.001),
        longitude: 139.6503 + (index * 0.001),
        anchorId: 'anchor$index',
        roomId: 'room123',
        createdAt: DateTime.now(),
      );
    });
    
    notifier.preloadIcons(samplePosts);
  }

  /// キャッシュ統計を表示
  void _showCacheStats(BuildContext context, MarkerIconNotifier notifier) {
    final stats = notifier.getCacheStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャッシュ統計'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('総キャッシュ数: ${stats['totalCached']}'),
            Text('カスタムアイコン数: ${stats['withIcons']}'),
            Text('デフォルトアイコン数: ${stats['withoutIcons']}'),
            Text('ローディング中: ${stats['isLoading']}'),
            Text('エラー有無: ${stats['hasError']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// Google Maps上でマーカーアイコンを使用する例
class MapWithCustomMarkersExample extends ConsumerStatefulWidget {
  const MapWithCustomMarkersExample({super.key});

  @override
  ConsumerState<MapWithCustomMarkersExample> createState() => 
      _MapWithCustomMarkersExampleState();
}

class _MapWithCustomMarkersExampleState 
    extends ConsumerState<MapWithCustomMarkersExample> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カスタムマーカー地図'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSampleMarker,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(35.6762, 139.6503), // 東京駅
          zoom: 14.0,
        ),
        markers: _markers,
      ),
    );
  }

  /// サンプルマーカーを追加
  void _addSampleMarker() async {
    final markerIconNotifier = ref.read(markerIconNotifierProvider.notifier);
    
    // サンプル投稿を作成
    final post = Post(
      id: 'marker_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user123',
      title: 'マーカー投稿',
      description: 'これは地図上のマーカーです',
      imageUrl: 'https://picsum.photos/200/200?random=${_markers.length}',
      latitude: 35.6762 + (_markers.length * 0.002),
      longitude: 139.6503 + (_markers.length * 0.002),
      anchorId: 'anchor${_markers.length}',
      roomId: 'room123',
      createdAt: DateTime.now(),
    );

    // アイコンを生成
    await markerIconNotifier.generateIconForPost(post);
    
    // マーカーアイコンを取得
    final bitmapDescriptor = markerIconNotifier.getIconForPost(post.id);
    
    // マーカーを作成して地図に追加
    final marker = Marker(
      markerId: MarkerId(post.id),
      position: LatLng(post.latitude, post.longitude),
      icon: bitmapDescriptor,
      infoWindow: InfoWindow(
        title: post.title,
        snippet: post.description,
      ),
      onTap: () => _onMarkerTapped(post),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  /// マーカータップ時の処理
  void _onMarkerTapped(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.description),
            const SizedBox(height: 8),
            Text('作成日時: ${post.createdAt.toString()}'),
            Text('Anchor ID: ${post.anchorId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}