import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'image_picker_platform.dart';
import 'models/image_source.dart';
import 'models/picked_image.dart';
import 'models/picker_options.dart';
import 'platforms/image_picker_factory.dart';
import 'widgets/camera_capture_widget.dart';

/// A cross-platform image picker for Flutter.
///
/// This class provides a unified API for picking images from the gallery
/// or camera across all Flutter platforms.
///
/// Example usage:
/// ```dart
/// final imagePicker = FlutterImagePicker();
///
/// // Pick a single image from gallery
/// final image = await imagePicker.pickImage();
///
/// // Pick from camera (requires BuildContext on mobile)
/// final photo = await imagePicker.pickFromCamera(context);
///
/// // Pick multiple images
/// final images = await imagePicker.pickMultipleImages();
/// ```
class FlutterImagePicker {
  /// Creates a [FlutterImagePicker] instance.
  ///
  /// Optionally, you can provide a custom [platform] implementation for testing.
  FlutterImagePicker({ImagePickerPlatform? platform})
    : _platform = platform ?? ImagePickerFactory.createPlatform();

  final ImagePickerPlatform _platform;

  /// Picks a single image from the specified source.
  ///
  /// [options] configures the picker behavior. If not provided, defaults to
  /// picking from the gallery.
  ///
  /// **Note:** For camera on mobile platforms, use [pickFromCamera] with a
  /// [BuildContext] to get the full camera preview experience.
  ///
  /// Returns a [PickedImage] if an image was selected, or `null` if the user
  /// cancelled the picker.
  Future<PickedImage?> pickImage({
    PickerOptions options = const PickerOptions(),
  }) {
    return _platform.pickImage(options.copyWith(allowMultiple: false));
  }

  /// Picks an image from the gallery.
  ///
  /// This is a convenience method equivalent to calling [pickImage] with
  /// `source: ImageSource.gallery`.
  Future<PickedImage?> pickFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return _platform.pickImage(
      PickerOptions(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      ),
    );
  }

  /// Captures an image from the camera with a live preview.
  ///
  /// On mobile platforms (Android, iOS), this opens a full-screen camera
  /// preview where the user can capture a photo.
  ///
  /// On web, this uses the HTML5 file input with capture attribute.
  ///
  /// [context] is required for mobile platforms to push the camera screen.
  ///
  /// Returns a [PickedImage] if a photo was captured, or `null` if cancelled.
  Future<PickedImage?> pickFromCamera(
    BuildContext context, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final options = PickerOptions(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
    );
    // On mobile, use CameraCapture for live preview
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return CameraCapture.capture(context, options: options);
    }
    // On web, use the platform implementation
    return _platform.pickImage(options);
  }

  /// Picks multiple images from the gallery.
  ///
  /// [options] configures the picker behavior. Note that [allowMultiple] is
  /// always set to `true` for this method.
  ///
  /// Returns a list of [PickedImage] objects. The list will be empty if the
  /// user cancelled the picker.
  Future<List<PickedImage>> pickMultipleImages({
    int maxImages = 10,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return _platform.pickMultipleImages(
      PickerOptions(
        source: ImageSource.gallery,
        allowMultiple: true,
        maxImages: maxImages,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      ),
    );
  }

  /// Returns `true` if the camera is available on this platform.
  Future<bool> isCameraAvailable() => _platform.isCameraAvailable();

  /// Returns `true` if the gallery is available on this platform.
  Future<bool> isGalleryAvailable() => _platform.isGalleryAvailable();
}
