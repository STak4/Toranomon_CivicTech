// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditRequest _$EditRequestFromJson(Map<String, dynamic> json) => EditRequest(
  prompt: json['prompt'] as String,
  imageId: json['imageId'] as String,
  numImages: (json['numImages'] as num?)?.toInt() ?? 1,
  strength: (json['strength'] as num?)?.toDouble() ?? 0.7,
);

Map<String, dynamic> _$EditRequestToJson(EditRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'imageId': instance.imageId,
      'numImages': instance.numImages,
      'strength': instance.strength,
    };
