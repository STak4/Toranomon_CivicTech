import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/leonardo_ai/generated_image.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_result.dart';
import '../models/leonardo_ai/inpainting_result.dart';
import '../providers/leonardo_ai_providers.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/edit_result_widget.dart';
import '../widgets/save_to_gallery_button.dart';
import '../utils/app_logger.dart';

/// 画像生成・編集結果表示画面
///
/// 生成または編集された画像の表示、ギャラリー保存、再修正機能を提供する
class ImageResultScreen extends ConsumerStatefulWidget {
  const ImageResultScreen({
    super.key,
    this.generatedImage,
    this.editedImage,
    this.generationResult,
    this.inpaintingResult,
  });

  final GeneratedImage? generatedImage;
  final EditedImage? editedImage;
  final GenerationResult? generationResult;
  final InpaintingResult? inpaintingResult;

  @override
  ConsumerState<ImageResultScreen> createState() => _ImageResultScreenState();
}

class _ImageResultScreenState extends ConsumerState<ImageResultScreen> {
  bool _isImageExpanded = false;
  int _currentImageIndex = 0;
  int _currentInpaintingImageIndex = 0; // Inpainting結果用の画像インデックス
  String _reEditPrompt = '';
  bool _showReEditSection = false;

  @override
  void initState() {
    super.initState();
    AppLogger.i('画像結果画面を初期化');
    AppLogger.i(
      '受け取ったパラメータ: generatedImage=${widget.generatedImage != null}, editedImage=${widget.editedImage != null}, generationResult=${widget.generationResult != null}, inpaintingResult=${widget.inpaintingResult != null}',
    );

    if (widget.inpaintingResult != null) {
      AppLogger.i(
        'InpaintingResult詳細: id=${widget.inpaintingResult!.id}, resultImageUrl=${widget.inpaintingResult!.resultImageUrl}',
      );
    }

    // Canvas Inpainting結果の場合は再修正セクションを表示
    if (widget.inpaintingResult != null) {
      _showReEditSection = true;
      _reEditPrompt = widget.inpaintingResult!.prompt;
    }
  }

  /// 現在表示中の画像を取得
  GeneratedImage? get _currentImage {
    if (widget.generationResult != null) {
      return widget.generationResult!.getImageAt(_currentImageIndex);
    } else if (widget.generatedImage != null) {
      return widget.generatedImage;
    }
    return null;
  }

  /// 画像URLを取得
  String get _imageUrl {
    final currentImage = _currentImage;
    if (currentImage != null) {
      return currentImage.url;
    } else if (widget.editedImage != null) {
      return widget.editedImage!.editedImageUrl;
    } else if (widget.inpaintingResult != null) {
      return widget.inpaintingResult!.getImageUrlAt(
        _currentInpaintingImageIndex,
      );
    }
    return '';
  }

  /// プロンプトを取得
  String get _prompt {
    final currentImage = _currentImage;
    if (currentImage != null) {
      return currentImage.prompt;
    } else if (widget.editedImage != null) {
      return widget.editedImage!.editPrompt;
    } else if (widget.inpaintingResult != null) {
      return widget.inpaintingResult!.prompt;
    }
    return '';
  }

  /// 作成日時を取得
  DateTime get _createdAt {
    final currentImage = _currentImage;
    if (currentImage != null) {
      return currentImage.createdAt;
    } else if (widget.editedImage != null) {
      return widget.editedImage!.createdAt;
    } else if (widget.inpaintingResult != null) {
      return widget.inpaintingResult!.createdAt;
    }
    return DateTime.now();
  }

  /// 画像タイプを取得
  String get _imageType {
    if (widget.generationResult != null) {
      return '生成画像';
    } else if (widget.generatedImage != null) {
      return '生成画像';
    } else if (widget.editedImage != null) {
      return '編集画像';
    } else if (widget.inpaintingResult != null) {
      return 'Canvas Inpainting';
    }
    return '画像';
  }

