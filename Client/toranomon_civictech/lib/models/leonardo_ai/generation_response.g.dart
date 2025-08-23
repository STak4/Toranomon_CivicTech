// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationResponse _$GenerationResponseFromJson(Map<String, dynamic> json) =>
    GenerationResponse(
      generationsByPk: json['generations_by_pk'] == null
          ? null
          : GenerationData.fromJson(
              json['generations_by_pk'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$GenerationResponseToJson(GenerationResponse instance) =>
    <String, dynamic>{'generations_by_pk': instance.generationsByPk};
