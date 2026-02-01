import '../image_picker_platform.dart';
import 'image_picker_io.dart'
    if (dart.library.js_interop) 'image_picker_web.dart'
    as platform_impl;

/// Factory for creating platform-specific [ImagePickerPlatform] implementations.
class ImagePickerFactory {
  ImagePickerFactory._();

  /// Creates the appropriate platform implementation.
  static ImagePickerPlatform createPlatform() {
    return platform_impl.createImagePicker();
  }
}
