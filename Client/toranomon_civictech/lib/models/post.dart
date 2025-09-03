import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

/// 投稿モデル
/// 
/// 地図上の投稿情報を表現するデータモデル
/// タイトル、説明文、画像、位置情報、Anchor ID、ルームIDを含む
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.anchorId,
    required this.roomId,
    required this.createdAt,
    this.author,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String anchorId;
  final String roomId;
  final DateTime createdAt;
  final User? author;

  /// コピーコンストラクタ
  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? anchorId,
    String? roomId,
    DateTime? createdAt,
    User? author,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      anchorId: anchorId ?? this.anchorId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  /// DateTime フィールドをパース（Timestamp または String に対応）
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is Timestamp) {
      // Firestore Timestamp を DateTime に変換
      return value.toDate();
    } else {
      // フォールバック
      return DateTime.now();
    }
  }

  /// JSONからPostオブジェクトを作成
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      anchorId: json['anchorId'] as String,
      roomId: json['roomId'] as String,
      createdAt: _parseDateTime(json['createdAt']),
      author: json['author'] != null 
          ? User.fromJson(json['author'] as Map<String, dynamic>) 
          : null,
    );
  }

  /// PostオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'anchorId': anchorId,
      'roomId': roomId,
      'createdAt': createdAt.toIso8601String(),
      'author': author?.toJson(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.anchorId == anchorId &&
        other.roomId == roomId &&
        other.createdAt == createdAt &&
        other.author == author;
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        description,
        imageUrl,
        latitude,
        longitude,
        anchorId,
        roomId,
        createdAt,
        author,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, title: $title, description: $description, imageUrl: $imageUrl, latitude: $latitude, longitude: $longitude, anchorId: $anchorId, roomId: $roomId, createdAt: $createdAt, author: $author)';
  }
}

/// 投稿作成リクエストモデル
/// 
/// 新しい投稿を作成する際に使用するデータモデル
class CreatePostRequest {
  const CreatePostRequest({
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.anchorId,
    required this.roomId,
    this.imageFile,
  });

  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String anchorId;
  final String roomId;
  final XFile? imageFile;

  /// コピーコンストラクタ
  CreatePostRequest copyWith({
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? anchorId,
    String? roomId,
    XFile? imageFile,
  }) {
    return CreatePostRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      anchorId: anchorId ?? this.anchorId,
      roomId: roomId ?? this.roomId,
      imageFile: imageFile ?? this.imageFile,
    );
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePostRequest &&
        other.title == title &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.anchorId == anchorId &&
        other.roomId == roomId &&
        other.imageFile == imageFile;
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        title,
        description,
        latitude,
        longitude,
        anchorId,
        roomId,
        imageFile,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'CreatePostRequest(title: $title, description: $description, latitude: $latitude, longitude: $longitude, anchorId: $anchorId, roomId: $roomId, imageFile: $imageFile)';
  }
}