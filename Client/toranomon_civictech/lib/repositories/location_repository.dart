import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import '../models/models.dart';
import '../utils/app_logger.dart';

/// 位置情報リポジトリインターフェース
/// 
/// 位置情報の取得と権限管理機能を提供するインターフェース
abstract class LocationRepository {
  /// 現在の位置情報を取得
  /// 
  /// 戻り値: 現在の位置情報
  /// 例外: LocationError - 位置情報の取得に失敗した場合
  Future<Position> getCurrentLocation();

  /// 位置情報のリアルタイム更新ストリームを取得
  /// 
  /// 戻り値: 位置情報の更新ストリーム
  Stream<Position> getLocationStream();

  /// 位置情報の使用許可を要求
  /// 
  /// 戻り値: 許可が得られたかどうか
  Future<bool> requestLocationPermission();

  /// 位置情報の使用許可状態を確認
  /// 
  /// 戻り値: 許可されているかどうか
  Future<bool> hasLocationPermission();

  /// 位置情報サービスが有効かどうかを確認
  /// 
  /// 戻り値: 位置情報サービスが有効かどうか
  Future<bool> isLocationServiceEnabled();

  /// 位置情報の精度設定を取得
  /// 
  /// 戻り値: 位置情報の精度レベル
  Future<LocationAccuracy> getLocationAccuracy();

  /// 位置情報の精度設定を変更
  /// 
  /// [accuracy] 設定する精度レベル
  Future<void> setLocationAccuracy(LocationAccuracy accuracy);

  /// 最後に取得した位置情報を取得
  /// 
  /// 戻り値: 最後に取得した位置情報（存在しない場合はnull）
  Future<Position?> getLastKnownLocation();
}

/// 位置情報の精度レベル
enum LocationAccuracy {
  /// 最低精度（~3000m）
  lowest,
  
  /// 低精度（~1000m）
  low,
  
  /// 中精度（~100m）
  medium,
  
  /// 高精度（~10m）
  high,
  
  /// 最高精度（~1m）
  best,
  
  /// ナビゲーション用の最高精度
  bestForNavigation,
}

