import 'package:json_annotation/json_annotation.dart';

part 'edit_request.g.dart';

@JsonSerializable()
class EditRequest {
  final String prompt;
  final String imageId;
  final int numImages;
  final double strength;

  const EditRequest({
    required this.prompt,
    required this.imageId,
    this.numImages = 1,
    this.strength = 0.7,
  });

  factory EditRequest.fromJson(Map<String, dynamic> json) =>
      _$EditRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EditRequestToJson(this);

  EditRequest copyWith({
    String? prompt,
    String? imageId,
    int? numImages,
    double? strength,
  }) {
    return EditRequest(
      prompt: prompt ?? this.prompt,
      imageId: imageId ?? this.imageId,
      numImages: numImages ?? this.numImages,
      strength: strength ?? this.strength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditRequest &&
        other.prompt == prompt &&
        other.imageId == imageId &&
        other.numImages == numImages &&
        other.strength == strength;
  }

  @override
  int get hashCode {
    return prompt.hashCode ^
        imageId.hashCode ^
        numImages.hashCode ^
        strength.hashCode;
  }

  @override
  String toString() {
    return 'EditRequest(prompt: $prompt, imageId: $imageId, numImages: $numImages, strength: $strength)';
  }
}