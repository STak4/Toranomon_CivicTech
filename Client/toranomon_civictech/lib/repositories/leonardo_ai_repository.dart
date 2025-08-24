import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/leonardo_ai/generated_image.dart';
import '../models/leonardo_ai/edited_image.dart';
import '../models/leonardo_ai/generation_request.dart';
import '../models/leonardo_ai/generation_response.dart';
import '../models/leonardo_ai/generation_result.dart';
import '../models/leonardo_ai/edit_request.dart';
import '../models/leonardo_ai/canvas_init_request.dart';
import '../models/leonardo_ai/canvas_init_response.dart';
import '../models/leonardo_ai/canvas_inpainting_request.dart';
import '../models/leonardo_ai/inpainting_result.dart';

import '../models/leonardo_ai/leonardo_ai_exception.dart';
import '../services/leonardo_ai/leonardo_ai_service.dart';
import '../services/leonardo_ai/image_upload_service.dart';
import '../services/leonardo_ai/generation_polling_service.dart';
import '../services/leonardo_ai/result.dart';
import '../utils/app_logger.dart';

/// Leonardo.ai Repository
///
/// Leonardo.ai APIとの通信をビジネスロジックから分離し、
/// 画像生成・編集機能を提供するリポジトリクラス
class LeonardoAiRepository {
  LeonardoAiRepository(this._service);

  LeonardoAiService _service;

  /// サービスが破棄されている場合に新しいインスタンスを作成
  LeonardoAiService _getOrCreateService() {
    // サービスが破棄されている場合は新しいインスタンスを作成
    if (_service.isDisposed) {
      AppLogger.w('サービスが破棄されているため、新しいインスタンスを作成します');
      _service = LeonardoAiService();
    }
    return _service;
  }

  /// 画像生成
  ///
  /// テキストプロンプトから画像を生成する
  ///
  /// [prompt] 画像生成用のテキストプロンプト
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns 生成された画像情報またはエラー
  Future<Result<GenerationResult, LeonardoAiException>> generateImage(
    String prompt, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.i('画像生成を開始: $prompt');

      // プロンプトのバリデーション
      if (prompt.trim().isEmpty) {
        return Result.failure(
          LeonardoAiException.validationError('プロンプトを入力してください'),
        );
      }

      // 生成リクエストを作成
      final request = GenerationRequest(
        prompt: prompt.trim(),
        width: 512,
        height: 512,
        modelId: "1e60896f-3c26-4296-8ecc-53e2afecc132",
      );

      // 1. 生成ジョブを作成
      final jobResult = await _service.generateImage(
        request,
        cancelToken: cancelToken,
      );

      if (jobResult.isFailure) {
        return Result.failure(jobResult.error);
      }

      final jobResponse = jobResult.data;
      AppLogger.i('生成ジョブが作成されました: ${jobResponse.generationId}');

      // 2. 生成状況を確認（最大30秒待機）
      const maxAttempts = 30;
      const delaySeconds = 1;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        await Future.delayed(Duration(seconds: delaySeconds));

        AppLogger.d('GET API呼び出し開始: ${jobResponse.generationId}');
        final statusResult = await _service.getGenerationStatus(
          jobResponse.generationId,
          cancelToken: cancelToken,
        );
        AppLogger.d('GET API呼び出し完了: ${statusResult.isSuccess ? '成功' : '失敗'}');

        if (statusResult.isSuccess) {
          final statusResponse = statusResult.data;

          // 生成が完了したかチェック
          if (statusResponse.status == 'COMPLETE' &&
              statusResponse.generatedImages.isNotEmpty) {
            // 複数の画像をGeneratedImageオブジェクトに変換
            final generatedImages = statusResponse.generatedImages.map((
              imageData,
            ) {
              return GeneratedImage(
                id: imageData.id,
                url: imageData.url,
                prompt: prompt.trim(),
                createdAt: DateTime.now(),
                status: ImageStatus.completed,
              );
            }).toList();

            final generationResult = GenerationResult(
              generationId: statusResponse.generationId,
              prompt: prompt.trim(),
              createdAt: DateTime.now(),
              images: generatedImages,
            );

            AppLogger.i(
              '画像生成が完了: ${generationResult.generationId} (画像数: ${generationResult.imageCount})',
            );
            return Result.success(generationResult);
          } else if (statusResponse.status == 'FAILED') {
            AppLogger.e('画像生成が失敗しました: ${statusResponse.generationId}');
            return Result.failure(
              LeonardoAiException.apiError(500, '画像生成に失敗しました'),
            );
          }

          AppLogger.d('生成中... ステータス: ${statusResponse.status}');
        } else {
          // GET APIが失敗した場合のエラーログ
          AppLogger.e('生成状況確認でエラーが発生: ${statusResult.error}');
          return Result.failure(statusResult.error);
        }

        AppLogger.d('生成状況確認中... (${attempt + 1}/$maxAttempts)');
      }

