import 'models/picked_image.dart';
import 'models/picker_options.dart';

/// Abstract interface for platform-specific image picker implementations.
abstract class ImagePickerPlatform {
  /// Picks a single image from the specified source.
  ///
  /// Returns a [PickedImage] if an image was selected, or `null` if the user
  /// cancelled the picker.
  Future<PickedImage?> pickImage(PickerOptions options);

  /// Picks multiple images from the gallery.
  ///
  /// Returns a list of [PickedImage] objects. The list may be empty if the
  /// user cancelled the picker or didn't select any images.
  Future<List<PickedImage>> pickMultipleImages(PickerOptions options);

  /// Returns `true` if the camera is available on this platform.
  Future<bool> isCameraAvailable();

  /// Returns `true` if the gallery is available on this platform.
  Future<bool> isGalleryAvailable();
}
