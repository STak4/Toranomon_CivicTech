import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/leonardo_ai/generation_request.dart';
import '../../models/leonardo_ai/generation_response.dart';
import '../../models/leonardo_ai/generation_job_response.dart';
import '../../models/leonardo_ai/edit_request.dart';
import '../../models/leonardo_ai/edit_response.dart';

part 'leonardo_ai_api_client.g.dart';

/// Leonardo.ai REST API クライアント
///
/// Retrofitを使用してLeonardo.ai APIとの通信を行う
@RestApi(baseUrl: "https://cloud.leonardo.ai/api/rest/v1")
abstract class LeonardoAiApiClient {
  factory LeonardoAiApiClient(Dio dio, {String baseUrl}) = _LeonardoAiApiClient;

  /// 画像生成API
  ///
  /// テキストプロンプトから画像生成ジョブを作成する
  ///
  /// [request] 画像生成リクエスト
  /// Returns 生成ジョブの情報
  @POST("/generations")
  Future<GenerationJobResponse> generateImage(
    @Body() GenerationRequest request,
  );

  /// 画像編集API
  ///
  /// 既存の画像を編集する
  ///
  /// [id] 編集対象の画像ID
  /// [request] 画像編集リクエスト
  /// Returns 編集された画像の情報
  @POST("/generations/{id}/edit")
  Future<EditResponse> editImage(
    @Path("id") String id,
    @Body() EditRequest request,
  );

  /// 生成状況確認API
  ///
  /// 画像生成・編集の進行状況を確認する
  ///
  /// [id] 生成ID
  /// Returns 生成状況の情報
  @GET("/generations/{id}")
  Future<GenerationResponse> getGenerationStatus(@Path("id") String id);

  // TODO: ユーザー情報とモデル一覧のAPIは後で実装
  // 現在はRetrofitのMap<String, dynamic>処理に問題があるため一時的に削除
}
