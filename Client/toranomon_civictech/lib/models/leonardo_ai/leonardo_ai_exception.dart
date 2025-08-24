/// Leonardo AI関連の例外基底クラス
abstract class LeonardoAiException implements Exception {
  const LeonardoAiException(this.message);
  
  final String message;
  
  // Freezedスタイルのファクトリメソッド（互換性のため）
  static NetworkError networkError(String message) => NetworkError(message);
  static ApiError apiError(int statusCode, String message) => ApiError(statusCode, message);
  static AuthenticationError authenticationError(String message) => AuthenticationError(message);
  static RateLimitError rateLimitError(String message, DateTime retryAfter) => RateLimitError(message, retryAfter);
  static ValidationError validationError(String message) => ValidationError(message);
  static ImageUploadError imageUploadError(String message) => ImageUploadError(message);
  static MaskGenerationError maskGenerationError(String message) => MaskGenerationError(message);
  static Cancelled cancelled() => const Cancelled();
  static Timeout timeout() => const Timeout();
  static UnknownError unknownError(String message) => UnknownError(message);
  
  @override
  String toString() => 'LeonardoAiException: $message';
}

/// ネットワークエラー
class NetworkError extends LeonardoAiException {
  const NetworkError(super.message);
  
  @override
  String toString() => 'NetworkError: $message';
}

/// APIエラー
class ApiError extends LeonardoAiException {
  const ApiError(this.statusCode, super.message);
  
  final int statusCode;
  
  @override
  String toString() => 'ApiError($statusCode): $message';
}

/// 認証エラー
class AuthenticationError extends LeonardoAiException {
  const AuthenticationError(super.message);
  
  @override
  String toString() => 'AuthenticationError: $message';
}

/// レート制限エラー
class RateLimitError extends LeonardoAiException {
  const RateLimitError(super.message, this.retryAfter);
  
  final DateTime retryAfter;
  
  @override
  String toString() => 'RateLimitError: $message (retry after: $retryAfter)';
}

/// バリデーションエラー
class ValidationError extends LeonardoAiException {
  const ValidationError(super.message);
  
  @override
  String toString() => 'ValidationError: $message';
}

/// 画像アップロードエラー
class ImageUploadError extends LeonardoAiException {
  const ImageUploadError(super.message);
  
  @override
  String toString() => 'ImageUploadError: $message';
}

/// マスク生成エラー
class MaskGenerationError extends LeonardoAiException {
  const MaskGenerationError(super.message);
  
  @override
  String toString() => 'MaskGenerationError: $message';
}

/// キャンセルエラー
class Cancelled extends LeonardoAiException {
  const Cancelled() : super('操作がキャンセルされました');
  
  @override
  String toString() => 'Cancelled: $message';
}

/// タイムアウトエラー
class Timeout extends LeonardoAiException {
  const Timeout() : super('タイムアウトしました');
  
  @override
  String toString() => 'Timeout: $message';
}

/// 不明なエラー
class UnknownError extends LeonardoAiException {
  const UnknownError(super.message);
  
  @override
  String toString() => 'UnknownError: $message';
}
