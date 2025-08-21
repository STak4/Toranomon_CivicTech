import 'package:dio/dio.dart';
import '../../../utils/app_logger.dart';

/// HTTP通信ログ出力用インターセプター
/// 
/// リクエスト・レスポンスの詳細をログに出力
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      'HTTP Request: ${options.method} ${options.uri}\n'
      'Headers: ${_sanitizeHeaders(options.headers)}\n'
      'Data: ${_sanitizeData(options.data)}',
    );
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
      'HTTP Response: ${response.statusCode} ${response.statusMessage}\n'
      'URL: ${response.requestOptions.uri}\n'
      'Headers: ${response.headers.map}\n'
      'Data: ${_truncateData(response.data)}',
    );
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      'HTTP Error: ${err.type}\n'
      'URL: ${err.requestOptions.uri}\n'
      'Status Code: ${err.response?.statusCode}\n'
      'Message: ${err.message}\n'
      'Response Data: ${err.response?.data}',
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

  /// データを適切な長さに切り詰め
  String _truncateData(dynamic data) {
    const maxLength = 1000;
    final dataString = data.toString();
    
    if (dataString.length <= maxLength) {
      return dataString;
    }
    
    return '${dataString.substring(0, maxLength)}... (truncated)';
  }
}