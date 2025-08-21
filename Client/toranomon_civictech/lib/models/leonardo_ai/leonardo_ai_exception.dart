import 'package:freezed_annotation/freezed_annotation.dart';

part 'leonardo_ai_exception.freezed.dart';

@freezed
sealed class LeonardoAiException
    with _$LeonardoAiException
    implements Exception {
  const factory LeonardoAiException.networkError(String message) = NetworkError;
  const factory LeonardoAiException.apiError(int statusCode, String message) =
      ApiError;
  const factory LeonardoAiException.authenticationError(String message) =
      AuthenticationError;
  const factory LeonardoAiException.rateLimitError(
    String message,
    DateTime retryAfter,
  ) = RateLimitError;
  const factory LeonardoAiException.validationError(String message) =
      ValidationError;
  const factory LeonardoAiException.unknownError(String message) = UnknownError;
}
