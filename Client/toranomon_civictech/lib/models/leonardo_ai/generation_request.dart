import 'package:json_annotation/json_annotation.dart';

part 'generation_request.g.dart';

@JsonSerializable()
class GenerationRequest {
  final String prompt;
  final int width;
  final int height;
  final String modelId;

  const GenerationRequest({
    required this.prompt,
    this.width = 512,
    this.height = 512,
    this.modelId = "1e60896f-3c26-4296-8ecc-53e2afecc132",
  });

  factory GenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationRequestToJson(this);

  GenerationRequest copyWith({
    String? prompt,
    int? width,
    int? height,
    String? modelId,
  }) {
    return GenerationRequest(
      prompt: prompt ?? this.prompt,
      width: width ?? this.width,
      height: height ?? this.height,
      modelId: modelId ?? this.modelId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationRequest &&
        other.prompt == prompt &&
        other.width == width &&
        other.height == height &&
        other.modelId == modelId;
  }

  @override
  int get hashCode {
    return prompt.hashCode ^
        width.hashCode ^
        height.hashCode ^
        modelId.hashCode;
  }

  @override
  String toString() {
    return 'GenerationRequest(prompt: $prompt, width: $width, height: $height, modelId: $modelId)';
  }
}
