import 'package:json_annotation/json_annotation.dart';

part 'canvas_init_request.g.dart';

/// Canvas初期化リクエストモデル
@JsonSerializable()
class CanvasInitRequest {
  const CanvasInitRequest({
    required this.initExtension,
    required this.maskExtension,
  });

  /// 元画像の拡張子
  final String initExtension;
  
  /// マスク画像の拡張子
  final String maskExtension;

  factory CanvasInitRequest.fromJson(Map<String, dynamic> json) =>
      _$CanvasInitRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasInitRequestToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasInitRequest &&
        other.initExtension == initExtension &&
        other.maskExtension == maskExtension;
  }

  @override
  int get hashCode => Object.hash(initExtension, maskExtension);

  @override
  String toString() {
    return 'CanvasInitRequest(initExtension: $initExtension, maskExtension: $maskExtension)';
  }
}