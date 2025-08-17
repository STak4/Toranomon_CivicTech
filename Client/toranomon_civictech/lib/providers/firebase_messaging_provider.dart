import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

// Firebase Messaging インスタンス
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// Messaging サービス
class MessagingService {
  final FirebaseMessaging _messaging;

  MessagingService(this._messaging);

  // 通知許可をリクエスト
  Future<NotificationSettings> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings;
  }

  // FCMトークンを取得
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // フォアグラウンドメッセージハンドラーを設定
  void setForegroundMessageHandler(
    Future<void> Function(RemoteMessage) handler,
  ) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  // バックグラウンドメッセージハンドラーを設定
  void setBackgroundMessageHandler(
    Future<void> Function(RemoteMessage) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  // 通知タップ時のハンドラーを設定
  void setNotificationTapHandler(
    Future<void> Function(RemoteMessage?) handler,
  ) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  // 初期通知を取得
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  // トピックを購読
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // トピックの購読を解除
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

// Messaging サービスプロバイダー
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(ref.read(firebaseMessagingProvider));
});

// バックグラウンドメッセージハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンドでのメッセージ処理
  AppLogger.i('バックグラウンドメッセージを受信: ${message.messageId}');
}
