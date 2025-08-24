import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'app_logger.dart';

/// 権限管理のユーティリティクラス
class PermissionUtils {
  /// 写真ライブラリへのアクセス権限をチェック・要求
  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidPhotoPermission();
      } else if (Platform.isIOS) {
        return await _requestIOSPhotoPermission();
      }
      return false;
    } catch (e) {
      AppLogger.e('権限要求でエラー: $e');
      return false;
    }
  }

  /// Androidでの写真権限要求
  static Future<bool> _requestAndroidPhotoPermission() async {
    try {
      // Android 13以降（API 33以降）ではREAD_MEDIA_IMAGESを使用
      if (await _isAndroid13OrHigher()) {
        final photosStatus = await Permission.photos.status;
        AppLogger.i('Android Photos権限の状態: $photosStatus');

        if (photosStatus.isGranted) {
          return true;
        } else if (photosStatus.isDenied) {
          final result = await Permission.photos.request();
          AppLogger.i('Android Photos権限要求結果: $result');
          return result.isGranted;
        } else {
          AppLogger.w('Android Photos権限が永続的に拒否されています');
          return false;
        }
      } else {
        // Android 12以前ではstorage権限を使用
        final storageStatus = await Permission.storage.status;
        AppLogger.i('Android Storage権限の状態: $storageStatus');

        if (storageStatus.isGranted) {
          return true;
        } else if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          AppLogger.i('Android Storage権限要求結果: $result');
          return result.isGranted;
        } else {
          AppLogger.w('Android Storage権限が永続的に拒否されています');
          return false;
        }
      }
    } catch (e) {
      AppLogger.e('Android権限要求でエラー: $e');
      return false;
    }
  }

  /// iOSでの写真権限要求（iOS 14以降対応）
  static Future<bool> _requestIOSPhotoPermission() async {
    try {
      // iOS 14以降では photosAddOnly を使用（保存専用）
      AppLogger.i('=== iOS 14+ 写真保存権限の要求 ===');

      var status = await Permission.photosAddOnly.status;
      AppLogger.i('iOS photosAddOnly権限の状態: $status');

      if (status.isDenied) {
        AppLogger.i('photosAddOnly権限を要求中...');
        status = await Permission.photosAddOnly.request();
        AppLogger.i('photosAddOnly権限要求結果: $status');
      }

      // iOS 13以下の端末向けフォールバック
      if (status.isDenied || status.isRestricted) {
        AppLogger.i('=== フォールバック: 従来のphotos権限 ===');
        var legacy = await Permission.photos.status;
        AppLogger.i('iOS photos権限の状態（フォールバック）: $legacy');

        if (legacy.isDenied) {
          AppLogger.i('photos権限を要求中（フォールバック）...');
          legacy = await Permission.photos.request();
          AppLogger.i('photos権限要求結果（フォールバック）: $legacy');
        }
        if (legacy.isGranted) {
          AppLogger.i('フォールバックで権限取得成功');
          return true;
        }
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        AppLogger.w('写真保存権限が永続的に拒否または制限されています');
        // 設定アプリへの誘導は呼び出し元で行う
        return false;
      }

      final isGranted = status.isGranted;
      AppLogger.i('最終的な権限状態: $isGranted');
      return isGranted;
    } catch (e) {
      AppLogger.e('iOS権限要求でエラー: $e');
      return false;
    }
  }

  /// Android 13以降（API 33以降）かどうかを判定
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 = API 33
    } catch (e) {
      AppLogger.e('Android SDKバージョンの取得に失敗: $e');
      return false;
    }
  }

  /// 権限が拒否された場合のエラーメッセージを取得
  static String getPermissionErrorMessage() {
    if (Platform.isIOS) {
      return '写真ライブラリへのアクセスが拒否されています。\n'
          '設定アプリ > プライバシーとセキュリティ > 写真 > Toranomon Civictech から「すべての写真」を選択してください。\n'
          '「プライベートアクセス」の場合は、写真の保存ができません。';
    } else {
      return '写真ライブラリへのアクセス権限が必要です。\n'
          '設定アプリ > アプリ > Toranomon Civictech > 権限 から写真へのアクセスを許可してください。';
    }
  }

  /// 権限の状態に応じたエラーメッセージを取得
  static Future<String> getDetailedPermissionErrorMessage() async {
    if (Platform.isIOS) {
      // iOS 14以降のphotosAddOnly権限を優先的にチェック
      final photosAddOnlyStatus = await Permission.photosAddOnly.status;
      final photosStatus = await Permission.photos.status;

      if (photosAddOnlyStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        return '写真保存権限が永続的に拒否されています。\n'
            '設定アプリ > プライバシーとセキュリティ > 写真 > Toranomon Civictech から「すべての写真」または「写真を追加」を許可してください。\n'
            '現在の状態を変更後、アプリを再起動してください。';
      } else if (photosStatus.isLimited) {
        return '写真ライブラリが「プライベートアクセス」に設定されています。\n'
            '写真を保存するには、設定アプリ > プライバシーとセキュリティ > 写真 > Toranomon Civictech から「すべての写真」または「写真を追加」を選択してください。';
      } else {
        return '写真保存のための権限が必要です。\n'
            '権限要求ダイアログで「許可」または「写真を追加」を選択してください。';
      }
    } else {
      return '写真ライブラリへのアクセス権限が必要です。\n'
          '設定アプリ > アプリ > Toranomon Civictech > 権限 から写真へのアクセスを許可してください。';
    }
  }

  /// 権限の状態を詳細にログ出力
  static Future<void> logPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final photosStatus = await Permission.photos.status;
          AppLogger.i('Android Photos権限の詳細状態: $photosStatus');
        } else {
          final storageStatus = await Permission.storage.status;
          AppLogger.i('Android Storage権限の詳細状態: $storageStatus');
        }
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        AppLogger.i('iOS Photos権限の詳細状態: $photosStatus');
      }
    } catch (e) {
      AppLogger.e('権限状態のログ出力でエラー: $e');
    }
  }

  /// 権限の詳細な状態を確認
  static Future<void> debugPermissionStatus() async {
    try {
      if (Platform.isIOS) {
        AppLogger.i('=== iOS権限状態の詳細デバッグ ===');

        // photosAddOnly（iOS 14+）の状態を確認
        final photosAddOnlyStatus = await Permission.photosAddOnly.status;
        AppLogger.i('photosAddOnly権限の状態: $photosAddOnlyStatus');
        AppLogger.i(
          'photosAddOnly isGranted: ${photosAddOnlyStatus.isGranted}',
        );
        AppLogger.i('photosAddOnly isDenied: ${photosAddOnlyStatus.isDenied}');
        AppLogger.i(
          'photosAddOnly isPermanentlyDenied: ${photosAddOnlyStatus.isPermanentlyDenied}',
        );
        AppLogger.i(
          'photosAddOnly isRestricted: ${photosAddOnlyStatus.isRestricted}',
        );

        // 従来のphotos権限の状態も確認
        final photosStatus = await Permission.photos.status;
        AppLogger.i('photos権限の状態: $photosStatus');
        AppLogger.i('photos isGranted: ${photosStatus.isGranted}');
        AppLogger.i('photos isDenied: ${photosStatus.isDenied}');
        AppLogger.i(
          'photos isPermanentlyDenied: ${photosStatus.isPermanentlyDenied}',
        );
        AppLogger.i('photos isLimited: ${photosStatus.isLimited}');
        AppLogger.i('photos isRestricted: ${photosStatus.isRestricted}');

        AppLogger.i('==============================');
      }
    } catch (e) {
      AppLogger.e('権限状態のデバッグでエラー: $e');
    }
  }

  /// 設定画面を開く
  static Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();
      AppLogger.i('設定画面を開きました: $opened');
      return opened;
    } catch (e) {
      AppLogger.e('設定画面を開く際にエラーが発生: $e');
      return false;
    }
  }

  /// 権限の状態を詳細に取得
  static Future<Map<String, dynamic>> getPermissionStatusDetails() async {
    try {
      final details = <String, dynamic>{};
      
      if (Platform.isIOS) {
        final photosAddOnlyStatus = await Permission.photosAddOnly.status;
        final photosStatus = await Permission.photos.status;
        
        details['platform'] = 'iOS';
        details['photosAddOnly'] = {
          'status': photosAddOnlyStatus.name,
          'isGranted': photosAddOnlyStatus.isGranted,
          'isDenied': photosAddOnlyStatus.isDenied,
          'isPermanentlyDenied': photosAddOnlyStatus.isPermanentlyDenied,
          'isRestricted': photosAddOnlyStatus.isRestricted,
        };
        details['photos'] = {
          'status': photosStatus.name,
          'isGranted': photosStatus.isGranted,
          'isDenied': photosStatus.isDenied,
          'isPermanentlyDenied': photosStatus.isPermanentlyDenied,
          'isLimited': photosStatus.isLimited,
          'isRestricted': photosStatus.isRestricted,
        };
        details['canSave'] = photosAddOnlyStatus.isGranted || photosStatus.isGranted;
        details['needsSettings'] = photosAddOnlyStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied;
      } else if (Platform.isAndroid) {
        final isAndroid13Plus = await _isAndroid13OrHigher();
        details['platform'] = 'Android';
        details['isAndroid13Plus'] = isAndroid13Plus;
        
        if (isAndroid13Plus) {
          final photosStatus = await Permission.photos.status;
          details['photos'] = {
            'status': photosStatus.name,
            'isGranted': photosStatus.isGranted,
            'isDenied': photosStatus.isDenied,
            'isPermanentlyDenied': photosStatus.isPermanentlyDenied,
          };
          details['canSave'] = photosStatus.isGranted;
          details['needsSettings'] = photosStatus.isPermanentlyDenied;
        } else {
          final storageStatus = await Permission.storage.status;
          details['storage'] = {
            'status': storageStatus.name,
            'isGranted': storageStatus.isGranted,
            'isDenied': storageStatus.isDenied,
            'isPermanentlyDenied': storageStatus.isPermanentlyDenied,
          };
          details['canSave'] = storageStatus.isGranted;
          details['needsSettings'] = storageStatus.isPermanentlyDenied;
        }
      }
      
      return details;
    } catch (e) {
      AppLogger.e('権限状態詳細取得でエラー: $e');
      return {'error': e.toString()};
    }
  }

  /// 権限要求のガイダンスメッセージを取得
  static Future<String> getPermissionGuidanceMessage() async {
    try {
      final details = await getPermissionStatusDetails();
      
      if (details['platform'] == 'iOS') {
        final photosAddOnly = details['photosAddOnly'] as Map<String, dynamic>?;
        final photos = details['photos'] as Map<String, dynamic>?;
        
        if (photosAddOnly?['isPermanentlyDenied'] == true || photos?['isPermanentlyDenied'] == true) {
          return '写真保存権限が拒否されています。\n\n'
              '設定方法：\n'
              '1. 設定アプリを開く\n'
              '2. プライバシーとセキュリティ > 写真\n'
              '3. Toranomon Civictech を選択\n'
              '4. 「すべての写真」または「写真を追加」を選択\n\n'
              '設定後、アプリを再起動してください。';
        } else if (photos?['isLimited'] == true) {
          return '写真ライブラリが「プライベートアクセス」に設定されています。\n\n'
              '写真を保存するには：\n'
              '1. 設定アプリ > プライバシーとセキュリティ > 写真\n'
              '2. Toranomon Civictech を選択\n'
              '3. 「すべての写真」または「写真を追加」を選択';
        } else {
          return '写真を保存するために、ギャラリーへのアクセス権限が必要です。\n\n'
              '権限要求ダイアログで「許可」または「写真を追加」を選択してください。';
        }
      } else if (details['platform'] == 'Android') {
        final needsSettings = details['needsSettings'] as bool? ?? false;
        
        if (needsSettings) {
          return '写真保存権限が拒否されています。\n\n'
              '設定方法：\n'
              '1. 設定アプリを開く\n'
              '2. アプリ > Toranomon Civictech\n'
              '3. 権限 > 写真とメディア（またはストレージ）\n'
              '4. 「許可」を選択\n\n'
              '設定後、アプリを再起動してください。';
        } else {
          return '写真を保存するために、ストレージへのアクセス権限が必要です。\n\n'
              '権限要求ダイアログで「許可」を選択してください。';
        }
      }
      
      return '写真を保存するために権限が必要です。権限要求ダイアログで「許可」を選択してください。';
    } catch (e) {
      AppLogger.e('権限ガイダンスメッセージ取得でエラー: $e');
      return '写真を保存するために権限が必要です。設定アプリで権限を許可してください。';
    }
  }

  /// 権限が永続的に拒否されているかチェック
  static Future<bool> isPermissionPermanentlyDenied() async {
    try {
      if (Platform.isIOS) {
        final photosAddOnlyStatus = await Permission.photosAddOnly.status;
        final photosStatus = await Permission.photos.status;
        return photosAddOnlyStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied;
      } else if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final photosStatus = await Permission.photos.status;
          return photosStatus.isPermanentlyDenied;
        } else {
          final storageStatus = await Permission.storage.status;
          return storageStatus.isPermanentlyDenied;
        }
      }
      return false;
    } catch (e) {
      AppLogger.e('永続拒否チェックでエラー: $e');
      return false;
    }
  }

  /// 権限要求の結果を詳細に解析
  static Future<Map<String, dynamic>> analyzePermissionRequest() async {
    try {
      AppLogger.i('権限要求の詳細解析を開始');
      
      final beforeDetails = await getPermissionStatusDetails();
      AppLogger.d('権限要求前の状態: $beforeDetails');
      
      final hasPermission = await requestPhotoLibraryPermission();
      
      final afterDetails = await getPermissionStatusDetails();
      AppLogger.d('権限要求後の状態: $afterDetails');
      
      return {
        'success': hasPermission,
        'beforeStatus': beforeDetails,
        'afterStatus': afterDetails,
        'needsSettings': await isPermissionPermanentlyDenied(),
        'guidanceMessage': await getPermissionGuidanceMessage(),
      };
    } catch (e) {
      AppLogger.e('権限要求解析でエラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'guidanceMessage': await getPermissionGuidanceMessage(),
      };
    }
  }

  /// 権限が永続的に拒否された場合の対処法を案内
  static Future<void> showPermissionDeniedDialog() async {
    try {
      final photosStatus = await Permission.photos.status;

      if (photosStatus.isPermanentlyDenied) {
        AppLogger.w('権限が永続的に拒否されています。設定画面を開きます。');
        await openAppSettings();
      }
    } catch (e) {
      AppLogger.e('権限拒否ダイアログの表示でエラー: $e');
    }
  }
}
