import 'image_source.dart';

/// Configuration options for the image picker.
class PickerOptions {
  /// Creates [PickerOptions] instance.
  const PickerOptions({
    this.source = ImageSource.gallery,
    this.allowMultiple = false,
    this.maxImages = 10,
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.preferredCameraDevice = CameraDevice.rear,
    this.allowedExtensions = const [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
    ],
  });

  /// The source from which to pick images.
  final ImageSource source;

  /// Whether to allow selecting multiple images (gallery only).
  final bool allowMultiple;

  /// Maximum number of images to pick when [allowMultiple] is true.
  final int maxImages;

  /// Maximum width of the picked image(s). Images will be resized if larger.
  final double? maxWidth;

  /// Maximum height of the picked image(s). Images will be resized if larger.
  final double? maxHeight;

  /// The quality of the picked image(s), from 0 to 100.
  final int? imageQuality;

  /// The preferred camera device to use when [source] is [ImageSource.camera].
  final CameraDevice preferredCameraDevice;

  /// List of allowed file extensions for image selection.
  final List<String> allowedExtensions;

  /// Creates a copy of this [PickerOptions] with the given fields replaced.
  PickerOptions copyWith({
    ImageSource? source,
    bool? allowMultiple,
    int? maxImages,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice? preferredCameraDevice,
    List<String>? allowedExtensions,
  }) {
    return PickerOptions(
      source: source ?? this.source,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      maxImages: maxImages ?? this.maxImages,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      imageQuality: imageQuality ?? this.imageQuality,
      preferredCameraDevice:
          preferredCameraDevice ?? this.preferredCameraDevice,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PickerOptions &&
        other.source == source &&
        other.allowMultiple == allowMultiple &&
        other.maxImages == maxImages &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.imageQuality == imageQuality &&
        other.preferredCameraDevice == preferredCameraDevice;
  }

  @override
  int get hashCode => Object.hash(
    source,
    allowMultiple,
    maxImages,
    maxWidth,
    maxHeight,
    imageQuality,
    preferredCameraDevice,
  );
}

/// Specifies the camera device to use.
enum CameraDevice {
  /// The rear-facing camera.
  rear,

  /// The front-facing camera.
  front,
}
