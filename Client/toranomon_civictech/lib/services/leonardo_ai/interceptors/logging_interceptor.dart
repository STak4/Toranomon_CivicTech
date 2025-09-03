import 'package:dio/dio.dart';
import '../../../utils/app_logger.dart';
import 'dart:convert'; // Added for JsonEncoder

/// HTTP通信ログ出力用インターセプター
///
/// リクエスト・レスポンスの詳細をログに出力
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.i(
      '🚀 API Request: ${options.method} ${options.uri}\n'
      '📋 Headers: ${_sanitizeHeaders(options.headers)}\n'
      '📦 Request Body: ${_formatJsonData(options.data)}',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.i(
      '✅ API Response: ${response.statusCode} ${response.statusMessage}\n'
      '🔗 URL: ${response.requestOptions.uri}\n'
      '📋 Response Headers: ${response.headers.map}\n'
      '📦 Response Body: ${_formatJsonData(response.data)}',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ API Error: ${err.type}\n'
      '🔗 URL: ${err.requestOptions.uri}\n'
      '📊 Status Code: ${err.response?.statusCode}\n'
      '💬 Error Message: ${err.message}\n'
      '🔍 Error Details: ${err.error}\n'
      '📦 Error Response: ${_formatJsonData(err.response?.data)}\n'
      '📋 Request Headers: ${_sanitizeHeaders(err.requestOptions.headers)}',
    );

    handler.next(err);
  }

  /// ヘッダーから機密情報を除去
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // Authorizationヘッダーをマスク
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String;
      if (auth.startsWith('Bearer ')) {
        sanitized['Authorization'] = 'Bearer ***';
      }
    }

    return sanitized;
  }

  /// リクエストデータから機密情報を除去
  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = Map.from(data);

      // APIキーなどの機密情報をマスク
      const sensitiveKeys = ['api_key', 'apiKey', 'token', 'password'];
      for (final key in sensitiveKeys) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***';
        }
      }

      return sanitized;
    }

    return data;
  }

  /// JSONデータを整形して表示
  String _formatJsonData(dynamic data) {
    if (data == null) {
      return 'null';
    }

    // 機密情報を除去
    final sanitizedData = _sanitizeData(data);

    try {
      // JSONとして整形
      if (sanitizedData is Map || sanitizedData is List) {
        const encoder = JsonEncoder.withIndent('  ');
        final jsonString = encoder.convert(sanitizedData);

        // 長すぎる場合は切り詰め
        const maxLength = 2000;
        if (jsonString.length <= maxLength) {
          return jsonString;
        }

        return '${jsonString.substring(0, maxLength)}... (truncated)';
      }

      return sanitizedData.toString();
    } catch (e) {
      // JSON変換に失敗した場合は文字列として返す
      return sanitizedData.toString();
    }
  }
}
