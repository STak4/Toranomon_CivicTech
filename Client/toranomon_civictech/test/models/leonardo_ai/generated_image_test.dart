import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_models.dart';

void main() {
  group('GeneratedImage', () {
    test('should create GeneratedImage from JSON', () {
      // Arrange
      final json = {
        'id': 'test-id-123',
        'url': 'https://example.com/image.jpg',
        'prompt': 'A beautiful sunset',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'status': 'completed',
      };

      // Act
      final generatedImage = GeneratedImage.fromJson(json);

      // Assert
      expect(generatedImage.id, 'test-id-123');
      expect(generatedImage.url, 'https://example.com/image.jpg');
      expect(generatedImage.prompt, 'A beautiful sunset');
      expect(generatedImage.status, ImageStatus.completed);
      expect(
        generatedImage.createdAt,
        DateTime.parse('2024-01-01T00:00:00.000Z'),
      );
    });

    test('should convert GeneratedImage to JSON', () {
      // Arrange
      final generatedImage = GeneratedImage(
        id: 'test-id-123',
        url: 'https://example.com/image.jpg',
        prompt: 'A beautiful sunset',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        status: ImageStatus.completed,
      );

      // Act
      final json = generatedImage.toJson();

      // Assert
      expect(json['id'], 'test-id-123');
      expect(json['url'], 'https://example.com/image.jpg');
      expect(json['prompt'], 'A beautiful sunset');
      expect(json['status'], 'completed');
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
    });

    test('should use default status when not provided', () {
      // Arrange
      final generatedImage = GeneratedImage(
        id: 'test-id-123',
        url: 'https://example.com/image.jpg',
        prompt: 'A beautiful sunset',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(generatedImage.status, ImageStatus.completed);
    });

    test('should support copyWith functionality', () {
      // Arrange
      final now = DateTime.now();
      final original = GeneratedImage(
        id: 'test-id-123',
        url: 'https://example.com/image.jpg',
        prompt: 'A beautiful sunset',
        createdAt: now,
        status: ImageStatus.pending,
      );

      // Act
      final updated = original.copyWith(status: ImageStatus.completed);

      // Assert
      expect(updated.id, original.id);
      expect(updated.url, original.url);
      expect(updated.prompt, original.prompt);
      expect(updated.createdAt, original.createdAt);
      expect(updated.status, ImageStatus.completed);
    });
  });

  group('ImageStatus', () {
    test('should have all expected values', () {
      expect(ImageStatus.values, [
        ImageStatus.pending,
        ImageStatus.processing,
        ImageStatus.completed,
        ImageStatus.failed,
      ]);
    });
  });
}
