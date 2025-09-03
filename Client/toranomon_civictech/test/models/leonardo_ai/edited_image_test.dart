import 'package:flutter_test/flutter_test.dart';
import 'package:toranomon_civictech/models/leonardo_ai/leonardo_ai_models.dart';

void main() {
  group('EditedImage', () {
    test('should create EditedImage from JSON', () {
      // Arrange
      final json = {
        'id': 'edit-id-123',
        'originalImagePath': '/path/to/original.jpg',
        'editedImageUrl': 'https://example.com/edited.jpg',
        'editPrompt': 'Make it more colorful',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'status': 'completed',
      };

      // Act
      final editedImage = EditedImage.fromJson(json);

      // Assert
      expect(editedImage.id, 'edit-id-123');
      expect(editedImage.originalImagePath, '/path/to/original.jpg');
      expect(editedImage.editedImageUrl, 'https://example.com/edited.jpg');
      expect(editedImage.editPrompt, 'Make it more colorful');
      expect(editedImage.status, ImageStatus.completed);
      expect(editedImage.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('should convert EditedImage to JSON', () {
      // Arrange
      final editedImage = EditedImage(
        id: 'edit-id-123',
        originalImagePath: '/path/to/original.jpg',
        editedImageUrl: 'https://example.com/edited.jpg',
        editPrompt: 'Make it more colorful',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        status: ImageStatus.completed,
      );

      // Act
      final json = editedImage.toJson();

      // Assert
      expect(json['id'], 'edit-id-123');
      expect(json['originalImagePath'], '/path/to/original.jpg');
      expect(json['editedImageUrl'], 'https://example.com/edited.jpg');
      expect(json['editPrompt'], 'Make it more colorful');
      expect(json['status'], 'completed');
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
    });

    test('should use default status when not provided', () {
      // Arrange
      final editedImage = EditedImage(
        id: 'edit-id-123',
        originalImagePath: '/path/to/original.jpg',
        editedImageUrl: 'https://example.com/edited.jpg',
        editPrompt: 'Make it more colorful',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(editedImage.status, ImageStatus.completed);
    });

    test('should support copyWith functionality', () {
      // Arrange
      final now = DateTime.now();
      final original = EditedImage(
        id: 'edit-id-123',
        originalImagePath: '/path/to/original.jpg',
        editedImageUrl: 'https://example.com/edited.jpg',
        editPrompt: 'Make it more colorful',
        createdAt: now,
        status: ImageStatus.processing,
      );

      // Act
      final updated = original.copyWith(status: ImageStatus.completed);

      // Assert
      expect(updated.id, original.id);
      expect(updated.originalImagePath, original.originalImagePath);
      expect(updated.editedImageUrl, original.editedImageUrl);
      expect(updated.editPrompt, original.editPrompt);
      expect(updated.createdAt, original.createdAt);
      expect(updated.status, ImageStatus.completed);
    });
  });
}
