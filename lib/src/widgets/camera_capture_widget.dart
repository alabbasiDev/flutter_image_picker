import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/picked_image.dart';
import '../models/picker_options.dart';
import '../utils/permissions.dart';

/// A full-screen camera capture widget with live preview.
///
/// This widget provides a camera preview with capture button and
/// camera switching functionality.
///
/// Example usage:
/// ```dart
/// final image = await Navigator.push<PickedImage>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CameraCaptureWidget(
///       options: PickerOptions(preferredCameraDevice: CameraDevice.rear),
///     ),
///   ),
/// );
/// ```
class CameraCaptureWidget extends StatefulWidget {
  /// Creates a [CameraCaptureWidget].
  const CameraCaptureWidget({super.key, this.options = const PickerOptions()});

  /// Configuration options including preferred camera device.
  final PickerOptions options;

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(_cameras[_currentCameraIndex]);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }
      // Find preferred camera based on options
      _currentCameraIndex = _findPreferredCameraIndex();
      await _initializeCameraController(_cameras[_currentCameraIndex]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  int _findPreferredCameraIndex() {
    final preferFront =
        widget.options.preferredCameraDevice == CameraDevice.front;
    final lensDirection = preferFront
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == lensDirection) {
        return i;
      }
    }
    return 0;
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isInitialized = false;
    });
    await _controller?.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCameraController(_cameras[_currentCameraIndex]);
  }

  Future<void> _captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() {
      _isCapturing = true;
    });
    try {
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();
      final pickedImage = PickedImage(
        bytes: bytes,
        name: xFile.name,
        mimeType: _getMimeType(xFile.path),
        path: xFile.path,
      );
      if (mounted) {
        Navigator.of(context).pop(pickedImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }
    if (!_isInitialized) {
      return _buildLoadingView();
    }
    return _buildCameraView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        Center(
          child: AspectRatio(
            aspectRatio: 1 / controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        // Top bar with close and switch buttons
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (_cameras.length > 1)
                    _buildCircleButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
          ),
        ),
        // Bottom bar with capture button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: _buildCaptureButton()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 28,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureImage,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: _isCapturing ? Colors.grey : Colors.white,
            shape: BoxShape.circle,
          ),
          child: _isCapturing
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// A helper class to handle camera capture without using the full widget.
class CameraCapture {
  CameraCapture._();

  /// Captures an image from the camera.
  ///
  /// This opens a full-screen camera preview and returns the captured image.
  /// Automatically handles camera permission requests with user-friendly dialogs.
  ///
  /// Returns `null` if:
  /// - The user cancels the capture
  /// - Permission is denied
  /// - An error occurs
  ///
  /// Set [requestPermission] to `false` to skip automatic permission handling.
  static Future<PickedImage?> capture(
    BuildContext context, {
    PickerOptions options = const PickerOptions(),
    bool requestPermission = true,
  }) async {
    // Check if we're on a supported platform
    if (kIsWeb) {
      throw UnsupportedError(
        'CameraCapture.capture() is not supported on web. '
        'Use the HTML5 file input with capture attribute instead.',
      );
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'Camera is not supported on this platform. '
        'Camera is only available on Android and iOS.',
      );
    }
    // Check/request camera permission
    if (requestPermission) {
      final hasPermission =
          await ImagePickerPermissions.requestCameraWithDialog(context);
      if (!hasPermission) {
        return null;
      }
    }
    if (!context.mounted) return null;
    return Navigator.of(context).push<PickedImage>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureWidget(options: options),
        fullscreenDialog: true,
      ),
    );
  }

  /// Checks if camera capture is available on the current platform.
  static bool isAvailable() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Checks if camera permission is currently granted.
  static Future<bool> hasPermission() =>
      ImagePickerPermissions.hasCameraPermission();

  /// Requests camera permission without showing a dialog.
  ///
  /// For a user-friendly experience with dialogs, use [capture] with
  /// `requestPermission: true` (the default).
  static Future<bool> requestPermission() async {
    final status = await ImagePickerPermissions.requestCameraPermission();
    return status.isGranted;
  }
}
