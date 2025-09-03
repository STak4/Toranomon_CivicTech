# Leonard.ai API サービス

Leonard.ai画像生成・編集APIとの通信を行うためのサービス層実装です。

## 構成

### 主要コンポーネント

- **LeonardoAiService**: メインサービスクラス（エラーハンドリング統合）
- **LeonardoAiApiClient**: Retrofit APIクライアント（自動生成）
- **DioConfig**: Dio設定とインターセプター管理
- **ErrorHandler**: エラー変換とハンドリング
- **Result<T, E>**: 型安全なエラーハンドリング

### インターセプター

- **AuthInterceptor**: APIキー自動付与
- **RetryInterceptor**: 指数バックオフリトライ
- **LoggingInterceptor**: リクエスト・レスポンスログ

## 使用方法

### 基本的な使用例

```dart
import 'package:toranomon_civictech/services/leonardo_ai/leonardo_ai_services.dart';

// サービスインスタンス作成
final service = LeonardoAiService();

// 画像生成
final request = GenerationRequest(
  prompt: '美しい風景画',
  numImages: 1,
);

final result = await service.generateImage(request);

result.fold(
  (response) => print('生成成功: ${response.generationId}'),
  (error) => print('エラー: ${error.message}'),
);

// リソース解放
service.dispose();
```

### キャンセル機能

```dart
final cancelToken = CancelToken();

// 生成開始
final future = service.generateImage(request, cancelToken: cancelToken);

// 必要に応じてキャンセル
cancelToken.cancel('ユーザーがキャンセル');
```

## エラーハンドリング

### エラータイプ

- **NetworkError**: ネットワーク関連エラー
- **AuthenticationError**: 認証エラー（APIキー無効など）
- **RateLimitError**: API制限エラー
- **ValidationError**: リクエスト検証エラー
- **ApiError**: サーバーエラー
- **UnknownError**: その他のエラー

### Result型の使用

```dart
final result = await service.generateImage(request);

// パターンマッチング
switch (result) {
  case Success(data: final response):
    // 成功処理
    break;
  case Failure(error: final error):
    // エラー処理
    break;
}

// または fold メソッド
result.fold(
  (response) => handleSuccess(response),
  (error) => handleError(error),
);
```

## 設定

### 環境変数

`.env`ファイルに以下を設定：

```
LEONARD_API_KEY=your_api_key_here
```

### タイムアウト設定

- 接続タイムアウト: 30秒
- 受信タイムアウト: 60秒
- 送信タイムアウト: 60秒

### リトライ設定

- 最大リトライ回数: 3回
- 指数バックオフ: 1秒から開始
- 最大遅延: 30秒

## テスト

```bash
# エラーハンドラーのテスト実行
flutter test test/services/leonardo_ai/error_handler_test.dart
```

## 注意事項

- APIキーは必ず環境変数で管理してください
- 本番環境では適切なログレベルを設定してください
- リソース解放のため、使用後は`dispose()`を呼び出してください