import 'dart:typed_data';

/// マーカーアイコンデータモデル
/// 
/// Advanced Markerで使用するアイコンデータを表現するデータモデル
class MarkerIconData {
  const MarkerIconData({
    required this.postId,
    this.imageUrl,
    this.croppedIconBytes,
  });

  final String postId;
  final String? imageUrl;
  final Uint8List? croppedIconBytes;

  /// コピーコンストラクタ
  MarkerIconData copyWith({
    String? postId,
    String? imageUrl,
    Uint8List? croppedIconBytes,
  }) {
    return MarkerIconData(
      postId: postId ?? this.postId,
      imageUrl: imageUrl ?? this.imageUrl,
      croppedIconBytes: croppedIconBytes ?? this.croppedIconBytes,
    );
  }

  /// アイコンが利用可能かどうかを判定
  bool get hasIcon => croppedIconBytes != null;

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkerIconData &&
        other.postId == postId &&
        other.imageUrl == imageUrl &&
        _uint8ListEquals(other.croppedIconBytes, croppedIconBytes);
  }

  /// ハッシュコードの生成
  @override
  int get hashCode => Object.hash(
        postId,
        imageUrl,
        croppedIconBytes?.hashCode,
      );

  /// 文字列表現
  @override
  String toString() {
    return 'MarkerIconData(postId: $postId, imageUrl: $imageUrl, hasIcon: $hasIcon)';
  }

  /// Uint8Listの等価性比較のヘルパーメソッド
  bool _uint8ListEquals(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}