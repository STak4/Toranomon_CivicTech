import 'package:json_annotation/json_annotation.dart';

part 'canvas_init_response.g.dart';

/// Canvas初期化レスポンスモデル
@JsonSerializable()
class CanvasInitResponse {
  const CanvasInitResponse({
    required this.initImageId,
    required this.masksImageId,
    required this.initUrl,
    required this.masksUrl,
    required this.initFields,
    required this.masksFields,
    required this.initKey,
    required this.masksKey,
  });

  /// 元画像のID
  final String initImageId;
  
  /// マスク画像のID
  final String masksImageId;
  
  /// 元画像アップロード用プリサインドURL
  final String initUrl;
  
  /// マスク画像アップロード用プリサインドURL
  final String masksUrl;
  
  /// 元画像アップロード用フィールド
  final Map<String, dynamic> initFields;
  
  /// マスク画像アップロード用フィールド
  final Map<String, dynamic> masksFields;
  
  /// 元画像のキー
  final String initKey;
  
  /// マスク画像のキー
  final String masksKey;

  factory CanvasInitResponse.fromJson(Map<String, dynamic> json) =>
      _$CanvasInitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasInitResponseToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasInitResponse &&
        other.initImageId == initImageId &&
        other.masksImageId == masksImageId &&
        other.initUrl == initUrl &&
        other.masksUrl == masksUrl &&
        other.initKey == initKey &&
        other.masksKey == masksKey;
  }

  @override
  int get hashCode => Object.hash(
    initImageId, masksImageId, initUrl, masksUrl, initKey, masksKey
  );

  @override
  String toString() {
    return 'CanvasInitResponse(initImageId: $initImageId, masksImageId: $masksImageId, initUrl: $initUrl, masksUrl: $masksUrl, initKey: $initKey, masksKey: $masksKey)';
  }
}