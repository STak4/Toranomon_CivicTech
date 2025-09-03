// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationResult _$GenerationResultFromJson(Map<String, dynamic> json) =>
    GenerationResult(
      generationId: json['generationId'] as String,
      prompt: json['prompt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      images: (json['images'] as List<dynamic>)
          .map((e) => GeneratedImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GenerationResultToJson(GenerationResult instance) =>
    <String, dynamic>{
      'generationId': instance.generationId,
      'prompt': instance.prompt,
      'createdAt': instance.createdAt.toIso8601String(),
      'images': instance.images,
    };
