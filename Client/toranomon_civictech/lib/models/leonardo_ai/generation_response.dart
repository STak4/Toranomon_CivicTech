import 'package:json_annotation/json_annotation.dart';

part 'generation_response.g.dart';

@JsonSerializable()
class GeneratedImageData {
  final String id;
  final String url;
  final String? nsfw;
  final String? likelyGender;

  const GeneratedImageData({
    required this.id,
    required this.url,
    this.nsfw,
    this.likelyGender,
  });

  factory GeneratedImageData.fromJson(Map<String, dynamic> json) =>
      _$GeneratedImageDataFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedImageDataToJson(this);

  GeneratedImageData copyWith({
    String? id,
    String? url,
    String? nsfw,
    String? likelyGender,
  }) {
    return GeneratedImageData(
      id: id ?? this.id,
      url: url ?? this.url,
      nsfw: nsfw ?? this.nsfw,
      likelyGender: likelyGender ?? this.likelyGender,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedImageData &&
        other.id == id &&
        other.url == url &&
        other.nsfw == nsfw &&
        other.likelyGender == likelyGender;
  }

  @override
  int get hashCode {
    return id.hashCode ^ url.hashCode ^ nsfw.hashCode ^ likelyGender.hashCode;
  }

  @override
  String toString() {
    return 'GeneratedImageData(id: $id, url: $url, nsfw: $nsfw, likelyGender: $likelyGender)';
  }
}

@JsonSerializable()
class GenerationResponse {
  final String generationId;
  final List<GeneratedImageData> generatedImages;

  const GenerationResponse({
    required this.generationId,
    required this.generatedImages,
  });

  factory GenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationResponseToJson(this);

  GenerationResponse copyWith({
    String? generationId,
    List<GeneratedImageData>? generatedImages,
  }) {
    return GenerationResponse(
      generationId: generationId ?? this.generationId,
      generatedImages: generatedImages ?? this.generatedImages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationResponse &&
        other.generationId == generationId &&
        other.generatedImages == generatedImages;
  }

  @override
  int get hashCode {
    return generationId.hashCode ^ generatedImages.hashCode;
  }

  @override
  String toString() {
    return 'GenerationResponse(generationId: $generationId, generatedImages: $generatedImages)';
  }
}