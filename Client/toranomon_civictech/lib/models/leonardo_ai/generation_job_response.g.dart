// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_job_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationJobResponse _$GenerationJobResponseFromJson(
  Map<String, dynamic> json,
) => GenerationJobResponse(
  sdGenerationJob: SdGenerationJob.fromJson(
    json['sdGenerationJob'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$GenerationJobResponseToJson(
  GenerationJobResponse instance,
) => <String, dynamic>{'sdGenerationJob': instance.sdGenerationJob};

SdGenerationJob _$SdGenerationJobFromJson(Map<String, dynamic> json) =>
    SdGenerationJob(
      generationId: json['generationId'] as String,
      apiCreditCost: (json['apiCreditCost'] as num).toInt(),
    );

Map<String, dynamic> _$SdGenerationJobToJson(SdGenerationJob instance) =>
    <String, dynamic>{
      'generationId': instance.generationId,
      'apiCreditCost': instance.apiCreditCost,
    };
