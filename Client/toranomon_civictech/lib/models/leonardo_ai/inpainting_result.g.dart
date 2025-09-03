// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inpainting_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InpaintingResult _$InpaintingResultFromJson(Map<String, dynamic> json) =>
    InpaintingResult(
      id: json['id'] as String,
      originalImagePath: json['originalImagePath'] as String,
      resultImageUrl: json['resultImageUrl'] as String,
      prompt: json['prompt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status:
          $enumDecodeNullable(_$InpaintingStatusEnumMap, json['status']) ??
          InpaintingStatus.completed,
      resultImageUrls:
          (json['resultImageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$InpaintingResultToJson(InpaintingResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalImagePath': instance.originalImagePath,
      'resultImageUrl': instance.resultImageUrl,
      'resultImageUrls': instance.resultImageUrls,
      'prompt': instance.prompt,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$InpaintingStatusEnumMap[instance.status]!,
    };

const _$InpaintingStatusEnumMap = {
  InpaintingStatus.pending: 'pending',
  InpaintingStatus.uploading: 'uploading',
  InpaintingStatus.processing: 'processing',
  InpaintingStatus.completed: 'completed',
  InpaintingStatus.failed: 'failed',
};
