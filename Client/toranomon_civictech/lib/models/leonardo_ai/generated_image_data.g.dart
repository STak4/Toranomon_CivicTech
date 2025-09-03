// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_image_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedImageData _$GeneratedImageDataFromJson(Map<String, dynamic> json) =>
    GeneratedImageData(
      id: json['id'] as String,
      url: json['url'] as String,
      nsfw: json['nsfw'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
      motionMP4URL: json['motionMP4URL'] as String?,
      generatedImageVariationGenerics:
          json['generated_image_variation_generics'] as List<dynamic>? ??
          const [],
    );

Map<String, dynamic> _$GeneratedImageDataToJson(GeneratedImageData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'nsfw': instance.nsfw,
      'likeCount': instance.likeCount,
      'motionMP4URL': instance.motionMP4URL,
      'generated_image_variation_generics':
          instance.generatedImageVariationGenerics,
    };
