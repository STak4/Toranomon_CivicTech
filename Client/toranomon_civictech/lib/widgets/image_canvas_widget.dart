import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leonardo_ai/brush_state.dart';
import '../providers/leonardo_ai_providers.dart';

import '../utils/resource_manager.dart';
import 'canvas_painter.dart';

/// ブラシ描画可能な画像キャンバスウィジェット
class ImageCanvasWidget extends ConsumerStatefulWidget {
  const ImageCanvasWidget({super.key, required this.image});

  /// 背景画像
  final File image;

  @override
  ConsumerState<ImageCanvasWidget> createState() => ImageCanvasWidgetState();
}

class ImageCanvasWidgetState extends ConsumerState<ImageCanvasWidget> {
  ui.Image? _backgroundImage;
  bool _isImageLoading = true;
  File? _optimizedImageFile;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  @override
  void didUpdateWidget(ImageCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.path != widget.image.path) {
      _loadBackgroundImage();
    }
  }

  /// 背景画像を読み込む
  Future<void> _loadBackgroundImage() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      // 元画像を直接使用（最適化処理をスキップ）
      _optimizedImageFile = widget.image;
      
      final bytes = await widget.image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (mounted) {
        // 画像をリソースマネージャーに登録
        ResourceManager.instance.registerImage(frame.image);
        
        setState(() {
          _backgroundImage = frame.image;
          _isImageLoading = false;
        });
      }
    } catch (e) {
      // 最適化に失敗した場合は元画像を使用
      try {
        final bytes = await widget.image.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        if (mounted) {
          // 画像をリソースマネージャーに登録
          ResourceManager.instance.registerImage(frame.image);
          
          setState(() {
            _backgroundImage = frame.image;
            _isImageLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isImageLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isImageLoading || _backgroundImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final brushState = ref.watch(brushDrawingProvider);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: CanvasPainter(
            backgroundImage: _backgroundImage!,
            strokes: brushState.strokes,
            brushSize: brushState.brushSize,
            brushColor: brushState.brushColor,
            showMask: true,
          ),
          size: Size.infinite,
          child: Container(),
        ),
      ),
    );
  }

  /// パン開始時の処理
  void _onPanStart(DragStartDetails details) {
    final brushState = ref.read(brushDrawingProvider);
    final newStroke = BrushStroke(
      points: [details.localPosition],
      brushSize: brushState.brushSize,
      color: brushState.brushColor,
      opacity: brushState.opacity,
    );

    ref.read(brushDrawingProvider.notifier).addStroke(newStroke);
  }

  /// パン更新時の処理
  void _onPanUpdate(DragUpdateDetails details) {
    ref
        .read(brushDrawingProvider.notifier)
        .updateCurrentStroke(details.localPosition);
  }

  /// パン終了時の処理
  void _onPanEnd(DragEndDetails details) {
    // マスク画像の生成は削除 - 生成ボタンが押された時のみ生成する
  }

  /// マスク画像を生成する（外部から呼び出し可能）
  Future<Uint8List?> generateMaskImage() async {
    if (_backgroundImage == null) return null;

    try {
      final canvasSize = Size(
        context.size?.width ?? 300,
        context.size?.height ?? 300,
      );
      final imageSize = Size(
        _backgroundImage!.width.toDouble(),
        _backgroundImage!.height.toDouble(),
      );

      final maskImage = await ref
          .read(brushDrawingProvider.notifier)
          .generateMaskImage(canvasSize, imageSize: imageSize);

      return maskImage;
    } catch (e) {
      // エラーハンドリング - ログ出力のみ
      debugPrint('マスク画像生成エラー: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // リソースマネージャーから画像を解除
    if (_backgroundImage != null) {
      ResourceManager.instance.unregisterImage(_backgroundImage!);
      _backgroundImage!.dispose();
    }
    
    // 最適化された画像ファイルを削除
    if (_optimizedImageFile != null) {
      try {
        ResourceManager.instance.unregisterTempFile(_optimizedImageFile!);
        _optimizedImageFile!.deleteSync();
      } catch (e) {
        // エラーは無視（一時ファイルなので）
      }
    }
    
    super.dispose();
  }
}
