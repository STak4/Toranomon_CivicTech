import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/leonardo_ai_providers.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/loading_overlay_widget.dart';
import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../models/leonardo_ai/generation_result.dart';
import '../utils/app_logger.dart';

/// 画像生成画面
///
/// プロンプト入力から画像生成までの完全なフローを提供する
/// Riverpodプロバイダーと連携した状態管理、入力検証、エラーハンドリングを実装
class ImageGenerationScreen extends ConsumerStatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  ConsumerState<ImageGenerationScreen> createState() =>
      _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends ConsumerState<ImageGenerationScreen> {
  String _prompt = '';
  bool _isGenerating = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    // 画面初期化時に前回の結果をクリア
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imageGenerationProvider.notifier).clearResult();
    });
  }

  /// 画像生成を開始
  Future<void> _generateImage() async {
    if (_prompt.trim().isEmpty) {
      _showErrorSnackBar('プロンプトを入力してください');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      AppLogger.i('画像生成を開始: $_prompt');

      // 画像生成を実行
      await ref.read(imageGenerationProvider.notifier).generateImage(_prompt);

      // 生成完了後の処理は AsyncValue の監視で行う
    } catch (e) {
      AppLogger.e('画像生成でエラー: $e');
      _showErrorSnackBar('画像生成でエラーが発生しました');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// 画像生成をキャンセル
  void _cancelGeneration() {
    AppLogger.i('画像生成をキャンセル');
    ref.read(imageGenerationProvider.notifier).cancelGeneration();

    setState(() {
      _isGenerating = false;
    });
  }

  /// エラーメッセージを表示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 成功メッセージを表示
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 再試行
  Future<void> _retryGeneration() async {
    AppLogger.i('画像生成を再試行');
    setState(() {
      _lastError = null;
    });
    await _generateImage();
  }

  /// エラーメッセージを取得
  String _getErrorMessage(LeonardoAiException error) {
    return switch (error) {
      NetworkError() => 'ネットワークエラーが発生しました。接続を確認してください。',
      ApiError() => 'APIエラーが発生しました: ${error.message}',
      AuthenticationError() => 'APIキーが無効です。設定を確認してください。',
      RateLimitError() => 'API制限に達しました。しばらく待ってから再試行してください。',
      ValidationError() => error.message,
      ImageUploadError() => '画像アップロードエラー: ${error.message}',
      MaskGenerationError() => 'マスク生成エラー: ${error.message}',
      Cancelled() => '操作がキャンセルされました',
      Timeout() => 'タイムアウトしました',
      UnknownError() => '予期しないエラーが発生しました: ${error.message}',
      _ => '予期しないエラーが発生しました: ${error.message}',
    };
  }

  @override
  Widget build(BuildContext context) {
    // 画像生成の状態を監視
    final imageGenerationState = ref.watch(imageGenerationProvider);

    // 生成完了時の処理
    ref.listen<AsyncValue<GenerationResult?>>(imageGenerationProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (generationResult) {
          if (generationResult != null && previous?.value != generationResult) {
            AppLogger.i('画像生成が完了、結果画面に遷移');
            _showSuccessSnackBar(
              '画像生成が完了しました (${generationResult.imageCount}枚)',
            );

            // 結果画面に遷移
            context.goNamed(
              'leonardo-ai-result',
              extra: {'generationResult': generationResult},
            );
          }
        },
        loading: () {
          // ローディング状態の処理は build メソッドで行う
        },
        error: (error, stackTrace) {
          if (error is LeonardoAiException) {
            final errorMessage = _getErrorMessage(error);
            _showErrorSnackBar(errorMessage);
            AppLogger.e('画像生成エラー: $errorMessage');

            setState(() {
              _lastError = errorMessage;
            });
          } else {
            _showErrorSnackBar('予期しないエラーが発生しました');
            AppLogger.e('予期しないエラー: $error', error, stackTrace);

            setState(() {
              _lastError = '予期しないエラーが発生しました';
            });
          }

          setState(() {
            _isGenerating = false;
          });
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('画像生成'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ヘッダーカード
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI画像生成',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'テキストプロンプトから美しい画像を生成します',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // プロンプト入力
                PromptInputWidget(
                  onChanged: (value) {
                    setState(() {
                      _prompt = value;
                    });
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty &&
                        !_isGenerating &&
                        !imageGenerationState.isLoading) {
                      _generateImage();
                    }
                  },
                  hintText:
                      '生成したい画像の説明を入力してください...\n例: 美しい夕日の海辺、猫が遊んでいる公園、未来都市の風景',
                  enabled: !_isGenerating && !imageGenerationState.isLoading,
                  maxLength: 500,
                  minLines: 4,
                  maxLines: 8,
                ),

                const SizedBox(height: 24),

                // 生成ボタン
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_prompt.trim().isNotEmpty &&
                            !_isGenerating &&
                            !imageGenerationState.isLoading)
                        ? _generateImage
                        : null,
                    icon: imageGenerationState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      imageGenerationState.isLoading ? '生成中...' : '画像を生成',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // キャンセルボタン（生成中のみ表示）
                if (imageGenerationState.isLoading) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _cancelGeneration,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('キャンセル'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // 再試行ボタン（エラー時のみ表示）
                if (_lastError != null && !imageGenerationState.isLoading) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _retryGeneration,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再試行'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // エラー表示（エラー時のみ表示）
                if (_lastError != null) ...[
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'エラーが発生しました',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _lastError!,
                            style: TextStyle(
                              color: Colors.red[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 使用方法のヒント
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'プロンプトのコツ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 具体的で詳細な説明を心がけましょう\n'
                          '• 色彩、雰囲気、スタイルを含めると効果的です\n'
                          '• 「高品質」「美しい」などの修飾語も有効です\n'
                          '• 英語でも日本語でも入力可能です',
                          style: TextStyle(
                            color: Colors.blue[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ローディングオーバーレイ
          LoadingOverlayWidget(
            isVisible: imageGenerationState.isLoading,
            message: '画像を生成中...',
            subMessage: 'AIが美しい画像を作成しています。\nしばらくお待ちください。',
            onCancel: _cancelGeneration,
            showCancelButton: true,
          ),
        ],
      ),
    );
  }
}
