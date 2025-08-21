import 'package:flutter/material.dart';

/// Leonardo AI用の共通ボタンコンポーネント
///
/// 統一されたデザインとアニメーションを提供する再利用可能なボタン
class LeonardoAiButton extends StatefulWidget {
  const LeonardoAiButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = LeonardoAiButtonVariant.primary,
    this.size = LeonardoAiButtonSize.medium,
  });

  /// ボタン押下時のコールバック
  final VoidCallback? onPressed;

  /// ボタンテキスト
  final String text;

  /// アイコン（オプション）
  final IconData? icon;

  /// ローディング状態
  final bool isLoading;

  /// 有効/無効状態
  final bool isEnabled;

  /// ボタンの種類
  final LeonardoAiButtonVariant variant;

  /// ボタンのサイズ
  final LeonardoAiButtonSize size;

  @override
  State<LeonardoAiButton> createState() => _LeonardoAiButtonState();
}

class _LeonardoAiButtonState extends State<LeonardoAiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.isEnabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(context, isInteractive),
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isInteractive) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // サイズ設定
    final buttonHeight = switch (widget.size) {
      LeonardoAiButtonSize.small => 40.0,
      LeonardoAiButtonSize.medium => 48.0,
      LeonardoAiButtonSize.large => 56.0,
    };

    final fontSize = switch (widget.size) {
      LeonardoAiButtonSize.small => 14.0,
      LeonardoAiButtonSize.medium => 16.0,
      LeonardoAiButtonSize.large => 18.0,
    };

    final iconSize = switch (widget.size) {
      LeonardoAiButtonSize.small => 18.0,
      LeonardoAiButtonSize.medium => 20.0,
      LeonardoAiButtonSize.large => 24.0,
    };

    // カラー設定
    final (
      backgroundColor,
      foregroundColor,
      borderColor,
    ) = switch (widget.variant) {
      LeonardoAiButtonVariant.primary => (
        isInteractive ? colorScheme.primary : Colors.grey[400]!,
        isInteractive ? colorScheme.onPrimary : Colors.grey[600]!,
        null,
      ),
      LeonardoAiButtonVariant.secondary => (
        isInteractive ? colorScheme.secondary : Colors.grey[200]!,
        isInteractive ? colorScheme.onSecondary : Colors.grey[600]!,
        null,
      ),
      LeonardoAiButtonVariant.outline => (
        Colors.transparent,
        isInteractive ? colorScheme.primary : Colors.grey[600]!,
        isInteractive ? colorScheme.primary : Colors.grey[400]!,
      ),
      LeonardoAiButtonVariant.text => (
        Colors.transparent,
        isInteractive ? colorScheme.primary : Colors.grey[600]!,
        null,
      ),
    };

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow:
            widget.variant == LeonardoAiButtonVariant.primary && isInteractive
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  )
                else if (widget.icon != null)
                  Icon(widget.icon, size: iconSize, color: foregroundColor),
                if ((widget.icon != null || widget.isLoading) &&
                    widget.text.isNotEmpty)
                  const SizedBox(width: 8),
                if (widget.text.isNotEmpty)
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ボタンの種類
enum LeonardoAiButtonVariant { primary, secondary, outline, text }

/// ボタンのサイズ
enum LeonardoAiButtonSize { small, medium, large }
