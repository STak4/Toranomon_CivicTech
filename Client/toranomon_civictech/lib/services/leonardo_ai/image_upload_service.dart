import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../models/leonardo_ai/leonardo_ai_exception.dart';
import '../../utils/app_logger.dart';

/// 画像アップロードサービス
///
/// プリサインドURLを使用した画像アップロード機能を提供する
class ImageUploadService {
  ImageUploadService() {
    // プリサインドURL用の専用Dioインスタンスを作成
    // 認証インターセプターを除外（プリサインドURLは認証情報を含む）
    _uploadDio = Dio();
    _uploadDio.options.connectTimeout = const Duration(seconds: 30);
    _uploadDio.options.receiveTimeout = const Duration(seconds: 30);
    _uploadDio.options.sendTimeout = const Duration(seconds: 30);
  }

  late final Dio _uploadDio;

  /// 画像ファイルをプリサインドURLにアップロードする
  ///
  /// [uploadUrl] アップロード先のプリサインドURL
  /// [fields] アップロード用のフィールド（S3の場合のポリシーなど）
  /// [imageFile] アップロードする画像ファイル
  /// [cancelToken] キャンセルトークン
  /// [onSendProgress] アップロード進行状況のコールバック
  Future<void> uploadImageFile({
    required String uploadUrl,
    required Map<String, dynamic> fields,
    required File imageFile,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      AppLogger.i('📤 画像ファイルアップロード開始:');
      AppLogger.i('  🔗 Upload URL: $uploadUrl');
      AppLogger.i('  📁 File Path: ${imageFile.path}');
      AppLogger.i('  📊 File Size: ${await imageFile.length()} bytes');
      AppLogger.i('  📋 Fields: $fields');

      // マルチパートフォームデータを作成
      final formData = FormData();

      // フィールドを追加（S3のポリシーなど）
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // ファイルを追加
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: 'image.jpg',
      );
      formData.files.add(MapEntry('file', multipartFile));

      AppLogger.d('📦 FormData作成完了:');
      AppLogger.d('  📋 Fields Count: ${formData.fields.length}');
      AppLogger.d('  📁 Files Count: ${formData.files.length}');

      // アップロード実行（認証ヘッダーなし）
      await _uploadDio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      AppLogger.i('✅ 画像ファイルアップロード完了: ${imageFile.path}');
    } on DioException catch (e) {
      AppLogger.e('❌ 画像ファイルアップロードでDioException:');
      AppLogger.e('  🔗 URL: ${e.requestOptions.uri}');
      AppLogger.e('  📊 Status Code: ${e.response?.statusCode}');
      AppLogger.e('  💬 Error Message: ${e.message}');
      throw _handleUploadError(e);
    } catch (e) {
      AppLogger.e('❌ 画像ファイルアップロードで予期しないエラー: $e');
      throw LeonardoAiException.imageUploadError(
        '画像アップロード中に予期しないエラーが発生しました: ${e.toString()}',
      );
    }
  }

  /// バイト配列をプリサインドURLにアップロードする
  ///
  /// [uploadUrl] アップロード先のプリサインドURL
  /// [fields] アップロード用のフィールド（S3の場合のポリシーなど）
  /// [imageBytes] アップロードする画像のバイト配列
  /// [filename] ファイル名
  /// [cancelToken] キャンセルトークン
  /// [onSendProgress] アップロード進行状況のコールバック
  Future<void> uploadImageBytes({
    required String uploadUrl,
    required Map<String, dynamic> fields,
    required Uint8List imageBytes,
    required String filename,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      AppLogger.i('📤 画像バイトアップロード開始:');
      AppLogger.i('  🔗 Upload URL: $uploadUrl');
      AppLogger.i('  📁 Filename: $filename');
      AppLogger.i('  📊 Data Size: ${imageBytes.length} bytes');
      AppLogger.i('  📋 Fields: $fields');

      // マルチパートフォームデータを作成
      final formData = FormData();

      // フィールドを追加（S3のポリシーなど）
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // バイト配列からマルチパートファイルを作成
      final multipartFile = MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
      );
      formData.files.add(MapEntry('file', multipartFile));

      AppLogger.d('📦 FormData作成完了:');
      AppLogger.d('  📋 Fields Count: ${formData.fields.length}');
      AppLogger.d('  📁 Files Count: ${formData.files.length}');

      // アップロード実行（認証ヘッダーなし）
      await _uploadDio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      AppLogger.i('✅ 画像バイトアップロード完了: $filename');
    } on DioException catch (e) {
      AppLogger.e('❌ 画像バイトアップロードでDioException:');
      AppLogger.e('  🔗 URL: ${e.requestOptions.uri}');
      AppLogger.e('  📊 Status Code: ${e.response?.statusCode}');
      AppLogger.e('  💬 Error Message: ${e.message}');
      throw _handleUploadError(e);
    } catch (e) {
      AppLogger.e('❌ 画像バイトアップロードで予期しないエラー: $e');
      throw LeonardoAiException.imageUploadError(
        '画像アップロード中に予期しないエラーが発生しました: ${e.toString()}',
      );
    }
  }

  /// 複数の画像を並行してアップロードする
  ///
  /// [uploads] アップロード情報のリスト
  /// [cancelToken] キャンセルトークン
  /// [onProgress] 全体の進行状況コールバック
  Future<void> uploadMultipleImages({
    required List<ImageUploadInfo> uploads,
    CancelToken? cancelToken,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      AppLogger.i('📤 複数画像並行アップロード開始:');
      AppLogger.i('  📊 Total Images: ${uploads.length}');

      for (int i = 0; i < uploads.length; i++) {
        final upload = uploads[i];
        AppLogger.i(
          '  📁 Image ${i + 1}: ${upload.imageFile?.path ?? upload.filename ?? 'unknown'}',
        );
        AppLogger.i('  🔗 Upload URL: ${upload.uploadUrl}');
      }

      int completed = 0;
      final futures = uploads.map((upload) async {
        try {
          if (upload.imageFile != null) {
            AppLogger.d('📤 並行アップロード開始: ${upload.imageFile!.path}');
            await uploadImageFile(
              uploadUrl: upload.uploadUrl,
              fields: upload.fields,
              imageFile: upload.imageFile!,
              cancelToken: cancelToken,
            );
          } else if (upload.imageBytes != null) {
            AppLogger.d('📤 並行アップロード開始: ${upload.filename ?? 'unknown'}');
            await uploadImageBytes(
              uploadUrl: upload.uploadUrl,
              fields: upload.fields,
              imageBytes: upload.imageBytes!,
              filename: upload.filename ?? 'image.jpg',
              cancelToken: cancelToken,
            );
          }

          completed++;
          onProgress?.call(completed, uploads.length);
          AppLogger.d('✅ 並行アップロード完了: $completed/${uploads.length}');
        } catch (e) {
          AppLogger.e('❌ 並行アップロードでエラー: $e');
          rethrow;
        }
      });

      await Future.wait(futures);
      AppLogger.i('✅ 複数画像並行アップロード完了: ${uploads.length}個の画像');
    } catch (e) {
      AppLogger.e('❌ 複数画像並行アップロードでエラー: $e');
      rethrow;
    }
  }

  /// リソースの解放
  void dispose() {
    _uploadDio.close();
  }

  /// アップロードエラーを適切な例外に変換する
  LeonardoAiException _handleUploadError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return LeonardoAiException.networkError('アップロードがタイムアウトしました');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode >= 400 && statusCode < 500) {
          return LeonardoAiException.imageUploadError(
            'アップロードリクエストが無効です ($statusCode)',
          );
        } else if (statusCode >= 500) {
          return LeonardoAiException.imageUploadError(
            'サーバーエラーによりアップロードに失敗しました ($statusCode)',
          );
        }
        return LeonardoAiException.imageUploadError(
          'アップロードに失敗しました ($statusCode)',
        );
      case DioExceptionType.cancel:
        return LeonardoAiException.cancelled();
      default:
        return LeonardoAiException.imageUploadError(
          'ネットワークエラーによりアップロードに失敗しました: ${error.message}',
        );
    }
  }
}

/// 画像アップロード情報
class ImageUploadInfo {
  const ImageUploadInfo({
    required this.uploadUrl,
    required this.fields,
    this.imageFile,
    this.imageBytes,
    this.filename,
  }) : assert(
         (imageFile != null) ^ (imageBytes != null),
         'imageFile または imageBytes のいずれか一方を指定してください',
       );

  /// アップロード先URL
  final String uploadUrl;

  /// アップロード用フィールド
  final Map<String, dynamic> fields;

  /// アップロードする画像ファイル
  final File? imageFile;

  /// アップロードする画像のバイト配列
  final Uint8List? imageBytes;

  /// ファイル名（imageBytes使用時）
  final String? filename;
}
