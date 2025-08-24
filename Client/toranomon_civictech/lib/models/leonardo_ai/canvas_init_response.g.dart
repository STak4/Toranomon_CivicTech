// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_init_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasInitResponse _$CanvasInitResponseFromJson(Map<String, dynamic> json) =>
    CanvasInitResponse(
      initImageId: json['initImageId'] as String,
      masksImageId: json['masksImageId'] as String,
      initUrl: json['initUrl'] as String,
      masksUrl: json['masksUrl'] as String,
      initFields: json['initFields'] as Map<String, dynamic>,
      masksFields: json['masksFields'] as Map<String, dynamic>,
      initKey: json['initKey'] as String,
      masksKey: json['masksKey'] as String,
    );

Map<String, dynamic> _$CanvasInitResponseToJson(CanvasInitResponse instance) =>
    <String, dynamic>{
      'initImageId': instance.initImageId,
      'masksImageId': instance.masksImageId,
      'initUrl': instance.initUrl,
      'masksUrl': instance.masksUrl,
      'initFields': instance.initFields,
      'masksFields': instance.masksFields,
      'initKey': instance.initKey,
      'masksKey': instance.masksKey,
    };
