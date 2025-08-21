import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../utils/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Leonard.ai API用のDio設定クラス
class DioConfig {
  static const String _baseUrl = 'https://cloud.leonardo.ai/api/rest/v1';
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 60);
  static const Duration _sendTimeout = Duration(seconds: 60);

  /// Leonard.ai API用に設定されたDioインスタンスを作成
  static Dio createDio() {
    final dio = Dio();
    
    // 基本設定
    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // インターセプターを追加
    dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(),
      LoggingInterceptor(),
    ]);

    AppLogger.i('Leonard.ai API用Dioクライアントを初期化しました');
    return dio;
  }

  /// APIキーを取得
  static String? getApiKey() {
    final apiKey = dotenv.env['LEONARD_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      AppLogger.e('LEONARD_API_KEYが設定されていません');
      return null;
    }
    return apiKey;
  }
}