import 'dart:math';
import 'package:dio/dio.dart';
import '../../../utils/app_logger.dart';

/// リトライ機能付きインターセプター
/// 
/// 指数バックオフによる自動リトライを実装
class RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 1000);
  
  /// リトライ対象のHTTPステータスコード
  static const List<int> _retryStatusCodes = [
    408, // Request Timeout
    429, // Too Many Requests
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  ];

  /// リトライ対象のDioExceptionType
  static const List<DioExceptionType> _retryExceptionTypes = [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);
    final retryCount = _getRetryCount(err.requestOptions);
    
    if (shouldRetry && retryCount < _maxRetries) {
      final newRetryCount = retryCount + 1;
      final delay = _calculateBackoffDelay(newRetryCount);
      
      AppLogger.i(
        'リトライを実行します ($newRetryCount/$_maxRetries) - $delay.inMilliseconds ms後',
      );
      
      // 遅延を追加
      await Future.delayed(delay);
      
      // リトライ回数を更新
      err.requestOptions.extra['retryCount'] = newRetryCount;
      
      try {
        // リクエストを再実行
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        
        AppLogger.i('リトライが成功しました ($newRetryCount回目)');
      } catch (e) {
        AppLogger.w('リトライが失敗しました ($newRetryCount回目): $e');
        
        if (e is DioException) {
          // 再帰的にリトライ処理を実行
          onError(e, handler);
        } else {
          handler.next(err);
        }
      }
    } else {
      if (retryCount >= _maxRetries) {
        AppLogger.e('最大リトライ回数($_maxRetries)に達しました');
      }
      handler.next(err);
    }
  }

  /// リトライすべきかどうかを判定
  bool _shouldRetry(DioException err) {
    // キャンセルされたリクエストはリトライしない
    if (err.type == DioExceptionType.cancel) {
      return false;
    }
    
    // レスポンスがある場合はステータスコードで判定
    if (err.response != null) {
      return _retryStatusCodes.contains(err.response!.statusCode);
    }
    
    // レスポンスがない場合はExceptionTypeで判定
    return _retryExceptionTypes.contains(err.type);
  }

  /// 現在のリトライ回数を取得
  int _getRetryCount(RequestOptions options) {
    return options.extra['retryCount'] as int? ?? 0;
  }

  /// 指数バックオフによる遅延時間を計算
  Duration _calculateBackoffDelay(int attempt) {
    final exponentialDelay = _baseDelay.inMilliseconds * pow(2, attempt - 1);
    
    // ジッターを追加（±25%のランダム性）
    final jitter = Random().nextDouble() * 0.5 + 0.75; // 0.75 - 1.25
    final delayWithJitter = (exponentialDelay * jitter).round();
    
    // 最大遅延時間を30秒に制限
    final maxDelay = Duration(seconds: 30).inMilliseconds;
    final finalDelay = min(delayWithJitter, maxDelay);
    
    return Duration(milliseconds: finalDelay);
  }
}