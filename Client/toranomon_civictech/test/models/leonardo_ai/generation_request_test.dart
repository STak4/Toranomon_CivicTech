import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_models.dart';

void main() {
  group('GenerationRequest', () {
    test('should create GenerationRequest from JSON', () {
      // Arrange
      final json = {
        'prompt': 'A beautiful landscape',
        'width': 1024,
        'height': 768,
        'modelId': '1e60896f-3c26-4296-8ecc-53e2afecc132',
      };

      // Act
      final request = GenerationRequest.fromJson(json);

      // Assert
      expect(request.prompt, 'A beautiful landscape');
      expect(request.width, 1024);
      expect(request.height, 768);
      expect(request.modelId, '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3');
    });

    test('should convert GenerationRequest to JSON', () {
      // Arrange
      const request = GenerationRequest(
        prompt: 'A beautiful landscape',
        width: 1024,
        height: 768,
        modelId: '1e60896f-3c26-4296-8ecc-53e2afecc132',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['prompt'], 'A beautiful landscape');
      expect(json['width'], 1024);
      expect(json['height'], 768);
      expect(json['modelId'], '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3');
    });

    test('should use default values when not provided', () {
      // Arrange & Act
      const request = GenerationRequest(prompt: 'A beautiful landscape');

      // Assert
      expect(request.prompt, 'A beautiful landscape');
      expect(request.width, 512);
      expect(request.height, 512);
      expect(request.modelId, '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3');
    });

    test('should support copyWith functionality', () {
      // Arrange
      const original = GenerationRequest(
        prompt: 'A beautiful landscape',
        width: 512,
        height: 512,
      );

      // Act
      final updated = original.copyWith(width: 1024, height: 768);

      // Assert
      expect(updated.prompt, original.prompt);
      expect(updated.modelId, original.modelId);
      expect(updated.width, 1024);
      expect(updated.height, 768);
    });
  });
}
