import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leonardo_ai/inpainting_result.dart';
import '../utils/app_logger.dart';

/// 編集結果画像表示ウィジェット
///
/// Canvas Inpainting結果の表示、ズーム機能を提供する
class EditResultWidget extends ConsumerStatefulWidget {
  const EditResultWidget({
    super.key,
    required this.inpaintingResult,
    this.onImageIndexChanged,
  });

  /// Inpainting結果データ
  final InpaintingResult inpaintingResult;

  /// 画像インデックス変更時のコールバック
  final void Function(int index)? onImageIndexChanged;

  @override
  ConsumerState<EditResultWidget> createState() => _EditResultWidgetState();
}

class _EditResultWidgetState extends ConsumerState<EditResultWidget>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _isZoomed = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // ズーム状態の監視
    _transformationController.addListener(_onTransformationChanged);

    // デバッグ情報を出力
    AppLogger.i(
      'EditResultWidget初期化: resultImageUrl=${widget.inpaintingResult.resultImageUrl}',
    );
    AppLogger.i('EditResultWidget画像数: ${widget.inpaintingResult.imageCount}');
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 変換状態の変更を監視
  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final newIsZoomed = scale > 1.1;

    if (newIsZoomed != _isZoomed) {
      setState(() {
        _isZoomed = newIsZoomed;
      });
    }
  }

  /// ズームをリセット
  void _resetZoom() {
    if (_isZoomed) {
      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: Matrix4.identity(),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  /// 画像をダブルタップでズーム
  void _onDoubleTap() {
    if (_isZoomed) {
      _resetZoom();
    } else {
      // 2倍ズーム
      const scale = 2.0;
      final matrix = Matrix4.identity()..scale(scale);

      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: matrix,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  /// 前の画像に切り替え
  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
      _resetZoom();
      widget.onImageIndexChanged?.call(_currentImageIndex);
    }
  }

  /// 次の画像に切り替え
  void _nextImage() {
    if (_currentImageIndex < widget.inpaintingResult.imageCount - 1) {
      setState(() {
        _currentImageIndex++;
      });
      _resetZoom();
      widget.onImageIndexChanged?.call(_currentImageIndex);
    }
  }

  /// 現在の画像URLを取得
  String get _currentImageUrl {
    return widget.inpaintingResult.getImageUrlAt(_currentImageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '編集結果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 複数画像の場合は画像切り替えコントロールを表示
                if (widget.inpaintingResult.imageCount > 1) ...[
                  IconButton(
                    onPressed: _currentImageIndex > 0 ? _previousImage : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '前の画像',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${widget.inpaintingResult.imageCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _currentImageIndex <
                            widget.inpaintingResult.imageCount - 1
                        ? _nextImage
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '次の画像',
                  ),
                ],
                if (_isZoomed)
                  IconButton(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'ズームリセット',
                  ),
              ],
            ),
          ),

          // 画像表示エリア
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[100],
            child: _buildSingleImageView(),
          ),

          // 画像情報
          Container(
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
                      '画像詳細',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('プロンプト', widget.inpaintingResult.prompt),
                _buildInfoRow(
                  '作成日時',
                  _formatDateTime(widget.inpaintingResult.createdAt),
                ),
                _buildInfoRow('ID', widget.inpaintingResult.id),
                _buildInfoRow(
                  '状態',
                  _getStatusText(widget.inpaintingResult.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 単体画像表示
  Widget _buildSingleImageView() {
    return Stack(
      children: [
        // メイン画像表示
        GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                _currentImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.e('結果画像の読み込みエラー: $error, URL: $_currentImageUrl');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '画像の読み込みに失敗しました',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'URL: $_currentImageUrl',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // スワイプ機能（複数画像の場合のみ）
        if (widget.inpaintingResult.imageCount > 1)
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // 右から左へのスワイプ（前の画像）
                  _previousImage();
                } else if (details.primaryVelocity! < 0) {
                  // 左から右へのスワイプ（次の画像）
                  _nextImage();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
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

  /// ステータステキストを取得
  String _getStatusText(InpaintingStatus status) {
    return switch (status) {
      InpaintingStatus.pending => '待機中',
      InpaintingStatus.uploading => 'アップロード中',
      InpaintingStatus.processing => '処理中',
      InpaintingStatus.completed => '完了',
      InpaintingStatus.failed => '失敗',
    };
  }
}
