import 'dart:typed_data';

import 'package:flutter_image_picker/flutter_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickedImage', () {
    test('creates instance with required parameters', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = PickedImage(bytes: bytes, name: 'test.jpg');
      expect(image.bytes, bytes);
      expect(image.name, 'test.jpg');
      expect(image.mimeType, isNull);
      expect(image.path, isNull);
      expect(image.size, 5);
    });

    test('creates instance with all parameters', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final image = PickedImage(
        bytes: bytes,
        name: 'photo.png',
        mimeType: 'image/png',
        path: '/path/to/photo.png',
      );
      expect(image.bytes, bytes);
      expect(image.name, 'photo.png');
      expect(image.mimeType, 'image/png');
      expect(image.path, '/path/to/photo.png');
      expect(image.size, 3);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = PickedImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'original.jpg',
        mimeType: 'image/jpeg',
      );
      final copied = original.copyWith(name: 'copied.jpg');
      expect(copied.name, 'copied.jpg');
      expect(copied.bytes, original.bytes);
      expect(copied.mimeType, original.mimeType);
    });

    test('equality works correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final image1 = PickedImage(bytes: bytes, name: 'test.jpg');
      final image2 = PickedImage(bytes: bytes, name: 'test.jpg');
      expect(image1, equals(image2));
    });

    test('toString returns formatted string', () {
      final image = PickedImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'test.jpg',
        mimeType: 'image/jpeg',
      );
      expect(image.toString(), contains('PickedImage'));
      expect(image.toString(), contains('test.jpg'));
    });
  });

  group('PickerOptions', () {
    test('creates instance with defaults', () {
      const options = PickerOptions();
      expect(options.source, ImageSource.gallery);
      expect(options.allowMultiple, false);
      expect(options.maxImages, 10);
      expect(options.maxWidth, isNull);
      expect(options.maxHeight, isNull);
      expect(options.imageQuality, isNull);
      expect(options.preferredCameraDevice, CameraDevice.rear);
    });

    test('creates instance with custom values', () {
      const options = PickerOptions(
        source: ImageSource.camera,
        allowMultiple: true,
        maxImages: 5,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      expect(options.source, ImageSource.camera);
      expect(options.allowMultiple, true);
      expect(options.maxImages, 5);
      expect(options.maxWidth, 800);
      expect(options.maxHeight, 600);
      expect(options.imageQuality, 85);
      expect(options.preferredCameraDevice, CameraDevice.front);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = PickerOptions();
      final copied = original.copyWith(source: ImageSource.camera);
      expect(copied.source, ImageSource.camera);
      expect(copied.allowMultiple, original.allowMultiple);
    });

    test('equality works correctly', () {
      const options1 = PickerOptions(source: ImageSource.gallery);
      const options2 = PickerOptions(source: ImageSource.gallery);
      expect(options1, equals(options2));
    });
  });

  group('ImageSource', () {
    test('has gallery and camera values', () {
      expect(ImageSource.values, contains(ImageSource.gallery));
      expect(ImageSource.values, contains(ImageSource.camera));
    });
  });

  group('CameraDevice', () {
    test('has rear and front values', () {
      expect(CameraDevice.values, contains(CameraDevice.rear));
      expect(CameraDevice.values, contains(CameraDevice.front));
    });
  });
}
