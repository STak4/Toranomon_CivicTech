// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_inpainting_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasInpaintingRequest _$CanvasInpaintingRequestFromJson(
  Map<String, dynamic> json,
) => CanvasInpaintingRequest(
  prompt: json['prompt'] as String,
  canvasRequest: json['canvasRequest'] as bool,
  canvasRequestType: json['canvasRequestType'] as String,
  canvasInitId: json['canvasInitId'] as String,
  canvasMaskId: json['canvasMaskId'] as String,
  modelId: json['modelId'] as String? ?? '1e60896f-3c26-4296-8ecc-53e2afecc132',
);

Map<String, dynamic> _$CanvasInpaintingRequestToJson(
  CanvasInpaintingRequest instance,
) => <String, dynamic>{
  'prompt': instance.prompt,
  'canvasRequest': instance.canvasRequest,
  'canvasRequestType': instance.canvasRequestType,
  'canvasInitId': instance.canvasInitId,
  'canvasMaskId': instance.canvasMaskId,
  'modelId': instance.modelId,
};
