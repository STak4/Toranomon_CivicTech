import 'dart:async';
import 'package:dio/dio.dart';
import '../../models/leonardo_ai/generation_response.dart';
import '../../models/leonardo_ai/leonardo_ai_exception.dart';
import '../../utils/app_logger.dart';
import 'leonardo_ai_api_client.dart';

/// 生成結果ポーリングサービス
///
/// Leonardo AI APIの生成状況を定期的にポーリングして結果を取得する
class GenerationPollingService {
  const GenerationPollingService(this._apiClient);

  final LeonardoAiApiClient _apiClient;

  /// 生成結果をポーリングして取得する
  ///
  /// [generationId] 生成ID
  /// [cancelToken] キャンセルトークン
  /// [maxAttempts] 最大試行回数（デフォルト: 20回）
  /// [pollInterval] ポーリング間隔（デフォルト: 45秒）
  /// [onProgress] 進行状況コールバック（現在の試行回数, 最大試行回数）
  /// Returns 完了した生成結果
  Future<GenerationResponse> pollForResult({
    required String generationId,
    CancelToken? cancelToken,
    int maxAttempts = 20,
    Duration pollInterval = const Duration(seconds: 45),
    void Function(int currentAttempt, int maxAttempts)? onProgress,
  }) async {
    AppLogger.i('🔄 ポーリング開始: Generation ID = $generationId');
    AppLogger.i('  ⏱️ Max Attempts: $maxAttempts');
    AppLogger.i('  ⏰ Poll Interval: ${pollInterval.inSeconds} seconds');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // キャンセルチェック
      if (cancelToken?.isCancelled == true) {
        AppLogger.w('⚠️ ポーリングがキャンセルされました');
        throw LeonardoAiException.cancelled();
      }

      // 進行状況を通知
      onProgress?.call(attempt, maxAttempts);

      try {
        AppLogger.d(
          '📡 ポーリング試行 $attempt/$maxAttempts: Generation ID = $generationId',
        );

        // 生成状況を確認
        final response = await _apiClient.getGenerationStatus(generationId);

        AppLogger.d('📊 ポーリングレスポンス:');
        AppLogger.d('  🆔 Generation ID: ${response.generationsByPk?.id}');
        AppLogger.d('  📊 Status: ${response.generationsByPk?.status}');
        AppLogger.d(
          '  🖼️ Generated Images: ${response.generationsByPk?.generatedImages.length ?? 0}',
        );

        // 完了チェック
        if (_isGenerationCompleted(response)) {
          AppLogger.i('✅ ポーリング完了: Generation ID = $generationId');
          AppLogger.i('  📊 Final Status: ${response.generationsByPk?.status}');
          AppLogger.i(
            '  🖼️ Generated Images: ${response.generationsByPk?.generatedImages.length ?? 0}',
          );
          return response;
        }

        // 失敗チェック
        if (_isGenerationFailed(response)) {
          final failureReason = _getFailureReason(response);
          AppLogger.e('❌ ポーリング失敗: Generation ID = $generationId');
          AppLogger.e('  📊 Status: ${response.generationsByPk?.status}');
          AppLogger.e('  💬 Failure Reason: $failureReason');
          throw LeonardoAiException.apiError(
            500,
            '画像生成が失敗しました: $failureReason',
          );
        }

        // 最後の試行でない場合は待機
        if (attempt < maxAttempts) {
          AppLogger.d('⏳ 次のポーリングまで待機中... (${pollInterval.inSeconds}秒)');
          await Future.delayed(pollInterval);
        }
      } on DioException catch (e) {
        AppLogger.e('❌ ポーリングでDioException: Attempt $attempt/$maxAttempts');
        AppLogger.e('  🔗 URL: ${e.requestOptions.uri}');
        AppLogger.e('  📊 Status Code: ${e.response?.statusCode}');
        AppLogger.e('  💬 Error Message: ${e.message}');

        // 最後の試行の場合はエラーを投げる
        if (attempt == maxAttempts) {
          AppLogger.e('❌ 最大試行回数に達しました: $maxAttempts');
          throw _handlePollingError(e);
        }

        // 一時的なエラーの場合は次の試行を続ける
        if (_isRetryableError(e)) {
          AppLogger.w('⚠️ 一時的なエラー、再試行します: ${e.message}');
          await Future.delayed(pollInterval);
          continue;
        }

        // 致命的なエラーの場合は即座に投げる
        AppLogger.e('❌ 致命的なエラー、ポーリングを中止: ${e.message}');
        throw _handlePollingError(e);
      }
    }

