import 'package:flutter/material.dart';

/// ローディングオーバーレイウィジェット
/// 
/// 画像生成・編集中に表示するローディング画面
/// 進行状況の表示、キャンセル機能、アニメーションを提供
class LoadingOverlayWidget extends StatefulWidget {
  const LoadingOverlayWidget({
    super.key,
    required this.isVisible,
    this.message = '処理中...',
    this.subMessage,
    this.onCancel,
    this.progress,
    this.showCancelButton = true,
  });

  /// オーバーレイの表示状態
  final bool isVisible;
  
  /// メインメッセージ
  final String message;
  
  /// サブメッセージ（詳細説明）
  final String? subMessage;
  
  /// キャンセルボタンのコールバック
  final VoidCallback? onCancel;
  
  /// 進行状況（0.0-1.0、nullの場合は不定）
  final double? progress;
  
  /// キャンセルボタンを表示するかどうか
  final bool showCancelButton;

  @override
  State<LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<LoadingOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isVisible) {
      _showOverlay();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    }
  }

  void _showOverlay() {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _hideOverlay() {
    _fadeController.reverse();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // アニメーション付きアイコン
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // メインメッセージ
                      Text(
                        widget.message,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // サブメッセージ
                      if (widget.subMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // 進行状況インジケーター
                      if (widget.progress != null)
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: widget.progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(widget.progress! * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        )
                      else
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      
                      // キャンセルボタン
                      if (widget.showCancelButton && widget.onCancel != null) ...[
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: widget.onCancel,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('キャンセル'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ローディングオーバーレイを表示するためのヘルパー関数
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// オーバーレイを表示
  static void show(
    BuildContext context, {
    String message = '処理中...',
    String? subMessage,
    VoidCallback? onCancel,
    double? progress,
    bool showCancelButton = true,
  }) {
    hide(); // 既存のオーバーレイがあれば削除
    
    _overlayEntry = OverlayEntry(
      builder: (context) => LoadingOverlayWidget(
        isVisible: true,
        message: message,
        subMessage: subMessage,
        onCancel: onCancel,
        progress: progress,
        showCancelButton: showCancelButton,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// オーバーレイを非表示
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// オーバーレイが表示中かどうか
  static bool get isVisible => _overlayEntry != null;
}