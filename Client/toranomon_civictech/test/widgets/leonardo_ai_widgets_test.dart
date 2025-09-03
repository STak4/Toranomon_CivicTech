import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/widgets/leonardo_ai_widgets.dart';

void main() {
  group('Leonardo AI Widgets Tests', () {
    testWidgets('PromptInputWidget displays correctly', (
      WidgetTester tester,
    ) async {
      String inputText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptInputWidget(
              onChanged: (text) => inputText = text,
              hintText: 'テストプロンプト',
            ),
          ),
        ),
      );

      // ウィジェットが表示されることを確認
      expect(find.text('プロンプト入力'), findsOneWidget);
      expect(find.text('テストプロンプト'), findsOneWidget);

      // テキスト入力をテスト
      await tester.enterText(find.byType(TextField), 'テスト入力');
      expect(inputText, equals('テスト入力'));
    });

    testWidgets('LeonardoAiButton displays correctly', (
      WidgetTester tester,
    ) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeonardoAiButton(
              text: 'テストボタン',
              onPressed: () => buttonPressed = true,
              icon: Icons.star,
            ),
          ),
        ),
      );

      // ボタンが表示されることを確認
      expect(find.text('テストボタン'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // ボタンタップをテスト
      await tester.tap(find.byType(LeonardoAiButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('LeonardoAiFeatureCard displays correctly', (
      WidgetTester tester,
    ) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeonardoAiFeatureCard(
              title: 'テスト機能',
              description: 'テスト説明',
              icon: Icons.image,
              onTap: () => cardTapped = true,
            ),
          ),
        ),
      );

      // カードが表示されることを確認
      expect(find.text('テスト機能'), findsOneWidget);
      expect(find.text('テスト説明'), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);

      // カードタップをテスト
      await tester.tap(find.byType(LeonardoAiFeatureCard));
      expect(cardTapped, isTrue);
    });

    testWidgets('LoadingOverlayWidget displays when visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlayWidget(isVisible: true, message: 'テスト処理中'),
          ),
        ),
      );

      // ローディングオーバーレイが表示されることを確認
      expect(find.text('テスト処理中'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingOverlayWidget hides when not visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlayWidget(isVisible: false, message: 'テスト処理中'),
          ),
        ),
      );

      // ローディングオーバーレイが非表示であることを確認
      expect(find.text('テスト処理中'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
