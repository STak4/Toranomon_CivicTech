import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/permission_utils.dart';
import '../utils/app_logger.dart';

part 'permission_provider.g.dart';

/// 権限の状態
enum PermissionState {
  /// 未確認
  unknown,
  /// 許可済み
  granted,
  /// 拒否
  denied,
  /// 永続的に拒否
  permanentlyDenied,
  /// 制限付き（iOS）
  restricted,
  /// 限定的（iOS）
  limited,
}

/// 権限情報
class PermissionInfo {
  const PermissionInfo({
    required this.state,
    required this.canSave,
    required this.needsSettings,
    required this.guidanceMessage,
    this.details,
  });

  /// 権限の状態
  final PermissionState state;
  
  /// 保存可能かどうか
  final bool canSave;
  
  /// 設定画面での操作が必要かどうか
  final bool needsSettings;
  
  /// ユーザー向けガイダンスメッセージ
  final String guidanceMessage;
  
  /// 詳細情報
  final Map<String, dynamic>? details;

  PermissionInfo copyWith({
    PermissionState? state,
    bool? canSave,
    bool? needsSettings,
    String? guidanceMessage,
    Map<String, dynamic>? details,
  }) {
    return PermissionInfo(
      state: state ?? this.state,
      canSave: canSave ?? this.canSave,
      needsSettings: needsSettings ?? this.needsSettings,
      guidanceMessage: guidanceMessage ?? this.guidanceMessage,
      details: details ?? this.details,
    );
  }

  @override
  String toString() {
    return 'PermissionInfo(state: $state, canSave: $canSave, needsSettings: $needsSettings)';
  }
}

/// ギャラリー権限プロバイダー
///
/// ギャラリー保存に必要な権限の状態を管理する
@riverpod
class GalleryPermission extends _$GalleryPermission {
  @override
  FutureOr<PermissionInfo> build() async {
    return await _checkPermissionStatus();
  }

  /// 権限の状態をチェック
  Future<PermissionInfo> _checkPermissionStatus() async {
    try {
      AppLogger.d('ギャラリー権限の状態をチェック中');
      
      final details = await PermissionUtils.getPermissionStatusDetails();
      final canSave = details['canSave'] as bool? ?? false;
      final needsSettings = details['needsSettings'] as bool? ?? false;
      final guidanceMessage = await PermissionUtils.getPermissionGuidanceMessage();
      
      PermissionState permissionState;
      
      if (canSave) {
        permissionState = PermissionState.granted;
      } else if (needsSettings) {
        permissionState = PermissionState.permanentlyDenied;
      } else {
        // プラットフォーム固有の状態を詳細に判定
        if (details['platform'] == 'iOS') {
          final photos = details['photos'] as Map<String, dynamic>?;
          if (photos?['isLimited'] == true) {
            permissionState = PermissionState.limited;
          } else if (photos?['isRestricted'] == true) {
            permissionState = PermissionState.restricted;
          } else {
            permissionState = PermissionState.denied;
          }
        } else {
          permissionState = PermissionState.denied;
        }
      }
      
      final permissionInfo = PermissionInfo(
        state: permissionState,
        canSave: canSave,
        needsSettings: needsSettings,
        guidanceMessage: guidanceMessage,
        details: details,
      );
      
      AppLogger.d('権限状態チェック完了: $permissionInfo');
      return permissionInfo;
    } catch (e) {
      AppLogger.e('権限状態チェックでエラー: $e');
      
      return PermissionInfo(
        state: PermissionState.unknown,
        canSave: false,
        needsSettings: false,
        guidanceMessage: '権限の確認中にエラーが発生しました。再度お試しください。',
        details: {'error': e.toString()},
      );
    }
  }

  /// 権限を要求
  Future<bool> requestPermission() async {
    try {
      AppLogger.i('ギャラリー権限を要求中');
      
      // 現在の状態を更新中に設定
      state = const AsyncValue.loading();
      
      // 権限要求の詳細解析を実行
      final analysis = await PermissionUtils.analyzePermissionRequest();
      
      // 新しい状態を取得
      final newPermissionInfo = await _checkPermissionStatus();
      
      // 状態を更新
      state = AsyncValue.data(newPermissionInfo);
      
      final success = analysis['success'] as bool? ?? false;
      AppLogger.i('権限要求結果: $success');
      
      return success;
    } catch (e) {
      AppLogger.e('権限要求でエラー: $e');
      
      // エラー状態を設定
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// 設定画面を開く
  Future<bool> openSettings() async {
    try {
      AppLogger.i('設定画面を開く');
      
      final opened = await PermissionUtils.openAppSettings();
      
      if (opened) {
        // 設定画面を開いた後、少し待ってから状態を再チェック
        Future.delayed(const Duration(seconds: 1), () {
          refresh();
        });
      }
      
      return opened;
    } catch (e) {
      AppLogger.e('設定画面を開く際にエラー: $e');
      return false;
    }
  }

  /// 権限状態を強制的に再チェック
  Future<void> refresh() async {
    try {
      AppLogger.d('権限状態を再チェック');
      
      state = const AsyncValue.loading();
      final newPermissionInfo = await _checkPermissionStatus();
      state = AsyncValue.data(newPermissionInfo);
    } catch (e) {
      AppLogger.e('権限状態再チェックでエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 権限が利用可能かチェック（キャッシュされた値を使用）
  bool get canSaveToGallery {
    return state.valueOrNull?.canSave ?? false;
  }

  /// 設定画面での操作が必要かチェック（キャッシュされた値を使用）
  bool get needsSettingsAccess {
    return state.valueOrNull?.needsSettings ?? false;
  }

  /// ガイダンスメッセージを取得（キャッシュされた値を使用）
  String get guidanceMessage {
    return state.valueOrNull?.guidanceMessage ?? 
           '権限の確認中です。しばらくお待ちください。';
  }

  /// 権限の詳細情報を取得
  Map<String, dynamic> getPermissionDetails() {
    final permissionInfo = state.valueOrNull;
    if (permissionInfo == null) {
      return {'status': 'loading'};
    }
    
    return {
      'state': permissionInfo.state.name,
      'canSave': permissionInfo.canSave,
      'needsSettings': permissionInfo.needsSettings,
      'guidanceMessage': permissionInfo.guidanceMessage,
      'details': permissionInfo.details,
    };
  }
}

/// 権限状態の監視プロバイダー
///
/// アプリがフォアグラウンドに戻った時などに権限状態を自動更新
@riverpod
class PermissionWatcher extends _$PermissionWatcher {
  @override
  bool build() {
    // アプリのライフサイクル変更を監視
    ref.listen(appLifecycleProvider, (previous, next) {
      if (previous == AppLifecycleState.paused && 
          next == AppLifecycleState.resumed) {
        // アプリがフォアグラウンドに戻った時に権限状態を再チェック
        AppLogger.d('アプリがフォアグラウンドに戻ったため権限状態を再チェック');
        ref.read(galleryPermissionProvider.notifier).refresh();
      }
    });
    
    return true;
  }
}

/// アプリライフサイクル状態プロバイダー
@riverpod
AppLifecycleState appLifecycle(Ref ref) {
  // 実際の実装では WidgetsBindingObserver を使用して監視
  return AppLifecycleState.resumed;
}