import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'inpainting_result.g.dart';

/// Inpainting処理の状態
enum InpaintingStatus {
  /// 待機中
  pending,
  /// アップロード中
  uploading,
  /// 処理中
  processing,
  /// 完了
  completed,
  /// 失敗
  failed,
}

/// Inpainting結果モデル
@JsonSerializable()
class InpaintingResult {
  const InpaintingResult({
    required this.id,
    required this.originalImagePath,
    required this.resultImageUrl,
    required this.prompt,
    required this.createdAt,
    this.status = InpaintingStatus.completed,
    this.resultImageUrls = const [],
  });

  /// 生成ID
  final String id;
  
  /// 元画像のパス
  final String originalImagePath;
  
  /// 結果画像のURL（メイン画像）
  final String resultImageUrl;
  
  /// 全ての結果画像のURL（複数画像対応）
  final List<String> resultImageUrls;
  
  /// 使用されたプロンプト
  final String prompt;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 処理状態
  final InpaintingStatus status;
  
  /// 画像数を取得
  int get imageCount => resultImageUrls.isNotEmpty ? resultImageUrls.length : 1;
  
  /// 指定されたインデックスの画像URLを取得
  String getImageUrlAt(int index) {
    if (resultImageUrls.isNotEmpty && index < resultImageUrls.length) {
      return resultImageUrls[index];
    }
    return resultImageUrl; // フォールバック
  }

  InpaintingResult copyWith({
    String? id,
    String? originalImagePath,
    String? resultImageUrl,
    String? prompt,
    DateTime? createdAt,
    InpaintingStatus? status,
    List<String>? resultImageUrls,
  }) {
    return InpaintingResult(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      resultImageUrls: resultImageUrls ?? this.resultImageUrls,
    );
  }

  factory InpaintingResult.fromJson(Map<String, dynamic> json) =>
      _$InpaintingResultFromJson(json);

  Map<String, dynamic> toJson() => _$InpaintingResultToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InpaintingResult &&
        other.id == id &&
        other.originalImagePath == originalImagePath &&
        other.resultImageUrl == resultImageUrl &&
        other.prompt == prompt &&
        other.createdAt == createdAt &&
        other.status == status &&
        _listEquals(other.resultImageUrls, resultImageUrls);
  }

  @override
  int get hashCode => Object.hash(
    id, originalImagePath, resultImageUrl, prompt, createdAt, status, resultImageUrls
  );
  
  /// リストの等価性をチェック
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'InpaintingResult(id: $id, originalImagePath: $originalImagePath, resultImageUrl: $resultImageUrl, prompt: $prompt, createdAt: $createdAt, status: $status, imageCount: $imageCount)';
  }
}

/// マスク画像データを含むInpainting結果モデル（実行時専用）
class InpaintingResultWithMask {
  const InpaintingResultWithMask({
    required this.result,
    required this.maskImage,
  });

  /// 基本結果データ
  final InpaintingResult result;
  
  /// マスク画像データ（JSONシリアライゼーション対象外）
  final Uint8List maskImage;

  InpaintingResultWithMask copyWith({
    InpaintingResult? result,
    Uint8List? maskImage,
  }) {
    return InpaintingResultWithMask(
      result: result ?? this.result,
      maskImage: maskImage ?? this.maskImage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InpaintingResultWithMask &&
        other.result == result &&
        other.maskImage.length == maskImage.length;
  }

  @override
  int get hashCode => Object.hash(result, maskImage.length);

  @override
  String toString() {
    return 'InpaintingResultWithMask(result: $result, maskImage: ${maskImage.length} bytes)';
  }
}