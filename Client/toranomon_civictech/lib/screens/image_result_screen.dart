import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/leonardo_ai/generated_image.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_result.dart';
import '../providers/leonardo_ai_providers.dart';
import '../widgets/loading_overlay_widget.dart';
import '../utils/app_logger.dart';

/// 画像生成・編集結果表示画面
///
/// 生成または編集された画像の表示、ギャラリー保存、共有機能を提供する
class ImageResultScreen extends ConsumerStatefulWidget {
  const ImageResultScreen({
    super.key,
    this.generatedImage,
    this.editedImage,
    this.generationResult,
  });

  final GeneratedImage? generatedImage;
  final EditedImage? editedImage;
  final GenerationResult? generationResult;

  @override
  ConsumerState<ImageResultScreen> createState() => _ImageResultScreenState();
}

class _ImageResultScreenState extends ConsumerState<ImageResultScreen> {
  bool _isImageExpanded = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.i('画像結果画面を初期化');
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
    }
    return '画像';
  }

  /// ギャラリーに保存
  Future<void> _saveToGallery() async {
    if (_imageUrl.isEmpty) {
      _showErrorSnackBar('保存する画像がありません');
      return;
    }

    try {
      AppLogger.i('ギャラリーへの保存を開始');

      final fileName = 'leonard_ai_${DateTime.now().millisecondsSinceEpoch}';
      await ref
          .read(gallerySaverProviderProvider.notifier)
          .saveToGallery(_imageUrl, fileName: fileName);
    } catch (e) {
      AppLogger.e('ギャラリー保存でエラー: $e');
      _showErrorSnackBar('ギャラリーへの保存に失敗しました');
    }
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

  /// 画像を編集
  void _editImage() {
    AppLogger.i('画像編集画面に遷移');
    context.push('/leonard-ai/edit');
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
    // ギャラリー保存の状態を監視
    final gallerySaveState = ref.watch(gallerySaverProviderProvider);

    // ギャラリー保存の結果を監視
    ref.listen<AsyncValue<bool>>(gallerySaverProviderProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (success) {
          if (success && previous?.value != success) {
            _showSuccessSnackBar('ギャラリーに保存しました');
            ref.read(gallerySaverProviderProvider.notifier).resetSaveState();
          }
        },
        loading: () {
          // ローディング状態の処理は build メソッドで行う
        },
        error: (error, stackTrace) {
          _showErrorSnackBar('ギャラリーへの保存に失敗しました');
          AppLogger.e('ギャラリー保存エラー: $error', error, stackTrace);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('$_imageType結果'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saveToGallery,
            icon: const Icon(Icons.download),
            tooltip: 'ギャラリーに保存',
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
                // 画像表示カード
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
                                                      MainAxisAlignment.center,
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '画像情報',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('タイプ', _imageType),
                            _buildInfoRow('作成日時', _formatDateTime(_createdAt)),
                            if (_prompt.isNotEmpty)
                              _buildInfoRow('プロンプト', _prompt),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: gallerySaveState.isLoading
                            ? null
                            : _saveToGallery,
                        icon: gallerySaveState.isLoading
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
                            : const Icon(Icons.download),
                        label: Text(
                          gallerySaveState.isLoading ? '保存中...' : 'ギャラリーに保存',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _editImage,
                        icon: const Icon(Icons.edit),
                        label: const Text('編集する'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

          // ローディングオーバーレイ（ギャラリー保存中）
          LoadingOverlayWidget(
            isVisible: gallerySaveState.isLoading,
            message: 'ギャラリーに保存中...',
            subMessage: '画像をデバイスに保存しています。\nしばらくお待ちください。',
            showCancelButton: false,
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
