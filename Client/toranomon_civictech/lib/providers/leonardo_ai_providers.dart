import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gallery_saver_plus/gallery_saver.dart' as gallery_saver;
import 'package:permission_handler/permission_handler.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leonardo_ai/brush_state.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_result.dart';
import '../models/leonardo_ai/inpainting_result.dart';

import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../services/leonardo_ai/leonardo_ai_service.dart';
import '../services/leonardo_ai/result.dart';
import '../repositories/leonardo_ai_repository.dart';
import '../utils/app_logger.dart';
import '../utils/permission_utils.dart';
import '../utils/mask_image_generator.dart';
import '../utils/resource_manager.dart';

part 'leonardo_ai_providers.g.dart';

/// セキュアストレージのインスタンス
const _secureStorage = FlutterSecureStorage();

/// Leonardo.ai APIキープロバイダー
///
/// 環境変数またはセキュアストレージからAPIキーを取得する
@riverpod
Future<String> leonardoApiKey(Ref ref) async {
  try {
    AppLogger.d('Leonardo.ai APIキーを取得中');

    // まず環境変数から取得を試行
    final envApiKey = dotenv.env['LEONARDO_API_KEY'];
    if (envApiKey != null && envApiKey.isNotEmpty) {
      AppLogger.d('環境変数からAPIキーを取得 (Length: ${envApiKey.length})');
      return envApiKey;
    }

    // 環境変数にない場合はセキュアストレージから取得
    final storedApiKey = await _secureStorage.read(key: 'leonardo_api_key');
    if (storedApiKey != null && storedApiKey.isNotEmpty) {
      AppLogger.d('セキュアストレージからAPIキーを取得 (Length: ${storedApiKey.length})');
      return storedApiKey;
    }

    // どちらからも取得できない場合はエラー
    AppLogger.e('Leonardo.ai APIキーが設定されていません');
    throw LeonardoAiException.authenticationError(
      'Leonardo.ai APIキーが設定されていません。.envファイルまたはアプリ設定でAPIキーを設定してください。',
    );
  } catch (e) {
    if (e is LeonardoAiException) {
      rethrow;
    }

    AppLogger.e('APIキー取得でエラーが発生: $e');
    throw LeonardoAiException.unknownError('APIキー取得でエラーが発生しました: $e');
  }
}