      return Result.failure(
        LeonardoAiException.apiError(500, '画像生成がタイムアウトしました'),
      );
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
        return Result.failure(
          LeonardoAiException.validationError('編集プロンプトを入力してください'),
        );
      }

      if (!await imageFile.exists()) {
        return Result.failure(
          LeonardoAiException.validationError('指定された画像ファイルが存在しません'),
        );
      }

      // 画像ファイルサイズチェック（10MB制限）
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return Result.failure(
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
          return Result.failure(
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
        return Result.failure(LeonardoAiException.validationError('生成IDが無効です'));
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

  /// Canvas Inpainting実行
  ///
  /// 元画像とマスク画像を使用してCanvas Inpaintingを実行する
  ///
  /// [originalImage] 元画像ファイル
  /// [maskImage] マスク画像データ
  /// [prompt] 編集プロンプト
  /// [cancelToken] リクエストキャンセル用トークン（オプション）
  /// Returns Canvas Inpainting結果またはエラー
  Future<Result<InpaintingResult, LeonardoAiException>>
  executeCanvasInpainting({
    required File originalImage,
    required Uint8List maskImage,
    required String prompt,
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.i('Canvas Inpainting実行開始: ${originalImage.path} - $prompt');

      // パラメータのバリデーション
      final validationResult = await _validateCanvasInpaintingParameters(
        originalImage,
        maskImage,
        prompt,
      );
      if (validationResult.isFailure) {
        return Result.failure(validationResult.error);
      }

      // 元画像のサイズをチェックし、必要に応じてリサイズ
      AppLogger.i('元画像のサイズをチェック: ${originalImage.path}');
      
      final originalImageBytes = await originalImage.readAsBytes();
      final originalImageData = img.decodeImage(originalImageBytes);
      if (originalImageData == null) {
        return Result.failure(
          LeonardoAiException.validationError('元画像の読み込みに失敗しました'),
        );
      }

      final originalWidth = originalImageData.width;
      final originalHeight = originalImageData.height;
      
      AppLogger.i('元画像サイズ: ${originalWidth}x$originalHeight');

      File processedImage = originalImage;
      Size processedImageSize = Size(originalWidth.toDouble(), originalHeight.toDouble());

      // Leonardo AIの制限（1536px）を超えている場合はリサイズ
      if (originalWidth > 1536 || originalHeight > 1536) {
        AppLogger.i('🔧 画像サイズが1536pxを超えているためリサイズします');
        AppLogger.i('  📏 元サイズ: ${originalWidth}x$originalHeight');
        
        // アスペクト比を保持しながら1536px以下にリサイズ
        final maxDimension = math.max(originalWidth, originalHeight);
        final scale = 1536.0 / maxDimension;
        final newWidth = (originalWidth * scale).round();
        final newHeight = (originalHeight * scale).round();
        
        AppLogger.i('  📐 スケール: $scale');
        AppLogger.i('  📏 計算後サイズ: ${newWidth}x$newHeight');
        
        // 8の倍数に調整（Leonardo AI要件）
        final alignedWidth = (newWidth / 8).round() * 8;
        final alignedHeight = (newHeight / 8).round() * 8;
        
        AppLogger.i('  📏 8の倍数調整後: ${alignedWidth}x$alignedHeight');
        
        // 最終確認：1536px以下であることを保証
        final finalWidth = math.min(alignedWidth, 1536);
        final finalHeight = math.min(alignedHeight, 1536);
        
        AppLogger.i('  📏 最終サイズ: ${finalWidth}x$finalHeight');
        
        final resizedImage = img.copyResize(
          originalImageData,
          width: finalWidth,
          height: finalHeight,
          interpolation: img.Interpolation.cubic,
        );
        
        // リサイズ結果を検証
        AppLogger.i('  ✅ リサイズ実行結果: ${resizedImage.width}x${resizedImage.height}');
        
        // 一時ファイルに保存
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final jpegBytes = img.encodeJpg(resizedImage, quality: 90);
        await tempFile.writeAsBytes(jpegBytes);
        
        processedImage = tempFile;
        processedImageSize = Size(finalWidth.toDouble(), finalHeight.toDouble());
        
        AppLogger.i('  💾 画像リサイズ完了: ${processedImage.path}');
        AppLogger.i('  📏 保存されたサイズ: ${processedImageSize.width}x${processedImageSize.height}');
      } else {
        AppLogger.i('✅ 画像サイズが適切なためそのまま使用: ${originalWidth}x$originalHeight');
      }

      // マスク画像を処理済み画像と同じサイズに調整
      final adjustedMask = await _adjustMaskForCanvas(
        maskBytes: maskImage,
        targetSize: processedImageSize,
      );

      // 1. Canvas初期化（プリサインドURL取得）
      AppLogger.i('Canvas初期化を開始');
      final initResult = await _initializeCanvas();
      if (initResult.isFailure) {
        return Result.failure(initResult.error);
      }
      final initResponse = initResult.data;

      // 2. 画像アップロード（並行実行）
      AppLogger.i('🚀 画像アップロードを開始');
      AppLogger.i('  📁 アップロード対象ファイル: ${processedImage.path}');
      AppLogger.i('  📏 アップロード予定サイズ: ${processedImageSize.width}x${processedImageSize.height}');
      
      // アップロード前の最終確認
      final uploadImageBytes = await processedImage.readAsBytes();
      final uploadImageData = img.decodeImage(uploadImageBytes);
      if (uploadImageData != null) {
        AppLogger.i('  ✅ アップロード画像の実際のサイズ: ${uploadImageData.width}x${uploadImageData.height}');
        if (uploadImageData.width > 1536 || uploadImageData.height > 1536) {
          AppLogger.e('  ⚠️ 警告: アップロード画像が1536pxを超えています！');
        }
      }
      
      final uploadResult = await _uploadImages(
        initResponse,
        processedImage, // 処理済み画像を使用
        adjustedMask, // 調整されたマスク画像を使用
        cancelToken,
      );
      if (uploadResult.isFailure) {
        return Result.failure(uploadResult.error);
      }

      // 3. Canvas Inpainting実行
      AppLogger.i('Canvas Inpainting処理を開始');
      final inpaintingResult = await _executeInpainting(
        initResponse,
        prompt,
        cancelToken,
      );
      if (inpaintingResult.isFailure) {
        return Result.failure(inpaintingResult.error);
      }
      final jobResponse = inpaintingResult.data;

      // 4. 結果取得（ポーリング）
      AppLogger.i('結果ポーリングを開始: ${jobResponse.generationId}');
      final resultPolling = await _pollForInpaintingResult(
        jobResponse.generationId,
        originalImage.path,
        prompt,
        cancelToken,
      );

      return resultPolling;
    } catch (e, stackTrace) {
      AppLogger.e('Canvas Inpainting実行で予期しないエラー: $e', e, stackTrace);
      return Result.failure(
        LeonardoAiException.unknownError(
          'Canvas Inpainting実行で予期しないエラーが発生しました: $e',
        ),
      );
    }
  }

  /// Canvas初期化（プリサインドURL取得）
  Future<Result<CanvasInitResponse, LeonardoAiException>>
  _initializeCanvas() async {
    try {
      final request = const CanvasInitRequest(
        initExtension: 'jpeg',
        maskExtension: 'jpeg',
      );

      AppLogger.i('🎨 Canvas初期化リクエスト:');
      AppLogger.i('  📋 Request: ${request.toJson()}');

      final service = _getOrCreateService();
      final result = await service.getCanvasInitUrls(request);

      if (result.isSuccess) {
        final response = result.data;
        AppLogger.i('✅ Canvas初期化成功:');
        AppLogger.i('  🆔 Init Image ID: ${response.initImageId}');
        AppLogger.i('  🆔 Mask Image ID: ${response.masksImageId}');
        AppLogger.i('  🔗 Init URL: ${response.initUrl}');
        AppLogger.i('  🔗 Mask URL: ${response.masksUrl}');
        AppLogger.i('  📦 Init Fields: ${response.initFields}');
        AppLogger.i('  📦 Mask Fields: ${response.masksFields}');
      }

      return result;
    } catch (e) {
      AppLogger.e('Canvas初期化でエラー: $e');
      return Result.failure(
        LeonardoAiException.apiError(500, 'Canvas初期化に失敗しました: $e'),
      );
    }
  }

  /// 画像アップロード（元画像とマスク画像を並行アップロード）
  Future<Result<void, LeonardoAiException>> _uploadImages(
    CanvasInitResponse initResponse,
    File originalImage,
    Uint8List maskImage,
    CancelToken? cancelToken,
  ) async {
    try {
      final uploadService = ImageUploadService();

      AppLogger.i('📤 画像アップロード開始:');
      AppLogger.i(
        '  📁 Original Image: ${originalImage.path} (${await originalImage.length()} bytes)',
      );
      AppLogger.i('  📁 Mask Image: ${maskImage.length} bytes');
      AppLogger.i('  🔗 Init Upload URL: ${initResponse.initUrl}');
      AppLogger.i('  🔗 Mask Upload URL: ${initResponse.masksUrl}');

      // アップロード情報を準備
      final uploads = [
        ImageUploadInfo(
          uploadUrl: initResponse.initUrl,
          fields: initResponse.initFields,
          imageFile: originalImage,
        ),
        ImageUploadInfo(
          uploadUrl: initResponse.masksUrl,
          fields: initResponse.masksFields,
          imageBytes: maskImage,
          filename: 'mask.jpg',
        ),
      ];

      // 並行アップロード実行
      await uploadService.uploadMultipleImages(
        uploads: uploads,
        cancelToken: cancelToken,
        onProgress: (completed, total) {
          AppLogger.d('📊 アップロード進行状況: $completed/$total');
        },
      );

      // アップロードサービスのリソースを解放
      uploadService.dispose();

      AppLogger.i('✅ 画像アップロード完了');
      AppLogger.i(
        '  🔗 Init Image CDN: https://cdn.leonardo.ai/${initResponse.initKey}',
      );
      AppLogger.i(
        '  🔗 Mask Image CDN: https://cdn.leonardo.ai/${initResponse.masksKey}',
      );

      return const Result.success(null);
    } catch (e) {
      AppLogger.e('画像アップロードでエラー: $e');
      if (e is LeonardoAiException) {
        return Result.failure(e);
      }
      return Result.failure(
        LeonardoAiException.imageUploadError('画像アップロードに失敗しました: $e'),
      );
    }
  }

  /// Canvas Inpainting実行
  Future<Result<dynamic, LeonardoAiException>> _executeInpainting(
    CanvasInitResponse initResponse,
    String prompt,
    CancelToken? cancelToken,
  ) async {
    try {
      final request = CanvasInpaintingRequest(
        prompt: prompt,
        canvasRequest: true,
        canvasRequestType: 'INPAINT',
        canvasInitId: initResponse.initImageId,
        canvasMaskId: initResponse.masksImageId,
        modelId: '1e60896f-3c26-4296-8ecc-53e2afecc132',
      );

      AppLogger.i('🎨 Canvas Inpainting実行:');
      AppLogger.i('  📋 Request: ${request.toJson()}');
      AppLogger.i('  🎯 Prompt: "$prompt"');
      AppLogger.i('  🆔 Init Image ID: ${initResponse.initImageId}');
      AppLogger.i('  🆔 Mask Image ID: ${initResponse.masksImageId}');
      AppLogger.i('  🎨 Model ID: ${request.modelId}');

      final service = _getOrCreateService();
      final result = await service.executeCanvasInpainting(
        request,
        cancelToken: cancelToken,
      );

      if (result.isSuccess) {
        final response = result.data;
        AppLogger.i('✅ Canvas Inpaintingジョブ作成成功:');
        AppLogger.i('  🆔 Generation ID: ${response.generationId}');
        AppLogger.i('  💰 API Credit Cost: ${response.apiCreditCost}');
      }

      return result;
    } catch (e) {
      AppLogger.e('Canvas Inpainting実行でエラー: $e');
      if (e is LeonardoAiException) {
        return Result.failure(e);
      }
      return Result.failure(
        LeonardoAiException.apiError(500, 'Canvas Inpainting実行に失敗しました: $e'),
      );
    }
  }

  /// Canvas Inpainting結果のポーリング
  Future<Result<InpaintingResult, LeonardoAiException>>
  _pollForInpaintingResult(
    String generationId,
    String originalImagePath,
    String prompt,
    CancelToken? cancelToken,
  ) async {
    try {
      final service = _getOrCreateService();
      final pollingService = GenerationPollingService(service.apiClient);

      AppLogger.i('🔄 結果ポーリング開始:');
      AppLogger.i('  🆔 Generation ID: $generationId');
      AppLogger.i('  📁 Original Image: $originalImagePath');
      AppLogger.i('  🎯 Prompt: "$prompt"');
      AppLogger.i('  ⏱️ Max Attempts: 20');
      AppLogger.i('  ⏰ Poll Interval: 5 seconds');

      final result = await pollingService.pollForResult(
        generationId: generationId,
        cancelToken: cancelToken,
        maxAttempts: 20,
        pollInterval: const Duration(seconds: 5),
        onProgress: (currentAttempt, maxAttempts) {
          AppLogger.d('📊 ポーリング進行状況: $currentAttempt/$maxAttempts');
        },
      );

      AppLogger.i('✅ ポーリング完了:');
      AppLogger.i('  🆔 Generation ID: ${result.generationsByPk?.id}');
      AppLogger.i('  📊 Status: ${result.generationsByPk?.status}');
      AppLogger.i(
        '  🖼️ Generated Images: ${result.generationsByPk?.generatedImages.length ?? 0}',
      );

      // GenerationResponseからInpaintingResultに変換
      final generationData = result.generationsByPk;
      if (generationData != null && generationData.generatedImages.isNotEmpty) {
        AppLogger.i('🖼️ 生成された画像数: ${generationData.generatedImages.length}');
        
        // 全ての画像URLをログ出力
        final allImageUrls = <String>[];
        for (int i = 0; i < generationData.generatedImages.length; i++) {
          final imageData = generationData.generatedImages[i];
          AppLogger.i('  📷 画像 ${i + 1}: ID=${imageData.id}, URL=${imageData.url}');
          if (imageData.url.isNotEmpty) {
            allImageUrls.add(imageData.url);
          }
        }
        
        if (allImageUrls.isEmpty) {
          AppLogger.e('❌ 有効な画像URLが見つかりません');
          return Result.failure(
            LeonardoAiException.apiError(500, '生成された画像のURLが取得できませんでした'),
          );
        }
        
        final mainImageUrl = allImageUrls.first;

        final inpaintingResult = InpaintingResult(
          id: generationData.id,
          originalImagePath: originalImagePath,
          resultImageUrl: mainImageUrl,
          resultImageUrls: allImageUrls,
          prompt: prompt,
          createdAt: DateTime.now(),
          status: InpaintingStatus.completed,
        );

        AppLogger.i('🎉 Canvas Inpainting完了:');
        AppLogger.i('  🆔 Result ID: ${inpaintingResult.id}');
        AppLogger.i('  🔗 Main Image URL: ${inpaintingResult.resultImageUrl}');
        AppLogger.i('  📅 Created At: ${inpaintingResult.createdAt}');
        AppLogger.i('  📊 Status: ${inpaintingResult.status}');
        AppLogger.i('  🖼️ 総画像数: ${inpaintingResult.imageCount}');
        
        // 全ての画像URLをログ出力
        for (int i = 0; i < inpaintingResult.resultImageUrls.length; i++) {
          AppLogger.i('  📷 画像 ${i + 1}: ${inpaintingResult.resultImageUrls[i]}');
        }

        // 最終確認：結果画像URLが有効なHTTP(S)URLかチェック
        if (!inpaintingResult.resultImageUrl.startsWith('http')) {
          AppLogger.e('❌ 無効な画像URL: ${inpaintingResult.resultImageUrl}');
          return Result.failure(
            LeonardoAiException.apiError(500, '無効な画像URLが返されました'),
          );
        }

        return Result.success(inpaintingResult);
      } else {
        AppLogger.e('❌ 生成された画像が見つかりません');
        AppLogger.e('  📊 Generation Data: ${generationData?.toJson()}');
        AppLogger.e('  🖼️ Generated Images Count: ${generationData?.generatedImages.length ?? 0}');
        return Result.failure(
          LeonardoAiException.apiError(500, '生成された画像が見つかりません'),
        );
      }
    } catch (e) {
      AppLogger.e('❌ 結果ポーリングでエラー: $e');
      if (e is LeonardoAiException) {
        return Result.failure(e);
      }
      return Result.failure(LeonardoAiException.timeout());
    }
  }

  /// Canvas Inpaintingパラメータのバリデーション
  Future<Result<void, LeonardoAiException>> _validateCanvasInpaintingParameters(
    File originalImage,
    Uint8List maskImage,
    String prompt,
  ) async {
    try {
      AppLogger.i('🔍 パラメータバリデーション開始:');
      AppLogger.i('  📁 Original Image: ${originalImage.path}');
      AppLogger.i('  📁 Mask Image Size: ${maskImage.length} bytes');
      AppLogger.i('  🎯 Prompt: "$prompt" (${prompt.length} chars)');

      // プロンプトのバリデーション
      if (prompt.trim().isEmpty) {
        AppLogger.e('❌ プロンプトが空です');
        return Result.failure(
          LeonardoAiException.validationError('プロンプトを入力してください'),
        );
      }

      if (prompt.trim().length > 1000) {
        AppLogger.e('❌ プロンプトが長すぎます: ${prompt.length} chars');
        return Result.failure(
          LeonardoAiException.validationError('プロンプトが長すぎます。1000文字以下で入力してください。'),
        );
      }

      // 元画像のバリデーション
      if (!await originalImage.exists()) {
        AppLogger.e('❌ 元画像ファイルが存在しません: ${originalImage.path}');
        return Result.failure(
          LeonardoAiException.validationError('元画像ファイルが存在しません。画像を再選択してください。'),
        );
      }

      final imageSize = await originalImage.length();
      const maxImageSize = 100 * 1024 * 1024; // 100MB
      if (imageSize > maxImageSize) {
        AppLogger.e(
          '❌ 画像ファイルサイズが大きすぎます: ${(imageSize / (1024 * 1024)).toStringAsFixed(1)}MB',
        );
        return Result.failure(
          LeonardoAiException.validationError(
            '画像ファイルサイズが大きすぎます（${(imageSize / (1024 * 1024)).toStringAsFixed(1)}MB）。100MB以下の画像を使用してください。',
          ),
        );
      }

      // 画像形式のチェック
      final extension = originalImage.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        AppLogger.e('❌ サポートされていない画像形式: $extension');
        return Result.failure(
          LeonardoAiException.validationError(
            'サポートされていない画像形式です。JPEG、PNG、WebP形式の画像を使用してください。',
          ),
        );
      }

      // マスク画像のバリデーション
      if (maskImage.isEmpty) {
        AppLogger.e('❌ マスク画像が空です');
        return Result.failure(
          LeonardoAiException.validationError(
            'マスク画像が生成されていません。ブラシでマスクを描画してください。',
          ),
        );
      }

      const minMaskSize = 1024; // 1KB
      if (maskImage.length < minMaskSize) {
        AppLogger.e('❌ マスク画像が小さすぎます: ${maskImage.length} bytes');
        return Result.failure(
          LeonardoAiException.validationError(
            'マスク画像が小さすぎます。より大きなマスクを描画してください。',
          ),
        );
      }

      AppLogger.i('✅ パラメータバリデーション完了:');
      AppLogger.i(
        '  📊 Image Size: ${(imageSize / 1024).toStringAsFixed(1)}KB',
      );
      AppLogger.i(
        '  📊 Mask Size: ${(maskImage.length / 1024).toStringAsFixed(1)}KB',
      );
      AppLogger.i('  📊 Prompt Length: ${prompt.length} chars');
      AppLogger.i('  📁 Image Format: $extension');

      return const Result.success(null);
    } catch (e) {
      AppLogger.e('❌ パラメータバリデーションでエラー: $e');
      return Result.failure(
        LeonardoAiException.validationError('パラメータの検証中にエラーが発生しました: $e'),
      );
    }
  }

  /// マスク画像をCanvas Inpainting用に調整（軽量版）
  Future<Uint8List> _adjustMaskForCanvas({
    required Uint8List maskBytes,
    required Size targetSize,
  }) async {
    try {
      AppLogger.i('Canvas Inpainting用マスク画像調整開始: ${maskBytes.length} bytes');

      // マスク画像をデコード
      final maskImage = img.decodeImage(maskBytes);
      if (maskImage == null) {
        throw Exception('マスク画像のデコードに失敗しました');
      }

      // 必要に応じてリサイズ（サイズが大きく異なる場合のみ）
      final currentSize = Size(maskImage.width.toDouble(), maskImage.height.toDouble());
      
      if ((currentSize.width - targetSize.width).abs() > 100 || 
          (currentSize.height - targetSize.height).abs() > 100) {
        // サイズが大きく異なる場合のみリサイズ
        final resizedMask = img.copyResize(
          maskImage,
          width: targetSize.width.toInt(),
          height: targetSize.height.toInt(),
          interpolation: img.Interpolation.linear, // 高速化のためlinearを使用
        );
        
        final jpegBytes = img.encodeJpg(resizedMask, quality: 85);
        AppLogger.i('マスク画像リサイズ完了: ${jpegBytes.length} bytes');
        return Uint8List.fromList(jpegBytes);
      } else {
        // サイズが近い場合はそのまま使用
        AppLogger.i('マスク画像サイズが適切なためそのまま使用');
        return maskBytes;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Canvas Inpainting用マスク画像調整でエラー: $e', stackTrace);
      rethrow;
    }
  }

  /// リソースの解放
  void dispose() {
    _service.dispose();
    AppLogger.i('LeonardoAiRepositoryのリソースを解放しました');
  }
}