/// LocationRepositoryの実装クラス
/// 
/// geolocatorパッケージを使用して位置情報機能を提供
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl() {
    AppLogger.i('LocationRepositoryImpl が初期化されました');
  }

  /// 現在の精度設定
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;

  /// 位置情報ストリームのコントローラー
  StreamController<Position>? _positionStreamController;

  /// 位置情報ストリームの購読
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  @override
  Future<Position> getCurrentLocation() async {
    try {
      AppLogger.i('現在地の取得を開始します');

      // 位置情報サービスの確認
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('位置情報サービスが無効です');
        throw LocationException('位置情報サービスが無効です。設定から有効にしてください。');
      }

      // 権限の確認
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        AppLogger.w('位置情報の権限がありません');
        throw LocationException('位置情報の権限がありません。設定から許可してください。');
      }

      // 位置情報の取得
      final geoPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: _getLocationSettings(),
      );

      final position = _convertGeoPositionToPosition(geoPosition);
      AppLogger.i('現在地の取得が完了しました: ${position.latitude}, ${position.longitude}');
      
      return position;
    } catch (e, stackTrace) {
      AppLogger.e('現在地の取得に失敗しました', e, stackTrace);
      if (e is LocationException) {
        rethrow;
      }
      throw LocationException('位置情報の取得に失敗しました: ${e.toString()}');
    }
  }

  @override
  Stream<Position> getLocationStream() {
    try {
      AppLogger.i('位置情報ストリームを開始します');

      // 既存のストリームがある場合は停止
      _stopLocationStream();

      // 新しいストリームコントローラーを作成
      _positionStreamController = StreamController<Position>.broadcast(
        onCancel: _stopLocationStream,
      );

      // geolocatorの位置情報ストリームを購読
      _positionStreamSubscription = geo.Geolocator.getPositionStream(
        locationSettings: _getLocationSettings(),
      ).listen(
        (geoPosition) {
          final position = _convertGeoPositionToPosition(geoPosition);
          AppLogger.d('位置情報が更新されました: ${position.latitude}, ${position.longitude}');
          _positionStreamController?.add(position);
        },
        onError: (error, stackTrace) {
          AppLogger.e('位置情報ストリームでエラーが発生しました', error, stackTrace);
          _positionStreamController?.addError(
            LocationException('位置情報の更新に失敗しました: ${error.toString()}'),
          );
        },
      );

      return _positionStreamController!.stream;
    } catch (e, stackTrace) {
      AppLogger.e('位置情報ストリームの開始に失敗しました', e, stackTrace);
      throw LocationException('位置情報ストリームの開始に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      AppLogger.i('位置情報の権限要求を開始します');

      // 現在の権限状態を確認
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      AppLogger.d('現在の権限状態: $permission');

      if (permission == geo.LocationPermission.denied) {
        // 権限を要求
        permission = await geo.Geolocator.requestPermission();
        AppLogger.d('権限要求後の状態: $permission');
      }

      final granted = permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always;

      if (granted) {
        AppLogger.i('位置情報の権限が許可されました');
      } else {
        AppLogger.w('位置情報の権限が拒否されました: $permission');
      }

      return granted;
    } catch (e, stackTrace) {
      AppLogger.e('位置情報の権限要求に失敗しました', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      final hasPermission = permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always;
      
      AppLogger.d('位置情報権限の確認結果: $hasPermission (権限状態: $permission)');
      return hasPermission;
    } catch (e, stackTrace) {
      AppLogger.e('位置情報権限の確認に失敗しました', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      final enabled = await geo.Geolocator.isLocationServiceEnabled();
      AppLogger.d('位置情報サービスの状態: $enabled');
      return enabled;
    } catch (e, stackTrace) {
      AppLogger.e('位置情報サービスの確認に失敗しました', e, stackTrace);
      return false;
    }
  }

  @override
  Future<LocationAccuracy> getLocationAccuracy() async {
    AppLogger.d('現在の位置情報精度設定: $_currentAccuracy');
    return _currentAccuracy;
  }

  @override
  Future<void> setLocationAccuracy(LocationAccuracy accuracy) async {
    AppLogger.i('位置情報精度を変更します: $_currentAccuracy -> $accuracy');
    _currentAccuracy = accuracy;
  }

  @override
  Future<Position?> getLastKnownLocation() async {
    try {
      AppLogger.i('最後に取得した位置情報を取得します');

      final geoPosition = await geo.Geolocator.getLastKnownPosition();
      if (geoPosition == null) {
        AppLogger.d('最後に取得した位置情報はありません');
        return null;
      }

      final position = _convertGeoPositionToPosition(geoPosition);
      AppLogger.d('最後に取得した位置情報: ${position.latitude}, ${position.longitude}');
      
      return position;
    } catch (e, stackTrace) {
      AppLogger.e('最後に取得した位置情報の取得に失敗しました', e, stackTrace);
      return null;
    }
  }

  /// geolocatorのPositionを独自のPositionモデルに変換
  Position _convertGeoPositionToPosition(geo.Position geoPosition) {
    return Position(
      latitude: geoPosition.latitude,
      longitude: geoPosition.longitude,
      accuracy: geoPosition.accuracy,
      timestamp: geoPosition.timestamp,
    );
  }

  /// 現在の精度設定に基づいてLocationSettingsを取得
  geo.LocationSettings _getLocationSettings() {
    final geoAccuracy = _convertToGeolocatorAccuracy(_currentAccuracy);
    
    return geo.LocationSettings(
      accuracy: geoAccuracy,
      distanceFilter: _getDistanceFilter(_currentAccuracy),
    );
  }

  /// LocationAccuracyをgeolocatorのLocationAccuracyに変換
  geo.LocationAccuracy _convertToGeolocatorAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return geo.LocationAccuracy.lowest;
      case LocationAccuracy.low:
        return geo.LocationAccuracy.low;
      case LocationAccuracy.medium:
        return geo.LocationAccuracy.medium;
      case LocationAccuracy.high:
        return geo.LocationAccuracy.high;
      case LocationAccuracy.best:
        return geo.LocationAccuracy.best;
      case LocationAccuracy.bestForNavigation:
        return geo.LocationAccuracy.bestForNavigation;
    }
  }

  /// 精度レベルに応じた距離フィルターを取得
  int _getDistanceFilter(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 100; // 100m以上移動した場合に更新
      case LocationAccuracy.low:
        return 50;  // 50m以上移動した場合に更新
      case LocationAccuracy.medium:
        return 20;  // 20m以上移動した場合に更新
      case LocationAccuracy.high:
        return 10;  // 10m以上移動した場合に更新
      case LocationAccuracy.best:
        return 5;   // 5m以上移動した場合に更新
      case LocationAccuracy.bestForNavigation:
        return 1;   // 1m以上移動した場合に更新
    }
  }

  /// 位置情報ストリームを停止
  void _stopLocationStream() {
    AppLogger.d('位置情報ストリームを停止します');
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _positionStreamController?.close();
    _positionStreamController = null;
  }

  /// リソースのクリーンアップ
  void dispose() {
    AppLogger.i('LocationRepositoryImpl のリソースをクリーンアップします');
    _stopLocationStream();
  }
}

/// 位置情報関連の例外クラス
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => 'LocationException: $message';
}