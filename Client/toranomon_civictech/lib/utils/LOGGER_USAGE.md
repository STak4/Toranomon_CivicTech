# AppLogger 使用方法ガイド

このプロジェクトでは、`AppLogger`クラスを使用してログ出力を行います。エラーログのみCrashlyticsに自動送信され、その他のログは通常のloggerで出力されます。

## 基本的な使用方法

### インポート
```dart
import 'package:your_app/utils/app_logger.dart';
```

### ログレベル別の使用方法

#### 1. デバッグログ（Crashlyticsには送信されません）
```dart
AppLogger.d('デバッグ情報: $variable');
AppLogger.d('ユーザーアクション', null, StackTrace.current);
```

#### 2. 情報ログ（Crashlyticsには送信されません）
```dart
AppLogger.i('ユーザーがログインしました');
AppLogger.i('API呼び出し完了: ${response.statusCode}');
```

#### 3. 警告ログ（Crashlyticsには送信されません）
```dart
AppLogger.w('ネットワーク接続が不安定です');
AppLogger.w('キャッシュの有効期限が切れています');
```

#### 4. エラーログ（Crashlyticsに自動送信）
```dart
AppLogger.e('API呼び出しに失敗しました', exception, stackTrace);
AppLogger.e('データベース接続エラー');
```

#### 5. 致命的エラーログ（Crashlyticsに自動送信）
```dart
AppLogger.f('アプリケーションがクラッシュしました', exception, stackTrace);
AppLogger.f('重要なデータが破損しました');
```

## 実装例

### 認証処理での使用例
```dart
class AuthService {
  Future<void> signIn(String email, String password) async {
    try {
      AppLogger.i('ユーザー認証を開始: $email');
      
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      AppLogger.i('ユーザー認証が成功しました: ${result.user?.uid}');
    } catch (e, stackTrace) {
      AppLogger.e('ユーザー認証に失敗しました', e, stackTrace);
      rethrow;
    }
  }
}
```

### API呼び出しでの使用例
```dart
class ApiService {
  Future<Map<String, dynamic>> fetchData() async {
    try {
      AppLogger.d('API呼び出しを開始');
      
      final response = await http.get(Uri.parse('https://api.example.com/data'));
      
      if (response.statusCode == 200) {
        AppLogger.i('API呼び出しが成功しました');
        return jsonDecode(response.body);
      } else {
        AppLogger.w('API呼び出しが失敗しました: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.e('API呼び出しでエラーが発生しました', e, stackTrace);
      rethrow;
    }
  }
}
```

### 非同期処理での使用例
```dart
Future<void> processData() async {
  try {
    AppLogger.i('データ処理を開始');
    
    await Future.delayed(Duration(seconds: 2));
    
    AppLogger.i('データ処理が完了しました');
  } catch (e, stackTrace) {
    AppLogger.logAsyncError(e, stackTrace, context: 'データ処理中');
  }
}
```

## ベストプラクティス

### 1. 適切なログレベルを使用
- **d (Debug)**: 開発時の詳細な情報
- **i (Info)**: 一般的な情報（ユーザーアクション、処理完了など）
- **w (Warning)**: 警告（パフォーマンス問題、非致命的なエラーなど）
- **e (Error)**: エラー（処理失敗、例外など）
- **f (Fatal)**: 致命的エラー（アプリクラッシュ、データ破損など）

### 2. 機密情報を避ける
```dart
// ❌ 悪い例
AppLogger.i('パスワード: $password');

// ✅ 良い例
AppLogger.i('ユーザー認証を開始: $email');
```

### 3. エラー情報を含める
```dart
// ❌ 悪い例
AppLogger.e('エラーが発生しました');

// ✅ 良い例
AppLogger.e('API呼び出しに失敗しました', exception, stackTrace);
```

### 4. コンテキスト情報を追加
```dart
AppLogger.e('ユーザー登録処理でエラーが発生しました', exception, stackTrace);
AppLogger.logAsyncError(error, stackTrace, context: '画像アップロード処理中');
```

## 設定

### 開発環境での設定
開発環境では、すべてのログレベルが表示されます。

### 本番環境での設定
本番環境では、デバッグログは表示されず、エラーログのみCrashlyticsに送信されます。

## トラブルシューティング

### Crashlyticsにログが送信されない場合
1. Firebase初期化が完了しているか確認
2. ネットワーク接続を確認
3. エラーログ（`AppLogger.e`、`AppLogger.f`）を使用しているか確認

### ログが表示されない場合
1. ログレベルが適切に設定されているか確認
2. デバッグモードで実行しているか確認

## 移行ガイド

### print文からAppLoggerへの移行
```dart
// 移行前
print('ユーザーがログインしました');

// 移行後
AppLogger.i('ユーザーがログインしました');
```

### エラーハンドリングでの使用
```dart
// 移行前
try {
  // 処理
} catch (e) {
  print('エラー: $e');
}

// 移行後
try {
  // 処理
} catch (e, stackTrace) {
  AppLogger.e('処理でエラーが発生しました', e, stackTrace);
}
``` 