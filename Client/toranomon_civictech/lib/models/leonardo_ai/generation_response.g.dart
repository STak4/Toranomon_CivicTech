// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedImageData _$GeneratedImageDataFromJson(Map<String, dynamic> json) =>
    GeneratedImageData(
      id: json['id'] as String,
      url: json['url'] as String,
      nsfw: json['nsfw'] as String?,
      likelyGender: json['likelyGender'] as String?,
    );

Map<String, dynamic> _$GeneratedImageDataToJson(GeneratedImageData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'nsfw': instance.nsfw,
      'likelyGender': instance.likelyGender,
    };

GenerationResponse _$GenerationResponseFromJson(Map<String, dynamic> json) =>
    GenerationResponse(
      generationId: json['generationId'] as String,
      generatedImages: (json['generatedImages'] as List<dynamic>)
          .map((e) => GeneratedImageData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GenerationResponseToJson(GenerationResponse instance) =>
    <String, dynamic>{
      'generationId': instance.generationId,
      'generatedImages': instance.generatedImages,
    };
