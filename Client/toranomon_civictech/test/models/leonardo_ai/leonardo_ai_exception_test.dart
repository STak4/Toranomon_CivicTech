import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_exception.dart';

void main() {
  group('LeonardoAiException', () {
    test('should create NetworkError', () {
      // Arrange & Act
      const exception = LeonardoAiException.networkError(
        'Network connection failed',
      );

      // Assert
      expect(exception, isA<NetworkError>());
      exception.when(
        networkError: (message) => expect(message, 'Network connection failed'),
        apiError: (statusCode, message) => fail('Should not be ApiError'),
        authenticationError: (message) =>
            fail('Should not be AuthenticationError'),
        rateLimitError: (message, retryAfter) =>
            fail('Should not be RateLimitError'),
        validationError: (message) => fail('Should not be ValidationError'),
        unknownError: (message) => fail('Should not be UnknownError'),
      );
    });

    test('should create ApiError', () {
      // Arrange & Act
      const exception = LeonardoAiException.apiError(
        500,
        'Internal server error',
      );

      // Assert
      expect(exception, isA<ApiError>());
      exception.when(
        networkError: (message) => fail('Should not be NetworkError'),
        apiError: (statusCode, message) {
          expect(statusCode, 500);
          expect(message, 'Internal server error');
        },
        authenticationError: (message) =>
            fail('Should not be AuthenticationError'),
        rateLimitError: (message, retryAfter) =>
            fail('Should not be RateLimitError'),
        validationError: (message) => fail('Should not be ValidationError'),
        unknownError: (message) => fail('Should not be UnknownError'),
      );
    });

    test('should create AuthenticationError', () {
      // Arrange & Act
      const exception = LeonardoAiException.authenticationError(
        'Invalid API key',
      );

      // Assert
      expect(exception, isA<AuthenticationError>());
      exception.when(
        networkError: (message) => fail('Should not be NetworkError'),
        apiError: (statusCode, message) => fail('Should not be ApiError'),
        authenticationError: (message) => expect(message, 'Invalid API key'),
        rateLimitError: (message, retryAfter) =>
            fail('Should not be RateLimitError'),
        validationError: (message) => fail('Should not be ValidationError'),
        unknownError: (message) => fail('Should not be UnknownError'),
      );
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
      exception.when(
        networkError: (message) => fail('Should not be NetworkError'),
        apiError: (statusCode, message) => fail('Should not be ApiError'),
        authenticationError: (message) =>
            fail('Should not be AuthenticationError'),
        rateLimitError: (message, actualRetryAfter) {
          expect(message, 'Rate limit exceeded');
          expect(actualRetryAfter, retryAfter);
        },
        validationError: (message) => fail('Should not be ValidationError'),
        unknownError: (message) => fail('Should not be UnknownError'),
      );
    });

    test('should create ValidationError', () {
      // Arrange & Act
      const exception = LeonardoAiException.validationError(
        'Invalid prompt format',
      );

      // Assert
      expect(exception, isA<ValidationError>());
      exception.when(
        networkError: (message) => fail('Should not be NetworkError'),
        apiError: (statusCode, message) => fail('Should not be ApiError'),
        authenticationError: (message) =>
            fail('Should not be AuthenticationError'),
        rateLimitError: (message, retryAfter) =>
            fail('Should not be RateLimitError'),
        validationError: (message) => expect(message, 'Invalid prompt format'),
        unknownError: (message) => fail('Should not be UnknownError'),
      );
    });

    test('should create UnknownError', () {
      // Arrange & Act
      const exception = LeonardoAiException.unknownError(
        'Something went wrong',
      );

      // Assert
      expect(exception, isA<UnknownError>());
      exception.when(
        networkError: (message) => fail('Should not be NetworkError'),
        apiError: (statusCode, message) => fail('Should not be ApiError'),
        authenticationError: (message) =>
            fail('Should not be AuthenticationError'),
        rateLimitError: (message, retryAfter) =>
            fail('Should not be RateLimitError'),
        validationError: (message) => fail('Should not be ValidationError'),
        unknownError: (message) => expect(message, 'Something went wrong'),
      );
    });

    test('should be an Exception', () {
      // Arrange & Act
      const exception = LeonardoAiException.networkError('Test error');

      // Assert
      expect(exception, isA<Exception>());
    });

    test('should support pattern matching with map', () {
      // Arrange
      const exception = LeonardoAiException.apiError(404, 'Not found');

      // Act
      final result = exception.map(
        networkError: (e) => 'Network: ${e.message}',
        apiError: (e) => 'API ${e.statusCode}: ${e.message}',
        authenticationError: (e) => 'Auth: ${e.message}',
        rateLimitError: (e) => 'Rate limit: ${e.message}',
        validationError: (e) => 'Validation: ${e.message}',
        unknownError: (e) => 'Unknown: ${e.message}',
      );

      // Assert
      expect(result, 'API 404: Not found');
    });
  });
}
