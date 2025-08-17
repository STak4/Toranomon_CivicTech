import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// アプリケーション全体で使用するカスタムロガー
/// エラーログのみCrashlyticsに送信し、その他のログは通常のloggerで出力
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// デバッグログ（Crashlyticsには送信しない）
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 情報ログ（Crashlyticsには送信しない）
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 警告ログ（Crashlyticsには送信しない）
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// エラーログ（Crashlyticsに送信）
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    // 通常のloggerで出力
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Crashlyticsに送信
    try {
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
        );
      } else {
        FirebaseCrashlytics.instance.log('ERROR: $message');
      }
    } catch (e) {
      // Crashlytics送信に失敗した場合でも、通常のログは出力する
      _logger.e('Failed to send error to Crashlytics: $e');
    }
  }

  /// 致命的エラーログ（Crashlyticsに送信）
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    // 通常のloggerで出力
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Crashlyticsに送信
    try {
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: true,
        );
      } else {
        FirebaseCrashlytics.instance.log('FATAL: $message');
      }
    } catch (e) {
      // Crashlytics送信に失敗した場合でも、通常のログは出力する
      _logger.e('Failed to send fatal error to Crashlytics: $e');
    }
  }

  /// カスタムログ（Crashlyticsには送信しない）
  static void log(
    Level level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, message, error: error, stackTrace: stackTrace);
  }

  /// 例外をログに記録（Crashlyticsに送信）
  static void logException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) {
    final message = reason ?? 'Exception occurred';
    e(message, exception, stackTrace);
  }

  /// 非同期処理のエラーをログに記録（Crashlyticsに送信）
  static void logAsyncError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    final message = context ?? 'Async operation failed';
    e(message, error, stackTrace);
  }
}
