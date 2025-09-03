import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_exception.dart';

void main() {
  group('LeonardoAiException', () {
    test('should create NetworkError', () {
      // Arrange & Act
      final exception = LeonardoAiException.networkError(
        'Network connection failed',
      );

      // Assert
      expect(exception, isA<NetworkError>());
      expect(exception.message, 'Network connection failed');
    });

    test('should create ApiError', () {
      // Arrange & Act
      final exception = LeonardoAiException.apiError(
        500,
        'Internal server error',
      );

      // Assert
      expect(exception, isA<ApiError>());
      expect(exception.message, 'Internal server error');
      expect(exception.statusCode, 500);
    });

    test('should create AuthenticationError', () {
      // Arrange & Act
      final exception = LeonardoAiException.authenticationError(
        'Invalid API key',
      );

      // Assert
      expect(exception, isA<AuthenticationError>());
      expect(exception.message, 'Invalid API key');
    });

    test('should create RateLimitError', () {
      // Arrange
      final retryAfter = DateTime.now().add(const Duration(minutes: 5));
      final exception = LeonardoAiException.rateLimitError(
        'Rate limit exceeded',
        retryAfter,
      );

      // Assert
      expect(exception, isA<RateLimitError>());
      expect(exception.message, 'Rate limit exceeded');
      expect(exception.retryAfter, retryAfter);
    });

    test('should create ValidationError', () {
      // Arrange & Act
      final exception = LeonardoAiException.validationError(
        'Invalid prompt format',
      );

      // Assert
      expect(exception, isA<ValidationError>());
      expect(exception.message, 'Invalid prompt format');
    });

    test('should create UnknownError', () {
      // Arrange & Act
      final exception = LeonardoAiException.unknownError(
        'Something went wrong',
      );

      // Assert
      expect(exception, isA<UnknownError>());
      expect(exception.message, 'Something went wrong');
    });

    test('should be an Exception', () {
      // Arrange & Act
      final exception = LeonardoAiException.networkError('Test error');

      // Assert
      expect(exception, isA<Exception>());
    });

    test('should support pattern matching with is operator', () {
      // Arrange
      final exception = LeonardoAiException.apiError(404, 'Not found');

      // Act & Assert
      expect(exception, isA<ApiError>());
      expect(exception.statusCode, 404);
      expect(exception.message, 'Not found');
    });
  });
}
