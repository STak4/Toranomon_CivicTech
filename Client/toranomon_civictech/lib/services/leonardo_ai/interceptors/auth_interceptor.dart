import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../utils/app_logger.dart';

/// Leonard.ai API認証用インターセプター
///
/// すべてのリクエストにAPIキーを自動的に付与する
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = dotenv.env['LEONARDO_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      AppLogger.e('LEONARDO_API_KEYが設定されていません');
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: 'APIキーが設定されていません',
        ),
      );
      return;
    }

    // Authorizationヘッダーにベアラートークンとして追加
    options.headers['Authorization'] = 'Bearer $apiKey';

    AppLogger.d('Leonardo APIキーをリクエストヘッダーに追加しました (Length: ${apiKey.length})');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 認証エラーの場合は詳細なログを出力
    if (err.response?.statusCode == 401) {
      AppLogger.e('認証エラー: APIキーが無効または期限切れです');
    }

    handler.next(err);
  }
}
