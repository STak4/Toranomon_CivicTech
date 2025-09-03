import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/models.dart';
import '../repositories/location_repository.dart';
import '../utils/app_logger.dart';

part 'location_provider.g.dart';

/// 位置情報の状態を表すクラス
class LocationState {
  final bool isLoading;
  final Position? currentPosition;
  final Position? lastKnownPosition;
  final LocationAccuracy accuracy;
  final bool hasPermission;
  final bool isServiceEnabled;
  final String? error;
  final bool isStreamActive;

  const LocationState({
    this.isLoading = false,
    this.currentPosition,
    this.lastKnownPosition,
    this.accuracy = LocationAccuracy.high,
    this.hasPermission = false,
    this.isServiceEnabled = false,
    this.error,
    this.isStreamActive = false,
  });

  LocationState copyWith({
    bool? isLoading,
    Position? currentPosition,
    Position? lastKnownPosition,
    LocationAccuracy? accuracy,
    bool? hasPermission,
    bool? isServiceEnabled,
    String? error,
    bool? isStreamActive,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      accuracy: accuracy ?? this.accuracy,
      hasPermission: hasPermission ?? this.hasPermission,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      error: error,
      isStreamActive: isStreamActive ?? this.isStreamActive,
    );
  }

  /// 位置情報が利用可能かどうか
  bool get isLocationAvailable => hasPermission && isServiceEnabled;

  /// 現在地が取得済みかどうか
  bool get hasCurrentLocation => currentPosition != null;

  @override
  String toString() {
    return 'LocationState('
        'isLoading: $isLoading, '
        'hasCurrentLocation: $hasCurrentLocation, '
        'accuracy: $accuracy, '
        'hasPermission: $hasPermission, '
        'isServiceEnabled: $isServiceEnabled, '
        'error: $error, '
        'isStreamActive: $isStreamActive'
        ')';
  }
}

/// 位置情報リポジトリのプロバイダー
@riverpod
LocationRepository locationRepository(Ref ref) {
  return LocationRepositoryImpl();
}

/// 位置情報状態管理のプロバイダー
@riverpod
class LocationNotifier extends _$LocationNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  LocationState build() {
    // プロバイダーが破棄される際のクリーンアップ
    ref.onDispose(() {
      _stopLocationStream();
    });

