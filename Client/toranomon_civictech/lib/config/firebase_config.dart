import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics設定
    await _configureCrashlytics();

    // RemoteConfig設定
    await _configureRemoteConfig();

    // Messaging設定（最後に実行）
    await _configureMessaging();
  }

  static Future<void> _configureCrashlytics() async {
    // 開発環境ではCrashlyticsを無効化
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // FlutterエラーをCrashlyticsに送信
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  static Future<void> _configureMessaging() async {
    try {
      // 通知許可をリクエスト
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.i('通知が許可されました');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.i('仮の通知許可が設定されました');
      } else {
        AppLogger.w('通知が拒否されました');
      }

      // iOSの場合、APNSトークンを確実に取得
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _initializeAPNSToken();
      }

      // FCMトークンを取得
      await _initializeFCMToken();

      // メッセージハンドラーを設定
      _setupMessageHandlers();
    } catch (e) {
      AppLogger.e('Messaging設定エラー', e);
    }
  }

  // APNSトークン初期化
  static Future<void> _initializeAPNSToken() async {
    try {
      // まず通知許可を確認
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.w('通知許可がありません。APNSトークンの取得をスキップします。');
        return;
      }

      // APNSトークンを取得（最大5回試行）
      String? apnsToken;
      for (int i = 0; i < 5; i++) {
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            AppLogger.i('APNS Token: $apnsToken');
            break;
          }
        } catch (e) {
          AppLogger.w('APNSトークン取得試行 ${i + 1} 失敗: $e');
        }

        // 少し待機してから再試行
        await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
      }

      if (apnsToken == null) {
        AppLogger.w('APNSトークンの取得に失敗しました。FCM機能が制限される可能性があります。');
      }
    } catch (e) {
      AppLogger.e('APNSトークン初期化エラー', e);
    }
  }

  // FCMトークン初期化
  static Future<void> _initializeFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        AppLogger.i('FCM Token: $token');
      } else {
        AppLogger.w('FCMトークンの取得に失敗しました');
      }
    } catch (e) {
      AppLogger.e('FCMトークン初期化エラー', e);
    }
  }

  // メッセージハンドラー設定
  static void _setupMessageHandlers() {
    // フォアグラウンドメッセージハンドラー
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.i('フォアグラウンドメッセージを受信: ${message.messageId}');
      // ここでローカル通知を表示するなどの処理を行う
    });

    // バックグラウンドメッセージハンドラー
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 通知タップ時のハンドラー
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.i('通知がタップされました: ${message.messageId}');
      // ここで画面遷移などの処理を行う
    });

    // 初期通知をチェック
    FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        AppLogger.i('初期通知: ${initialMessage.messageId}');
        // ここで画面遷移などの処理を行う
      }
    });
  }

  // RemoteConfig設定
  static Future<void> _configureRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // 設定を設定
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // デフォルト値を設定
    await remoteConfig.setDefaults(const {
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
      await remoteConfig.fetchAndActivate();
      AppLogger.i('RemoteConfig初期化完了');
    } catch (e) {
      AppLogger.e('RemoteConfig初期化エラー', e);
    }
  }
}

// バックグラウンドメッセージハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.i('バックグラウンドメッセージを受信: ${message.messageId}');
}
