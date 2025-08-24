import 'package:json_annotation/json_annotation.dart';
import 'generated_image_data.dart';

part 'generation_data.g.dart';

@JsonSerializable()
class GenerationData {
  @JsonKey(name: 'generated_images')
  final List<GeneratedImageData> generatedImages;
  final String? modelId;
  final String? motion;
  final String? motionModel;
  final String? motionStrength;
  final String prompt;
  final String negativePrompt;
  final int imageHeight;
  final String? imageToVideo;
  final int imageWidth;
  final int inferenceSteps;
  final int seed;
  final String? ultra;
  final bool public;
  final String scheduler;
  final String sdVersion;
  final String status;
  final String? presetStyle;
  final String? initStrength;
  final int guidanceScale;
  final String id;
  final String createdAt;
  final bool promptMagic;
  final String? promptMagicVersion;
  final String? promptMagicStrength;
  final bool photoReal;
  final String? photoRealStrength;
  final String? fantasyAvatar;
  @JsonKey(name: 'prompt_moderations')
  final List<dynamic> promptModerations;
  @JsonKey(name: 'generation_elements')
  final List<dynamic> generationElements;

  const GenerationData({
    required this.generatedImages,
    required this.modelId,
    this.motion,
    this.motionModel,
    this.motionStrength,
    required this.prompt,
    required this.negativePrompt,
    required this.imageHeight,
    this.imageToVideo,
    required this.imageWidth,
    required this.inferenceSteps,
    required this.seed,
    this.ultra,
    required this.public,
    required this.scheduler,
    required this.sdVersion,
    required this.status,
    this.presetStyle,
    this.initStrength,
    required this.guidanceScale,
    required this.id,
    required this.createdAt,
    required this.promptMagic,
    this.promptMagicVersion,
    this.promptMagicStrength,
    required this.photoReal,
    this.photoRealStrength,
    this.fantasyAvatar,
    this.promptModerations = const [],
    this.generationElements = const [],
  });

  factory GenerationData.fromJson(Map<String, dynamic> json) =>
      _$GenerationDataFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationDataToJson(this);

  @override
  String toString() {
    return 'GenerationData(id: $id, status: $status, prompt: $prompt, generatedImages: ${generatedImages.length})';
  }
}
