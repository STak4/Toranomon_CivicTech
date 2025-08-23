import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_result.dart';

import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../services/leonardo_ai/leonardo_ai_service.dart';
import '../services/leonardo_ai/result.dart';
import '../repositories/leonardo_ai_repository.dart';
import '../utils/app_logger.dart';

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
    throw const LeonardoAiException.authenticationError(
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

    try {
      AppLogger.i('画像生成を開始: $prompt');

      // プロンプトのバリデーション
      if (prompt.trim().isEmpty) {
        throw const LeonardoAiException.validationError('プロンプトを入力してください');
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
          const LeonardoAiException.unknownError('画像生成がキャンセルされました'),
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
          const LeonardoAiException.unknownError('画像生成がキャンセルされました'),
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
        throw const LeonardoAiException.validationError('編集プロンプトを入力してください');
      }

      if (!await imageFile.exists()) {
        throw const LeonardoAiException.validationError('指定された画像ファイルが存在しません');
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
          const LeonardoAiException.unknownError('画像編集がキャンセルされました'),
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
          const LeonardoAiException.unknownError('画像編集がキャンセルされました'),
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

/// ギャラリー保存プロバイダー
///
/// 生成・編集された画像をデバイスのギャラリーに保存する
@riverpod
class GallerySaverProvider extends _$GallerySaverProvider {
  @override
  FutureOr<bool> build() => false;

  /// 画像をギャラリーに保存
  ///
  /// [imageUrl] 保存する画像のURL
  /// [fileName] 保存時のファイル名（オプション）
  Future<void> saveToGallery(String imageUrl, {String? fileName}) async {
    state = const AsyncValue.loading();

    try {
      AppLogger.i('ギャラリーへの保存を開始: $imageUrl');

      // 権限チェック
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        throw const LeonardoAiException.validationError(
          'ストレージへのアクセス権限が必要です。設定から権限を許可してください。',
        );
      }

      // 画像をダウンロード
      final dioClient = dio.Dio();
      final response = await dioClient.get(
        imageUrl,
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw LeonardoAiException.networkError(
          '画像のダウンロードに失敗しました: ${response.statusCode}',
        );
      }

      // ギャラリーに保存
      final result = await GallerySaver.saveImage(
        imageUrl,
        albumName: 'Leonardo AI',
      );

      if (result == true) {
        AppLogger.i('ギャラリーへの保存が完了');
        state = const AsyncValue.data(true);
      } else {
        throw const LeonardoAiException.unknownError('ギャラリーへの保存に失敗しました');
      }
    } catch (e) {
      AppLogger.e('ギャラリー保存でエラー: $e');

      if (e is LeonardoAiException) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          LeonardoAiException.unknownError('ギャラリー保存でエラーが発生しました: $e'),
          StackTrace.current,
        );
      }
    }
  }

  /// ストレージ権限をチェック
  Future<bool> _checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13以降（API 33以降）ではREAD_MEDIA_IMAGESを使用
        if (await _isAndroid13OrHigher()) {
          final photosStatus = await Permission.photos.status;
          if (photosStatus.isGranted) {
            return true;
          } else {
            final result = await Permission.photos.request();
            return result.isGranted;
          }
        } else {
          // Android 12以前ではstorage権限を使用
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) {
            return true;
          } else {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
        }
      } else {
        // iOSではphotos権限を使用
        final photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted) {
          return true;
        } else {
          final result = await Permission.photos.request();
          return result.isGranted;
        }
      }
    } catch (e) {
      AppLogger.e('権限チェックでエラー: $e');
      return false;
    }
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

  /// 保存状態をリセット
  void resetSaveState() {
    state = const AsyncValue.data(false);
  }
}
