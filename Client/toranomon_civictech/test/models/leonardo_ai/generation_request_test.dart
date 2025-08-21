import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_models.dart';

void main() {
  group('GenerationRequest', () {
    test('should create GenerationRequest from JSON', () {
      // Arrange
      final json = {
        'prompt': 'A beautiful landscape',
        'numImages': 2,
        'width': 1024,
        'height': 768,
        'modelId': 'LEONARDO_DIFFUSION_XL',
      };

      // Act
      final request = GenerationRequest.fromJson(json);

      // Assert
      expect(request.prompt, 'A beautiful landscape');
      expect(request.numImages, 2);
      expect(request.width, 1024);
      expect(request.height, 768);
      expect(request.modelId, 'LEONARDO_DIFFUSION_XL');
    });

    test('should convert GenerationRequest to JSON', () {
      // Arrange
      const request = GenerationRequest(
        prompt: 'A beautiful landscape',
        numImages: 2,
        width: 1024,
        height: 768,
        modelId: 'LEONARDO_DIFFUSION_XL',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['prompt'], 'A beautiful landscape');
      expect(json['numImages'], 2);
      expect(json['width'], 1024);
      expect(json['height'], 768);
      expect(json['modelId'], 'LEONARDO_DIFFUSION_XL');
    });

    test('should use default values when not provided', () {
      // Arrange & Act
      const request = GenerationRequest(prompt: 'A beautiful landscape');

      // Assert
      expect(request.prompt, 'A beautiful landscape');
      expect(request.numImages, 1);
      expect(request.width, 512);
      expect(request.height, 512);
      expect(request.modelId, 'LEONARDO_DIFFUSION_XL');
    });

    test('should support copyWith functionality', () {
      // Arrange
      const original = GenerationRequest(
        prompt: 'A beautiful landscape',
        numImages: 1,
        width: 512,
        height: 512,
      );

      // Act
      final updated = original.copyWith(numImages: 2, width: 1024, height: 768);

      // Assert
      expect(updated.prompt, original.prompt);
      expect(updated.modelId, original.modelId);
      expect(updated.numImages, 2);
      expect(updated.width, 1024);
      expect(updated.height, 768);
    });
  });
}