  /// 前の画像に切り替え
  void _previousImage() {
    if (widget.generationResult != null && _currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  /// 次の画像に切り替え
  void _nextImage() {
    if (widget.generationResult != null &&
        _currentImageIndex < widget.generationResult!.imageCount - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  /// 新しい画像を生成
  void _generateNewImage() {
    AppLogger.i('新しい画像生成画面に遷移');
    context.pop(); // 結果画面を閉じて生成画面に戻る
  }

  /// 再修正を実行
  Future<void> _executeReEdit() async {
    if (_reEditPrompt.trim().isEmpty) {
      _showErrorSnackBar('プロンプトを入力してください');
      return;
    }

    if (widget.inpaintingResult == null) {
      _showErrorSnackBar('再修正用のデータがありません');
      return;
    }

    try {
      AppLogger.i('再修正を実行: $_reEditPrompt');

      await ref
          .read(canvasInpaintingProvider.notifier)
          .reEditWithNewPrompt(_reEditPrompt.trim());
    } catch (e) {
      AppLogger.e('再修正でエラー: $e');
      _showErrorSnackBar('再修正に失敗しました');
    }
  }

  /// 再修正セクションの表示切り替え
  void _toggleReEditSection() {
    setState(() {
      _showReEditSection = !_showReEditSection;
    });
  }

  /// 再修正が可能かチェック
  bool get _canReEdit {
    return widget.inpaintingResult != null &&
        ref.read(canvasInpaintingProvider.notifier).canReEdit();
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

  @override
  Widget build(BuildContext context) {
    // Canvas Inpainting状態を監視
    final canvasInpaintingState = ref.watch(canvasInpaintingProvider);
    final canvasInpaintingProgress = ref.watch(
      canvasInpaintingProgressProvider,
    );

    // Canvas Inpainting結果を監視（再修正完了時の処理）
    ref.listen<AsyncValue<InpaintingResult?>>(canvasInpaintingProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (result) {
          if (result != null && previous?.value != result) {
            _showSuccessSnackBar('再修正が完了しました');
            // 新しい結果で画面を更新するため、ナビゲーションで置き換え
            context.pushReplacement(
              '/leonardo-ai/result',
              extra: {'inpaintingResult': result},
            );
          }
        },
        loading: () {
          // ローディング状態の処理は LoadingOverlayWidget で行う
        },
        error: (error, stackTrace) {
          _showErrorSnackBar('再修正に失敗しました');
          AppLogger.e('再修正エラー: $error', error, stackTrace);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('$_imageType結果'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          SimpleGallerySaveButton(
            imageUrl: _imageUrl,
            fileName: 'leonardo_ai_${DateTime.now().millisecondsSinceEpoch}',
            onSaveSuccess: () {
              _showSuccessSnackBar('ギャラリーに保存しました');
            },
            onSaveError: (error) {
              _showErrorSnackBar('ギャラリーへの保存に失敗しました');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 画像表示 - Canvas Inpainting結果の場合は専用ウィジェットを使用
                if (widget.inpaintingResult != null)
                  EditResultWidget(
                    inpaintingResult: widget.inpaintingResult!,
                    onImageIndexChanged: (index) {
                      setState(() {
                        _currentInpaintingImageIndex = index;
                      });
                    },
                  )
                else
                  // 従来の画像表示カード（生成画像用）
                  Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // 画像表示エリア
                        Stack(
                          children: [
                            // 画像
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isImageExpanded = !_isImageExpanded;
                                });
                              },
                              child: Hero(
                                tag: 'generated_image_$_imageUrl',
                                child: Container(
                                  width: double.infinity,
                                  height: _isImageExpanded ? 400 : 300,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  child: _imageUrl.isNotEmpty
                                      ? Image.network(
                                          _imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 48,
                                                        color: Colors.grey,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        '画像の読み込みに失敗しました',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '画像がありません',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // 左右フリック機能
                            if (widget.generationResult != null &&
                                widget.generationResult!.imageCount > 1)
                              GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  if (details.primaryVelocity! > 0) {
                                    // 右から左へのスワイプ（前の画像）
                                    _previousImage();
                                  } else if (details.primaryVelocity! < 0) {
                                    // 左から右へのスワイプ（次の画像）
                                    _nextImage();
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: _isImageExpanded ? 400 : 300,
                                  color: Colors.transparent,
                                ),
                              ),

                            // ナビゲーションボタン
                            if (widget.generationResult != null &&
                                widget.generationResult!.imageCount > 1)
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    // 前の画像ボタン
                                    if (_currentImageIndex > 0)
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _previousImage,
                                          child: Container(
                                            color: Colors.transparent,
                                            child: const Center(
                                              child: Icon(
                                                Icons.chevron_left,
                                                size: 32,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // 中央のスペース
                                    const Expanded(flex: 2, child: SizedBox()),

                                    // 次の画像ボタン
                                    if (_currentImageIndex <
                                        widget.generationResult!.imageCount - 1)
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _nextImage,
                                          child: Container(
                                            color: Colors.transparent,
                                            child: const Center(
                                              child: Icon(
                                                Icons.chevron_right,
                                                size: 32,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // 画像インデックス表示
                            if (widget.generationResult != null &&
                                widget.generationResult!.imageCount > 1)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1} / ${widget.generationResult!.imageCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // 画像情報
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '画像情報',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('タイプ', _imageType),
                              _buildInfoRow(
                                '作成日時',
                                _formatDateTime(_createdAt),
                              ),
                              if (_prompt.isNotEmpty)
                                _buildInfoRow('プロンプト', _prompt),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 再修正セクション（Canvas Inpainting結果の場合のみ表示）
                if (_canReEdit) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_fix_high,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '再修正',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _toggleReEditSection,
                                icon: Icon(
                                  _showReEditSection
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                tooltip: _showReEditSection ? '閉じる' : '開く',
                              ),
                            ],
                          ),
                          if (_showReEditSection) ...[
                            const SizedBox(height: 12),
                            Text(
                              '同じ編集領域で異なるプロンプトを試すことができます',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PromptInputWidget(
                              initialValue: _reEditPrompt,
                              onChanged: (value) {
                                setState(() {
                                  _reEditPrompt = value;
                                });
                              },
                              onSubmitted: (_) => _executeReEdit(),
                              hintText: '新しいプロンプトを入力してください...',
                              enabled: !canvasInpaintingState.isLoading,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    canvasInpaintingState.isLoading ||
                                        _reEditPrompt.trim().isEmpty
                                    ? null
                                    : _executeReEdit,
                                icon: canvasInpaintingState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.auto_fix_high),
                                label: Text(
                                  canvasInpaintingState.isLoading
                                      ? '再修正中...'
                                      : '再修正を実行',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: SaveToGalleryButton(
                        imageUrl: _imageUrl,
                        fileName:
                            'leonardo_ai_${DateTime.now().millisecondsSinceEpoch}',
                        onSaveSuccess: () {
                          _showSuccessSnackBar('ギャラリーに保存しました');
                        },
                        onSaveError: (error) {
                          _showErrorSnackBar('ギャラリーへの保存に失敗しました');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 新しい画像を生成ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateNewImage,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('新しい画像を生成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                              'ヒント',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 画像をタップすると拡大表示されます\n'
                          '• ギャラリーに保存して他のアプリで使用できます\n'
                          '• 編集機能でさらに画像を加工できます\n'
                          '• 気に入らない場合は新しい画像を生成してみましょう',
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

          // ギャラリー保存のローディングは SaveToGalleryButton で処理

          // ローディングオーバーレイ（再修正中）
          LoadingOverlayWidget(
            isVisible: canvasInpaintingState.isLoading,
            message: canvasInpaintingProgress?.message ?? '再修正中...',
            subMessage:
                canvasInpaintingProgress?.subMessage ??
                '新しいプロンプトで画像を再編集しています。\nしばらくお待ちください。',
            progress: canvasInpaintingProgress?.progress,
            showCancelButton: true,
            onCancel: () {
              ref.read(canvasInpaintingProvider.notifier).cancelInpainting();
            },
          ),
        ],
      ),
    );
  }

  /// 情報行を構築
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
