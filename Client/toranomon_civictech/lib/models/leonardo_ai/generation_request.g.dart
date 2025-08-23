// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationRequest _$GenerationRequestFromJson(Map<String, dynamic> json) =>
    GenerationRequest(
      prompt: json['prompt'] as String,
      width: (json['width'] as num?)?.toInt() ?? 512,
      height: (json['height'] as num?)?.toInt() ?? 512,
      modelId:
          json['modelId'] as String? ?? "1e60896f-3c26-4296-8ecc-53e2afecc132",
    );

Map<String, dynamic> _$GenerationRequestToJson(GenerationRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'width': instance.width,
      'height': instance.height,
      'modelId': instance.modelId,
    };