    return const LocationState();
  }

  /// 位置情報システムを初期化する
  Future<void> initialize() async {
    try {
      AppLogger.i('LocationProvider - 位置情報システムの初期化を開始');
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(locationRepositoryProvider);

      // 位置情報サービスの状態を確認
      final isServiceEnabled = await repository.isLocationServiceEnabled();
      AppLogger.d('LocationProvider - 位置情報サービス状態: $isServiceEnabled');

      // 権限の状態を確認
      final hasPermission = await repository.hasLocationPermission();
      AppLogger.d('LocationProvider - 位置情報権限状態: $hasPermission');

      // 最後に取得した位置情報を取得
      final lastKnownPosition = await repository.getLastKnownLocation();
      if (lastKnownPosition != null) {
        AppLogger.d('LocationProvider - 最後に取得した位置情報を読み込みました');
      }

      state = state.copyWith(
        isLoading: false,
        hasPermission: hasPermission,
        isServiceEnabled: isServiceEnabled,
        lastKnownPosition: lastKnownPosition,
        error: null,
      );

      AppLogger.i('LocationProvider - 位置情報システムの初期化が完了しました');
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 位置情報システムの初期化中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: '位置情報システムの初期化に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 位置情報の権限を要求する
  Future<bool> requestPermission() async {
    try {
      AppLogger.i('LocationProvider - 位置情報権限の要求を開始');
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(locationRepositoryProvider);
      final granted = await repository.requestLocationPermission();

      // サービスの状態も再確認
      final isServiceEnabled = await repository.isLocationServiceEnabled();

      state = state.copyWith(
        isLoading: false,
        hasPermission: granted,
        isServiceEnabled: isServiceEnabled,
        error: null,
      );

      if (granted) {
        AppLogger.i('LocationProvider - 位置情報権限が許可されました');
      } else {
        AppLogger.w('LocationProvider - 位置情報権限が拒否されました');
      }

      return granted;
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 位置情報権限の要求中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: '位置情報権限の要求に失敗しました: ${e.toString()}',
      );
      return false;
    }
  }

  /// 現在地を取得する
  Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.i('LocationProvider - 現在地の取得を開始');
      state = state.copyWith(isLoading: true, error: null);

      // 権限とサービスの状態を確認
      if (!state.isLocationAvailable) {
        AppLogger.w('LocationProvider - 位置情報が利用できません');
        state = state.copyWith(
          isLoading: false,
          error: '位置情報が利用できません。権限とサービスの設定を確認してください。',
        );
        return null;
      }

      final repository = ref.read(locationRepositoryProvider);
      final position = await repository.getCurrentLocation();

      state = state.copyWith(
        isLoading: false,
        currentPosition: position,
        error: null,
      );

      AppLogger.i('LocationProvider - 現在地の取得が完了しました');
      return position;
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 現在地の取得中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: '現在地の取得に失敗しました: ${e.toString()}',
      );
      return null;
    }
  }

  /// 位置情報のリアルタイム更新を開始する
  Future<void> startLocationStream() async {
    try {
      AppLogger.i('LocationProvider - 位置情報ストリームの開始');

      // 既存のストリームがある場合は停止
      _stopLocationStream();

      // 権限とサービスの状態を確認
      if (!state.isLocationAvailable) {
        AppLogger.w('LocationProvider - 位置情報が利用できないためストリームを開始できません');
        state = state.copyWith(
          error: '位置情報が利用できません。権限とサービスの設定を確認してください。',
        );
        return;
      }

      final repository = ref.read(locationRepositoryProvider);
      final locationStream = repository.getLocationStream();

      _positionStreamSubscription = locationStream.listen(
        (position) {
          AppLogger.d('LocationProvider - 位置情報が更新されました: ${position.latitude}, ${position.longitude}');
          state = state.copyWith(
            currentPosition: position,
            error: null,
          );
        },
        onError: (error, stackTrace) {
          AppLogger.e('LocationProvider - 位置情報ストリームでエラーが発生しました', error, stackTrace);
          state = state.copyWith(
            error: '位置情報の更新に失敗しました: ${error.toString()}',
          );
        },
      );

      state = state.copyWith(
        isStreamActive: true,
        error: null,
      );

      AppLogger.i('LocationProvider - 位置情報ストリームが開始されました');
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 位置情報ストリームの開始中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        error: '位置情報ストリームの開始に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 位置情報のリアルタイム更新を停止する
  void stopLocationStream() {
    AppLogger.i('LocationProvider - 位置情報ストリームの停止');
    _stopLocationStream();
    state = state.copyWith(isStreamActive: false);
  }

  /// 位置情報の精度を設定する
  Future<void> setLocationAccuracy(LocationAccuracy accuracy) async {
    try {
      AppLogger.i('LocationProvider - 位置情報精度の設定: ${state.accuracy} -> $accuracy');

      final repository = ref.read(locationRepositoryProvider);
      await repository.setLocationAccuracy(accuracy);

      state = state.copyWith(accuracy: accuracy);

      // ストリームが有効な場合は再開
      if (state.isStreamActive) {
        AppLogger.d('LocationProvider - 精度変更のためストリームを再開します');
        await startLocationStream();
      }

      AppLogger.i('LocationProvider - 位置情報精度が設定されました: $accuracy');
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 位置情報精度の設定中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        error: '位置情報精度の設定に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 権限とサービスの状態を再確認する
  Future<void> refreshPermissionStatus() async {
    try {
      AppLogger.i('LocationProvider - 権限とサービス状態の再確認');

      final repository = ref.read(locationRepositoryProvider);

      final hasPermission = await repository.hasLocationPermission();
      final isServiceEnabled = await repository.isLocationServiceEnabled();

      state = state.copyWith(
        hasPermission: hasPermission,
        isServiceEnabled: isServiceEnabled,
        error: null,
      );

      AppLogger.d('LocationProvider - 権限: $hasPermission, サービス: $isServiceEnabled');
    } catch (e, stackTrace) {
      AppLogger.e('LocationProvider - 権限とサービス状態の確認中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        error: '権限とサービス状態の確認に失敗しました: ${e.toString()}',
      );
    }
  }

  /// エラーをクリアする
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 位置情報をリセットする
  void resetLocation() {
    AppLogger.i('LocationProvider - 位置情報をリセット');
    _stopLocationStream();
    state = state.copyWith(
      currentPosition: null,
      isStreamActive: false,
      error: null,
    );
  }

  /// 内部的にストリームを停止する
  void _stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}

/// 現在地を取得する便利なプロバイダー
@riverpod
Future<Position?> currentLocation(Ref ref) async {
  final locationNotifier = ref.read(locationNotifierProvider.notifier);
  return await locationNotifier.getCurrentLocation();
}

/// 位置情報が利用可能かどうかを確認する便利なプロバイダー
@riverpod
bool isLocationAvailable(Ref ref) {
  final locationState = ref.watch(locationNotifierProvider);
  return locationState.isLocationAvailable;
}