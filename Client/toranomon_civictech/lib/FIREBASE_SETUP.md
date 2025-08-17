# Firebase設定ガイド

このプロジェクトでは、以下のFirebaseサービスを使用しています：

## 設定済みサービス

### 1. Firebase Authentication
- メール・パスワード認証
- ユーザー管理
- パスワードリセット機能

### 2. Firebase Analytics
- ユーザー行動分析
- イベント追跡
- 画面表示追跡

### 3. Firebase Crashlytics
- クラッシュレポート
- エラー追跡
- パフォーマンス監視

### 4. Firebase Cloud Messaging (FCM)
- プッシュ通知
- フォアグラウンド・バックグラウンド通知
- 通知タップ処理

### 5. Firebase Storage
- ファイルアップロード・ダウンロード
- 画像・動画保存
- セキュアなファイル管理

### 6. Cloud Firestore
- NoSQLデータベース
- リアルタイムデータ同期
- オフライン対応

### 7. Firebase Remote Config
- リモート設定管理
- 機能フラグ制御
- A/Bテスト対応
- メンテナンスモード制御

## 使用方法

### 認証機能
```dart
// サインイン
await ref.read(authNotifierProvider.notifier).signInWithEmailAndPassword(
  email, password
);

// サインアップ
await ref.read(authNotifierProvider.notifier).signUpWithEmailAndPassword(
  email, password
);

// サインアウト
await ref.read(authNotifierProvider.notifier).signOut();
```

### Analytics機能
```dart
// カスタムイベント
await ref.read(analyticsServiceProvider).logEvent(
  name: 'button_click',
  parameters: {'button_name': 'submit'}
);

// 画面表示
await ref.read(analyticsServiceProvider).logScreenView(
  screenName: 'home_screen'
);
```

### Storage機能
```dart
// ファイルアップロード
final url = await ref.read(storageServiceProvider).uploadFile(
  path: 'images/profile.jpg',
  file: imageFile,
  contentType: 'image/jpeg'
);
```

### Firestore機能
```dart
// ドキュメント追加
await ref.read(firestoreServiceProvider).addDocument(
  'users',
  {'name': 'John', 'email': 'john@example.com'}
);

// リアルタイムリスナー
ref.read(firestoreServiceProvider).collectionStream('users')
  .listen((snapshot) {
    // データ更新時の処理
  });
```

### RemoteConfig機能
```dart
// 設定値を取得
final welcomeMessage = ref.watch(welcomeMessageProvider);
final featureFlag = ref.watch(featureFlagNewUIProvider);
final isMaintenance = ref.watch(isMaintenanceModeProvider);

// 設定を手動で更新
await ref.read(remoteConfigStateProvider.notifier).refresh();

// カスタム設定値を取得
final remoteConfig = ref.read(remoteConfigServiceProvider);
final customValue = remoteConfig.getString('custom_key');
```

## 設定ファイル

- `lib/firebase_options.dart`: Firebase設定（自動生成）
- `lib/config/firebase_config.dart`: Firebase初期化設定
- `lib/providers/firebase_*.dart`: 各サービスのプロバイダー
- `lib/screens/remote_config_demo_screen.dart`: RemoteConfigデモ画面

## 注意事項

1. **セキュリティルール**: FirestoreとStorageのセキュリティルールを適切に設定してください
2. **APIキー**: 設定ファイルに含まれるAPIキーは公開リポジトリにコミットしないでください
3. **通知許可**: iOSでは通知許可のリクエストが必要です
4. **Crashlytics**: 開発環境では必要に応じて無効化できます

## トラブルシューティング

### よくある問題

1. **Firebase初期化エラー**
   - `flutterfire configure`を再実行
   - 設定ファイルが正しく生成されているか確認

2. **通知が受信できない**
   - 通知許可が許可されているか確認
   - FCMトークンが正しく取得されているか確認

3. **Crashlyticsが動作しない**
   - デバッグビルドでは無効化されている可能性
   - リリースビルドでテスト

4. **RemoteConfigが更新されない**
   - Firebase Consoleで設定値が正しく設定されているか確認
   - 最小取得間隔（デフォルト1時間）を確認
   - デバッグモードで強制更新を試行

### デバッグ方法

```dart
// FCMトークンの確認
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// 認証状態の確認
final user = FirebaseAuth.instance.currentUser;
print('Current User: ${user?.email}');

// RemoteConfig状態の確認
final remoteConfig = FirebaseRemoteConfig.instance;
print('Last Fetch Time: ${remoteConfig.lastFetchTime}');
print('Last Fetch Status: ${remoteConfig.lastFetchStatus}');