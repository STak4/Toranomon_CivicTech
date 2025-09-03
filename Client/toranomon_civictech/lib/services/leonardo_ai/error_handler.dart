import 'package:dio/dio.dart';
import '../../models/leonardo_ai/leonardo_ai_exception.dart';
import '../../utils/app_logger.dart';

/// Leonardo.ai API用エラーハンドラー
///
/// DioExceptionをLeonardoAiExceptionに変換し、適切なエラー処理を行う
class ErrorHandler {
  /// DioExceptionをLeonardoAiExceptionに変換
  ///
  /// [error] Dioで発生したエラー
  /// Returns 変換されたLeonardoAiException
  static LeonardoAiException handleDioError(DioException error) {
    AppLogger.e('DioException発生: ${error.type} - ${error.message}');

    return switch (error.type) {
      // タイムアウト系エラー
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => LeonardoAiException.networkError(
        '通信がタイムアウトしました。ネットワーク接続を確認してください。',
      ),

      // 接続エラー
      DioExceptionType.connectionError =>
        LeonardoAiException.networkError(
          'ネットワークに接続できません。インターネット接続を確認してください。',
        ),

      // レスポンスエラー（HTTPステータスコード）
      DioExceptionType.badResponse => _handleHttpError(error),

      // キャンセルエラー
      DioExceptionType.cancel => LeonardoAiException.unknownError(
        'リクエストがキャンセルされました',
      ),

      // その他のエラー
      DioExceptionType.badCertificate => LeonardoAiException.networkError(
        'SSL証明書エラーが発生しました',
      ),

      DioExceptionType.unknown => LeonardoAiException.unknownError(
        '予期しないエラーが発生しました: ${error.message ?? "不明なエラー"} (Error: ${error.error})',
      ),
    };
  }

  /// HTTPステータスコードに基づくエラー処理
  static LeonardoAiException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    AppLogger.e('HTTPエラー: $statusCode - $responseData');

    return switch (statusCode) {
      // 認証エラー
      401 => LeonardoAiException.authenticationError(
        'APIキーが無効または期限切れです。設定を確認してください。',
      ),

      // 権限エラー
      403 => LeonardoAiException.authenticationError(
        'このAPIにアクセスする権限がありません。',
      ),

      // リソースが見つからない
      404 => LeonardoAiException.apiError(404, '指定されたリソースが見つかりません。'),

      // レート制限
      429 => _handleRateLimitError(error),

      // バリデーションエラー
      int() when statusCode >= 400 && statusCode < 500 =>
        _handleValidationError(error),

      // サーバーエラー
      int() when statusCode >= 500 => LeonardoAiException.apiError(
        statusCode,
        'サーバーエラーが発生しました。しばらく時間をおいて再試行してください。',
      ),

      // その他のエラー
      _ => LeonardoAiException.unknownError(
        'HTTPエラーが発生しました (ステータスコード: $statusCode)',
      ),
    };
  }

  /// レート制限エラーの処理
  static LeonardoAiException _handleRateLimitError(DioException error) {
    final retryAfter = _parseRetryAfter(error.response?.headers);
    final message = 'API制限に達しました。${_formatRetryAfter(retryAfter)}後に再試行してください。';

    return LeonardoAiException.rateLimitError(message, retryAfter);
  }

  /// バリデーションエラーの処理
  static LeonardoAiException _handleValidationError(DioException error) {
    final responseData = error.response?.data;
    String message = 'リクエストが無効です。';

    // レスポンスからエラーメッセージを抽出
    if (responseData is Map<String, dynamic>) {
      final errorMessage =
          responseData['message'] ??
          responseData['error'] ??
          responseData['detail'];
      if (errorMessage != null) {
        message = errorMessage.toString();
      }
    }

    return LeonardoAiException.validationError(message);
  }

  /// Retry-Afterヘッダーから再試行時刻を解析
  static DateTime _parseRetryAfter(Headers? headers) {
    if (headers == null) {
      return DateTime.now().add(const Duration(minutes: 1));
    }

    final retryAfterHeader = headers.value('retry-after');
    if (retryAfterHeader == null) {
      return DateTime.now().add(const Duration(minutes: 1));
    }

    // 秒数で指定されている場合
    final seconds = int.tryParse(retryAfterHeader);
    if (seconds != null) {
      return DateTime.now().add(Duration(seconds: seconds));
    }

    // HTTP日付形式で指定されている場合
    try {
      return DateTime.parse(retryAfterHeader);
    } catch (e) {
      AppLogger.w('Retry-Afterヘッダーの解析に失敗: $retryAfterHeader');
      return DateTime.now().add(const Duration(minutes: 1));
    }
  }

  /// 再試行時刻を人間が読みやすい形式にフォーマット
  static String _formatRetryAfter(DateTime retryAfter) {
    final now = DateTime.now();
    final difference = retryAfter.difference(now);

    if (difference.inMinutes > 0) {
      return '約${difference.inMinutes}分';
    } else if (difference.inSeconds > 0) {
      return '約${difference.inSeconds}秒';
    } else {
      return '少し';
    }
  }

  /// 一般的なExceptionをLeonardoAiExceptionに変換
  static LeonardoAiException handleGenericError(
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.e('予期しないエラー: $error', error, stackTrace);

    if (error is LeonardoAiException) {
      return error;
    }

    return LeonardoAiException.unknownError(
      '予期しないエラーが発生しました: ${error.toString()}',
    );
  }
}
