import 'package:json_annotation/json_annotation.dart';
import 'generation_response.dart';

part 'edit_response.g.dart';

@JsonSerializable()
class EditResponse {
  final String generationId;
  final List<GeneratedImageData> generatedImages;

  const EditResponse({
    required this.generationId,
    required this.generatedImages,
  });

  factory EditResponse.fromJson(Map<String, dynamic> json) =>
      _$EditResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EditResponseToJson(this);

  EditResponse copyWith({
    String? generationId,
    List<GeneratedImageData>? generatedImages,
  }) {
    return EditResponse(
      generationId: generationId ?? this.generationId,
      generatedImages: generatedImages ?? this.generatedImages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditResponse &&
        other.generationId == generationId &&
        other.generatedImages == generatedImages;
  }

  @override
  int get hashCode {
    return generationId.hashCode ^ generatedImages.hashCode;
  }

  @override
  String toString() {
    return 'EditResponse(generationId: $generationId, generatedImages: $generatedImages)';
  }
}