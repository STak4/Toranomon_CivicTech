import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_exception.dart';
import 'package:toranomon_civictech/services/leonardo_ai/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('タイムアウトエラーをネットワークエラーに変換する', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );

      // Act
      final result = ErrorHandler.handleDioError(dioError);

      // Assert
      expect(result, isA<NetworkError>());
      expect(result.message, contains('タイムアウト'));
    });

    test('401エラーを認証エラーに変換する', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );

      // Act
      final result = ErrorHandler.handleDioError(dioError);

      // Assert
      expect(result, isA<AuthenticationError>());
      expect(result.message, contains('APIキー'));
    });

    test('429エラーをレート制限エラーに変換する', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['60'],
          }),
        ),
      );

      // Act
      final result = ErrorHandler.handleDioError(dioError);

      // Assert
      expect(result, isA<RateLimitError>());
      expect(result.message, contains('API制限'));
    });

    test('500エラーをAPIエラーに変換する', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      // Act
      final result = ErrorHandler.handleDioError(dioError);

      // Assert
      expect(result, isA<ApiError>());
      expect(result.message, contains('サーバーエラー'));
    });

    test('一般的な例外を未知のエラーに変換する', () {
      // Arrange
      const error = 'Test error';
      final stackTrace = StackTrace.current;

      // Act
      final result = ErrorHandler.handleGenericError(error, stackTrace);

      // Assert
      expect(result, isA<UnknownError>());
      expect(result.message, contains('予期しないエラー'));
    });
  });
}
