import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../image_picker_platform.dart';
import '../models/image_source.dart';
import '../models/picked_image.dart';
import '../models/picker_options.dart';

/// Creates the IO (mobile/desktop) implementation of [ImagePickerPlatform].
ImagePickerPlatform createImagePicker() => ImagePickerIO();

/// IO implementation for mobile (Android, iOS) and desktop (macOS, Windows, Linux).
///
/// **Note:** For camera functionality on mobile, use the [CameraCapture] widget
/// which provides a live camera preview. This is handled automatically by
/// [FlutterImagePicker.pickFromCamera].
class ImagePickerIO implements ImagePickerPlatform {
  @override
  Future<PickedImage?> pickImage(PickerOptions options) async {
    if (options.source == ImageSource.camera) {
      // Camera is handled by CameraCapture widget in FlutterImagePicker
      // This fallback is for direct platform access
      throw UnsupportedError(
        'For camera on mobile, use FlutterImagePicker.pickFromCamera(context) '
        'or CameraCapture.capture(context) which provides a live preview.',
      );
    }
    return _pickFromGallery(options);
  }

  @override
  Future<List<PickedImage>> pickMultipleImages(PickerOptions options) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return [];
    }
    final images = <PickedImage>[];
    final filesToProcess = result.files.take(options.maxImages);
    for (final file in filesToProcess) {
      final pickedImage = await _processFileResult(file, options);
      if (pickedImage != null) {
        images.add(pickedImage);
      }
    }
    return images;
  }

  @override
  Future<bool> isCameraAvailable() async {
    // Camera is available on mobile platforms
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<bool> isGalleryAvailable() async {
    // Gallery/file access is always available
    return true;
  }

  Future<PickedImage?> _pickFromGallery(PickerOptions options) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return _processFileResult(result.files.first, options);
  }

  Future<PickedImage?> _processFileResult(
    PlatformFile file,
    PickerOptions options,
  ) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      final ioFile = File(file.path!);
      bytes = await ioFile.readAsBytes();
    }
    if (bytes == null) {
      return null;
    }
    final processedBytes = await _processImage(bytes, options);
    return PickedImage(
      bytes: processedBytes,
      name: file.name,
      mimeType: _getMimeType(file.extension),
      path: file.path,
    );
  }

  Future<Uint8List> _processImage(
    Uint8List bytes,
    PickerOptions options,
  ) async {
    // Basic implementation - returns original bytes
    // For image processing (resize, quality), you would use an image processing package
    return bytes;
  }

  String? _getMimeType(String? extension) {
    if (extension == null) return null;
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/$ext';
    }
  }
}
