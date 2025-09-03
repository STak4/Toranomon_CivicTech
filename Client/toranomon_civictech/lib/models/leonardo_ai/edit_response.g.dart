// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditResponse _$EditResponseFromJson(Map<String, dynamic> json) => EditResponse(
  generationId: json['generationId'] as String,
  generatedImages: (json['generatedImages'] as List<dynamic>)
      .map((e) => GeneratedImageData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EditResponseToJson(EditResponse instance) =>
    <String, dynamic>{
      'generationId': instance.generationId,
      'generatedImages': instance.generatedImages,
    };
