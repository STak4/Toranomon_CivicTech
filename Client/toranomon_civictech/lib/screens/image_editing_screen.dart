import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/leonardo_ai_providers.dart';
import '../widgets/image_canvas_widget.dart';
import '../widgets/brush_size_slider.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/loading_overlay_widget.dart';
import '../utils/app_logger.dart';
import '../utils/permission_utils.dart';
import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../models/leonardo_ai/inpainting_result.dart';

/// 画像編集画面
///
/// ギャラリー選択、ブラシ描画、プロンプト入力、編集実行の統合画面
class ImageEditingScreen extends ConsumerStatefulWidget {
  const ImageEditingScreen({super.key});

  @override
  ConsumerState<ImageEditingScreen> createState() => _ImageEditingScreenState();
}

class _ImageEditingScreenState extends ConsumerState<ImageEditingScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<ImageCanvasWidgetState> _canvasKey =
      GlobalKey<ImageCanvasWidgetState>();
  String _prompt = '';
  Uint8List? _currentMaskImage;
  bool _showBrushControls = false;
  bool _isExecuting = false; // 編集実行中の状態を管理
  bool _navigated = false; // 二重遷移ガード

  @override
  void initState() {
    super.initState();

    // ref.listenManualを使用してinitStateでリスナー登録
    ref.listenManual<AsyncValue<InpaintingResult?>>(canvasInpaintingProvider, (
      previous,
      next,
    ) {
      AppLogger.i(
        '【遷移監視】_isExecuting=$_isExecuting, next: '
        'hasValue=${next.hasValue}, isLoading=${next.isLoading}, hasError=${next.hasError}',
      );

      if (!_isExecuting) return;

      if (next.hasValue && !next.isLoading && next.value != null) {
        _handleNavigationToResult(next.value!);
      } else if (next.hasError) {
        setState(() => _isExecuting = false);
        _handleExecutionError(next.error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = ref.watch(selectedImageProvider);
    final brushState = ref.watch(brushDrawingProvider);
    final canvasInpaintingState = ref.watch(canvasInpaintingProvider);
    final canvasInpaintingProgress = ref.watch(
      canvasInpaintingProgressProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('画像編集'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (selectedImage != null)
            IconButton(
              onPressed: () => _clearAll(),
              icon: const Icon(Icons.refresh),
              tooltip: '全てクリア',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 画像表示エリア
              Expanded(
                flex: 3,
                child: _buildImageArea(selectedImage, brushState),
              ),

              // コントロールエリア
              Expanded(
                flex: 2,
                child: _buildControlArea(selectedImage, brushState),
              ),
            ],
          ),

          // ローディングオーバーレイ（進行状況付き）
          LoadingOverlayWidget(
            isVisible: _isExecuting,
            message: canvasInpaintingState.isLoading
                ? canvasInpaintingProgress?.message ?? '画像を編集中...'
                : 'マスク画像を生成中...',
            subMessage: _isExecuting && !canvasInpaintingState.isLoading
                ? '描画内容からマスク画像を作成しています...'
                : canvasInpaintingProgress?.subMessage ??
                      'Leonardo AIで画像を処理しています...',
            progress: canvasInpaintingProgress?.progress,
            onCancel: () => _showCancelConfirmation(),
          ),

          // ブラシコントロールパネル
          if (_showBrushControls && selectedImage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBrushControlPanel(brushState),
            ),
        ],
      ),
    );
  }

  /// 画像表示エリアを構築
  Widget _buildImageArea(File? selectedImage, dynamic brushState) {
    if (selectedImage == null) {
      return _buildImageSelectionArea();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1 * 255),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 画像キャンバス
            ImageCanvasWidget(key: _canvasKey, image: selectedImage),

            // ブラシコントロール切り替えボタン
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _showBrushControls = !_showBrushControls;
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.9 * 255),
                child: Icon(
                  _showBrushControls ? Icons.close : Icons.brush,
                  color: Colors.black87,
                ),
              ),
            ),

            // ストローク数表示
            if (brushState.strokes.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7 * 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '編集領域: ${brushState.strokes.length}箇所',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 画像選択エリアを構築
  Widget _buildImageSelectionArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _selectImageFromGallery,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'ギャラリーから画像を選択',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'タップして画像を選択してください',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// コントロールエリアを構築
  Widget _buildControlArea(File? selectedImage, dynamic brushState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // プロンプト入力
          Expanded(
            child: PromptInputWidget(
              onChanged: (value) {
                setState(() {
                  _prompt = value;
                });
              },
              hintText: '編集内容を入力してください（例：空を青空に変更、花を追加）',
              enabled: selectedImage != null,
            ),
          ),

          const SizedBox(height: 16),

          // アクションボタン
          Row(
            children: [
              // ギャラリー選択ボタン
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(selectedImage == null ? '画像を選択' : '画像を変更'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 編集実行ボタン
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _canExecuteEditing(selectedImage, brushState)
                      ? () async {
                          // ボタンを押した瞬間にダイアログを表示
                          setState(() {
                            _isExecuting = true;
                          });
                          AppLogger.i('【ボタン押下】編集実行ボタンが押され、即座にダイアログを表示');

                          // UI更新を確実に実行するために複数回待機
                          await Future.delayed(Duration.zero);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          // 実際にダイアログが表示されたかログで確認
                          AppLogger.i(
                            '【ボタン押下】setState完了、_isExecuting=$_isExecuting',
                          );

                          // 非同期で実際の処理を実行
                          await _executeEditing();
                        }
                      : null,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('編集実行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ギャラリーから画像を選択
  Future<void> _selectImageFromGallery() async {
    try {
      AppLogger.i('ギャラリーから画像選択を開始');

      // 権限チェック
      final hasPermission = await _checkGalleryPermission();
      if (!hasPermission) {
        return;
      }

      // 画像選択
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) {
        AppLogger.d('画像選択がキャンセルされました');
        return;
      }

      final imageFile = File(image.path);

      // 画像を選択状態に設定
      ref.read(selectedImageProvider.notifier).selectImage(imageFile);

      // ブラシ描画をクリア
      ref.read(brushDrawingProvider.notifier).clearStrokes();

      setState(() {
        _showBrushControls = false;
      });

      AppLogger.i('画像選択完了: ${image.path}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を選択しました。ブラシで編集領域を指定してください。'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('画像選択でエラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ギャラリー権限をチェック
  Future<bool> _checkGalleryPermission() async {
    try {
      final hasPermission =
          await PermissionUtils.requestPhotoLibraryPermission();

      if (!hasPermission) {
        final status = await Permission.photos.status;

        if (status.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ギャラリーアクセス権限が必要です'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.e('権限チェックでエラー: $e');
      return false;
    }
  }

  /// 権限設定ダイアログを表示
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限が必要です'),
        content: const Text(
          'ギャラリーから画像を選択するには、写真へのアクセス権限が必要です。\n設定画面で権限を許可してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionUtils.openAppSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  /// 編集実行が可能かチェック
  bool _canExecuteEditing(File? selectedImage, dynamic brushState) {
    return selectedImage != null &&
        brushState.strokes.isNotEmpty &&
        _prompt.trim().isNotEmpty;
  }

  /// 編集実行前の事前チェック
  Future<bool> _preExecutionCheck() async {
    final selectedImage = ref.read(selectedImageProvider);
    final brushState = ref.read(brushDrawingProvider);

    // 基本的な前提条件チェック
    if (selectedImage == null) {
      _showValidationError('画像を選択してください');
      return false;
    }

    if (brushState.strokes.isEmpty) {
      _showValidationError('ブラシで編集領域を指定してください');
      return false;
    }

    if (_prompt.trim().isEmpty) {
      _showValidationError('編集内容のプロンプトを入力してください');
      return false;
    }

    // ファイル存在チェック
    if (!selectedImage.existsSync()) {
      _showValidationError('選択された画像ファイルが見つかりません。画像を再選択してください');
      return false;
    }

    // プロンプト長チェック
    if (_prompt.trim().length > 1000) {
      _showValidationError('プロンプトが長すぎます。1000文字以下で入力してください');
      return false;
    }

    return true;
  }

  /// バリデーションエラーを表示
  void _showValidationError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// キャンセル確認ダイアログを表示
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('処理をキャンセル'),
          ],
        ),
        content: const Text('画像編集処理を中止しますか？\n\n処理を中止すると、現在の進行状況は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('続行'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(canvasInpaintingProvider.notifier).cancelInpainting();

              // 実行状態をリセット
              setState(() {
                _isExecuting = false;
              });

              // キャンセル完了メッセージ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('処理をキャンセルしました'),
                    ],
                  ),
                  backgroundColor: Colors.grey.shade600,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 編集を実行
  Future<void> _executeEditing() async {
    AppLogger.i('【編集実行】開始 - _isExecuting=$_isExecuting');

    // 事前チェック
    if (!await _preExecutionCheck()) {
      AppLogger.e('【編集実行】事前チェック失敗');
      setState(() {
        _isExecuting = false;
      });
      return;
    }

    final selectedImage = ref.read(selectedImageProvider)!;

    try {
      // プロバイダーの状態をリセット
      AppLogger.i('【編集実行】プロバイダーリセット');
      ref.read(canvasInpaintingProvider.notifier).clearResult();
      _navigated = false; // 二重遷移ガードをリセット

      // マスク画像を生成
      AppLogger.i('【編集実行】マスク画像生成開始');
      final maskImage = await _canvasKey.currentState?.generateMaskImage();
      if (maskImage == null) {
        throw Exception('マスク画像の生成に失敗しました。');
      }
      _currentMaskImage = maskImage;
      AppLogger.i('【編集実行】マスク画像生成完了: ${maskImage.length} bytes');

      // Canvas Inpainting実行（結果はlistenで監視）
      AppLogger.i('【編集実行】Canvas Inpainting実行開始');
      ref
          .read(canvasInpaintingProvider.notifier)
          .executeInpainting(
            originalImage: selectedImage,
            maskImage: _currentMaskImage!,
            prompt: _prompt.trim(),
          );
      AppLogger.i('【編集実行】Canvas Inpainting実行呼び出し完了');
    } catch (e) {
      AppLogger.e('【編集実行】エラー: $e');
      setState(() {
        _isExecuting = false;
      });
      _handleExecutionError(e);
    }
  }

  /// 実行エラーのハンドリング
  void _handleExecutionError(Object? error) {
    if (!mounted) return;

    // 実行状態をリセット
    setState(() {
      _isExecuting = false;
    });

    String errorMessage = 'エラーが発生しました';
    String? errorDetails;
    bool canRetry = true;

    if (error is LeonardoAiException) {
      errorMessage = error.message;

      // エラータイプに応じた詳細処理
      if (error is NetworkError) {
        errorDetails = 'ネットワーク接続を確認してください';
      } else if (error is AuthenticationError) {
        errorDetails = 'APIキーの設定を確認してください';
        canRetry = false;
      } else if (error is ValidationError) {
        errorDetails = '入力内容を確認してください';
        canRetry = false;
      } else if (error is RateLimitError) {
        errorDetails = 'しばらく待ってから再試行してください';
      } else if (error is Cancelled) {
        errorMessage = '処理がキャンセルされました';
        canRetry = false;
      } else if (error is Timeout) {
        errorDetails = '処理に時間がかかりすぎました';
      }
    } else if (error != null) {
      errorMessage = error.toString();
      errorDetails = '予期しないエラーが発生しました';
    }

    AppLogger.e(
      '編集実行エラー: $errorMessage${errorDetails != null ? ' - $errorDetails' : ''}',
    );

    // エラーダイアログを表示
    _showErrorDialog(errorMessage, errorDetails, canRetry);
  }

  /// エラーダイアログを表示
  void _showErrorDialog(String message, String? details, bool canRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('エラー'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (canRetry)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeEditing();
              },
              child: const Text('再試行'),
            ),
        ],
      ),
    );
  }

  /// ブラシストロークをクリア
  void _clearBrushStrokes() {
    ref.read(brushDrawingProvider.notifier).clearStrokes();
  }

  /// ブラシコントロールパネルを構築
  Widget _buildBrushControlPanel(dynamic brushState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1 * 255),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ブラシ設定',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showBrushControls = false;
                  });
                },
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ブラシサイズスライダー
          const BrushSizeSlider(),

          const SizedBox(height: 16),

          // アクションボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: brushState.strokes.isNotEmpty
                      ? () => ref
                            .read(brushDrawingProvider.notifier)
                            .undoLastStroke()
                      : null,
                  icon: const Icon(Icons.undo),
                  label: const Text('取り消し'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: brushState.strokes.isNotEmpty
                      ? _clearBrushStrokes
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('クリア'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 全てをクリア
  void _clearAll() {
    ref.read(selectedImageProvider.notifier).clearImage();
    ref.read(brushDrawingProvider.notifier).clearStrokes();
    ref.read(canvasInpaintingProvider.notifier).clearResult();

    setState(() {
      _prompt = '';
      _showBrushControls = false;
    });
  }

  /// 結果画面への遷移処理
  void _handleNavigationToResult(InpaintingResult result) {
    if (_navigated) return;
    if (result.resultImageUrl.isEmpty) {
      AppLogger.w('【遷移監視】画像URLが空');
      return;
    }

    _navigated = true;
    setState(() => _isExecuting = false);

    AppLogger.i('【遷移監視】結果OK、画面遷移へ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.goNamed(
          'leonardo-ai-result',
          extra: {'inpaintingResult': result},
        );
        AppLogger.i('【遷移監視】✅ 遷移成功');
      } catch (e) {
        AppLogger.e('【遷移監視】❌ 遷移エラー: $e');
        _navigated = false; // 失敗時は解除
      }
    });
  }
}
