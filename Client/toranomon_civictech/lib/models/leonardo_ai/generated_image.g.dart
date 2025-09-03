// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedImage _$GeneratedImageFromJson(Map<String, dynamic> json) =>
    GeneratedImage(
      id: json['id'] as String,
      url: json['url'] as String,
      prompt: json['prompt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status:
          $enumDecodeNullable(_$ImageStatusEnumMap, json['status']) ??
          ImageStatus.completed,
    );

Map<String, dynamic> _$GeneratedImageToJson(GeneratedImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'prompt': instance.prompt,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$ImageStatusEnumMap[instance.status]!,
    };

const _$ImageStatusEnumMap = {
  ImageStatus.pending: 'pending',
  ImageStatus.processing: 'processing',
  ImageStatus.completed: 'completed',
  ImageStatus.failed: 'failed',
};
