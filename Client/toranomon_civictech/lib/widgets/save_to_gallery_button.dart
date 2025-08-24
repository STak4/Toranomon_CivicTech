import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leonardo_ai_providers.dart';
import '../providers/permission_provider.dart';
import '../utils/app_logger.dart';

/// ギャラリー保存ボタンウィジェット
///
/// 画像をデバイスのギャラリーに保存するためのボタン
/// 権限管理、ローディング状態、エラーハンドリングを含む
class SaveToGalleryButton extends ConsumerStatefulWidget {
  const SaveToGalleryButton({
    super.key,
    required this.imageUrl,
    this.fileName,
    this.onSaveSuccess,
    this.onSaveError,
    this.style,
    this.icon,
    this.label,
    this.showProgress = true,
    this.showPermissionDialog = true,
  });

  /// 保存する画像のURL
  final String imageUrl;
  
  /// 保存時のファイル名（オプション）
  final String? fileName;
  
  /// 保存成功時のコールバック
  final VoidCallback? onSaveSuccess;
  
  /// 保存エラー時のコールバック
  final void Function(String error)? onSaveError;
  
  /// ボタンのスタイル
  final ButtonStyle? style;
  
  /// ボタンのアイコン
  final Widget? icon;
  
  /// ボタンのラベル
  final String? label;
  
  /// 進行状況を表示するかどうか
  final bool showProgress;
  
  /// 権限ダイアログを表示するかどうか
  final bool showPermissionDialog;

  @override
  ConsumerState<SaveToGalleryButton> createState() => _SaveToGalleryButtonState();
}

