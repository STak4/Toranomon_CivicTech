// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edited_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditedImage _$EditedImageFromJson(Map<String, dynamic> json) => EditedImage(
  id: json['id'] as String,
  originalImagePath: json['originalImagePath'] as String,
  editedImageUrl: json['editedImageUrl'] as String,
  editPrompt: json['editPrompt'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  status:
      $enumDecodeNullable(_$ImageStatusEnumMap, json['status']) ??
      ImageStatus.completed,
);

Map<String, dynamic> _$EditedImageToJson(EditedImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalImagePath': instance.originalImagePath,
      'editedImageUrl': instance.editedImageUrl,
      'editPrompt': instance.editPrompt,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$ImageStatusEnumMap[instance.status]!,
    };

const _$ImageStatusEnumMap = {
  ImageStatus.pending: 'pending',
  ImageStatus.processing: 'processing',
  ImageStatus.completed: 'completed',
  ImageStatus.failed: 'failed',
};
