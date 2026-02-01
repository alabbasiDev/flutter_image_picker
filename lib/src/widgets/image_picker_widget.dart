import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../image_picker.dart';
import '../models/image_source.dart';
import '../models/picked_image.dart';
import '../models/picker_options.dart';
import 'camera_capture_widget.dart';

/// A customizable image picker widget that provides a complete UI for
/// picking images from gallery or camera.
///
/// Example usage:
/// ```dart
/// ImagePickerWidget(
///   onImagePicked: (image) {
///     print('Selected: ${image.name}');
///   },
///   onMultipleImagesPicked: (images) {
///     print('Selected ${images.length} images');
///   },
/// )
/// ```
class ImagePickerWidget extends StatefulWidget {
  /// Creates an [ImagePickerWidget].
  const ImagePickerWidget({
    super.key,
    this.onImagePicked,
    this.onMultipleImagesPicked,
    this.onError,
    this.options = const PickerOptions(),
    this.showCameraOption = true,
    this.showGalleryOption = true,
    this.allowMultiple = false,
    this.child,
    this.galleryIcon,
    this.cameraIcon,
    this.galleryLabel = 'Gallery',
    this.cameraLabel = 'Camera',
    this.title = 'Select Image Source',
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  /// Callback when a single image is picked.
  final ValueChanged<PickedImage>? onImagePicked;

  /// Callback when multiple images are picked.
  final ValueChanged<List<PickedImage>>? onMultipleImagesPicked;

  /// Callback when an error occurs.
  final ValueChanged<String>? onError;

  /// Configuration options for the picker.
  final PickerOptions options;

  /// Whether to show the camera option.
  final bool showCameraOption;

  /// Whether to show the gallery option.
  final bool showGalleryOption;

  /// Whether to allow multiple image selection.
  final bool allowMultiple;

  /// Custom child widget. If provided, tapping it will show the picker.
  final Widget? child;

  /// Custom gallery icon.
  final Widget? galleryIcon;

  /// Custom camera icon.
  final Widget? cameraIcon;

  /// Label for the gallery option.
  final String galleryLabel;

  /// Label for the camera option.
  final String cameraLabel;

  /// Title for the bottom sheet.
  final String title;

  /// Border radius for the options.
  final double borderRadius;

  /// Background color for the bottom sheet.
  final Color? backgroundColor;

  /// Color for the icons.
  final Color? iconColor;

  /// Color for the text.
  final Color? textColor;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final FlutterImagePicker _imagePicker = FlutterImagePicker();
  bool _isLoading = false;
  bool _isCameraAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    final isAvailable = await _imagePicker.isCameraAvailable();
    if (mounted) {
      setState(() {
        _isCameraAvailable = isAvailable;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      if (source == ImageSource.camera) {
        await _pickFromCamera();
      } else {
        await _pickFromGallery();
      }
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final options = widget.options.copyWith(source: ImageSource.gallery);
    if (widget.allowMultiple) {
      final images = await _imagePicker.pickMultipleImages(
        maxImages: options.maxImages,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        imageQuality: options.imageQuality,
      );
      if (images.isNotEmpty) {
        widget.onMultipleImagesPicked?.call(images);
      }
    } else {
      final image = await _imagePicker.pickImage(options: options);
      if (image != null) {
        widget.onImagePicked?.call(image);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (!mounted) return;
    // Use CameraCapture for mobile platforms, fallback to web implementation
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final image = await CameraCapture.capture(
        context,
        options: widget.options.copyWith(source: ImageSource.camera),
      );
      if (image != null) {
        widget.onImagePicked?.call(image);
      }
    } else {
      // For web, use the platform implementation
      final options = widget.options.copyWith(source: ImageSource.camera);
      final image = await _imagePicker.pickImage(options: options);
      if (image != null) {
        widget.onImagePicked?.call(image);
      }
    }
  }

  void _showSourcePicker(BuildContext context) {
    final shouldShowCamera = widget.showCameraOption && _isCameraAvailable;
    final shouldShowGallery = widget.showGalleryOption;
    if (!shouldShowCamera && shouldShowGallery) {
      _pickImage(ImageSource.gallery);
      return;
    }
    if (shouldShowCamera && !shouldShowGallery) {
      _pickImage(ImageSource.camera);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(widget.borderRadius),
        ),
      ),
      builder: (context) => _buildBottomSheet(context),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.iconColor ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? theme.colorScheme.onSurface;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (widget.showGalleryOption)
              ListTile(
                leading:
                    widget.galleryIcon ??
                    Icon(Icons.photo_library_rounded, color: iconColor),
                title: Text(
                  widget.galleryLabel,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            if (widget.showCameraOption && _isCameraAvailable)
              ListTile(
                leading:
                    widget.cameraIcon ??
                    Icon(Icons.camera_alt_rounded, color: iconColor),
                title: Text(
                  widget.cameraLabel,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultChild() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.add_photo_alternate_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          const SizedBox(width: 8),
          Text(
            widget.allowMultiple ? 'Select Images' : 'Select Image',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _showSourcePicker(context),
      child: widget.child ?? _buildDefaultChild(),
    );
  }
}
