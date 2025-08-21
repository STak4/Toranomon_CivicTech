// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationRequest _$GenerationRequestFromJson(Map<String, dynamic> json) =>
    GenerationRequest(
      prompt: json['prompt'] as String,
      numImages: (json['numImages'] as num?)?.toInt() ?? 1,
      width: (json['width'] as num?)?.toInt() ?? 512,
      height: (json['height'] as num?)?.toInt() ?? 512,
      modelId: json['modelId'] as String? ?? "LEONARDO_DIFFUSION_XL",
    );

Map<String, dynamic> _$GenerationRequestToJson(GenerationRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'numImages': instance.numImages,
      'width': instance.width,
      'height': instance.height,
      'modelId': instance.modelId,
    };
