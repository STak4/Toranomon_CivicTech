import 'package:json_annotation/json_annotation.dart';
import 'generation_data.dart';
import 'generated_image_data.dart';

part 'generation_response.g.dart';

@JsonSerializable()
class GenerationResponse {
  @JsonKey(name: 'generations_by_pk')
  final GenerationData? generationsByPk;

  const GenerationResponse({this.generationsByPk});

  factory GenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationResponseToJson(this);

  // 便利メソッド
  String get generationId => generationsByPk?.id ?? '';
  List<GeneratedImageData> get generatedImages =>
      generationsByPk?.generatedImages ?? [];
  String get status => generationsByPk?.status ?? '';

  GenerationResponse copyWith({GenerationData? generationsByPk}) {
    return GenerationResponse(
      generationsByPk: generationsByPk ?? this.generationsByPk,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationResponse &&
        other.generationsByPk == generationsByPk;
  }

  @override
  int get hashCode {
    return generationsByPk.hashCode;
  }

  @override
  String toString() {
    return 'GenerationResponse(generationsByPk: $generationsByPk)';
  }
}
