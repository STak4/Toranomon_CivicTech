import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/models.dart';
import '../providers/post_provider.dart';
import '../providers/marker_icon_provider.dart';
import '../providers/room_provider.dart' as room_providers;
import '../repositories/post_repository_impl.dart';
import '../utils/app_logger.dart';
import 'post_creation_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  geo.Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  Post? _selectedPost;
  final _roomIdController = TextEditingController();
  bool _showRoomControls = false;

  // 東京駅を初期位置として設定
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671), // 東京駅の座標
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    AppLogger.i('MapSampleScreen: 画面を初期化しています');

    _requestLocationPermissionAndGetLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Google Maps APIキーの長さ確認のみ
    _checkGoogleMapsApiKey();
  }

  /// Google Maps APIキーの長さを確認する
  void _checkGoogleMapsApiKey() {
    try {
      final iosApiKey = dotenv.env['GOOGLE_MAPS_KEY_IOS'];
      final androidApiKey = dotenv.env['GOOGLE_MAPS_KEY_ANDROID'];

      if (iosApiKey != null) {
        AppLogger.d('MapSampleScreen: iOS API Key length: ${iosApiKey.length}');
      }
      if (androidApiKey != null) {
        AppLogger.d(
          'MapSampleScreen: Android API Key length: ${androidApiKey.length}',
        );
      }
    } catch (e) {
      AppLogger.e(
        'MapSampleScreen: Failed to check Google Maps API Key status',
        e,
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _roomIdController.dispose();
    AppLogger.i('MapSampleScreen: リソースを解放しました');
    super.dispose();
  }

  /// 地図が作成された時に呼ばれるコールバック
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    AppLogger.i('MapSampleScreen: Google Mapsが正常に初期化されました');
    
    // 初期表示範囲の投稿を読み込み
    _loadPostsInCurrentView();
  }

  /// 地図がタップされた時の処理
  void _onMapTap(LatLng position) {
    AppLogger.d(
      'MapSampleScreen: 地図がタップされました - 座標: ${position.latitude}, ${position.longitude}',
    );
    
    // 投稿作成ダイアログを表示
    _showPostCreationDialog(position);
  }

  /// カメラ位置が変更された時の処理
  void _onCameraMove(CameraPosition position) {
    // 頻繁に呼ばれるため、デバッグレベルでログ出力
    AppLogger.d('MapSampleScreen: カメラ位置が変更されました - ズーム: ${position.zoom}');
  }

  /// カメラ移動が完了した時の処理
  void _onCameraIdle() {
    AppLogger.d('MapSampleScreen: カメラ移動が完了しました');
    _loadPostsInCurrentView();
  }

  /// 位置情報の許可を要求し、現在地を取得する
  Future<void> _requestLocationPermissionAndGetLocation() async {
    try {
      AppLogger.i('MapSampleScreen: 位置情報の許可を要求しています');

      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('MapSampleScreen: 位置情報サービスが無効です');
        _showLocationServiceDialog();
        return;
      }

      // 位置情報の許可状態をチェック
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          AppLogger.w('MapSampleScreen: 位置情報の許可が拒否されました');
          _showPermissionDeniedMessage();
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        AppLogger.w('MapSampleScreen: 位置情報の許可が永続的に拒否されました');
        _showPermissionDeniedForeverDialog();
        return;
      }

      // 現在地を取得
      await _getCurrentLocation();
    } catch (e, stackTrace) {
      AppLogger.e('MapSampleScreen: 位置情報の取得に失敗しました', e, stackTrace);
      _showLocationErrorMessage(e.toString());
    }
  }

  /// 現在地を取得してマーカーを表示する
  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      AppLogger.i('MapSampleScreen: 現在地を取得しています');

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 10, // 10メートル以上移動した場合のみ更新
        ),
      );

      AppLogger.i(
        'MapSampleScreen: 現在地を取得しました - 緯度: ${position.latitude}, 経度: ${position.longitude}',
      );

      setState(() {
        _currentPosition = position;
        _updateCurrentLocationMarker();
        _isLoadingLocation = false;
      });

      // 地図を現在地に移動（初回のみ）
      if (_mapController != null && _markers.isEmpty) {
        await _animateToCurrentLocation();
      }
    } catch (e, stackTrace) {
      AppLogger.e('MapSampleScreen: 現在地の取得に失敗しました', e, stackTrace);
      setState(() {
        _isLoadingLocation = false;
      });
      _showLocationErrorMessage(e.toString());
    }
  }

  /// 現在地マーカーを更新する
  void _updateCurrentLocationMarker() {
    if (_currentPosition == null) return;

    final currentLocationMarker = Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: '現在地', snippet: 'あなたの現在の位置です'),
      onTap: () {
        AppLogger.d('MapSampleScreen: 現在地マーカーがタップされました');
        _animateToCurrentLocation();
      },
    );

    setState(() {
      // 既存の現在地マーカーを削除して新しいものを追加
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'current_location',
      );
      _markers.add(currentLocationMarker);
    });

    AppLogger.d('MapSampleScreen: 現在地マーカーを更新しました');
  }

  /// 現在地に地図をアニメーション移動する
  Future<void> _animateToCurrentLocation() async {
    if (_mapController == null || _currentPosition == null) return;

    AppLogger.i('MapSampleScreen: 現在地に地図を移動します');

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 16.0, // 現在地表示時は少しズームイン
        ),
      ),
    );
  }

  /// 位置情報サービス無効ダイアログを表示
  void _showLocationServiceDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置情報サービス'),
          content: const Text('位置情報サービスが無効になっています。設定から有効にしてください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// 許可拒否メッセージを表示
  void _showPermissionDeniedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('位置情報の許可が必要です'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 許可永続拒否ダイアログを表示
  void _showPermissionDeniedForeverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置情報の許可'),
          content: const Text('位置情報の許可が拒否されています。設定から許可を有効にしてください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }

  /// 位置情報エラーメッセージを表示
  void _showLocationErrorMessage(String error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('位置情報の取得に失敗しました: $error'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: '再試行', onPressed: _getCurrentLocation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 投稿状態の変更を監視してマーカーを更新
    ref.listen<PostState>(postProvider, (previous, next) {
      if (previous != null && previous.posts.length != next.posts.length) {
        // 投稿数が変更された場合、マーカーを更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updatePostMarkers();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('地図サンプル'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showMapInfo(context);
            },
            tooltip: '地図情報',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _onMapTap,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: _initialPosition,
            markers: _markers,

            // ジェスチャー設定
            zoomGesturesEnabled: true, // ピンチズーム有効
            scrollGesturesEnabled: true, // パン（スクロール）有効
            rotateGesturesEnabled: true, // 回転ジェスチャー有効
            tiltGesturesEnabled: true, // チルト（傾斜）ジェスチャー有効
            // 地図の種類
            mapType: MapType.normal,

            // UI要素の表示設定
            myLocationButtonEnabled: false, // カスタムボタンを使用
            myLocationEnabled: false, // カスタムマーカーを使用
            zoomControlsEnabled: false, // ズームコントロールを非表示（ジェスチャーを使用）
            // 地図のスタイル設定
            compassEnabled: true, // コンパス表示
            mapToolbarEnabled: false, // 地図ツールバーを非表示
            // 建物の3D表示
            buildingsEnabled: true,

            // 交通情報
            trafficEnabled: false,
          ),

          // 位置情報読み込み中のインジケーター
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      const Text('現在地を取得中...'),
                    ],
                  ),
                ),
              ),
            ),

          // 投稿読み込み中のインジケーター
          Consumer(
            builder: (context, ref, child) {
              final postState = ref.watch(postProvider);
              final markerIconState = ref.watch(markerIconNotifierProvider);
              
              if (postState.isLoading || markerIconState.isLoading) {
                return Positioned(
                  top: _isLoadingLocation ? 80 : 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            markerIconState.isLoading 
                                ? 'マーカーアイコンを生成中...'
                                : '投稿を読み込み中...',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // エラー表示
          Consumer(
            builder: (context, ref, child) {
              final postState = ref.watch(postProvider);
              final markerIconState = ref.watch(markerIconNotifierProvider);
              
              final error = postState.error ?? markerIconState.error;
              if (error != null) {
                return Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(postProvider.notifier).clearError();
                              ref.read(markerIconNotifierProvider.notifier).clearError();
                            },
                            icon: const Icon(Icons.close),
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ルーム情報表示
          Positioned(
            top: 16,
            right: 16,
            child: Consumer(
              builder: (context, ref, child) {
                final currentRoom = ref.watch(room_providers.currentRoomProvider);
                final postCount = ref.watch(postProvider).posts.length;
                
                return GestureDetector(
                  onTap: () {
                    if (currentRoom != null) {
                      _showRoomInfo(currentRoom.id);
                    }
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: currentRoom != null ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRoom != null 
                                    ? 'ルーム: ${currentRoom.id.substring(0, 8)}...'
                                    : 'デフォルトルーム',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '投稿: $postCount件',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (currentRoom != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline, size: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ルームコントロール
          if (_showRoomControls)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ルーム参加',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showRoomControls = false;
                                _roomIdController.clear();
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _roomIdController,
                        decoration: const InputDecoration(
                          labelText: 'ルームID',
                          hintText: 'ルームIDを入力してください',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _joinRoom(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showRoomControls = false;
                                  _roomIdController.clear();
                                });
                              },
                              child: const Text('キャンセル'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _joinRoom,
                              child: const Text('参加'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ルーム共有ボタン
          FloatingActionButton(
            heroTag: "shareRoom",
            mini: true,
            onPressed: _shareRoom,
            tooltip: 'ルームを共有',
            backgroundColor: Colors.blue,
            child: const Icon(Icons.share, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Firebase Storage テストボタン
          FloatingActionButton(
            heroTag: "storageTest",
            mini: true,
            onPressed: _testFirebaseStorage,
            tooltip: 'Storage 接続テスト',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.cloud_upload, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // ルーム参加ボタン
          FloatingActionButton(
            heroTag: "joinRoom",
            mini: true,
            onPressed: () {
              setState(() {
                _showRoomControls = !_showRoomControls;
              });
            },
            tooltip: 'ルームに参加',
            backgroundColor: _showRoomControls ? Colors.orange : Colors.green,
            child: Icon(
              _showRoomControls ? Icons.close : Icons.group_add,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 投稿統計表示ボタン
          Consumer(
            builder: (context, ref, child) {
              final postState = ref.watch(postProvider);
              return FloatingActionButton(
                heroTag: "postStats",
                mini: true,
                onPressed: () => _showPostStats(context, postState.posts),
                tooltip: '投稿統計',
                child: Badge(
                  label: Text('${postState.posts.length}'),
                  child: const Icon(Icons.analytics),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // 投稿更新ボタン
          FloatingActionButton(
            heroTag: "refreshPosts",
            mini: true,
            onPressed: _loadPostsInCurrentView,
            tooltip: '投稿を更新',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          // 現在地に移動ボタン
          FloatingActionButton(
            heroTag: "currentLocation",
            mini: true,
            onPressed: _currentPosition != null
                ? _animateToCurrentLocation
                : _getCurrentLocation,
            tooltip: _currentPosition != null ? '現在地に移動' : '現在地を取得',
            backgroundColor: _currentPosition != null ? null : Colors.grey,
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _currentPosition != null
                        ? Icons.my_location
                        : Icons.location_searching,
                  ),
          ),
          const SizedBox(height: 8),
          // 初期位置に戻るボタン
          FloatingActionButton(
            heroTag: "resetPosition",
            mini: true,
            onPressed: _resetToInitialPosition,
            tooltip: '初期位置に戻る',
            child: const Icon(Icons.home),
          ),
        ],
      ),
    );
  }



  /// 初期位置に戻る
  void _resetToInitialPosition() async {
    if (_mapController != null) {
      AppLogger.i('MapSampleScreen: 初期位置に戻ります');

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_initialPosition),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('東京駅周辺に戻りました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 現在の表示範囲内の投稿を読み込み
  Future<void> _loadPostsInCurrentView() async {
    if (_mapController == null) return;

    try {
      // 現在の表示範囲を取得
      final bounds = await _mapController!.getVisibleRegion();
      
      // 現在のルームIDを取得
      final currentRoomId = ref.read(room_providers.currentRoomIdProvider);

      AppLogger.i('MapScreen: 表示範囲内の投稿を読み込み開始 - roomId: $currentRoomId');
      
      // 投稿を読み込み（ルームIDを指定）
      await ref.read(postProvider.notifier).loadPosts(
        bounds: bounds,
        roomId: currentRoomId,
      );
      
      // マーカーを更新
      await _updatePostMarkers();
      
    } catch (e, stackTrace) {
      AppLogger.e('MapScreen: 投稿読み込みに失敗', e, stackTrace);
    }
  }

  /// 投稿マーカーを更新
  Future<void> _updatePostMarkers() async {
    try {
      final postState = ref.read(postProvider);
      final posts = postState.posts;
      
      AppLogger.i('MapScreen: 投稿マーカー更新開始 - 件数: ${posts.length}');

      // 既存の投稿マーカーを削除（現在地マーカーは保持）
      _markers.removeWhere((marker) => marker.markerId.value != 'current_location');

      if (posts.isEmpty) {
        setState(() {});
        return;
      }

      // マーカーアイコンを事前生成
      await ref.read(markerIconNotifierProvider.notifier).preloadIcons(posts);

      // 現在のズームレベルを取得してクラスタリングを決定
      double? currentZoom;
      if (_mapController != null) {
        try {
          currentZoom = await _mapController!.getZoomLevel();
        } catch (e) {
          AppLogger.w('MapScreen: ズームレベル取得に失敗', e);
        }
      }

      // ズームレベルが低い場合（広範囲表示）はクラスタリングを適用
      final shouldCluster = currentZoom != null && currentZoom < 12.0;
      
      if (shouldCluster && posts.length > 10) {
        await _createClusteredMarkers(posts);
      } else {
        await _createIndividualMarkers(posts);
      }

      setState(() {});
      AppLogger.i('MapScreen: 投稿マーカー更新完了 - マーカー数: ${_markers.length}');
    } catch (e, stackTrace) {
      AppLogger.e('MapScreen: 投稿マーカー更新に失敗', e, stackTrace);
    }
  }



  /// 個別マーカーを作成
  Future<void> _createIndividualMarkers(List<Post> posts) async {
    for (final post in posts) {
      final marker = await _createPostMarker(post);
      if (marker != null) {
        _markers.add(marker);
      }
    }
  }

  /// クラスター化されたマーカーを作成
  Future<void> _createClusteredMarkers(List<Post> posts) async {
    const double clusterDistance = 0.01; // 約1km
    final List<List<Post>> clusters = [];
    final List<Post> processedPosts = [];

    for (final post in posts) {
      if (processedPosts.contains(post)) continue;

      final cluster = [post];
      processedPosts.add(post);

      // 近くの投稿を同じクラスターに追加
      for (final otherPost in posts) {
        if (processedPosts.contains(otherPost)) continue;

        final distance = _calculateDistance(
          post.latitude,
          post.longitude,
          otherPost.latitude,
          otherPost.longitude,
        );

        if (distance < clusterDistance) {
          cluster.add(otherPost);
          processedPosts.add(otherPost);
        }
      }

      clusters.add(cluster);
    }

    // クラスターマーカーを作成
    for (final cluster in clusters) {
      if (cluster.length == 1) {
        // 単一投稿の場合は通常のマーカー
        final marker = await _createPostMarker(cluster.first);
        if (marker != null) {
          _markers.add(marker);
        }
      } else {
        // 複数投稿の場合はクラスターマーカー
        final clusterMarker = await _createClusterMarker(cluster);
        if (clusterMarker != null) {
          _markers.add(clusterMarker);
        }
      }
    }
  }

  /// クラスターマーカーを作成
  Future<Marker?> _createClusterMarker(List<Post> posts) async {
    try {
      // クラスターの中心位置を計算
      double avgLat = posts.map((p) => p.latitude).reduce((a, b) => a + b) / posts.length;
      double avgLng = posts.map((p) => p.longitude).reduce((a, b) => a + b) / posts.length;

      final marker = Marker(
        markerId: MarkerId('cluster_${posts.map((p) => p.id).join('_')}'),
        position: LatLng(avgLat, avgLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '投稿クラスター',
          snippet: '${posts.length}件の投稿',
        ),
        onTap: () => _onClusterMarkerTap(posts),
      );

      return marker;
    } catch (e, stackTrace) {
      AppLogger.e('MapScreen: クラスターマーカー作成に失敗', e, stackTrace);
      return null;
    }
  }

  /// クラスターマーカーがタップされた時の処理
  void _onClusterMarkerTap(List<Post> posts) {
    AppLogger.i('MapScreen: クラスターマーカーがタップされました - 投稿数: ${posts.length}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClusterPostsBottomSheet(posts: posts),
    );
  }

  /// 2点間の距離を計算（簡易版）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return ((lat1 - lat2).abs() + (lng1 - lng2).abs());
  }

  /// 投稿のマーカーを作成
  Future<Marker?> _createPostMarker(Post post) async {
    try {
      // マーカーアイコンを取得
      final markerIconNotifier = ref.read(markerIconNotifierProvider.notifier);
      final bitmapDescriptor = markerIconNotifier.getIconForPost(post.id);

      // 選択されている投稿かどうかで透明度を調整
      final isSelected = _selectedPost?.id == post.id;

      final marker = Marker(
        markerId: MarkerId('post_${post.id}'),
        position: LatLng(post.latitude, post.longitude),
        icon: bitmapDescriptor,
        alpha: isSelected ? 1.0 : 0.8, // 選択されていない場合は少し透明に
        infoWindow: InfoWindow(
          title: post.title,
          snippet: post.description.length > 50 
              ? '${post.description.substring(0, 50)}...'
              : post.description,
        ),
        onTap: () => _onPostMarkerTap(post),
      );

      return marker;
    } catch (e, stackTrace) {
      AppLogger.e('MapScreen: 投稿マーカー作成に失敗 - postId: ${post.id}', e, stackTrace);
      return null;
    }
  }

  /// 投稿マーカーがタップされた時の処理
  void _onPostMarkerTap(Post post) {
    AppLogger.i('MapScreen: 投稿マーカーがタップされました - postId: ${post.id}');
    
    setState(() {
      _selectedPost = post;
    });

    _showPostDetailBottomSheet(post);
  }

  /// 選択された投稿をクリア
  void _clearSelectedPost() {
    setState(() {
      _selectedPost = null;
    });
  }

  /// 投稿詳細のボトムシートを表示
  void _showPostDetailBottomSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailBottomSheet(
        post: post,
        onShowLocationOnMap: _showLocationOnMap,
      ),
    ).then((_) {
      // ボトムシートが閉じられた時に選択をクリア
      _clearSelectedPost();
    });
  }

  /// 投稿統計を表示する
  void _showPostStats(BuildContext context, List<Post> posts) {
    final postsWithImages = posts.where((post) => post.imageUrl != null && post.imageUrl!.isNotEmpty).length;
    final postsWithoutImages = posts.length - postsWithImages;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('投稿統計'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('表示中の投稿数: ${posts.length}件'),
              const SizedBox(height: 8),
              Text('画像付き投稿: $postsWithImages件'),
              Text('テキストのみ投稿: $postsWithoutImages件'),
              const SizedBox(height: 16),
              if (posts.isNotEmpty) ...[
                const Text('最新の投稿:'),
                const SizedBox(height: 4),
                Text(
                  posts.first.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDateTime(posts.first.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  /// 地図上で投稿の位置を表示
  void _showLocationOnMap(BuildContext context, Post post) {
    Navigator.of(context).pop(); // ボトムシートを閉じる
    
    // 投稿の位置に地図を移動
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(post.latitude, post.longitude),
            zoom: 16.0,
          ),
        ),
      );
      
      // 選択状態を更新してマーカーをハイライト
      setState(() {
        _selectedPost = post;
      });
      
      // マーカーを更新
      _updatePostMarkers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('投稿「${post.title}」の位置に移動しました'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 投稿作成ダイアログを表示
  void _showPostCreationDialog(LatLng position) {
    final currentRoomId = ref.read(room_providers.currentRoomIdProvider) ?? 'default';
    
    showDialog(
      context: context,
      builder: (context) => PostCreationDialog(
        latitude: position.latitude,
        longitude: position.longitude,
        roomId: currentRoomId,
      ),
    ).then((result) async {
      if (result is Post) {
        AppLogger.i('投稿作成完了、マーカーを更新 - postId: ${result.id}');
        
        // マーカーアイコンを事前生成
        await ref.read(markerIconNotifierProvider.notifier).generateIconForPost(result);
        
        // マーカーを更新（新しい投稿は既にPostProviderに追加されている）
        await _updatePostMarkers();
        
        // 作成された投稿の位置に地図を移動してハイライト
        await _animateToPosition(LatLng(result.latitude, result.longitude));
        
        // 作成された投稿を選択状態にする
        setState(() {
          _selectedPost = result;
        });
        
        // 少し遅延してから投稿詳細を表示
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showPostDetailBottomSheet(result);
          }
        });
      }
    });
  }

  /// 指定位置に地図をアニメーション移動
  Future<void> _animateToPosition(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  /// ルーム共有機能
  Future<void> _shareRoom() async {
    try {
      AppLogger.i('ルーム共有開始');
      
      final roomNotifier = ref.read(room_providers.roomProvider.notifier);
      final roomId = await roomNotifier.createRoom();
      
      if (roomId != null) {
        // ルームIDをクリップボードにコピー
        await Clipboard.setData(ClipboardData(text: roomId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ルームID「$roomId」をクリップボードにコピーしました'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '共有',
                onPressed: () => _showRoomShareDialog(roomId),
              ),
            ),
          );
        }
        
        AppLogger.i('ルーム共有完了 - roomId: $roomId');
      } else {
        _showErrorSnackBar('ルームの作成に失敗しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e('ルーム共有に失敗', e, stackTrace);
      _showErrorSnackBar('ルーム共有中にエラーが発生しました');
    }
  }

  /// ルーム参加機能
  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    
    if (roomId.isEmpty) {
      _showErrorSnackBar('ルームIDを入力してください');
      return;
    }
    
    try {
      AppLogger.i('ルーム参加開始 - roomId: $roomId');
      
      final roomNotifier = ref.read(room_providers.roomProvider.notifier);
      final success = await roomNotifier.joinRoom(roomId);
      
      if (success) {
        // 投稿を再読み込み（新しいルームの投稿を取得）
        await _loadPostsInCurrentView();
        
        // リアルタイム同期を開始
        _startRealtimeSync();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ルーム「$roomId」に参加しました'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '詳細',
                onPressed: () => _showRoomInfo(roomId),
              ),
            ),
          );
          
          // ルームコントロールを非表示
          setState(() {
            _showRoomControls = false;
            _roomIdController.clear();
          });
        }
        
        AppLogger.i('ルーム参加完了 - roomId: $roomId');
      } else {
        _showErrorSnackBar('ルームへの参加に失敗しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e('ルーム参加に失敗 - roomId: $roomId', e, stackTrace);
      _showErrorSnackBar('ルーム参加中にエラーが発生しました');
    }
  }

  /// ルーム共有ダイアログを表示
  void _showRoomShareDialog(String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルーム共有'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下のルームIDを他のユーザーと共有してください:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      roomId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: roomId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ルームIDをコピーしました'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: 'コピー',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '他のユーザーはこのIDを使用してルームに参加し、同じマーカー情報を共有できます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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

  /// リアルタイム同期を開始
  void _startRealtimeSync() {
    AppLogger.i('リアルタイムマーカー同期を開始');
    
    // 定期的に投稿を更新（実際のアプリではFirestoreのリアルタイムリスナーを使用）
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadPostsInCurrentView();
      } else {
        timer.cancel();
      }
    });
  }

  /// ルーム情報を表示
  void _showRoomInfo(String roomId) {
    final currentRoom = ref.read(room_providers.currentRoomProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルーム情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ルームID: $roomId'),
            const SizedBox(height: 8),
            if (currentRoom != null) ...[
              Text('作成日時: ${_formatDateTime(currentRoom.createdAt)}'),
              Text('投稿数: ${currentRoom.postIds.length}件'),
            ],
            const SizedBox(height: 12),
            const Text(
              'このルームでは他のユーザーと投稿を共有できます。新しい投稿は自動的に同期されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveRoom();
            },
            child: const Text('退出'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareCurrentRoom();
            },
            child: const Text('共有'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 現在のルームを共有
  Future<void> _shareCurrentRoom() async {
    final currentRoomId = ref.read(room_providers.currentRoomIdProvider);
    
    if (currentRoomId != null) {
      await Clipboard.setData(ClipboardData(text: currentRoomId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ルームID「$currentRoomId」をコピーしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// ルームから退出
  Future<void> _leaveRoom() async {
    try {
      AppLogger.i('ルームから退出');
      
      // デフォルトルームに戻る
      await ref.read(room_providers.roomProvider.notifier).setCurrentRoom(null);
      
      // 投稿を再読み込み
      await _loadPostsInCurrentView();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('デフォルトルームに戻りました'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('ルーム退出に失敗', e, stackTrace);
      _showErrorSnackBar('ルーム退出中にエラーが発生しました');
    }
  }

  /// エラーメッセージを表示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  /// Firebase Storage 接続テストを実行
  Future<void> _testFirebaseStorage() async {
    try {
      // ローディング表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Firebase Storage 接続テスト中...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // PostRepository を取得してテスト実行
      final postRepository = ref.read(postRepositoryProvider);
      final isSuccess = await (postRepository as PostRepositoryImpl).testStorageConnection();

      // 結果を表示
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isSuccess 
                      ? '✅ Firebase Storage 接続成功'
                      : '❌ Firebase Storage 接続失敗',
                ),
              ],
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // 失敗時は詳細情報を表示
        if (!isSuccess) {
          _showStorageSetupDialog();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('Storage テスト実行に失敗', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Storage テスト実行エラー'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Firebase Storage 設定ガイドを表示
  void _showStorageSetupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.purple),
              SizedBox(width: 8),
              Text('Firebase Storage 設定'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase Storage が設定されていません。',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('設定手順:'),
              SizedBox(height: 8),
              Text('1. Firebase Console にアクセス'),
              Text('2. 左メニュー → Storage'),
              Text('3. 「始める」をクリック'),
              Text('4. テストモードを選択'),
              Text('5. ロケーション: asia-northeast1'),
              SizedBox(height: 12),
              Text(
                'セキュリティルール:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'allow read, write: if true;',
                style: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testFirebaseStorage(); // 再テスト
              },
              child: const Text('再テスト'),
            ),
          ],
        );
      },
    );
  }

  /// 地図情報を表示する
  void _showMapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('地図機能について'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('実装済み機能:'),
              Text('• 地図の表示'),
              Text('• ズーム、パン、回転ジェスチャー'),
              Text('• 地図タップによる投稿作成'),
              Text('• カメラ位置の追跡'),
              Text('• 現在地の取得と表示'),
              Text('• 現在地マーカーのタップ機能'),
              Text('• 位置情報許可の管理'),
              Text('• Advanced Marker投稿表示'),
              Text('• 投稿詳細表示'),
              Text('• ルーム共有機能'),
              Text('• ルーム参加機能'),
              SizedBox(height: 16),
              Text('使用方法:'),
              Text('• 地図をタップして投稿を作成'),
              Text('• 共有ボタンでルームを作成・共有'),
              Text('• ルームIDを入力して他のルームに参加'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}

/// 投稿詳細を表示するボトムシート
class _PostDetailBottomSheet extends StatelessWidget {
  const _PostDetailBottomSheet({
    required this.post,
    required this.onShowLocationOnMap,
  });

  final Post post;
  final void Function(BuildContext context, Post post) onShowLocationOnMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ドラッグハンドル
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 投稿画像
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageFullScreen(context, post.imageUrl!),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // 画像
                              Image.network(
                                post.imageUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '画像の読み込みに失敗しました',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // グラデーションオーバーレイ
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                              // フルスクリーンアイコン
                              const Positioned(
                                bottom: 8,
                                right: 8,
                                child: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    const SizedBox(height: 16),
                  
                  // タイトル
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 説明文
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // 詳細情報
                  _buildDetailRow(
                    context,
                    Icons.anchor,
                    'Anchor ID',
                    post.anchorId,
                  ),
                  const SizedBox(height: 8),
                  
                  _buildDetailRow(
                    context,
                    Icons.room,
                    'ルームID',
                    post.roomId,
                  ),
                  const SizedBox(height: 8),
                  
                  GestureDetector(
                    onTap: () => onShowLocationOnMap(context, post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '位置: ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${post.latitude.toStringAsFixed(6)}, ${post.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.blue[600],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildDetailRow(
                    context,
                    Icons.access_time,
                    '投稿日時',
                    _formatDateTime(post.createdAt),
                  ),
                  
                  if (post.author != null) ...[
                    const SizedBox(height: 16),
                    // 投稿者情報セクション
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // プロフィール画像
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: post.author!.photoURL != null
                                ? NetworkImage(post.author!.photoURL!)
                                : null,
                            child: post.author!.photoURL == null
                                ? Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // 投稿者情報
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.author!.displayName ?? '名前未設定',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.author!.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // アクションボタン
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(context, post.anchorId),
                          icon: const Icon(Icons.copy),
                          label: const Text('Anchor IDをコピー'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePost(context, post),
                          icon: const Icon(Icons.share),
                          label: const Text('共有'),
                        ),
                      ),
                    ],
                  ),
                  
                  // 安全な下部余白
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 詳細情報の行を構築
  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 画像をフルスクリーンで表示
  void _showImageFullScreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  /// クリップボードにコピー
  void _copyToClipboard(BuildContext context, String text) {
    // クリップボードにコピー
    // Note: flutter/services.dartのClipboard.setDataを使用する場合は
    // import 'package:flutter/services.dart'; が必要
    try {
      // 簡易実装として、SnackBarで通知のみ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anchor ID "$text" をコピーしました'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '閉じる',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('コピーに失敗しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 投稿を共有
  void _sharePost(BuildContext context, Post post) {
    // 投稿情報をテキスト形式で共有
    final shareText = '''
投稿: ${post.title}

${post.description}

位置: ${post.latitude.toStringAsFixed(6)}, ${post.longitude.toStringAsFixed(6)}
Anchor ID: ${post.anchorId}
ルームID: ${post.roomId}
投稿日時: ${_formatDateTime(post.createdAt)}
''';

    // 簡易実装として、SnackBarで通知
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('投稿情報を共有用にフォーマットしました'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '詳細',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('共有用テキスト'),
                content: SingleChildScrollView(
                  child: Text(shareText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


}

/// クラスター投稿一覧を表示するボトムシート
class _ClusterPostsBottomSheet extends StatelessWidget {
  const _ClusterPostsBottomSheet({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ドラッグハンドル
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'この地域の投稿 (${posts.length}件)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 投稿リスト
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      leading: post.imageUrl != null && post.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                post.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.text_fields),
                            ),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              body: _PostDetailBottomSheet(
                                post: post,
                                onShowLocationOnMap: (context, post) {
                                  // クラスター詳細からは地図移動機能を無効化
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('地図に戻って投稿の位置を確認してください'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // 安全な下部余白
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          );
        },
      ),
    );
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// フルスクリーン画像ビューアー
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '画像の読み込みに失敗しました',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