    // 最大試行回数に達した場合
    AppLogger.e('❌ ポーリングタイムアウト: $maxAttempts回試行しました');
    throw LeonardoAiException.timeout();
  }

  /// 複数の生成IDを並行してポーリングする
  ///
  /// [generationIds] 生成IDのリスト
  /// [cancelToken] キャンセルトークン
  /// [maxAttempts] 最大試行回数
  /// [pollInterval] ポーリング間隔
  /// [onProgress] 進行状況コールバック（完了数, 総数）
  /// Returns 完了した生成結果のリスト
  Future<List<GenerationResponse>> pollForMultipleResults({
    required List<String> generationIds,
    CancelToken? cancelToken,
    int maxAttempts = 20,
    Duration pollInterval = const Duration(seconds: 45),
    void Function(int completed, int total)? onProgress,
  }) async {
    int completed = 0;

    final futures = generationIds.map((id) async {
      final result = await pollForResult(
        generationId: id,
        cancelToken: cancelToken,
        maxAttempts: maxAttempts,
        pollInterval: pollInterval,
      );

      completed++;
      onProgress?.call(completed, generationIds.length);

      return result;
    });

    return await Future.wait(futures);
  }

  /// ストリームベースのポーリング
  ///
  /// [generationId] 生成ID
  /// [cancelToken] キャンセルトークン
  /// [maxAttempts] 最大試行回数
  /// [pollInterval] ポーリング間隔
  /// Returns 生成状況のストリーム
  Stream<GenerationPollingStatus> pollForResultStream({
    required String generationId,
    CancelToken? cancelToken,
    int maxAttempts = 20,
    Duration pollInterval = const Duration(seconds: 45),
  }) async* {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // キャンセルチェック
      if (cancelToken?.isCancelled == true) {
        yield GenerationPollingStatus.cancelled();
        return;
      }

      // 進行状況を通知
      yield GenerationPollingStatus.polling(attempt, maxAttempts);

      try {
        // 生成状況を確認
        final response = await _apiClient.getGenerationStatus(generationId);

        // 完了チェック
        if (_isGenerationCompleted(response)) {
          yield GenerationPollingStatus.completed(response);
          return;
        }

        // 失敗チェック
        if (_isGenerationFailed(response)) {
          yield GenerationPollingStatus.failed(
            '画像生成が失敗しました: ${_getFailureReason(response)}',
          );
          return;
        }

        // 最後の試行でない場合は待機
        if (attempt < maxAttempts) {
          await Future.delayed(pollInterval);
        }
      } on DioException catch (e) {
        // 最後の試行の場合はエラーを投げる
        if (attempt == maxAttempts) {
          yield GenerationPollingStatus.error(_handlePollingError(e));
          return;
        }

        // 一時的なエラーの場合は次の試行を続ける
        if (_isRetryableError(e)) {
          await Future.delayed(pollInterval);
          continue;
        }

        // 致命的なエラーの場合は即座に投げる
        yield GenerationPollingStatus.error(_handlePollingError(e));
        return;
      }
    }

    // 最大試行回数に達した場合
    yield GenerationPollingStatus.timeout();
  }

  /// 生成が完了しているかチェック
  bool _isGenerationCompleted(GenerationResponse response) {
    // Leonardo AIのAPIレスポンス構造に基づいて判定
    // 通常は status が "COMPLETE" の場合に完了
    return response.generationsByPk?.status == 'COMPLETE' ||
        response.generationsByPk?.status == 'COMPLETED';
  }

  /// 生成が失敗しているかチェック
  bool _isGenerationFailed(GenerationResponse response) {
    // Leonardo AIのAPIレスポンス構造に基づいて判定
    final status = response.generationsByPk?.status;
    return status == 'FAILED' || status == 'ERROR';
  }

  /// 失敗理由を取得
  String _getFailureReason(GenerationResponse response) {
    return response.generationsByPk?.status ?? '不明なエラー';
  }

  /// リトライ可能なエラーかチェック
  bool _isRetryableError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        // 5xx系エラーはリトライ可能
        return statusCode >= 500;
      default:
        return false;
    }
  }

  /// ポーリングエラーを適切な例外に変換
  LeonardoAiException _handlePollingError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return LeonardoAiException.networkError('ポーリング中にタイムアウトが発生しました');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401) {
          return LeonardoAiException.authenticationError('APIキーが無効です');
        } else if (statusCode == 429) {
          return LeonardoAiException.rateLimitError(
            'API制限に達しました',
            // TODO: Retry-Afterヘッダーから取得
            DateTime.now().add(const Duration(minutes: 1)),
          );
        } else if (statusCode >= 400 && statusCode < 500) {
          return LeonardoAiException.apiError(statusCode, 'ポーリングリクエストが無効です');
        } else if (statusCode >= 500) {
          return LeonardoAiException.apiError(statusCode, 'サーバーエラーが発生しました');
        }
        return LeonardoAiException.apiError(statusCode, 'ポーリング中にエラーが発生しました');
      case DioExceptionType.cancel:
        return LeonardoAiException.cancelled();
      default:
        return LeonardoAiException.networkError(
          'ポーリング中にネットワークエラーが発生しました: ${error.message}',
        );
    }
  }
}

