# Toranomon CivicTech App

## プロジェクト構造

```
lib/
├── main.dart                 # アプリのエントリーポイント
├── router/
│   └── app_router.dart      # go_routerの設定
├── providers/
│   └── app_providers.dart   # riverpodプロバイダーの定義
├── screens/
│   └── unity_demo_screen.dart # Unity統合画面
└── widgets/
    └── counter_widget.dart   # サンプルウィジェット
```

## セットアップ手順

1. 依存関係のインストール:
```bash
flutter pub get
```

2. Riverpodコード生成の実行:
```bash
flutter packages pub run build_runner build
```

3. アプリの実行:
```bash
flutter run
```

## 使用方法

### Go Router
- ルートの定義は `lib/router/app_router.dart` で行います
- 新しいページを追加する場合は、`GoRoute`を追加してください
- ナビゲーションには `context.goNamed('route_name')` を使用します

### Riverpod
- プロバイダーの定義は `lib/providers/app_providers.dart` で行います
- `@riverpod`アノテーションを使用してプロバイダーを作成します
- ウィジェットでは `ConsumerWidget`を使用してプロバイダーにアクセスします

## 注意事項

- Riverpodのコード生成ファイル（`*.g.dart`）は自動生成されるため、手動で編集しないでください
- プロバイダーを変更した場合は、必ず `build_runner`を実行してください 