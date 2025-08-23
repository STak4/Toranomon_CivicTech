import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/app_logger.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoadingLocation = false;

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
    AppLogger.i('MapSampleScreen: リソースを解放しました');
    super.dispose();
  }

  /// 地図が作成された時に呼ばれるコールバック
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    AppLogger.i('MapSampleScreen: Google Mapsが正常に初期化されました');
  }

  /// 地図がタップされた時の処理
  void _onMapTap(LatLng position) {
    AppLogger.d(
      'MapSampleScreen: 地図がタップされました - 座標: ${position.latitude}, ${position.longitude}',
    );
  }

  /// カメラ位置が変更された時の処理
  void _onCameraMove(CameraPosition position) {
    // 頻繁に呼ばれるため、デバッグレベルでログ出力
    AppLogger.d('MapSampleScreen: カメラ位置が変更されました - ズーム: ${position.zoom}');
  }

  /// 位置情報の許可を要求し、現在地を取得する
  Future<void> _requestLocationPermissionAndGetLocation() async {
    try {
      AppLogger.i('MapSampleScreen: 位置情報の許可を要求しています');

      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('MapSampleScreen: 位置情報サービスが無効です');
        _showLocationServiceDialog();
        return;
      }

      // 位置情報の許可状態をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('MapSampleScreen: 位置情報の許可が拒否されました');
          _showPermissionDeniedMessage();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 地図タイプ切り替えボタン
          FloatingActionButton(
            heroTag: "mapType",
            mini: true,
            onPressed: _toggleMapType,
            tooltip: '地図タイプ切り替え',
            child: const Icon(Icons.layers),
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

  /// 地図タイプを切り替える
  void _toggleMapType() {
    // 現在の実装では地図タイプの状態管理は簡略化
    // 実際のアプリでは状態管理を使用
    AppLogger.i('MapSampleScreen: 地図タイプ切り替えが要求されました');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('地図タイプ切り替え機能は今後実装予定です'),
        duration: Duration(seconds: 2),
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
              Text('• 地図のタップ検出'),
              Text('• カメラ位置の追跡'),
              Text('• 現在地の取得と表示'),
              Text('• 現在地マーカーのタップ機能'),
              Text('• 位置情報許可の管理'),
              SizedBox(height: 16),
              Text('今後実装予定:'),
              Text('• 投稿ピンの表示'),
              Text('• 地図タイプの切り替え'),
              Text('• リアルタイム位置更新'),
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
