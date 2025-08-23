import 'package:json_annotation/json_annotation.dart';

part 'generation_job_response.g.dart';

@JsonSerializable()
class GenerationJobResponse {
  @JsonKey(name: 'sdGenerationJob')
  final SdGenerationJob sdGenerationJob;

  const GenerationJobResponse({required this.sdGenerationJob});

  factory GenerationJobResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerationJobResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationJobResponseToJson(this);

  // 便利なゲッター
  String get generationId => sdGenerationJob.generationId;
  int get apiCreditCost => sdGenerationJob.apiCreditCost;

  GenerationJobResponse copyWith({SdGenerationJob? sdGenerationJob}) {
    return GenerationJobResponse(
      sdGenerationJob: sdGenerationJob ?? this.sdGenerationJob,
    );
  }
}

@JsonSerializable()
class SdGenerationJob {
  final String generationId;
  final int apiCreditCost;

  const SdGenerationJob({
    required this.generationId,
    required this.apiCreditCost,
  });

  factory SdGenerationJob.fromJson(Map<String, dynamic> json) =>
      _$SdGenerationJobFromJson(json);

  Map<String, dynamic> toJson() => _$SdGenerationJobToJson(this);

  SdGenerationJob copyWith({String? generationId, int? apiCreditCost}) {
    return SdGenerationJob(
      generationId: generationId ?? this.generationId,
      apiCreditCost: apiCreditCost ?? this.apiCreditCost,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationJobResponse &&
        other.generationId == generationId &&
        other.apiCreditCost == apiCreditCost;
  }

  @override
  int get hashCode {
    return generationId.hashCode ^ apiCreditCost.hashCode;
  }

  @override
  String toString() {
    return 'GenerationJobResponse(generationId: $generationId, apiCreditCost: $apiCreditCost)';
  }
}
