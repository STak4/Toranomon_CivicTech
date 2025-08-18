import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/camera_repository.dart';
import '../utils/app_logger.dart';

part 'camera_provider.g.dart';

/// カメラズームの定数
class CameraZoomConstants {
  static const double minZoom = 1.0; // iOSカメラプラグインの制限に合わせて1.0に変更
  static const double maxZoom = 25.0;
  static const double zoomStep = 0.5;
}

/// カメラの状態を表すクラス
class CameraState {
  final bool isLoading;
  final CameraController? controller;
  final List<CameraDescription> availableCameras;
  final String? error;
  final XFile? capturedImage;
  final double zoomLevel;

  const CameraState({
    this.isLoading = false,
    this.controller,
    this.availableCameras = const [],
    this.error,
    this.capturedImage,
    this.zoomLevel = CameraZoomConstants.minZoom,
  });

  CameraState copyWith({
    bool? isLoading,
    CameraController? controller,
    List<CameraDescription>? availableCameras,
    String? error,
    XFile? capturedImage,
    double? zoomLevel,
  }) {
    return CameraState(
      isLoading: isLoading ?? this.isLoading,
      controller: controller ?? this.controller,
      availableCameras: availableCameras ?? this.availableCameras,
      error: error,
      capturedImage: capturedImage ?? this.capturedImage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

/// カメラリポジトリのプロバイダー
@riverpod
CameraRepository cameraRepository(Ref ref) {
  return CameraRepositoryImpl();
}

/// カメラ状態管理のプロバイダー
@riverpod
class CameraNotifier extends _$CameraNotifier {
  @override
  CameraState build() {
    return const CameraState();
  }

  /// カメラを初期化する
  Future<void> initializeCamera([CameraDescription? camera]) async {
    try {
      AppLogger.i('CameraProvider - カメラ初期化を開始');
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(cameraRepositoryProvider);

      // 利用可能なカメラを取得
      final cameras = await repository.getAvailableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'カメラが見つかりません');
        return;
      }

      // カメラコントローラーを初期化
      final controller = await repository.initializeCamera(camera);
      if (controller == null) {
        state = state.copyWith(isLoading: false, error: 'カメラの初期化に失敗しました');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        controller: controller,
        availableCameras: cameras,
        error: null,
        zoomLevel: CameraZoomConstants.minZoom,
      );

      AppLogger.i('CameraProvider - カメラ初期化が完了しました');
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - カメラ初期化中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'カメラの初期化に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 写真を撮影する
  Future<XFile?> capturePhoto() async {
    try {
      AppLogger.i('CameraProvider - 写真撮影を開始');

      final controller = state.controller;
      if (controller == null || !controller.value.isInitialized) {
        AppLogger.w('CameraProvider - カメラが初期化されていません');
        state = state.copyWith(error: 'カメラが初期化されていません');
        return null;
      }

      state = state.copyWith(isLoading: true, error: null);

      // 写真を撮影
      final image = await controller.takePicture();

      state = state.copyWith(
        isLoading: false,
        capturedImage: image,
        error: null,
      );

      AppLogger.i('CameraProvider - 写真撮影が完了しました: ${image.path}');
      return image;
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - 写真撮影中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: '写真撮影に失敗しました: ${e.toString()}',
      );
      return null;
    }
  }

  /// image_pickerを使用して写真を撮影する（簡単な方法）
  Future<XFile?> takePictureWithImagePicker() async {
    try {
      AppLogger.i('CameraProvider - ImagePickerでの写真撮影を開始');
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(cameraRepositoryProvider);
      final image = await repository.takePicture();

      state = state.copyWith(
        isLoading: false,
        capturedImage: image,
        error: null,
      );

      if (image != null) {
        AppLogger.i('CameraProvider - ImagePickerでの写真撮影が完了しました');
      } else {
        AppLogger.i('CameraProvider - 写真撮影がキャンセルされました');
      }

      return image;
    } catch (e, stackTrace) {
      AppLogger.e(
        'CameraProvider - ImagePickerでの写真撮影中にエラーが発生しました',
        e,
        stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: '写真撮影に失敗しました: ${e.toString()}',
      );
      return null;
    }
  }

  /// ギャラリーから画像を選択する
  Future<XFile?> pickImageFromGallery() async {
    try {
      AppLogger.i('CameraProvider - ギャラリーからの画像選択を開始');
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(cameraRepositoryProvider);
      final image = await repository.pickImageFromGallery();

      state = state.copyWith(
        isLoading: false,
        capturedImage: image,
        error: null,
      );

      if (image != null) {
        AppLogger.i('CameraProvider - ギャラリーからの画像選択が完了しました');
      } else {
        AppLogger.i('CameraProvider - 画像選択がキャンセルされました');
      }

      return image;
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - ギャラリーからの画像選択中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'ギャラリーからの画像選択に失敗しました: ${e.toString()}',
      );
      return null;
    }
  }

  /// カメラを切り替える
  Future<void> switchCamera() async {
    try {
      AppLogger.i('CameraProvider - カメラ切り替えを開始');

      final cameras = state.availableCameras;
      final currentController = state.controller;

      if (cameras.length < 2) {
        AppLogger.w('CameraProvider - 切り替え可能なカメラがありません');
        state = state.copyWith(error: '切り替え可能なカメラがありません');
        return;
      }

      if (currentController == null) {
        AppLogger.w('CameraProvider - 現在のカメラが初期化されていません');
        state = state.copyWith(error: 'カメラが初期化されていません');
        return;
      }

      // 現在のカメラを特定
      final currentCamera = cameras.firstWhere(
        (camera) => camera.name == currentController.description.name,
        orElse: () => cameras.first,
      );

      // 次のカメラを選択
      final currentIndex = cameras.indexOf(currentCamera);
      final nextIndex = (currentIndex + 1) % cameras.length;
      final nextCamera = cameras[nextIndex];

      AppLogger.i(
        'CameraProvider - カメラを切り替えます: ${currentCamera.name} -> ${nextCamera.name}',
      );

      // 現在のカメラを破棄
      final repository = ref.read(cameraRepositoryProvider);
      await repository.disposeCamera(currentController);

      // 新しいカメラを初期化
      await initializeCamera(nextCamera);
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - カメラ切り替え中にエラーが発生しました', e, stackTrace);
      state = state.copyWith(error: 'カメラの切り替えに失敗しました: ${e.toString()}');
    }
  }

  /// カメラを破棄する
  Future<void> disposeCamera() async {
    try {
      AppLogger.i('CameraProvider - カメラ破棄を開始');

      final controller = state.controller;
      if (controller != null) {
        final repository = ref.read(cameraRepositoryProvider);
        await repository.disposeCamera(controller);
      }

      state = const CameraState();
      AppLogger.i('CameraProvider - カメラ破棄が完了しました');
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - カメラ破棄中にエラーが発生しました', e, stackTrace);
    }
  }

  /// エラーをクリアする
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 撮影した画像をクリアする
  void clearCapturedImage() {
    state = state.copyWith(capturedImage: null);
  }

  /// ズームレベルを設定する
  Future<void> setZoomLevel(double zoomLevel) async {
    try {
      AppLogger.i('CameraProvider - ズームレベルを設定: $zoomLevel');

      final controller = state.controller;
      if (controller == null || !controller.value.isInitialized) {
        AppLogger.w('CameraProvider - カメラが初期化されていません');
        return;
      }

      // ズームレベルの範囲を制限
      final clampedZoomLevel = zoomLevel.clamp(
        CameraZoomConstants.minZoom,
        CameraZoomConstants.maxZoom,
      );

      // カメラコントローラーにズームを設定
      await controller.setZoomLevel(clampedZoomLevel);

      // 状態を更新
      state = state.copyWith(zoomLevel: clampedZoomLevel);

      AppLogger.i('CameraProvider - ズームレベルが設定されました: $clampedZoomLevel');
    } catch (e, stackTrace) {
      AppLogger.e('CameraProvider - ズームレベル設定中にエラーが発生しました', e, stackTrace);
    }
  }

  /// ズームインする
  Future<void> zoomIn() async {
    final currentZoom = state.zoomLevel;
    final newZoom = (currentZoom + CameraZoomConstants.zoomStep).clamp(
      CameraZoomConstants.minZoom,
      CameraZoomConstants.maxZoom,
    );
    await setZoomLevel(newZoom);
  }

  /// ズームアウトする
  Future<void> zoomOut() async {
    final currentZoom = state.zoomLevel;
    final newZoom = (currentZoom - CameraZoomConstants.zoomStep).clamp(
      CameraZoomConstants.minZoom,
      CameraZoomConstants.maxZoom,
    );
    await setZoomLevel(newZoom);
  }
}
