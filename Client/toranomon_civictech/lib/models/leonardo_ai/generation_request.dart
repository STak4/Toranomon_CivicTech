import 'package:json_annotation/json_annotation.dart';

part 'generation_request.g.dart';

@JsonSerializable()
class GenerationRequest {
  final String prompt;
  final int numImages;
  final int width;
  final int height;
  final String modelId;

  const GenerationRequest({
    required this.prompt,
    this.numImages = 1,
    this.width = 512,
    this.height = 512,
    this.modelId = "LEONARDO_DIFFUSION_XL",
  });

  factory GenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationRequestToJson(this);

  GenerationRequest copyWith({
    String? prompt,
    int? numImages,
    int? width,
    int? height,
    String? modelId,
  }) {
    return GenerationRequest(
      prompt: prompt ?? this.prompt,
      numImages: numImages ?? this.numImages,
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
        other.numImages == numImages &&
        other.width == width &&
        other.height == height &&
        other.modelId == modelId;
  }

  @override
  int get hashCode {
    return prompt.hashCode ^
        numImages.hashCode ^
        width.hashCode ^
        height.hashCode ^
        modelId.hashCode;
  }

  @override
  String toString() {
    return 'GenerationRequest(prompt: $prompt, numImages: $numImages, width: $width, height: $height, modelId: $modelId)';
  }
}