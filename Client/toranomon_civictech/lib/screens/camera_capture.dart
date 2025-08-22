import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/camera_provider.dart';
import '../utils/app_logger.dart';

/// カメラ撮影画面
/// 独立した画面として実装され、カメラプレビュー、撮影、撮影後のプレビュー機能を提供
class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver {
  bool _isPreviewMode = false;
  XFile? _capturedImage;
  double _baseZoomLevel = CameraZoomConstants.minZoom; // ピンチジェスチャー用のベースズームレベル

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.i('CameraCaptureScreen - 画面を初期化しました');

    // 画面表示後にカメラを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // カメラを破棄
    ref.read(cameraNotifierProvider.notifier).disposeCamera();
    AppLogger.i('CameraCaptureScreen - 画面を破棄しました');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraState = ref.read(cameraNotifierProvider);
    final controller = cameraState.controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // アプリが非アクティブになった時はカメラを停止
      AppLogger.i('CameraCaptureScreen - アプリが非アクティブになりました。カメラを停止します。');
      ref.read(cameraNotifierProvider.notifier).disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // アプリが再開された時はカメラを再初期化
      AppLogger.i('CameraCaptureScreen - アプリが再開されました。カメラを再初期化します。');
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      AppLogger.i('CameraCaptureScreen - カメラ初期化を開始');
      await ref.read(cameraNotifierProvider.notifier).initializeCamera();
    } catch (e, stackTrace) {
      AppLogger.e('CameraCaptureScreen - カメラ初期化に失敗しました', e, stackTrace);
    }
  }

  Future<void> _capturePhoto() async {
    try {
      AppLogger.i('CameraCaptureScreen - 写真撮影を開始');

      final image = await ref
          .read(cameraNotifierProvider.notifier)
          .capturePhoto();

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isPreviewMode = true;
        });
        AppLogger.i('CameraCaptureScreen - 写真撮影が完了し、プレビューモードに移行しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e('CameraCaptureScreen - 写真撮影中にエラーが発生しました', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('写真撮影に失敗しました: ${e.toString()}')));
      }
    }
  }

  Future<void> _captureWithImagePicker() async {
    try {
      AppLogger.i('CameraCaptureScreen - ImagePickerでの撮影を開始');

      final image = await ref
          .read(cameraNotifierProvider.notifier)
          .takePictureWithImagePicker();

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isPreviewMode = true;
        });
        AppLogger.i(
          'CameraCaptureScreen - ImagePickerでの撮影が完了し、プレビューモードに移行しました',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'CameraCaptureScreen - ImagePickerでの撮影中にエラーが発生しました',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('写真撮影に失敗しました: ${e.toString()}')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      AppLogger.i('CameraCaptureScreen - ギャラリーからの選択を開始');

      final image = await ref
          .read(cameraNotifierProvider.notifier)
          .pickImageFromGallery();

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isPreviewMode = true;
        });
        AppLogger.i('CameraCaptureScreen - ギャラリーからの選択が完了し、プレビューモードに移行しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'CameraCaptureScreen - ギャラリーからの選択中にエラーが発生しました',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('画像選択に失敗しました: ${e.toString()}')));
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _isPreviewMode = false;
      _capturedImage = null;
    });
    AppLogger.i('CameraCaptureScreen - 再撮影モードに戻りました');
  }

  Future<void> _usePhoto() async {
    if (_capturedImage != null) {
      AppLogger.i(
        'CameraCaptureScreen - 撮影した写真をギャラリーに保存します: ${_capturedImage!.path}',
      );

      try {
        // ストレージ権限を確認（Android 13以降はREAD_MEDIA_IMAGES、それ以前はstorage）
        bool hasPermission = false;
        if (Platform.isAndroid) {
          // Android 13以降（API 33以降）ではREAD_MEDIA_IMAGESを使用
          if (await _isAndroid13OrHigher()) {
            final photosStatus = await Permission.photos.status;
            if (photosStatus.isGranted) {
              hasPermission = true;
            } else {
              final result = await Permission.photos.request();
              hasPermission = result.isGranted;
            }
          } else {
            // Android 12以前ではstorage権限を使用
            final storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) {
              hasPermission = true;
            } else {
              final result = await Permission.storage.request();
              hasPermission = result.isGranted;
            }
          }
        } else {
          // iOSではphotos権限を使用
          final photosStatus = await Permission.photos.status;
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else {
            final result = await Permission.photos.request();
            hasPermission = result.isGranted;
          }
        }

        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('写真の保存にはギャラリーへのアクセス権限が必要です'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // 写真をギャラリーに保存
        final result = await GallerySaver.saveImage(
          _capturedImage!.path,
          albumName: 'Toranomon CivicTech',
        );

        if (result == true) {
          AppLogger.i('CameraCaptureScreen - 写真をギャラリーに保存しました');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('写真をギャラリーに保存しました'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('保存に失敗しました');
        }

        // ホーム画面に戻る
        if (mounted) {
          context.go('/');
        }
      } catch (e, stackTrace) {
        AppLogger.e('CameraCaptureScreen - 写真の保存中にエラーが発生しました', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('写真の保存に失敗しました: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCameraSwitchTooltip(CameraState cameraState) {
    final controller = cameraState.controller;
    if (controller == null) return 'カメラを切り替え';

    final currentDirection = controller.description.lensDirection;
    if (currentDirection == CameraLensDirection.back) {
      return 'インカメラに切り替え';
    } else if (currentDirection == CameraLensDirection.front) {
      return '外カメラに切り替え';
    } else {
      return 'カメラを切り替え';
    }
  }

  /// ズームコントロールウィジェットを構築
  Widget _buildZoomControls(CameraState cameraState) {
    return Positioned(
      right: 16,
      top: 100, // カメラ切り替えボタンの下に配置
      child: Column(
        children: [
          // ズームインボタン
          Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: cameraState.isLoading
                  ? null
                  : () async {
                      await ref.read(cameraNotifierProvider.notifier).zoomIn();
                    },
              tooltip: 'ズームイン',
            ),
          ),
          const SizedBox(height: 8),
          // 現在のズームレベル表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${cameraState.zoomLevel.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ズームアウトボタン
          Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: cameraState.isLoading
                  ? null
                  : () async {
                      await ref.read(cameraNotifierProvider.notifier).zoomOut();
                    },
              tooltip: 'ズームアウト',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    try {
      AppLogger.i('CameraCaptureScreen - カメラ切り替えを開始');

      // 切り替え中のフィードバックを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カメラを切り替えています...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await ref.read(cameraNotifierProvider.notifier).switchCamera();

      // 切り替え完了のフィードバックを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カメラの切り替えが完了しました'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('CameraCaptureScreen - カメラ切り替え中にエラーが発生しました', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラの切り替えに失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('カメラ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            AppLogger.i('CameraCaptureScreen - ユーザーがカメラ画面を閉じました');
            context.pop();
          },
        ),
      ),
      body: _isPreviewMode
          ? _buildPreviewMode()
          : _buildCameraMode(cameraState),
    );
  }

  Widget _buildCameraMode(CameraState cameraState) {
    if (cameraState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('カメラを初期化しています...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (cameraState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              cameraState.error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('再試行'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _captureWithImagePicker,
              child: const Text(
                'カメラアプリで撮影',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('カメラが利用できません', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // カメラプレビュー（ピンチジェスチャー対応）
        Positioned.fill(
          child: GestureDetector(
            onScaleStart: (details) {
              // ピンチジェスチャーの開始時のズームレベルを保存
              _baseZoomLevel = cameraState.zoomLevel;
            },
            onScaleUpdate: (details) async {
              // ピンチジェスチャーによるズーム調整
              if (details.scale != 1.0) {
                final newZoomLevel = (_baseZoomLevel * details.scale).clamp(
                  CameraZoomConstants.minZoom,
                  CameraZoomConstants.maxZoom,
                );
                await ref
                    .read(cameraNotifierProvider.notifier)
                    .setZoomLevel(newZoomLevel);
              }
            },
            child: CameraPreview(controller),
          ),
        ),

        // 上部のコントロール
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // カメラ切り替えボタン
              if (cameraState.availableCameras.length > 1)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                    ),
                    onPressed: cameraState.isLoading ? null : _switchCamera,
                    tooltip: _getCameraSwitchTooltip(cameraState),
                  ),
                ),
            ],
          ),
        ),

        // ズームコントロール
        _buildZoomControls(cameraState),

        // 下部のコントロール
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ギャラリーボタン
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    onPressed: _pickFromGallery,
                    iconSize: 32,
                  ),
                ),

                // シャッターボタン
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // 右側のスペース（バランスを取るため）
                const SizedBox(width: 56),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewMode() {
    if (_capturedImage == null) {
      return const Center(
        child: Text('画像が見つかりません', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // 撮影した画像のプレビュー
        Positioned.fill(
          child: Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
        ),

        // 下部のコントロール
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 再撮影ボタン
                ElevatedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再撮影'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

                // 使用するボタン
                ElevatedButton.icon(
                  onPressed: _usePhoto,
                  icon: const Icon(Icons.check),
                  label: const Text('使用する'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Android 13以降（API 33以降）かどうかを判定
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // Android SDKバージョンを取得
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 = API 33
    } catch (e) {
      AppLogger.e('Android SDKバージョンの取得に失敗: $e');
      return false;
    }
  }
}
