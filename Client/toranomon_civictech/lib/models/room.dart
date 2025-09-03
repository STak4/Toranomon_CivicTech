import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ルームモデル
/// 
/// 地図情報を共有するためのルーム情報を表現するデータモデル
class Room {
  const Room({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.postIds,
  });

  final String id;
  final String createdBy;
  final DateTime createdAt;
  final List<String> postIds;

  /// コピーコンストラクタ
  Room copyWith({
    String? id,
    String? createdBy,
    DateTime? createdAt,
    List<String>? postIds,
  }) {
    return Room(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      postIds: postIds ?? this.postIds,
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

  /// JSONからRoomオブジェクトを作成
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: _parseDateTime(json['createdAt']),
      postIds: List<String>.from(json['postIds'] as List),
    );
  }

  /// RoomオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'postIds': postIds,
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room &&
        other.id == id &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        listEquals(other.postIds, postIds);
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        id,
        createdBy,
        createdAt,
        postIds,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'Room(id: $id, createdBy: $createdBy, createdAt: $createdAt, postIds: $postIds)';
  }
}