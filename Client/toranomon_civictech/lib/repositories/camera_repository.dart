import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// カメラ機能のリポジトリインターフェース
abstract class CameraRepository {
  /// カメラ権限を要求する
  Future<bool> requestCameraPermission();

  /// 写真を撮影する
  Future<XFile?> takePicture();

  /// ギャラリーから画像を選択する
  Future<XFile?> pickImageFromGallery();

  /// 利用可能なカメラを取得する
  Future<List<CameraDescription>> getAvailableCameras();

  /// カメラを初期化する
  Future<CameraController?> initializeCamera([CameraDescription? camera]);

  /// カメラコントローラーを破棄する
  Future<void> disposeCamera(CameraController controller);
}

/// カメラリポジトリの実装
class CameraRepositoryImpl implements CameraRepository {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<bool> requestCameraPermission() async {
    try {
      AppLogger.i('カメラ権限の要求を開始');

      final status = await Permission.camera.request();

      switch (status) {
        case PermissionStatus.granted:
          AppLogger.i('カメラ権限が許可されました');
          return true;
        case PermissionStatus.denied:
          AppLogger.w('カメラ権限が拒否されました');
          return false;
        case PermissionStatus.permanentlyDenied:
          AppLogger.w('カメラ権限が永続的に拒否されました');
          return false;
        case PermissionStatus.restricted:
          AppLogger.w('カメラ権限が制限されています');
          return false;
        case PermissionStatus.limited:
          AppLogger.w('カメラ権限が制限付きで許可されました');
          return true;
        case PermissionStatus.provisional:
          AppLogger.w('カメラ権限が仮許可されました');
          return true;
      }
    } catch (e, stackTrace) {
      AppLogger.e('カメラ権限の要求中にエラーが発生しました', e, stackTrace);
      return false;
    }
  }

  @override
  Future<XFile?> takePicture() async {
    try {
      AppLogger.i('カメラでの写真撮影を開始');

      // カメラ権限を確認
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        AppLogger.w('カメラ権限がないため撮影をキャンセルしました');
        return null;
      }

      // image_pickerを使用してカメラから撮影
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // 品質を85%に設定（ファイルサイズとのバランス）
        maxWidth: 1920, // 最大幅を制限
        maxHeight: 1920, // 最大高さを制限
      );

      if (image != null) {
        AppLogger.i('写真撮影が完了しました: ${image.path}');

        // ファイルサイズをログ出力
        final file = File(image.path);
        final fileSize = await file.length();
        AppLogger.i(
          '撮影した画像のファイルサイズ: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      } else {
        AppLogger.i('写真撮影がキャンセルされました');
      }

      return image;
    } catch (e, stackTrace) {
      AppLogger.e('写真撮影中にエラーが発生しました', e, stackTrace);
      return null;
    }
  }

  @override
  Future<XFile?> pickImageFromGallery() async {
    try {
      AppLogger.i('ギャラリーからの画像選択を開始');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 品質を85%に設定
        maxWidth: 1920, // 最大幅を制限
        maxHeight: 1920, // 最大高さを制限
        requestFullMetadata: true, // iOS 14以降でメタデータを要求
      );

      if (image != null) {
        AppLogger.i('ギャラリーから画像を選択しました: ${image.path}');

        // ファイルサイズをログ出力
        final file = File(image.path);
        final fileSize = await file.length();
        AppLogger.i(
          '選択した画像のファイルサイズ: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      } else {
        AppLogger.i('画像選択がキャンセルされました');
      }

      return image;
    } catch (e, stackTrace) {
      AppLogger.e('ギャラリーからの画像選択中にエラーが発生しました', e, stackTrace);
      return null;
    }
  }

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      AppLogger.i('利用可能なカメラの取得を開始');

      final cameras = await availableCameras();

      AppLogger.i('利用可能なカメラ数: ${cameras.length}');
      for (int i = 0; i < cameras.length; i++) {
        final camera = cameras[i];
        AppLogger.i('カメラ $i: ${camera.name} (${camera.lensDirection})');
      }

      return cameras;
    } catch (e, stackTrace) {
      AppLogger.e('利用可能なカメラの取得中にエラーが発生しました', e, stackTrace);
      return [];
    }
  }

  @override
  Future<CameraController?> initializeCamera([
    CameraDescription? camera,
  ]) async {
    try {
      AppLogger.i('カメラの初期化を開始');

      // カメラが指定されていない場合は、利用可能なカメラから選択
      CameraDescription? targetCamera = camera;
      if (targetCamera == null) {
        final cameras = await getAvailableCameras();
        if (cameras.isEmpty) {
          AppLogger.w('利用可能なカメラがありません');
          return null;
        }

        // 背面カメラを優先的に選択
        targetCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      AppLogger.i(
        '使用するカメラ: ${targetCamera.name} (${targetCamera.lensDirection})',
      );

      // iOS固有の設定
      ImageFormatGroup imageFormatGroup;
      if (Platform.isIOS) {
        imageFormatGroup = ImageFormatGroup.bgra8888;
      } else {
        imageFormatGroup = ImageFormatGroup.jpeg;
      }

      // カメラコントローラーを作成
      final controller = CameraController(
        targetCamera,
        ResolutionPreset.high,
        enableAudio: false, // 音声は不要
        imageFormatGroup: imageFormatGroup,
      );

      // カメラを初期化
      await controller.initialize();

      AppLogger.i('カメラの初期化が完了しました');
      return controller;
    } catch (e, stackTrace) {
      AppLogger.e('カメラの初期化中にエラーが発生しました', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    try {
      AppLogger.i('カメラコントローラーの破棄を開始');

      if (controller.value.isInitialized) {
        // iOSでは、カメラを停止してから破棄する
        if (Platform.isIOS) {
          try {
            // 画像ストリームを停止
            await controller.stopImageStream();
          } catch (e) {
            // ストリームが既に停止している場合は無視
            AppLogger.d('画像ストリームは既に停止しています');
          }

          // iOSでの安定性向上のため、少し待機
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await controller.dispose();
        AppLogger.i('カメラコントローラーの破棄が完了しました');
      } else {
        AppLogger.i('カメラコントローラーは既に破棄されています');
      }
    } catch (e, stackTrace) {
      AppLogger.e('カメラコントローラーの破棄中にエラーが発生しました', e, stackTrace);
    }
  }
}
