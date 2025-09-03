/// アプリケーションエラーモデル
/// 
/// アプリケーション内で発生する様々なエラーを分類して表現するデータモデル
abstract class AppError {
  const AppError(this.message);
  
  final String message;
  
  @override
  String toString() => message;
}

/// ネットワーク関連のエラー
class NetworkError extends AppError {
  const NetworkError(super.message);
  
  @override
  String toString() => 'ネットワークエラー: $message';
}

/// 権限関連のエラー
class PermissionError extends AppError {
  const PermissionError(super.message);
  
  @override
  String toString() => '権限エラー: $message';
}

/// 認証関連のエラー
class AuthenticationError extends AppError {
  const AuthenticationError(super.message);
  
  @override
  String toString() => '認証エラー: $message';
}

/// バリデーション関連のエラー
class ValidationError extends AppError {
  const ValidationError(super.message);
  
  @override
  String toString() => 'バリデーションエラー: $message';
}

/// 不明なエラー
class UnknownError extends AppError {
  const UnknownError(super.message);
  
  @override
  String toString() => '不明なエラー: $message';
}

/// ストレージ関連のエラー
class StorageError extends AppError {
  const StorageError(super.message);
  
  @override
  String toString() => 'ストレージエラー: $message';
}

/// 位置情報関連のエラー
class LocationError extends AppError {
  const LocationError(super.message);
  
  @override
  String toString() => '位置情報エラー: $message';
}

/// カメラ関連のエラー
class CameraError extends AppError {
  const CameraError(super.message);
  
  @override
  String toString() => 'カメラエラー: $message';
}