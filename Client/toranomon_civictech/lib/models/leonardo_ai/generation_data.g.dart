// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationData _$GenerationDataFromJson(
  Map<String, dynamic> json,
) => GenerationData(
  generatedImages: (json['generated_images'] as List<dynamic>)
      .map((e) => GeneratedImageData.fromJson(e as Map<String, dynamic>))
      .toList(),
  modelId: json['modelId'] as String,
  motion: json['motion'] as String?,
  motionModel: json['motionModel'] as String?,
  motionStrength: json['motionStrength'] as String?,
  prompt: json['prompt'] as String,
  negativePrompt: json['negativePrompt'] as String,
  imageHeight: (json['imageHeight'] as num).toInt(),
  imageToVideo: json['imageToVideo'] as String?,
  imageWidth: (json['imageWidth'] as num).toInt(),
  inferenceSteps: (json['inferenceSteps'] as num).toInt(),
  seed: (json['seed'] as num).toInt(),
  ultra: json['ultra'] as String?,
  public: json['public'] as bool,
  scheduler: json['scheduler'] as String,
  sdVersion: json['sdVersion'] as String,
  status: json['status'] as String,
  presetStyle: json['presetStyle'] as String?,
  initStrength: json['initStrength'] as String?,
  guidanceScale: (json['guidanceScale'] as num).toInt(),
  id: json['id'] as String,
  createdAt: json['createdAt'] as String,
  promptMagic: json['promptMagic'] as bool,
  promptMagicVersion: json['promptMagicVersion'] as String?,
  promptMagicStrength: json['promptMagicStrength'] as String?,
  photoReal: json['photoReal'] as bool,
  photoRealStrength: json['photoRealStrength'] as String?,
  fantasyAvatar: json['fantasyAvatar'] as String?,
  promptModerations: json['prompt_moderations'] as List<dynamic>? ?? const [],
  generationElements: json['generation_elements'] as List<dynamic>? ?? const [],
);

Map<String, dynamic> _$GenerationDataToJson(GenerationData instance) =>
    <String, dynamic>{
      'generated_images': instance.generatedImages,
      'modelId': instance.modelId,
      'motion': instance.motion,
      'motionModel': instance.motionModel,
      'motionStrength': instance.motionStrength,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'imageHeight': instance.imageHeight,
      'imageToVideo': instance.imageToVideo,
      'imageWidth': instance.imageWidth,
      'inferenceSteps': instance.inferenceSteps,
      'seed': instance.seed,
      'ultra': instance.ultra,
      'public': instance.public,
      'scheduler': instance.scheduler,
      'sdVersion': instance.sdVersion,
      'status': instance.status,
      'presetStyle': instance.presetStyle,
      'initStrength': instance.initStrength,
      'guidanceScale': instance.guidanceScale,
      'id': instance.id,
      'createdAt': instance.createdAt,
      'promptMagic': instance.promptMagic,
      'promptMagicVersion': instance.promptMagicVersion,
      'promptMagicStrength': instance.promptMagicStrength,
      'photoReal': instance.photoReal,
      'photoRealStrength': instance.photoRealStrength,
      'fantasyAvatar': instance.fantasyAvatar,
      'prompt_moderations': instance.promptModerations,
      'generation_elements': instance.generationElements,
    };
