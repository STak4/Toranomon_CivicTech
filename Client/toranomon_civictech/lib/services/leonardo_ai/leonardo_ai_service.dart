import 'package:dio/dio.dart';
import '../../models/leonardo_ai/leonardo_ai_exception.dart';
import '../../models/leonardo_ai/generation_request.dart';
import '../../models/leonardo_ai/generation_response.dart';
import '../../models/leonardo_ai/generation_job_response.dart';
import '../../models/leonardo_ai/edit_request.dart';
import '../../models/leonardo_ai/edit_response.dart';
import '../../utils/app_logger.dart';
import 'dio_config.dart';
import 'error_handler.dart';
import 'leonardo_ai_api_client.dart';
import 'result.dart';

/// Leonardo.ai APIサービス
///
/// API通信とエラーハンドリングを統合したサービスクラス
class LeonardoAiService {
  late final Dio _dio;
  bool _isDisposed = false;

  LeonardoAiService() {
    _dio = DioConfig.createDio();
    AppLogger.i('LeonardoAiServiceを初期化しました');
  }

  /// 画像生成
  ///
  /// [request] 画像生成リクエスト
  /// [cancelToken] キャンセルトークン（オプション）
  /// Returns 生成結果またはエラー
  Future<Result<GenerationJobResponse, LeonardoAiException>> generateImage(
    GenerationRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (_isDisposed) {
      return Result.failure(
        const LeonardoAiException.unknownError('サービスが既に破棄されています'),
      );
    }

    Dio? dio;
    try {
      AppLogger.i('画像生成を開始: ${request.prompt}');

      // 新しいDioインスタンスを作成（接続の問題を回避）
      dio = DioConfig.createDio();
      final apiClient = LeonardoAiApiClient(dio);

      // キャンセルトークンを設定
      if (cancelToken != null) {
        dio.options.extra['cancelToken'] = cancelToken;
      }

      final response = await apiClient.generateImage(request);

      // 使用後にDioを閉じる
      dio.close();

      AppLogger.i('画像生成ジョブが作成されました: ${response.generationId}');
      return Result.success(response);
    } on DioException catch (e) {
      // Dioを閉じる
      dio?.close();

      final error = ErrorHandler.handleDioError(e);
      AppLogger.e('画像生成でエラーが発生: $error');
      return Result.failure(error);
    } catch (e, stackTrace) {
      // Dioを閉じる
      dio?.close();

      final error = ErrorHandler.handleGenericError(e, stackTrace);
      AppLogger.e('画像生成で予期しないエラーが発生: $error');
      return Result.failure(error);
    }
  }

  /// 画像編集
  ///
  /// [id] 編集対象の画像ID
  /// [request] 画像編集リクエスト
  /// [cancelToken] キャンセルトークン（オプション）
  /// Returns 編集結果またはエラー
  Future<Result<EditResponse, LeonardoAiException>> editImage(
    String id,
    EditRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (_isDisposed) {
      return Result.failure(
        const LeonardoAiException.unknownError('サービスが既に破棄されています'),
      );
    }

    try {
      AppLogger.i('画像編集を開始: $id - ${request.prompt}');

      // 新しいDioインスタンスを作成（接続の問題を回避）
      final dio = DioConfig.createDio();
      final apiClient = LeonardoAiApiClient(dio);

      // キャンセルトークンを設定
      if (cancelToken != null) {
        dio.options.extra['cancelToken'] = cancelToken;
      }

      final response = await apiClient.editImage(id, request);

      // 使用後にDioを閉じる
      dio.close();

      AppLogger.i('画像編集が完了: ${response.generationId}');
      return Result.success(response);
    } on DioException catch (e) {
      final error = ErrorHandler.handleDioError(e);
      AppLogger.e('画像編集でエラーが発生: $error');
      return Result.failure(error);
    } catch (e, stackTrace) {
      final error = ErrorHandler.handleGenericError(e, stackTrace);
      AppLogger.e('画像編集で予期しないエラーが発生: $error');
      return Result.failure(error);
    }
  }

  /// 生成状況確認
  ///
  /// [id] 生成ID
  /// [cancelToken] キャンセルトークン（オプション）
  /// Returns 生成状況またはエラー
  Future<Result<GenerationResponse, LeonardoAiException>> getGenerationStatus(
    String id, {
    CancelToken? cancelToken,
  }) async {
    // 一時的に_isDisposedチェックを無効化（デバッグ用）
    // if (_isDisposed) {
    //   AppLogger.e('サービスが既に破棄されています: $id');
    //   return Result.failure(
    //     const LeonardoAiException.unknownError('サービスが既に破棄されています'),
    //   );
    // }

    try {
      AppLogger.d('生成状況を確認: $id');
      AppLogger.i(
        'GET API呼び出し: https://cloud.leonardo.ai/api/rest/v1/generations/$id',
      );

      // 新しいDioインスタンスを作成（接続の問題を回避）
      final dio = DioConfig.createDio();
      final apiClient = LeonardoAiApiClient(dio);

      // キャンセルトークンを設定
      if (cancelToken != null) {
        dio.options.extra['cancelToken'] = cancelToken;
      }

      final response = await apiClient.getGenerationStatus(id);

      // 使用後にDioを閉じる
      dio.close();

      AppLogger.d('生成状況を取得: ${response.generationId}');
      return Result.success(response);
    } on DioException catch (e) {
      final error = ErrorHandler.handleDioError(e);
      AppLogger.e('生成状況確認でエラーが発生: $error');
      return Result.failure(error);
    } catch (e, stackTrace) {
      final error = ErrorHandler.handleGenericError(e, stackTrace);
      AppLogger.e('生成状況確認で予期しないエラーが発生: $error');
      return Result.failure(error);
    }
  }

  /// ユーザー情報取得（未実装）
  ///
  /// TODO: RetrofitのMap処理問題解決後に実装
  Future<Result<Map<String, dynamic>, LeonardoAiException>> getUserInfo({
    CancelToken? cancelToken,
  }) async {
    AppLogger.w('getUserInfo: 未実装のメソッドが呼び出されました');
    return Result.failure(
      LeonardoAiException.apiError(501, 'ユーザー情報取得機能は未実装です'),
    );
  }

  /// リソースの解放
  void dispose() {
    if (!_isDisposed) {
      _dio.close();
      _isDisposed = true;
      AppLogger.i('LeonardoAiServiceのリソースを解放しました');
    }
  }
}