/// Leonardo.ai サービスプロバイダー
///
/// APIキーを使用してLeonardoAiServiceのインスタンスを提供する
@riverpod
LeonardoAiService leonardoAiService(Ref ref) {
  // APIキーの変更を監視
  ref.watch(leonardoApiKeyProvider);

  final service = LeonardoAiService();

  // 長時間の非同期処理中にプロバイダーが破棄されるのを防ぐ
  ref.keepAlive();

  // プロバイダーが破棄される際にリソースを解放
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Leonardo.ai リポジトリプロバイダー
///
/// LeonardoAiRepositoryのインスタンスを提供する
@riverpod
LeonardoAiRepository leonardoAiRepository(Ref ref) {
  final service = ref.watch(leonardoAiServiceProvider);

  final repository = LeonardoAiRepository(service);

  // 長時間の非同期処理中にプロバイダーが破棄されるのを防ぐ
  ref.keepAlive();

  // プロバイダーが破棄される際にリソースを解放
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
}

/// 画像生成プロバイダー
///
/// テキストプロンプトから画像を生成する機能を提供する
@riverpod
class ImageGeneration extends _$ImageGeneration {
  dio.CancelToken? _cancelToken;

  @override
  FutureOr<GenerationResult?> build() => null;

  /// 画像生成を実行
  ///
  /// [prompt] 画像生成用のテキストプロンプト
  Future<void> generateImage(String prompt) async {
    state = const AsyncValue.loading();

    // 新しいキャンセルトークンを作成
    _cancelToken = dio.CancelToken();
    ResourceManager.instance.registerCancelToken(_cancelToken!);

    try {
      AppLogger.i('画像生成を開始: $prompt');

      // プロンプトのバリデーション
      if (prompt.trim().isEmpty) {
        throw LeonardoAiException.validationError('プロンプトを入力してください');
      }

      final repository = ref.read(leonardoAiRepositoryProvider);
      final result = await repository.generateImage(
        prompt.trim(),
        cancelToken: _cancelToken,
      );

      // キャンセルされた場合は処理を中断
      if (_cancelToken?.isCancelled == true) {
        AppLogger.i('画像生成がキャンセルされました');
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像生成がキャンセルされました'),
          StackTrace.current,
        );
        return;
      }

      result.fold(
        (generationResult) {
          AppLogger.i(
            '画像生成が完了: ${generationResult.generationId} (画像数: ${generationResult.imageCount})',
          );
          state = AsyncValue.data(generationResult);
        },
        (error) {
          AppLogger.e('画像生成でエラーが発生: $error');
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        AppLogger.i('画像生成がキャンセルされました');
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像生成がキャンセルされました'),
          StackTrace.current,
        );
      } else {
        AppLogger.e('画像生成でDioエラー: $e');
        state = AsyncValue.error(
          LeonardoAiException.networkError('ネットワークエラーが発生しました: ${e.message}'),
          StackTrace.current,
        );
      }
    } catch (e) {
      AppLogger.e('画像生成で予期しないエラー: $e');

      if (e is LeonardoAiException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像生成で予期しないエラーが発生しました: $e'),
          StackTrace.current,
        );
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// 画像生成をキャンセル
  void cancelGeneration() {
    if (state.isLoading && _cancelToken != null && !_cancelToken!.isCancelled) {
      AppLogger.i('画像生成をキャンセル中...');
      _cancelToken!.cancel('ユーザーによってキャンセルされました');
    }
  }

  /// 生成結果をクリア
  void clearResult() {
    AppLogger.d('画像生成結果をクリア');
    state = const AsyncValue.data(null);
  }
}

/// 画像編集プロバイダー
///
/// 既存の画像を編集する機能を提供する
@riverpod
class ImageEditing extends _$ImageEditing {
  dio.CancelToken? _cancelToken;

  @override
  FutureOr<EditedImage?> build() => null;

  /// 画像編集を実行
  ///
  /// [imageFile] 編集対象の画像ファイル
  /// [prompt] 編集指示のテキストプロンプト
  Future<void> editImage(File imageFile, String prompt) async {
    state = const AsyncValue.loading();

    // 新しいキャンセルトークンを作成
    _cancelToken = dio.CancelToken();

    try {
      AppLogger.i('画像編集を開始: ${imageFile.path} - $prompt');

      // パラメータのバリデーション
      if (prompt.trim().isEmpty) {
        throw LeonardoAiException.validationError('編集プロンプトを入力してください');
      }

      if (!await imageFile.exists()) {
        throw LeonardoAiException.validationError('指定された画像ファイルが存在しません');
      }

      final repository = ref.read(leonardoAiRepositoryProvider);
      final result = await repository.editImage(
        imageFile,
        prompt.trim(),
        cancelToken: _cancelToken,
      );

      // キャンセルされた場合は処理を中断
      if (_cancelToken?.isCancelled == true) {
        AppLogger.i('画像編集がキャンセルされました');
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像編集がキャンセルされました'),
          StackTrace.current,
        );
        return;
      }

      result.fold(
        (editedImage) {
          AppLogger.i('画像編集が完了: ${editedImage.id}');
          state = AsyncValue.data(editedImage);
        },
        (error) {
          AppLogger.e('画像編集でエラーが発生: $error');
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        AppLogger.i('画像編集がキャンセルされました');
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像編集がキャンセルされました'),
          StackTrace.current,
        );
      } else {
        AppLogger.e('画像編集でDioエラー: $e');
        state = AsyncValue.error(
          LeonardoAiException.networkError('ネットワークエラーが発生しました: ${e.message}'),
          StackTrace.current,
        );
      }
    } catch (e) {
      AppLogger.e('画像編集で予期しないエラー: $e');

      if (e is LeonardoAiException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          LeonardoAiException.unknownError('画像編集で予期しないエラーが発生しました: $e'),
          StackTrace.current,
        );
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// 画像編集をキャンセル
  void cancelEditing() {
    if (state.isLoading && _cancelToken != null && !_cancelToken!.isCancelled) {
      AppLogger.i('画像編集をキャンセル中...');
      _cancelToken!.cancel('ユーザーによってキャンセルされました');
    }
  }

  /// 編集結果をクリア
  void clearResult() {
    AppLogger.d('画像編集結果をクリア');
    state = const AsyncValue.data(null);
  }
}

/// ギャラリー保存の状態
enum GallerySaveStatus {
  /// 初期状態
  idle,

  /// 権限確認中
  checkingPermission,

  /// 権限要求中
  requestingPermission,

  /// 画像ダウンロード中
  downloading,

  /// ギャラリーに保存中
  saving,

  /// 保存完了
  completed,

  /// エラー発生
  error,
}

/// ギャラリー保存の進行状況
class GallerySaveProgress {
  const GallerySaveProgress({
    required this.status,
    required this.message,
    this.subMessage,
    this.progress,
    this.error,
  });

  /// 現在のステータス
  final GallerySaveStatus status;

  /// メインメッセージ
  final String message;

  /// サブメッセージ
  final String? subMessage;

  /// 進行状況（0.0-1.0）
  final double? progress;

  /// エラー情報
  final LeonardoAiException? error;

  GallerySaveProgress copyWith({
    GallerySaveStatus? status,
    String? message,
    String? subMessage,
    double? progress,
    LeonardoAiException? error,
  }) {
    return GallerySaveProgress(
      status: status ?? this.status,
      message: message ?? this.message,
      subMessage: subMessage ?? this.subMessage,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'GallerySaveProgress(status: $status, message: $message, progress: $progress)';
  }
}

/// ギャラリー保存プロバイダー
///
/// 生成・編集された画像をデバイスのギャラリーに保存する
@riverpod
class GallerySaver extends _$GallerySaver {
  GallerySaveProgress? _currentProgress;

  @override
  FutureOr<bool> build() => false;

  /// 現在の進行状況を取得
  GallerySaveProgress? get currentProgress => _currentProgress;

  /// 画像をギャラリーに保存
  ///
  /// [imageUrl] 保存する画像のURL
  /// [fileName] 保存時のファイル名（オプション）
  Future<void> saveToGallery(String imageUrl, {String? fileName}) async {
    state = const AsyncValue.loading();

    try {
      AppLogger.i('ギャラリーへの保存を開始: $imageUrl');

      // 1. 権限確認段階
      _updateProgress(
        const GallerySaveProgress(
          status: GallerySaveStatus.checkingPermission,
          message: '権限を確認中...',
          subMessage: 'ギャラリーアクセス権限を確認しています',
          progress: 0.1,
        ),
      );

      // URLのバリデーション
      if (imageUrl.trim().isEmpty) {
        throw LeonardoAiException.validationError('保存する画像のURLが指定されていません');
      }

      // 権限チェック
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        return; // エラーは _checkAndRequestPermission 内で処理済み
      }

      // 2. ダウンロード段階
      _updateProgress(
        const GallerySaveProgress(
          status: GallerySaveStatus.downloading,
          message: '画像をダウンロード中...',
          subMessage: '画像データを取得しています',
          progress: 0.4,
        ),
      );

      // 画像をダウンロード（検証のため）
      await _downloadImage(imageUrl);

      // 3. 保存段階
      _updateProgress(
        const GallerySaveProgress(
          status: GallerySaveStatus.saving,
          message: 'ギャラリーに保存中...',
          subMessage: '画像をデバイスに保存しています',
          progress: 0.8,
        ),
      );

      // ギャラリーに保存
      final success = await _saveImageToGallery(imageUrl, fileName);

      if (success) {
        // 4. 完了段階
        _updateProgress(
          const GallerySaveProgress(
            status: GallerySaveStatus.completed,
            message: '保存完了',
            subMessage: 'ギャラリーに保存しました',
            progress: 1.0,
          ),
        );

        AppLogger.i('ギャラリーへの保存が完了');
        state = const AsyncValue.data(true);

        // 少し待ってから進行状況をクリア
        Future.delayed(const Duration(seconds: 2), () {
          _clearProgress();
        });
      } else {
        throw LeonardoAiException.unknownError('ギャラリーへの保存に失敗しました');
      }
    } catch (e) {
      AppLogger.e('ギャラリー保存でエラー: $e');

      final error = e is LeonardoAiException
          ? e
          : LeonardoAiException.unknownError('ギャラリー保存でエラーが発生しました: $e');

      _updateProgress(
        GallerySaveProgress(
          status: GallerySaveStatus.error,
          message: 'エラーが発生しました',
          subMessage: error.message,
          error: error,
        ),
      );

      state = AsyncValue.error(error, StackTrace.current);

      // エラー状態も一定時間後にクリア
      Future.delayed(const Duration(seconds: 3), () {
        _clearProgress();
      });
    }
  }

  /// 権限をチェックして必要に応じて要求
  Future<bool> _checkAndRequestPermission() async {
    try {
      // 権限の現在の状態を確認
      await PermissionUtils.debugPermissionStatus();

      _updateProgress(
        const GallerySaveProgress(
          status: GallerySaveStatus.requestingPermission,
          message: '権限を要求中...',
          subMessage: 'ギャラリーアクセス権限を要求しています',
          progress: 0.2,
        ),
      );

      final hasPermission =
          await PermissionUtils.requestPhotoLibraryPermission();

      if (!hasPermission) {
        // 権限の状態をログ出力
        await PermissionUtils.logPermissionStatus();

        // 権限が拒否されている場合の詳細なエラーメッセージ
        final errorMessage =
            await PermissionUtils.getDetailedPermissionErrorMessage();

        // 権限が永続的に拒否された場合は設定画面を開く
        final photosAddOnlyStatus = await Permission.photosAddOnly.status;
        final photosStatus = await Permission.photos.status;

        if (photosAddOnlyStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          AppLogger.w('権限が永続的に拒否されています。設定画面を開きます。');

          _updateProgress(
            GallerySaveProgress(
              status: GallerySaveStatus.error,
              message: '権限が必要です',
              subMessage: '設定画面を開いています...',
              error: LeonardoAiException.validationError(errorMessage),
            ),
          );

          // 設定画面を開く
          await PermissionUtils.openAppSettings();
        }

        final error = LeonardoAiException.validationError(errorMessage);

        _updateProgress(
          GallerySaveProgress(
            status: GallerySaveStatus.error,
            message: '権限が拒否されました',
            subMessage: errorMessage,
            error: error,
          ),
        );

        state = AsyncValue.error(error, StackTrace.current);
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.e('権限チェックでエラー: $e');

      final error = LeonardoAiException.unknownError('権限チェックでエラーが発生しました: $e');

      _updateProgress(
        GallerySaveProgress(
          status: GallerySaveStatus.error,
          message: '権限チェックエラー',
          subMessage: error.message,
          error: error,
        ),
      );

      state = AsyncValue.error(error, StackTrace.current);
      return false;
    }
  }

  /// 画像をダウンロード
  Future<Uint8List> _downloadImage(String imageUrl) async {
    try {
      final dioClient = dio.Dio();

      // タイムアウト設定
      dioClient.options.connectTimeout = const Duration(seconds: 30);
      dioClient.options.receiveTimeout = const Duration(seconds: 60);

      final response = await dioClient.get(
        imageUrl,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          headers: {'User-Agent': 'Toranomon CivicTech App/1.0'},
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = 0.4 + (received / total) * 0.3; // 0.4-0.7の範囲
            _updateProgress(
              GallerySaveProgress(
                status: GallerySaveStatus.downloading,
                message: '画像をダウンロード中...',
                subMessage:
                    '${(received / 1024).toStringAsFixed(1)}KB / ${(total / 1024).toStringAsFixed(1)}KB',
                progress: progress,
              ),
            );
          }
        },
      );

      if (response.statusCode != 200) {
        throw LeonardoAiException.networkError(
          '画像のダウンロードに失敗しました: HTTP ${response.statusCode}',
        );
      }

      final imageData = response.data as Uint8List;

      // ダウンロードしたデータのサイズをチェック
      if (imageData.isEmpty) {
        throw LeonardoAiException.networkError('ダウンロードした画像データが空です');
      }

      AppLogger.i('画像ダウンロード完了: ${imageData.length / 1024}KB');
      return imageData;
    } catch (e) {
      AppLogger.e('画像ダウンロードでエラー: $e');

      if (e is dio.DioException) {
        if (e.type == dio.DioExceptionType.connectionTimeout) {
          throw LeonardoAiException.networkError('接続がタイムアウトしました');
        } else if (e.type == dio.DioExceptionType.receiveTimeout) {
          throw LeonardoAiException.networkError('データの受信がタイムアウトしました');
        } else {
          throw LeonardoAiException.networkError(
            'ネットワークエラーが発生しました: ${e.message}',
          );
        }
      }

      if (e is LeonardoAiException) {
        rethrow;
      }

      throw LeonardoAiException.unknownError('画像ダウンロードでエラーが発生しました: $e');
    }
  }

  /// 画像をギャラリーに保存
  Future<bool> _saveImageToGallery(String imageUrl, String? fileName) async {
    try {
      // アルバム名を設定
      const albumName = 'Leonardo AI';

      AppLogger.i('ギャラリーに保存開始: album=$albumName, fileName=$fileName');

      // gallery_saver_plusを使用して保存
      final result = await gallery_saver.GallerySaver.saveImage(
        imageUrl,
        albumName: albumName,
      );

      AppLogger.i('ギャラリー保存結果: $result');
      return result == true;
    } catch (e) {
      AppLogger.e('ギャラリー保存でエラー: $e');
      throw LeonardoAiException.unknownError('ギャラリーへの保存処理でエラーが発生しました: $e');
    }
  }

  /// 進行状況を更新
  void _updateProgress(GallerySaveProgress progress) {
    _currentProgress = progress;
    AppLogger.d('ギャラリー保存進行状況: ${progress.message} (${progress.progress})');
    // 状態変更を通知（UIの更新のため）
    ref.notifyListeners();
  }

  /// 進行状況をクリア
  void _clearProgress() {
    _currentProgress = null;
  }

  /// 保存状態をリセット
  void resetSaveState() {
    AppLogger.d('ギャラリー保存状態をリセット');
    _clearProgress();
    state = const AsyncValue.data(false);
  }

  /// 保存が可能かチェック
  Future<bool> canSaveToGallery() async {
    try {
      return await PermissionUtils.requestPhotoLibraryPermission();
    } catch (e) {
      AppLogger.e('保存可能性チェックでエラー: $e');
      return false;
    }
  }

  /// 保存処理の統計情報を取得
  Map<String, dynamic> getSaveStats() {
    try {
      return {
        'isLoading': state.isLoading,
        'hasCompleted': state.hasValue && state.value == true,
        'hasError': state.hasError,
        'currentStatus': _currentProgress?.status.name,
        'currentMessage': _currentProgress?.message,
        'progress': _currentProgress?.progress,
      };
    } catch (e) {
      AppLogger.e('保存統計取得でエラー: $e');
      return {};
    }
  }
}

/// ギャラリー保存進行状況プロバイダー
@riverpod
GallerySaveProgress? gallerySaveProgress(Ref ref) {
  final gallerySaver = ref.watch(gallerySaverProvider.notifier);
  return gallerySaver.currentProgress;
}

/// 選択画像プロバイダー
///
/// ギャラリーから選択した画像を管理する
@riverpod
class SelectedImage extends _$SelectedImage {
  @override
  File? build() => null;

  /// 画像を選択
  void selectImage(File image) {
    try {
      AppLogger.i('画像を選択: ${image.path}');

      // ファイルの存在確認
      if (!image.existsSync()) {
        AppLogger.e('選択された画像ファイルが存在しません: ${image.path}');
        throw LeonardoAiException.validationError('選択された画像ファイルが存在しません');
      }

      // ファイルサイズの確認（100MB制限）
      final fileSize = image.lengthSync();
      const maxSize = 100 * 1024 * 1024; // 100MB
      if (fileSize > maxSize) {
        AppLogger.e('画像ファイルサイズが大きすぎます: ${fileSize / (1024 * 1024)}MB');
        throw LeonardoAiException.validationError(
          '画像ファイルサイズが大きすぎます。100MB以下の画像を選択してください。',
        );
      }

      state = image;
      AppLogger.d('画像選択完了: ${image.path} (${fileSize / 1024}KB)');
    } catch (e) {
      AppLogger.e('画像選択でエラー: $e');
      if (e is LeonardoAiException) {
        rethrow;
      }
      throw LeonardoAiException.unknownError('画像選択でエラーが発生しました: $e');
    }
  }

  /// 選択画像をクリア
  void clearImage() {
    AppLogger.d('選択画像をクリア');
    state = null;
  }

  /// 選択画像の情報を取得
  Map<String, dynamic>? getImageInfo() {
    if (state == null) return null;

    try {
      final file = state!;
      final fileSize = file.lengthSync();
      final fileName = file.path.split('/').last;

      return {
        'path': file.path,
        'name': fileName,
        'size': fileSize,
        'sizeFormatted': '${(fileSize / 1024).toStringAsFixed(1)}KB',
        'exists': file.existsSync(),
      };
    } catch (e) {
      AppLogger.e('画像情報取得でエラー: $e');
      return null;
    }
  }

  /// 選択画像が有効かチェック
  bool isImageValid() {
    if (state == null) return false;

    try {
      return state!.existsSync();
    } catch (e) {
      AppLogger.e('画像有効性チェックでエラー: $e');
      return false;
    }
  }
}

/// ブラシ描画プロバイダー
///
/// ブラシサイズ、ストローク、描画状態を管理する
@riverpod
class BrushDrawing extends _$BrushDrawing {
  @override
  BrushState build() => const BrushState();

  /// ブラシサイズを更新
  void updateBrushSize(double size) {
    try {
      // ブラシサイズの範囲チェック（5.0 - 100.0）
      final clampedSize = size.clamp(5.0, 100.0);
      if (clampedSize != size) {
        AppLogger.w('ブラシサイズが範囲外のため調整: $size -> $clampedSize');
      }

      state = state.copyWith(brushSize: clampedSize);
      AppLogger.d('ブラシサイズを更新: $clampedSize');
    } catch (e) {
      AppLogger.e('ブラシサイズ更新でエラー: $e');
    }
  }

  /// 新しいストロークを開始
  void startStroke(Offset startPoint) {
    try {
      final newStroke = BrushStroke(
        points: [startPoint],
        brushSize: state.brushSize,
        color: state.brushColor,
        opacity: state.opacity,
      );

      state = state.copyWith(strokes: [...state.strokes, newStroke]);
      AppLogger.d('新しいストロークを開始: ${startPoint.dx}, ${startPoint.dy}');
    } catch (e) {
      AppLogger.e('ストローク開始でエラー: $e');
    }
  }

  /// 現在のストロークに点を追加
  void updateCurrentStroke(Offset point) {
    if (state.strokes.isEmpty) {
      AppLogger.w('ストロークが存在しないため点を追加できません');
      return;
    }

    try {
      final strokes = [...state.strokes];
      final currentStroke = strokes.last;
      final updatedStroke = currentStroke.copyWith(
        points: [...currentStroke.points, point],
      );
      strokes[strokes.length - 1] = updatedStroke;

      state = state.copyWith(strokes: strokes);
    } catch (e) {
      AppLogger.e('ストローク更新でエラー: $e');
    }
  }

  /// 現在のストロークを終了
  void endStroke() {
    if (state.strokes.isEmpty) return;

    try {
      final currentStroke = state.strokes.last;
      AppLogger.d('ストロークを終了: ${currentStroke.points.length} points');

      // ストロークが1点のみの場合は小さな円として扱う
      if (currentStroke.points.length == 1) {
        final point = currentStroke.points.first;
        final radius = currentStroke.brushSize / 4;
        final circlePoints = [
          point,
          Offset(point.dx + radius, point.dy),
          Offset(point.dx, point.dy + radius),
          Offset(point.dx - radius, point.dy),
          Offset(point.dx, point.dy - radius),
        ];

        final strokes = [...state.strokes];
        strokes[strokes.length - 1] = currentStroke.copyWith(
          points: circlePoints,
        );
        state = state.copyWith(strokes: strokes);
      }
    } catch (e) {
      AppLogger.e('ストローク終了でエラー: $e');
    }
  }

  /// 新しいストロークを追加（互換性のため）
  void addStroke(BrushStroke stroke) {
    try {
      state = state.copyWith(strokes: [...state.strokes, stroke]);
      AppLogger.d('ストロークを追加: ${stroke.points.length} points');
    } catch (e) {
      AppLogger.e('ストローク追加でエラー: $e');
    }
  }

  /// すべてのストロークをクリア
  void clearStrokes() {
    try {
      AppLogger.d('すべてのストロークをクリア (${state.strokes.length} strokes)');
      state = state.copyWith(strokes: []);
    } catch (e) {
      AppLogger.e('ストローククリアでエラー: $e');
    }
  }

  /// 最後のストロークを取り消し
  void undoLastStroke() {
    if (state.strokes.isEmpty) {
      AppLogger.w('取り消すストロークがありません');
      return;
    }

    try {
      final strokes = [...state.strokes];
      strokes.removeLast();
      state = state.copyWith(strokes: strokes);
      AppLogger.d('最後のストロークを取り消し (残り: ${strokes.length} strokes)');
    } catch (e) {
      AppLogger.e('ストローク取り消しでエラー: $e');
    }
  }

  /// ブラシの色を変更
  void updateBrushColor(Color color) {
    try {
      state = state.copyWith(brushColor: color);
      AppLogger.d('ブラシ色を更新: $color');
    } catch (e) {
      AppLogger.e('ブラシ色更新でエラー: $e');
    }
  }

  /// ブラシの透明度を変更
  void updateOpacity(double opacity) {
    try {
      final clampedOpacity = opacity.clamp(0.0, 1.0);
      if (clampedOpacity != opacity) {
        AppLogger.w('透明度が範囲外のため調整: $opacity -> $clampedOpacity');
      }

      state = state.copyWith(opacity: clampedOpacity);
      AppLogger.d('ブラシ透明度を更新: $clampedOpacity');
    } catch (e) {
      AppLogger.e('透明度更新でエラー: $e');
    }
  }

  /// マスク画像を生成
  Future<Uint8List> generateMaskImage(
    Size canvasSize, {
    Size? imageSize,
  }) async {
    try {
      if (state.strokes.isEmpty) {
        AppLogger.w('ストロークが存在しないため空のマスク画像を生成');
        // 空のマスク画像を生成
        return await MaskImageGenerator.generateEmptyMask(canvasSize);
      }

      AppLogger.i(
        'マスク画像を生成中: ${state.strokes.length} strokes, canvas: $canvasSize',
      );

      final maskImage = await MaskImageGenerator.generateMaskFromStrokes(
        strokes: state.strokes,
        canvasSize: canvasSize,
        imageSize: imageSize,
      );

      AppLogger.i('マスク画像生成完了: ${maskImage.length} bytes');
      return maskImage;
    } catch (e) {
      AppLogger.e('マスク画像生成でエラー: $e');
      throw LeonardoAiException.maskGenerationError('マスク画像の生成に失敗しました: $e');
    }
  }

  /// プレビュー用のマスク画像を生成
  Future<ui.Image> generatePreviewImage(Size canvasSize) async {
    try {
      AppLogger.d('プレビュー画像を生成中: canvas: $canvasSize');

      final previewImage = await MaskImageGenerator.createPreviewImage(
        strokes: state.strokes,
        canvasSize: canvasSize,
        maskColor: state.brushColor,
        opacity: state.opacity,
      );

      AppLogger.d('プレビュー画像生成完了');
      return previewImage;
    } catch (e) {
      AppLogger.e('プレビュー画像生成でエラー: $e');
      throw LeonardoAiException.maskGenerationError('プレビュー画像の生成に失敗しました: $e');
    }
  }

  /// 描画状態の統計情報を取得
  Map<String, dynamic> getDrawingStats() {
    try {
      final totalPoints = state.strokes.fold<int>(
        0,
        (sum, stroke) => sum + stroke.points.length,
      );

      return {
        'strokeCount': state.strokes.length,
        'totalPoints': totalPoints,
        'brushSize': state.brushSize,
        'brushColor': state.brushColor.toString(),
        'opacity': state.opacity,
        'hasDrawing': state.strokes.isNotEmpty,
      };
    } catch (e) {
      AppLogger.e('描画統計取得でエラー: $e');
      return {};
    }
  }

  /// 描画データが有効かチェック
  bool isDrawingValid() {
    try {
      return state.strokes.isNotEmpty &&
          state.strokes.any((stroke) => stroke.points.isNotEmpty);
    } catch (e) {
      AppLogger.e('描画有効性チェックでエラー: $e');
      return false;
    }
  }
}

/// Canvas Inpainting処理の進行状況
enum CanvasInpaintingStage {
  /// 初期化中
  initializing,

  /// 画像アップロード中
  uploading,

  /// 処理中
  processing,

  /// 結果取得中
  polling,

  /// 完了
  completed,
}

/// Canvas Inpainting進行状況データ
class CanvasInpaintingProgress {
  const CanvasInpaintingProgress({
    required this.stage,
    required this.message,
    this.subMessage,
    this.progress,
    this.currentStep,
    this.totalSteps,
  });

  /// 現在のステージ
  final CanvasInpaintingStage stage;

  /// メインメッセージ
  final String message;

  /// サブメッセージ
  final String? subMessage;

  /// 進行状況（0.0-1.0）
  final double? progress;

  /// 現在のステップ
  final int? currentStep;

  /// 総ステップ数
  final int? totalSteps;

  CanvasInpaintingProgress copyWith({
    CanvasInpaintingStage? stage,
    String? message,
    String? subMessage,
    double? progress,
    int? currentStep,
    int? totalSteps,
  }) {
    return CanvasInpaintingProgress(
      stage: stage ?? this.stage,
      message: message ?? this.message,
      subMessage: subMessage ?? this.subMessage,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  @override
  String toString() {
    return 'CanvasInpaintingProgress(stage: $stage, message: $message, progress: $progress)';
  }
}

/// Canvas Inpainting進行状況プロバイダー
@riverpod
CanvasInpaintingProgress? canvasInpaintingProgress(Ref ref) {
  final canvasInpainting = ref.watch(canvasInpaintingProvider.notifier);
  return canvasInpainting.currentProgress;
}

/// Canvas Inpaintingプロバイダー
///
/// Canvas Inpainting処理を管理するAsyncNotifierプロバイダー
@riverpod
class CanvasInpainting extends _$CanvasInpainting {
  dio.CancelToken? _cancelToken;
  InpaintingResultWithMask? _currentResult;
  CanvasInpaintingProgress? _currentProgress;

  @override
  FutureOr<InpaintingResult?> build() {
    // 長時間の非同期処理中にプロバイダーが破棄されるのを防ぐ
    ref.keepAlive();
    // 初期状態は何も返さない（AsyncValueが自動的に適切な状態を管理）
    return null;
  }

  /// 現在の進行状況を取得
  CanvasInpaintingProgress? get currentProgress => _currentProgress;

  /// Canvas Inpaintingを実行
  ///
  /// [originalImage] 元画像ファイル
  /// [maskImage] マスク画像データ
  /// [prompt] 編集プロンプト
  Future<void> executeInpainting({
    required File originalImage,
    required Uint8List maskImage,
    required String prompt,
  }) async {
    state = const AsyncValue.loading();

    // 新しいキャンセルトークンを作成
    _cancelToken = dio.CancelToken();

    try {
      AppLogger.i('Canvas Inpainting実行開始: ${originalImage.path} - $prompt');

      // 1. 初期化段階
      _updateProgress(
        const CanvasInpaintingProgress(
          stage: CanvasInpaintingStage.initializing,
          message: '初期化中...',
          subMessage: 'Canvas Inpaintingの準備をしています',
          progress: 0.1,
          currentStep: 1,
          totalSteps: 4,
        ),
      );

      // パラメータのバリデーション
      await _validateInpaintingParameters(originalImage, maskImage, prompt);

      // 2. アップロード段階
      _updateProgress(
        const CanvasInpaintingProgress(
          stage: CanvasInpaintingStage.uploading,
          message: '画像をアップロード中...',
          subMessage: '元画像とマスク画像をアップロードしています',
          progress: 0.3,
          currentStep: 2,
          totalSteps: 4,
        ),
      );

      // リポジトリを取得（keepAliveで破棄を防いでいる）
      final repository = ref.read(leonardoAiRepositoryProvider);

      // Canvas Inpainting実行
      final result = await _executeCanvasInpaintingProcess(
        repository,
        originalImage,
        maskImage,
        prompt,
      );

      // キャンセルされた場合は処理を中断
      if (_cancelToken?.isCancelled == true) {
        AppLogger.i('Canvas Inpaintingがキャンセルされました');
        _clearProgress();
        state = AsyncValue.error(
          LeonardoAiException.cancelled(),
          StackTrace.current,
        );
        return;
      }

      // 直接的な結果チェックと状態設定
      if (result.isSuccess) {
        final inpaintingResult = result.data;
        AppLogger.i('Canvas Inpainting完了: ${inpaintingResult.id}');
        AppLogger.i('  - 結果画像URL: ${inpaintingResult.resultImageUrl}');
        AppLogger.i('  - プロンプト: ${inpaintingResult.prompt}');
        AppLogger.i('  - ステータス: ${inpaintingResult.status}');

        // 結果画像URLが有効かチェック
        if (inpaintingResult.resultImageUrl.isEmpty) {
          AppLogger.e('Canvas Inpainting結果の画像URLが空です');
          _clearProgress();
          state = AsyncValue.error(
            LeonardoAiException.apiError(500, '生成された画像のURLが取得できませんでした'),
            StackTrace.current,
          );
          return;
        }

        // 完了段階
        _updateProgress(
          const CanvasInpaintingProgress(
            stage: CanvasInpaintingStage.completed,
            message: '完了しました',
            subMessage: '画像の編集が完了しました',
            progress: 1.0,
            currentStep: 4,
            totalSteps: 4,
          ),
        );

        // マスク画像と一緒に結果を保存
        _currentResult = InpaintingResultWithMask(
          result: inpaintingResult,
          maskImage: maskImage,
        );

        // 結果を状態に設定
        AppLogger.i('【プロバイダー】結果を状態に設定開始');
        AppLogger.i('【プロバイダー】設定する結果:');
        AppLogger.i('  - id: ${inpaintingResult.id}');
        AppLogger.i('  - url: "${inpaintingResult.resultImageUrl}"');
        AppLogger.i('  - prompt: "${inpaintingResult.prompt}"');
        AppLogger.i('  - status: ${inpaintingResult.status}');

        // 状態を直接設定
        state = AsyncValue.data(inpaintingResult);

        AppLogger.i('【プロバイダー】✅ Canvas Inpainting結果を状態に設定完了');
        AppLogger.i('【プロバイダー】設定後の状態:');
        AppLogger.i('  - hasValue: ${state.hasValue}');
        AppLogger.i('  - isLoading: ${state.isLoading}');
        AppLogger.i('  - hasError: ${state.hasError}');
        AppLogger.i('  - value: ${state.value}');
        AppLogger.i('  - value != null: ${state.value != null}');
        if (state.value != null) {
          AppLogger.i('  - value.id: ${state.value!.id}');
          AppLogger.i(
            '  - value.resultImageUrl: "${state.value!.resultImageUrl}"',
          );
        }

        // 少し待ってから進行状況をクリア
        Future.delayed(const Duration(seconds: 1), () {
          _clearProgress();
        });
      } else {
        final error = result.error;
        AppLogger.e('Canvas Inpaintingでエラー: $error');
        _clearProgress();
        state = AsyncValue.error(error, StackTrace.current);
      }
    } on dio.DioException catch (e) {
      _clearProgress();
      if (e.type == dio.DioExceptionType.cancel) {
        AppLogger.i('Canvas Inpaintingがキャンセルされました');
        state = AsyncValue.error(
          LeonardoAiException.cancelled(),
          StackTrace.current,
        );
      } else {
        AppLogger.e('Canvas InpaintingでDioエラー: $e');
        state = AsyncValue.error(
          LeonardoAiException.networkError('ネットワークエラーが発生しました: ${e.message}'),
          StackTrace.current,
        );
      }
    } catch (e) {
      _clearProgress();
      AppLogger.e('Canvas Inpaintingで予期しないエラー: $e');

      if (e is LeonardoAiException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          LeonardoAiException.unknownError(
            'Canvas Inpaintingで予期しないエラーが発生しました: $e',
          ),
          StackTrace.current,
        );
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// 新しいプロンプトで再修正を実行
  ///
  /// [newPrompt] 新しい編集プロンプト
  Future<void> reEditWithNewPrompt(String newPrompt) async {
    if (_currentResult == null) {
      AppLogger.e('再修正用の元データが存在しません');
      state = AsyncValue.error(
        LeonardoAiException.validationError('再修正用のデータが存在しません'),
        StackTrace.current,
      );
      return;
    }

    try {
      AppLogger.i('新しいプロンプトで再修正開始: $newPrompt');

      // プロンプトのバリデーション
      if (newPrompt.trim().isEmpty) {
        throw LeonardoAiException.validationError('プロンプトを入力してください');
      }

      // 元画像ファイルを再取得
      final originalImageFile = File(_currentResult!.result.originalImagePath);
      if (!originalImageFile.existsSync()) {
        throw LeonardoAiException.validationError('元画像ファイルが見つかりません');
      }

      // 同じマスク画像を使用して再実行
      await executeInpainting(
        originalImage: originalImageFile,
        maskImage: _currentResult!.maskImage,
        prompt: newPrompt.trim(),
      );
    } catch (e) {
      AppLogger.e('再修正でエラー: $e');
      if (e is LeonardoAiException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          LeonardoAiException.unknownError('再修正でエラーが発生しました: $e'),
          StackTrace.current,
        );
      }
    }
  }

  /// Canvas Inpaintingをキャンセル
  void cancelInpainting() {
    if (state.isLoading && _cancelToken != null && !_cancelToken!.isCancelled) {
      AppLogger.i('Canvas Inpaintingをキャンセル中...');

      // キャンセル中の進行状況を表示
      _updateProgress(
        const CanvasInpaintingProgress(
          stage: CanvasInpaintingStage.initializing,
          message: 'キャンセル中...',
          subMessage: '処理を中止しています',
          progress: null,
        ),
      );

      _cancelToken!.cancel('ユーザーによってキャンセルされました');

      // 少し待ってから状態をクリア
      Future.delayed(const Duration(milliseconds: 500), () {
        _clearProgress();
        state = AsyncValue.error(
          LeonardoAiException.cancelled(),
          StackTrace.current,
        );
      });
    }
  }

  /// 結果をクリア
  void clearResult() {
    AppLogger.d('Canvas Inpainting結果をクリア');
    _currentResult = null;
    state = const AsyncValue.data(null);
  }

  /// 現在の結果とマスク画像を取得
  InpaintingResultWithMask? getCurrentResultWithMask() {
    return _currentResult;
  }

  /// 再修正が可能かチェック
  bool canReEdit() {
    return _currentResult != null &&
        File(_currentResult!.result.originalImagePath).existsSync();
  }

  /// パラメータのバリデーション
  Future<void> _validateInpaintingParameters(
    File originalImage,
    Uint8List maskImage,
    String prompt,
  ) async {
    // プロンプトのバリデーション
    if (prompt.trim().isEmpty) {
      throw LeonardoAiException.validationError('プロンプトを入力してください');
    }

    if (prompt.trim().length > 1000) {
      throw LeonardoAiException.validationError(
        'プロンプトが長すぎます。1000文字以下で入力してください。',
      );
    }

    // 元画像のバリデーション
    if (!originalImage.existsSync()) {
      throw LeonardoAiException.validationError('元画像ファイルが存在しません');
    }

    final imageSize = originalImage.lengthSync();
    const maxImageSize = 100 * 1024 * 1024; // 100MB
    if (imageSize > maxImageSize) {
      throw LeonardoAiException.validationError(
        '画像ファイルサイズが大きすぎます。100MB以下の画像を使用してください。',
      );
    }

    // マスク画像のバリデーション
    if (maskImage.isEmpty) {
      throw LeonardoAiException.validationError('マスク画像が生成されていません');
    }

    const maxMaskSize = 50 * 1024 * 1024; // 50MB
    if (maskImage.length > maxMaskSize) {
      throw LeonardoAiException.validationError(
        'マスク画像サイズが大きすぎます。編集領域を小さくしてください。',
      );
    }

    AppLogger.d(
      'パラメータバリデーション完了: '
      'image: ${imageSize / 1024}KB, mask: ${maskImage.length / 1024}KB, '
      'prompt: ${prompt.length} chars',
    );
  }

  /// Canvas Inpainting処理の実行
  Future<Result<InpaintingResult, LeonardoAiException>>
  _executeCanvasInpaintingProcess(
    LeonardoAiRepository repository,
    File originalImage,
    Uint8List maskImage,
    String prompt,
  ) async {
    try {
      // 3. 処理段階
      _updateProgress(
        const CanvasInpaintingProgress(
          stage: CanvasInpaintingStage.processing,
          message: '画像を処理中...',
          subMessage: 'Leonardo AIが画像を編集しています',
          progress: 0.6,
          currentStep: 3,
          totalSteps: 4,
        ),
      );

      // 実際のCanvas Inpainting APIを使用
      final result = await repository.executeCanvasInpainting(
        originalImage: originalImage,
        maskImage: maskImage,
        prompt: prompt,
        cancelToken: _cancelToken,
      );

      // 4. ポーリング段階
      if (result.isSuccess) {
        _updateProgress(
          const CanvasInpaintingProgress(
            stage: CanvasInpaintingStage.polling,
            message: '結果を取得中...',
            subMessage: '生成された画像を取得しています',
            progress: 0.9,
            currentStep: 4,
            totalSteps: 4,
          ),
        );
      }

      return result;
    } catch (e) {
      AppLogger.e('Canvas Inpainting処理でエラー: $e');
      if (e is LeonardoAiException) {
        return Result.failure(e);
      }
      return Result.failure(
        LeonardoAiException.unknownError('処理中にエラーが発生しました: $e'),
      );
    }
  }

  /// 進行状況を更新
  void _updateProgress(CanvasInpaintingProgress progress) {
    _currentProgress = progress;
    AppLogger.d(
      'Canvas Inpainting進行状況: ${progress.message} (${progress.progress})',
    );
    // 状態変更を通知（UIの更新のため）
    ref.notifyListeners();
  }

  /// 進行状況をクリア
  void _clearProgress() {
    _currentProgress = null;
  }

  /// 処理状況の統計情報を取得
  Map<String, dynamic> getProcessingStats() {
    try {
      return {
        'isLoading': state.isLoading,
        'hasResult': state.hasValue && state.value != null,
        'hasError': state.hasError,
        'canReEdit': canReEdit(),
        'currentResultId': _currentResult?.result.id,
        'isCancellable': _cancelToken != null && !_cancelToken!.isCancelled,
      };
    } catch (e) {
      AppLogger.e('処理統計取得でエラー: $e');
      return {};
    }
  }
}
