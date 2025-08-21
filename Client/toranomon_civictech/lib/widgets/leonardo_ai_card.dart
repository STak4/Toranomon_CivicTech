import 'package:flutter/material.dart';

/// Leonardo AI用の共通カードコンポーネント
///
/// 統一されたデザインとレイアウトを提供する再利用可能なカード
class LeonardoAiCard extends StatelessWidget {
  const LeonardoAiCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.elevation = 2,
    this.borderRadius = 12,
    this.backgroundColor,
    this.showBorder = false,
    this.borderColor,
  });

  /// カードの内容
  final Widget child;

  /// タイトル（オプション）
  final String? title;

  /// サブタイトル（オプション）
  final String? subtitle;

  /// アイコン（オプション）
  final IconData? icon;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// 内部パディング
  final EdgeInsetsGeometry padding;

  /// 外部マージン
  final EdgeInsetsGeometry margin;

  /// 影の高さ
  final double elevation;

  /// 角の丸み
  final double borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 境界線を表示するかどうか
  final bool showBorder;

  /// 境界線の色
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ヘッダー部分
        if (title != null || subtitle != null || icon != null)
          _buildHeader(context),

        // メインコンテンツ
        child,
      ],
    );

    return Container(
      margin: margin,
      child: Card(
        elevation: elevation,
        color: backgroundColor ?? colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: showBorder
              ? BorderSide(
                  color:
                      borderColor ?? colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                )
              : BorderSide.none,
        ),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(padding: padding, child: cardContent),
              )
            : Padding(padding: padding, child: cardContent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (subtitle != null) ...[
                    if (title != null) const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 機能カード用の特別なカードコンポーネント
class LeonardoAiFeatureCard extends StatelessWidget {
  const LeonardoAiFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.color,
    this.isEnabled = true,
  });

  /// 機能名
  final String title;

  /// 機能の説明
  final String description;

  /// アイコン
  final IconData icon;

  /// タップ時のコールバック
  final VoidCallback onTap;

  /// テーマカラー
  final Color? color;

  /// 有効/無効状態
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final featureColor = color ?? colorScheme.primary;

    return LeonardoAiCard(
      onTap: isEnabled ? onTap : null,
      elevation: isEnabled ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    featureColor.withValues(alpha: 0.1),
                    featureColor.withValues(alpha: 0.05),
                  ],
                )
              : null,
        ),
        child: Row(
          children: [
            // アイコン部分
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? featureColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isEnabled ? featureColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),

            // テキスト部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? featureColor : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isEnabled
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // 矢印アイコン
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? featureColor : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
