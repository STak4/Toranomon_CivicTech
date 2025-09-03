import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_logger.dart';
import '../widgets/leonardo_ai_widgets.dart';

class LeonardoAiMenuScreen extends ConsumerWidget {
  const LeonardoAiMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leonardo AI'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー説明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Leonardo AI',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AIを使用して画像の生成と編集を行います',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 機能選択ボタン
            Expanded(
              child: Column(
                children: [
                  LeonardoAiFeatureCard(
                    title: '画像生成',
                    description: 'テキストプロンプトから新しい画像を生成',
                    icon: Icons.image,
                    color: Colors.blue,
                    onTap: () {
                      AppLogger.d(
                        'Navigation - User navigated to image generation screen',
                      );
                      context.goNamed('leonardo-ai-generate');
                    },
                  ),
                  const SizedBox(height: 16),
                  LeonardoAiFeatureCard(
                    title: '画像編集',
                    description: '既存の画像をAIで編集・加工',
                    icon: Icons.edit,
                    color: Colors.green,
                    onTap: () {
                      AppLogger.d(
                        'Navigation - User navigated to image editing screen',
                      );
                      context.goNamed('leonardo-ai-edit');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
