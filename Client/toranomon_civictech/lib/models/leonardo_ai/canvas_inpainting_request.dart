import 'package:json_annotation/json_annotation.dart';

part 'canvas_inpainting_request.g.dart';

/// Canvas Inpaintingリクエストモデル
@JsonSerializable()
class CanvasInpaintingRequest {
  const CanvasInpaintingRequest({
    required this.prompt,
    required this.canvasRequest,
    required this.canvasRequestType,
    required this.canvasInitId,
    required this.canvasMaskId,
    this.modelId = '1e60896f-3c26-4296-8ecc-53e2afecc132',
  });

  /// 生成プロンプト
  final String prompt;

  /// Canvasリクエストフラグ
  final bool canvasRequest;

  /// Canvasリクエストタイプ（"INPAINT"）
  final String canvasRequestType;

  /// Canvas初期化画像ID
  final String canvasInitId;

  /// Canvasマスク画像ID
  final String canvasMaskId;

  /// 使用するモデルID
  final String modelId;

  factory CanvasInpaintingRequest.fromJson(Map<String, dynamic> json) =>
      _$CanvasInpaintingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasInpaintingRequestToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasInpaintingRequest &&
        other.prompt == prompt &&
        other.canvasRequest == canvasRequest &&
        other.canvasRequestType == canvasRequestType &&
        other.canvasInitId == canvasInitId &&
        other.canvasMaskId == canvasMaskId &&
        other.modelId == modelId;
  }

  @override
  int get hashCode => Object.hash(
    prompt,
    canvasRequest,
    canvasRequestType,
    canvasInitId,
    canvasMaskId,
    modelId,
  );

  @override
  String toString() {
    return 'CanvasInpaintingRequest(prompt: $prompt, canvasRequest: $canvasRequest, canvasRequestType: $canvasRequestType, canvasInitId: $canvasInitId, canvasMaskId: $canvasMaskId, modelId: $modelId)';
  }
}