class _SaveToGalleryButtonState extends ConsumerState<SaveToGalleryButton> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    // 権限状態を初期化時にチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryPermissionProvider.notifier).refresh();
    });
  }

  /// ギャラリーに保存を実行
  Future<void> _saveToGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      AppLogger.i('ギャラリー保存ボタンがタップされました: ${widget.imageUrl}');

      // URLの検証
      if (widget.imageUrl.trim().isEmpty) {
        _showError('保存する画像が指定されていません');
        return;
      }

      // 権限チェック
      final permissionInfo = ref.read(galleryPermissionProvider).valueOrNull;
      
      if (permissionInfo == null) {
        // 権限状態が不明な場合は再チェック
        AppLogger.d('権限状態が不明なため再チェック');
        await ref.read(galleryPermissionProvider.notifier).refresh();
        
        final updatedPermissionInfo = ref.read(galleryPermissionProvider).valueOrNull;
        if (updatedPermissionInfo == null) {
          _showError('権限の確認に失敗しました');
          return;
        }
      }

      final currentPermissionInfo = ref.read(galleryPermissionProvider).valueOrNull!;
      
      // 権限が拒否されている場合の処理
      if (!currentPermissionInfo.canSave) {
        if (widget.showPermissionDialog) {
          await _showPermissionDialog(currentPermissionInfo);
        } else {
          _showError(currentPermissionInfo.guidanceMessage);
        }
        return;
      }

      // ギャラリーに保存を実行
      AppLogger.i('ギャラリー保存を開始');
      await ref.read(gallerySaverProvider.notifier).saveToGallery(
        widget.imageUrl,
        fileName: widget.fileName,
      );

      // 保存成功のコールバックを呼び出し
      widget.onSaveSuccess?.call();
      
    } catch (e) {
      AppLogger.e('ギャラリー保存でエラー: $e');
      final errorMessage = 'ギャラリーへの保存に失敗しました: $e';
      _showError(errorMessage);
      widget.onSaveError?.call(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 権限ダイアログを表示
  Future<void> _showPermissionDialog(PermissionInfo permissionInfo) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionDialog(
        permissionInfo: permissionInfo,
      ),
    );

    if (result == true) {
      // 権限が許可された場合は再度保存を試行
      await _saveToGallery();
    }
  }

  /// エラーメッセージを表示
  void _showError(String message) {
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
  void _showSuccess(String message) {
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
    final gallerySaveState = ref.watch(gallerySaverProvider);
    final gallerySaveProgress = ref.watch(gallerySaveProgressProvider);
    
    // 権限状態を監視
    final permissionState = ref.watch(galleryPermissionProvider);

    // 保存結果を監視
    ref.listen<AsyncValue<bool>>(gallerySaverProvider, (previous, next) {
      next.when(
        data: (success) {
          if (success && previous?.value != success) {
            _showSuccess('ギャラリーに保存しました');
            ref.read(gallerySaverProvider.notifier).resetSaveState();
          }
        },
        loading: () {
          // ローディング状態の処理はUIで行う
        },
        error: (error, stackTrace) {
          final errorMessage = 'ギャラリーへの保存に失敗しました';
          _showError(errorMessage);
          widget.onSaveError?.call(errorMessage);
          AppLogger.e('ギャラリー保存エラー: $error', error, stackTrace);
        },
      );
    });

    // ボタンの有効/無効状態を判定
    final isLoading = gallerySaveState.isLoading || _isProcessing;
    final isEnabled = !isLoading && widget.imageUrl.trim().isNotEmpty;

    // 進行状況メッセージを取得
    String progressMessage = widget.label ?? 'ギャラリーに保存';
    if (isLoading && gallerySaveProgress != null) {
      progressMessage = gallerySaveProgress.message;
    } else if (isLoading) {
      progressMessage = '保存中...';
    }

    // アイコンを決定
    Widget buttonIcon;
    if (isLoading) {
      buttonIcon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      buttonIcon = widget.icon ?? const Icon(Icons.download);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // メインの保存ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isEnabled ? _saveToGallery : null,
            icon: buttonIcon,
            label: Text(progressMessage),
            style: widget.style ?? ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // 進行状況バー（オプション）
        if (widget.showProgress && isLoading && gallerySaveProgress?.progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: gallerySaveProgress!.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
                if (gallerySaveProgress.subMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      gallerySaveProgress.subMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        // 権限エラー表示
        if (permissionState.hasValue && !permissionState.value!.canSave)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, 
                       color: Colors.orange[700], 
                       size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '権限が必要です',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showPermissionDialog(permissionState.value!),
                    child: const Text('設定', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 権限要求ダイアログ
class _PermissionDialog extends ConsumerWidget {
  const _PermissionDialog({
    required this.permissionInfo,
  });

  final PermissionInfo permissionInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.photo_library, color: Colors.blue),
          SizedBox(width: 8),
          Text('ギャラリーアクセス権限'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '画像をギャラリーに保存するために権限が必要です。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              permissionInfo.guidanceMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        if (permissionInfo.needsSettings)
          ElevatedButton.icon(
            onPressed: () async {
              final opened = await ref.read(galleryPermissionProvider.notifier).openSettings();
              if (context.mounted) {
                Navigator.of(context).pop(opened);
              }
            },
            icon: const Icon(Icons.settings),
            label: const Text('設定を開く'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final granted = await ref.read(galleryPermissionProvider.notifier).requestPermission();
              if (context.mounted) {
                Navigator.of(context).pop(granted);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('権限を許可'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

/// シンプルなギャラリー保存ボタン
///
/// 最小限の機能を持つ保存ボタン
class SimpleGallerySaveButton extends ConsumerWidget {
  const SimpleGallerySaveButton({
    super.key,
    required this.imageUrl,
    this.fileName,
    this.onSaveSuccess,
    this.onSaveError,
  });

  final String imageUrl;
  final String? fileName;
  final VoidCallback? onSaveSuccess;
  final void Function(String error)? onSaveError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallerySaveState = ref.watch(gallerySaverProvider);

    return IconButton(
      onPressed: gallerySaveState.isLoading 
          ? null 
          : () async {
              try {
                await ref.read(gallerySaverProvider.notifier).saveToGallery(
                  imageUrl,
                  fileName: fileName,
                );
                onSaveSuccess?.call();
              } catch (e) {
                final errorMessage = 'ギャラリーへの保存に失敗しました';
                onSaveError?.call(errorMessage);
              }
            },
      icon: gallerySaveState.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      tooltip: 'ギャラリーに保存',
    );
  }
}

/// フローティングアクションボタン形式のギャラリー保存ボタン
class GallerySaveFab extends ConsumerWidget {
  const GallerySaveFab({
    super.key,
    required this.imageUrl,
    this.fileName,
    this.onSaveSuccess,
    this.onSaveError,
  });

  final String imageUrl;
  final String? fileName;
  final VoidCallback? onSaveSuccess;
  final void Function(String error)? onSaveError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallerySaveState = ref.watch(gallerySaverProvider);

    return FloatingActionButton(
      onPressed: gallerySaveState.isLoading 
          ? null 
          : () async {
              try {
                await ref.read(gallerySaverProvider.notifier).saveToGallery(
                  imageUrl,
                  fileName: fileName,
                );
                onSaveSuccess?.call();
              } catch (e) {
                final errorMessage = 'ギャラリーへの保存に失敗しました';
                onSaveError?.call(errorMessage);
              }
            },
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      tooltip: 'ギャラリーに保存',
      child: gallerySaveState.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.download),
    );
  }
}