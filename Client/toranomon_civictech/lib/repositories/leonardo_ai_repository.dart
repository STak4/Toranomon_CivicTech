import 'dart:io';
import 'package:dio/dio.dart';
import '../models/leonardo_ai/generated_image.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_request.dart';
import '../models/leonardo_ai/generation_response.dart';
import '../models/leonardo_ai/edit_request.dart';

import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../services/leonardo_ai/leonardo_ai_service.dart';
import '../services/leonardo_ai/result.dart';
import '../utils/app_logger.dart';

/// Leonardo.ai Repository
///
/// Leonardo.ai APIとの通信をビジネスロジックから分離し、
/// 画像生成・編集機能を提供するリポジトリクラス
class LeonardoAiRepository {
  const LeonardoAiRepository(this._service);

  final LeonardoAiService _service;

  /// 画像生成
  ///
  /// テキストプロンプトから画像を生成する
  ///
  /// [prompt] 画像生成用のテキストプロンプト
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns 生成された画像情報またはエラー
  Future<Result<GeneratedImage, LeonardoAiException>> generateImage(
    String prompt, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.i('画像生成を開始: $prompt');

      // プロンプトのバリデーション
      if (prompt.trim().isEmpty) {
        return const Result.failure(
          LeonardoAiException.validationError('プロンプトを入力してください'),
        );
      }

      // 生成リクエストを作成
      final request = GenerationRequest(
        prompt: prompt.trim(),
        numImages: 1,
        width: 512,
        height: 512,
        modelId: "LEONARDO_DIFFUSION_XL",
      );

      // API呼び出し
      final result = await _service.generateImage(
        request,
        cancelToken: cancelToken,
      );

      return result.flatMap((response) {
        // レスポンスから最初の画像を取得
        if (response.generatedImages.isEmpty) {
          return const Result.failure(
            LeonardoAiException.apiError(500, '画像が生成されませんでした'),
          );
        }

        final imageData = response.generatedImages.first;
        final generatedImage = GeneratedImage(
          id: response.generationId,
          url: imageData.url,
          prompt: prompt.trim(),
          createdAt: DateTime.now(),
          status: ImageStatus.completed,
        );

        AppLogger.i('画像生成が完了: ${generatedImage.id}');
        return Result.success(generatedImage);
      });
    } catch (e, stackTrace) {
      AppLogger.e('画像生成で予期しないエラー: $e', e, stackTrace);
      return Result.failure(
        LeonardoAiException.unknownError('画像生成で予期しないエラーが発生しました: $e'),
      );
    }
  }

  /// 画像編集
  ///
  /// 既存の画像にテキストプロンプトを適用して編集する
  ///
  /// [imageFile] 編集対象の画像ファイル
  /// [prompt] 編集指示のテキストプロンプト
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns 編集された画像情報またはエラー
  Future<Result<EditedImage, LeonardoAiException>> editImage(
    File imageFile,
    String prompt, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.i('画像編集を開始: ${imageFile.path} - $prompt');

      // パラメータのバリデーション
      if (prompt.trim().isEmpty) {
        return const Result.failure(
          LeonardoAiException.validationError('編集プロンプトを入力してください'),
        );
      }

      if (!await imageFile.exists()) {
        return const Result.failure(
          LeonardoAiException.validationError('指定された画像ファイルが存在しません'),
        );
      }

      // 画像ファイルサイズチェック（10MB制限）
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return const Result.failure(
          LeonardoAiException.validationError(
            '画像ファイルサイズが大きすぎます（10MB以下にしてください）',
          ),
        );
      }

      // 一意のIDを生成（実際のAPIでは画像をアップロードしてIDを取得）
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();

      // 編集リクエストを作成
      final request = EditRequest(
        prompt: prompt.trim(),
        imageId: imageId,
        numImages: 1,
        strength: 0.7,
      );

      // API呼び出し
      final result = await _service.editImage(
        imageId,
        request,
        cancelToken: cancelToken,
      );

      return result.flatMap((response) {
        // レスポンスから編集された画像を取得
        if (response.generatedImages.isEmpty) {
          return const Result.failure(
            LeonardoAiException.apiError(500, '画像が編集されませんでした'),
          );
        }

        final imageData = response.generatedImages.first;
        final editedImage = EditedImage(
          id: response.generationId,
          originalImagePath: imageFile.path,
          editedImageUrl: imageData.url,
          editPrompt: prompt.trim(),
          createdAt: DateTime.now(),
          status: ImageStatus.completed,
        );

        AppLogger.i('画像編集が完了: ${editedImage.id}');
        return Result.success(editedImage);
      });
    } catch (e, stackTrace) {
      AppLogger.e('画像編集で予期しないエラー: $e', e, stackTrace);
      return Result.failure(
        LeonardoAiException.unknownError('画像編集で予期しないエラーが発生しました: $e'),
      );
    }
  }

  /// 生成状況確認
  ///
  /// 画像生成・編集の進行状況を確認する
  ///
  /// [generationId] 生成ID
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns 生成状況またはエラー
  Future<Result<GenerationResponse, LeonardoAiException>> getGenerationStatus(
    String generationId, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.d('生成状況を確認: $generationId');

      if (generationId.trim().isEmpty) {
        return const Result.failure(
          LeonardoAiException.validationError('生成IDが無効です'),
        );
      }

      final result = await _service.getGenerationStatus(
        generationId.trim(),
        cancelToken: cancelToken,
      );

      return result;
    } catch (e, stackTrace) {
      AppLogger.e('生成状況確認で予期しないエラー: $e', e, stackTrace);
      return Result.failure(
        LeonardoAiException.unknownError('生成状況確認で予期しないエラーが発生しました: $e'),
      );
    }
  }

  /// ユーザー情報取得
  ///
  /// 現在のユーザー情報を取得する
  ///
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns ユーザー情報またはエラー
  Future<Result<Map<String, dynamic>, LeonardoAiException>> getUserInfo({
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.d('ユーザー情報を取得');

      final result = await _service.getUserInfo(cancelToken: cancelToken);

      return result;
    } catch (e, stackTrace) {
      AppLogger.e('ユーザー情報取得で予期しないエラー: $e', e, stackTrace);
      return Result.failure(
        LeonardoAiException.unknownError('ユーザー情報取得で予期しないエラーが発生しました: $e'),
      );
    }
  }

  /// リソースの解放
  void dispose() {
    _service.dispose();
    AppLogger.i('LeonardoAiRepositoryのリソースを解放しました');
  }
}
