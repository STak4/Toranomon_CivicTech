import 'package:json_annotation/json_annotation.dart';

part 'generated_image.g.dart';

enum ImageStatus {
  pending,
  processing,
  completed,
  failed,
}

@JsonSerializable()
class GeneratedImage {
  final String id;
  final String url;
  final String prompt;
  final DateTime createdAt;
  final ImageStatus status;

  const GeneratedImage({
    required this.id,
    required this.url,
    required this.prompt,
    required this.createdAt,
    this.status = ImageStatus.completed,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) =>
      _$GeneratedImageFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedImageToJson(this);

  GeneratedImage copyWith({
    String? id,
    String? url,
    String? prompt,
    DateTime? createdAt,
    ImageStatus? status,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      url: url ?? this.url,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedImage &&
        other.id == id &&
        other.url == url &&
        other.prompt == prompt &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        url.hashCode ^
        prompt.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'GeneratedImage(id: $id, url: $url, prompt: $prompt, createdAt: $createdAt, status: $status)';
  }
}