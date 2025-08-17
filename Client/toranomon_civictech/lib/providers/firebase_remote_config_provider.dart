import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

// Firebase RemoteConfig インスタンス
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

// RemoteConfig サービス
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  // RemoteConfig初期化
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // デフォルト値を設定
    await _remoteConfig.setDefaults(const {
      'welcome_message': 'アプリへようこそ！',
      'feature_flag_new_ui': false,
      'api_endpoint': 'https://api.example.com',
      'max_retry_count': 3,
      'cache_duration': 3600,
      'is_maintenance_mode': false,
      'maintenance_message': 'メンテナンス中です',
      'app_version_required': '1.0.0',
      'show_ads': true,
      'ad_frequency': 5,
    });

    try {
      // リモート設定を取得
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // エラーが発生した場合はローカル設定を使用
      AppLogger.e('RemoteConfig取得エラー', e);
    }
  }

  // 文字列値を取得
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  // 真偽値を取得
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  // 整数値を取得
  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }

  // 倍精度浮動小数点数値を取得
  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }

  // 最後の取得時刻を取得
  DateTime get lastFetchTime {
    return _remoteConfig.lastFetchTime;
  }

  // 最後の取得ステータスを取得
  RemoteConfigFetchStatus get lastFetchStatus {
    return _remoteConfig.lastFetchStatus;
  }

  // 設定を手動で更新
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      AppLogger.e('RemoteConfig更新エラー', e);
      return false;
    }
  }

  // 設定を手動で更新（最小間隔を無視）
  Future<bool> fetchAndActivateMinimum() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      AppLogger.e('RemoteConfig更新エラー', e);
      return false;
    }
  }

  // 設定変更のストリームを取得
  Stream<RemoteConfigUpdate> get configUpdateStream {
    return _remoteConfig.onConfigUpdated;
  }

  // 設定値の存在確認
  bool containsKey(String key) {
    try {
      final value = _remoteConfig.getValue(key);
      return value.asString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 設定値のソースを取得
  ValueSource getValueSource(String key) {
    return _remoteConfig.getValue(key).source;
  }

  // 設定値のメタデータを取得
  RemoteConfigValue getValue(String key) {
    return _remoteConfig.getValue(key);
  }

  // 設定値の情報を取得
  Map<String, RemoteConfigValue> getAll() {
    return _remoteConfig.getAll();
  }
}

// RemoteConfig サービスプロバイダー
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(ref.read(firebaseRemoteConfigProvider));
});

// RemoteConfig 状態プロバイダー
final remoteConfigStateProvider =
    StateNotifierProvider<RemoteConfigNotifier, RemoteConfigState>((ref) {
      return RemoteConfigNotifier(ref.read(remoteConfigServiceProvider));
    });

// RemoteConfig 状態クラス
class RemoteConfigState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchTime;
  final RemoteConfigFetchStatus? lastFetchStatus;

  RemoteConfigState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.lastFetchTime,
    this.lastFetchStatus,
  });

  RemoteConfigState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    DateTime? lastFetchTime,
    RemoteConfigFetchStatus? lastFetchStatus,
  }) {
    return RemoteConfigState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      lastFetchStatus: lastFetchStatus ?? this.lastFetchStatus,
    );
  }
}

// RemoteConfig 管理クラス
class RemoteConfigNotifier extends StateNotifier<RemoteConfigState> {
  final RemoteConfigService _remoteConfigService;

  RemoteConfigNotifier(this._remoteConfigService) : super(RemoteConfigState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _remoteConfigService.initialize();
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        lastFetchTime: _remoteConfigService.lastFetchTime,
        lastFetchStatus: _remoteConfigService.lastFetchStatus,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'RemoteConfig初期化エラー: $e');
    }
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final success = await _remoteConfigService.fetchAndActivate();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          lastFetchTime: _remoteConfigService.lastFetchTime,
          lastFetchStatus: _remoteConfigService.lastFetchStatus,
        );
      } else {
        state = state.copyWith(isLoading: false, error: '設定の更新に失敗しました');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '設定更新エラー: $e');
    }
  }

  // エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// よく使用される設定値のプロバイダー
final welcomeMessageProvider = Provider<String>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getString('welcome_message');
});

final featureFlagNewUIProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getBool('feature_flag_new_ui');
});

final apiEndpointProvider = Provider<String>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getString('api_endpoint');
});

final maxRetryCountProvider = Provider<int>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getInt('max_retry_count');
});

final isMaintenanceModeProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getBool('is_maintenance_mode');
});

final maintenanceMessageProvider = Provider<String>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getString('maintenance_message');
});

final showAdsProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getBool('show_ads');
});

final adFrequencyProvider = Provider<int>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getInt('ad_frequency');
});
