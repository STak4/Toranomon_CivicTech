import 'package:json_annotation/json_annotation.dart';
import 'generated_image.dart';

part 'generation_result.g.dart';

@JsonSerializable()
class GenerationResult {
  final String generationId;
  final String prompt;
  final DateTime createdAt;
  final List<GeneratedImage> images;

  const GenerationResult({
    required this.generationId,
    required this.prompt,
    required this.createdAt,
    required this.images,
  });

  factory GenerationResult.fromJson(Map<String, dynamic> json) =>
      _$GenerationResultFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationResultToJson(this);

  /// 最初の画像を取得（後方互換性のため）
  GeneratedImage? get firstImage => images.isNotEmpty ? images.first : null;

  /// 画像数を取得
  int get imageCount => images.length;

  /// 指定されたインデックスの画像を取得
  GeneratedImage? getImageAt(int index) {
    if (index >= 0 && index < images.length) {
      return images[index];
    }
    return null;
  }

  GenerationResult copyWith({
    String? generationId,
    String? prompt,
    DateTime? createdAt,
    List<GeneratedImage>? images,
  }) {
    return GenerationResult(
      generationId: generationId ?? this.generationId,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationResult &&
        other.generationId == generationId &&
        other.prompt == prompt &&
        other.createdAt == createdAt &&
        other.images == images;
  }

  @override
  int get hashCode {
    return generationId.hashCode ^
        prompt.hashCode ^
        createdAt.hashCode ^
        images.hashCode;
  }

  @override
  String toString() {
    return 'GenerationResult(generationId: $generationId, prompt: $prompt, createdAt: $createdAt, images: $images)';
  }
}