/// 生成ポーリング状況
sealed class GenerationPollingStatus {
  const GenerationPollingStatus();

  /// ポーリング中
  const factory GenerationPollingStatus.polling(
    int currentAttempt,
    int maxAttempts,
  ) = GenerationPollingStatusPolling;

  /// 完了
  const factory GenerationPollingStatus.completed(GenerationResponse result) =
      GenerationPollingStatusCompleted;

  /// 失敗
  const factory GenerationPollingStatus.failed(String reason) =
      GenerationPollingStatusFailed;

  /// エラー
  const factory GenerationPollingStatus.error(LeonardoAiException error) =
      GenerationPollingStatusError;

  /// キャンセル
  const factory GenerationPollingStatus.cancelled() =
      GenerationPollingStatusCancelled;

  /// タイムアウト
  const factory GenerationPollingStatus.timeout() =
      GenerationPollingStatusTimeout;
}

class GenerationPollingStatusPolling extends GenerationPollingStatus {
  const GenerationPollingStatusPolling(this.currentAttempt, this.maxAttempts);

  final int currentAttempt;
  final int maxAttempts;
}

class GenerationPollingStatusCompleted extends GenerationPollingStatus {
  const GenerationPollingStatusCompleted(this.result);

  final GenerationResponse result;
}

class GenerationPollingStatusFailed extends GenerationPollingStatus {
  const GenerationPollingStatusFailed(this.reason);

  final String reason;
}

class GenerationPollingStatusError extends GenerationPollingStatus {
  const GenerationPollingStatusError(this.error);

  final LeonardoAiException error;
}

class GenerationPollingStatusCancelled extends GenerationPollingStatus {
  const GenerationPollingStatusCancelled();
}

class GenerationPollingStatusTimeout extends GenerationPollingStatus {
  const GenerationPollingStatusTimeout();
}
