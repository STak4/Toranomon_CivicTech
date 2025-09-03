import 'package:json_annotation/json_annotation.dart';

part 'generated_image_data.g.dart';

@JsonSerializable()
class GeneratedImageData {
  final String id;
  final String url;
  final bool nsfw;
  final int likeCount;
  final String? motionMP4URL;
  @JsonKey(name: 'generated_image_variation_generics')
  final List<dynamic> generatedImageVariationGenerics;

  const GeneratedImageData({
    required this.id,
    required this.url,
    required this.nsfw,
    required this.likeCount,
    this.motionMP4URL,
    this.generatedImageVariationGenerics = const [],
  });

  factory GeneratedImageData.fromJson(Map<String, dynamic> json) =>
      _$GeneratedImageDataFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedImageDataToJson(this);

  GeneratedImageData copyWith({
    String? id,
    String? url,
    bool? nsfw,
    int? likeCount,
    String? motionMP4URL,
    List<dynamic>? generatedImageVariationGenerics,
  }) {
    return GeneratedImageData(
      id: id ?? this.id,
      url: url ?? this.url,
      nsfw: nsfw ?? this.nsfw,
      likeCount: likeCount ?? this.likeCount,
      motionMP4URL: motionMP4URL ?? this.motionMP4URL,
      generatedImageVariationGenerics:
          generatedImageVariationGenerics ??
          this.generatedImageVariationGenerics,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedImageData &&
        other.id == id &&
        other.url == url &&
        other.nsfw == nsfw &&
        other.likeCount == likeCount &&
        other.motionMP4URL == motionMP4URL;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        url.hashCode ^
        nsfw.hashCode ^
        likeCount.hashCode ^
        motionMP4URL.hashCode;
  }

  @override
  String toString() {
    return 'GeneratedImageData(id: $id, url: $url, nsfw: $nsfw, likeCount: $likeCount, motionMP4URL: $motionMP4URL)';
  }
}
