/// 位置情報モデル
/// 
/// GPS座標と精度、タイムスタンプを含む位置情報を表現するデータモデル
class Position {
  const Position({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  /// コピーコンストラクタ
  Position copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// JSONからPositionオブジェクトを作成
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// PositionオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp;
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracy,
        timestamp,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'Position(latitude: $latitude, longitude: $longitude, accuracy: $accuracy, timestamp: $timestamp)';
  }
}