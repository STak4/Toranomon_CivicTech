import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーモデル
/// 
/// アプリケーション内のユーザー情報を表現するデータモデル
class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// コピーコンストラクタ
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  /// JSONからUserオブジェクトを作成
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// UserオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        photoURL,
        createdAt,
        updatedAt,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, photoURL: $photoURL, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}