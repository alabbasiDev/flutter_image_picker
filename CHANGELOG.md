# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-02-01

### Added
- Initial release of flutter_image_picker
- Cross-platform support for Android, iOS, Web, macOS, Windows, and Linux
- `FlutterImagePicker` class with unified API
- `pickImage()` - Pick a single image with configurable options
- `pickFromGallery()` - Convenience method for gallery selection
- `pickFromCamera()` - Convenience method for camera capture
- `pickMultipleImages()` - Pick multiple images at once
- `isCameraAvailable()` - Check camera availability
- `isGalleryAvailable()` - Check gallery availability
- `PickedImage` model with bytes, name, mimeType, and path
- `PickerOptions` for configuring picker behavior
- `ImagePickerWidget` - Ready-to-use widget with customizable UI
- Platform-specific implementations using conditional imports
- Comprehensive documentation and examples
