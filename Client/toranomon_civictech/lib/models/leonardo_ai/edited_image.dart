import 'package:json_annotation/json_annotation.dart';
import 'generated_image.dart';

part 'edited_image.g.dart';

@JsonSerializable()
class EditedImage {
  final String id;
  final String originalImagePath;
  final String editedImageUrl;
  final String editPrompt;
  final DateTime createdAt;
  final ImageStatus status;

  const EditedImage({
    required this.id,
    required this.originalImagePath,
    required this.editedImageUrl,
    required this.editPrompt,
    required this.createdAt,
    this.status = ImageStatus.completed,
  });

  factory EditedImage.fromJson(Map<String, dynamic> json) =>
      _$EditedImageFromJson(json);

  Map<String, dynamic> toJson() => _$EditedImageToJson(this);

  EditedImage copyWith({
    String? id,
    String? originalImagePath,
    String? editedImageUrl,
    String? editPrompt,
    DateTime? createdAt,
    ImageStatus? status,
  }) {
    return EditedImage(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      editedImageUrl: editedImageUrl ?? this.editedImageUrl,
      editPrompt: editPrompt ?? this.editPrompt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditedImage &&
        other.id == id &&
        other.originalImagePath == originalImagePath &&
        other.editedImageUrl == editedImageUrl &&
        other.editPrompt == editPrompt &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        originalImagePath.hashCode ^
        editedImageUrl.hashCode ^
        editPrompt.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'EditedImage(id: $id, originalImagePath: $originalImagePath, editedImageUrl: $editedImageUrl, editPrompt: $editPrompt, createdAt: $createdAt, status: $status)';
  }
}