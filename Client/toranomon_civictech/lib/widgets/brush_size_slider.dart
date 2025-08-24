import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leonardo_ai_providers.dart';

/// ブラシサイズ調整スライダーウィジェット
class BrushSizeSlider extends ConsumerWidget {
  const BrushSizeSlider({super.key, this.minSize = 5.0, this.maxSize = 100.0});

  /// 最小ブラシサイズ
  final double minSize;

  /// 最大ブラシサイズ
  final double maxSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brushState = ref.watch(brushDrawingProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9 * 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1 * 255),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ブラシサイズ表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ブラシサイズ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${brushState.brushSize.round()}px',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // スライダー
          Row(
            children: [
              // 最小値表示
              Text(
                '${minSize.round()}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              // スライダー本体
              Expanded(
                child: Slider(
                  value: brushState.brushSize.clamp(minSize, maxSize),
                  min: minSize,
                  max: maxSize,
                  divisions: ((maxSize - minSize) / 5).round(),
                  activeColor: brushState.brushColor,
                  inactiveColor: brushState.brushColor.withValues(
                    alpha: 0.3 * 255,
                  ),
                  thumbColor: brushState.brushColor,
                  onChanged: (value) {
                    ref
                        .read(brushDrawingProvider.notifier)
                        .updateBrushSize(value);
                  },
                ),
              ),

              // 最大値表示
              Text(
                '${maxSize.round()}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          // ブラシプレビュー
          const SizedBox(height: 8),
          _BrushPreview(
            size: brushState.brushSize,
            color: brushState.brushColor.withValues(
              alpha: brushState.opacity * 255,
            ),
          ),
        ],
      ),
    );
  }
}

/// ブラシプレビューウィジェット
class _BrushPreview extends StatelessWidget {
  const _BrushPreview({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: Container(
        width: size.clamp(5.0, 40.0),
        height: size.clamp(5.0, 40.0),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}

/// ブラシコントロールパネルウィジェット
class BrushControlPanel extends ConsumerWidget {
  const BrushControlPanel({super.key, this.onClear});

  /// クリアボタンが押された時のコールバック
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brushState = ref.watch(brushDrawingProvider);
    final hasStrokes = brushState.strokes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95 * 255),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1 * 255),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // ブラシサイズスライダー
          const BrushSizeSlider(),

          const SizedBox(height: 16),

          // コントロールボタン
          Row(
            children: [
              // クリアボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasStrokes
                      ? () {
                          ref
                              .read(brushDrawingProvider.notifier)
                              .clearStrokes();
                          onClear?.call();
                        }
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('クリア'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasStrokes
                        ? Colors.red.shade400
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ストローク数表示
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${brushState.strokes.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
