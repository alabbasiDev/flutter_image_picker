import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../image_picker_platform.dart';
import '../models/image_source.dart';
import '../models/picked_image.dart';
import '../models/picker_options.dart';

/// Creates the Web implementation of [ImagePickerPlatform].
ImagePickerPlatform createImagePicker() => ImagePickerWeb();

/// Web implementation using browser APIs.
class ImagePickerWeb implements ImagePickerPlatform {
  @override
  Future<PickedImage?> pickImage(PickerOptions options) async {
    if (options.source == ImageSource.camera) {
      return _captureFromCamera(options);
    }
    return _pickFromGallery(options);
  }

  @override
  Future<List<PickedImage>> pickMultipleImages(PickerOptions options) async {
    final completer = Completer<List<PickedImage>>();
    final input = _createFileInput(options, multiple: true);

    // Handle file selection
    input.onchange = ((web.Event event) {
      _handleMultipleFilesSelection(input, options, completer);
    }).toJS;

    // Handle cancel - the 'cancel' event fires when user closes picker without selection
    input.addEventListener(
      'cancel',
      ((web.Event event) {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      }).toJS,
    );

    input.click();
    return completer.future;
  }

  @override
  Future<bool> isCameraAvailable() async {
    return _hasMediaDevices();
  }

  @override
  Future<bool> isGalleryAvailable() async {
    return true; // File input is always available on web
  }

  Future<PickedImage?> _pickFromGallery(PickerOptions options) async {
    final completer = Completer<PickedImage?>();
    final input = _createFileInput(options, multiple: false);

    // Handle file selection
    input.onchange = ((web.Event event) {
      _handleSingleFileSelection(input, options, completer);
    }).toJS;

    // Handle cancel - the 'cancel' event fires when user closes picker without selection
    input.addEventListener(
      'cancel',
      ((web.Event event) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
    );

    input.click();
    return completer.future;
  }

  Future<PickedImage?> _captureFromCamera(PickerOptions options) async {
    if (!_hasMediaDevices()) {
      throw UnsupportedError('Camera is not available on this browser');
    }

    final completer = Completer<PickedImage?>();

    try {
      // Request camera stream using getUserMedia
      final facingMode = options.preferredCameraDevice == CameraDevice.front
          ? 'user'
          : 'environment';

      final constraints = _createMediaConstraints(facingMode);
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      _showCameraDialog(stream, options, completer);
    } catch (e) {
      // If getUserMedia fails, fall back to file input with capture attribute
      _fallbackToFileInput(options, completer);
    }

    return completer.future;
  }

  web.MediaStreamConstraints _createMediaConstraints(String facingMode) {
    final videoConstraints = {
      'facingMode': facingMode.toJS,
      'width': {'ideal': 1920.toJS}.jsify(),
      'height': {'ideal': 1080.toJS}.jsify(),
    }.jsify()!;

    return web.MediaStreamConstraints(
      video: videoConstraints,
      audio: false.toJS,
    );
  }

  void _showCameraDialog(
    web.MediaStream stream,
    PickerOptions options,
    Completer<PickedImage?> completer,
  ) {
    // Create overlay container
    final overlay = web.document.createElement('div') as web.HTMLDivElement;
    overlay.id = 'flutter_image_picker_camera_overlay';
    overlay.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = 'rgba(0, 0, 0, 0.95)'
      ..display = 'flex'
      ..flexDirection = 'column'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..zIndex = '999999';

    // Create video element
    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video.autoplay = true;
    video.setAttribute('playsinline', 'true');
    video.srcObject = stream;
    video.style
      ..maxWidth = '90%'
      ..maxHeight = '70%'
      ..borderRadius = '12px'
      ..transform = options.preferredCameraDevice == CameraDevice.front
          ? 'scaleX(-1)'
          : 'none';

    // Create button container
    final buttonContainer =
        web.document.createElement('div') as web.HTMLDivElement;
    buttonContainer.style
      ..marginTop = '24px'
      ..display = 'flex'
      ..gap = '24px'
      ..alignItems = 'center';

    // Create cancel button
    final cancelButton = _createStyledButton('Cancel', '#6b7280', '#ffffff');

    // Create capture button
    final captureButton = _createCaptureButton();

    buttonContainer.appendChild(cancelButton);
    buttonContainer.appendChild(captureButton);

    overlay.appendChild(video);
    overlay.appendChild(buttonContainer);

    // Handle cancel
    cancelButton.onclick = ((web.Event e) {
      _cleanupCamera(overlay, stream);
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }).toJS;

    // Handle capture
    captureButton.onclick = ((web.Event e) {
      _captureFrame(video, options)
          .then((image) {
            _cleanupCamera(overlay, stream);
            if (!completer.isCompleted) {
              completer.complete(image);
            }
          })
          .catchError((err) {
            _cleanupCamera(overlay, stream);
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          });
    }).toJS;

    // Add to document
    web.document.body?.appendChild(overlay);
  }

  web.HTMLButtonElement _createStyledButton(
    String text,
    String bgColor,
    String textColor,
  ) {
    final button =
        web.document.createElement('button') as web.HTMLButtonElement;
    button.textContent = text;
    button.style
      ..padding = '12px 32px'
      ..fontSize = '16px'
      ..fontWeight = '600'
      ..border = 'none'
      ..borderRadius = '8px'
      ..cursor = 'pointer'
      ..backgroundColor = bgColor
      ..color = textColor
      ..transition = 'transform 0.15s, opacity 0.15s';

    button.onmouseenter = ((web.Event e) {
      button.style.opacity = '0.9';
    }).toJS;

    button.onmouseleave = ((web.Event e) {
      button.style.opacity = '1';
    }).toJS;

    return button;
  }

  web.HTMLButtonElement _createCaptureButton() {
    final button =
        web.document.createElement('button') as web.HTMLButtonElement;
    button.style
      ..width = '72px'
      ..height = '72px'
      ..borderRadius = '50%'
      ..border = '4px solid white'
      ..backgroundColor = 'transparent'
      ..cursor = 'pointer'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..padding = '4px'
      ..transition = 'transform 0.15s';

    // Inner circle
    final innerCircle = web.document.createElement('div') as web.HTMLDivElement;
    innerCircle.style
      ..width = '100%'
      ..height = '100%'
      ..borderRadius = '50%'
      ..backgroundColor = 'white';

    button.appendChild(innerCircle);

    button.onmouseenter = ((web.Event e) {
      button.style.transform = 'scale(1.1)';
    }).toJS;

    button.onmouseleave = ((web.Event e) {
      button.style.transform = 'scale(1)';
    }).toJS;

    return button;
  }

  Future<PickedImage?> _captureFrame(
    web.HTMLVideoElement video,
    PickerOptions options,
  ) async {
    final canvas =
        web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

    // Mirror the image if using front camera
    if (options.preferredCameraDevice == CameraDevice.front) {
      ctx.translate(canvas.width.toDouble(), 0);
      ctx.scale(-1, 1);
    }

    ctx.drawImage(video, 0, 0);

    // Get image data as blob
    final completer = Completer<PickedImage?>();

    canvas.toBlob(
      ((web.Blob? blob) {
        if (blob == null) {
          completer.complete(null);
          return;
        }
        _blobToPickedImage(blob, 'camera_capture.jpg').then((image) {
          completer.complete(image);
        });
      }).toJS,
      'image/jpeg',
      0.92.toJS,
    );

    return completer.future;
  }

  Future<PickedImage> _blobToPickedImage(web.Blob blob, String name) async {
    final completer = Completer<PickedImage>();
    final reader = web.FileReader();

    reader.onloadend = ((web.Event event) {
      final result = reader.result;
      if (result == null) {
        throw Exception('Failed to read blob');
      }
      final arrayBuffer = result as JSArrayBuffer;
      final bytes = arrayBuffer.toDart.asUint8List();
      completer.complete(
        PickedImage(
          bytes: bytes,
          name: name,
          mimeType: 'image/jpeg',
          path: null,
        ),
      );
    }).toJS;

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  void _cleanupCamera(web.HTMLDivElement overlay, web.MediaStream stream) {
    // Stop all tracks
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }

    // Remove overlay
    overlay.remove();
  }

  void _fallbackToFileInput(
    PickerOptions options,
    Completer<PickedImage?> completer,
  ) {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*';
    input.setAttribute(
      'capture',
      options.preferredCameraDevice == CameraDevice.front
          ? 'user'
          : 'environment',
    );

    // Handle file selection
    input.onchange = ((web.Event event) {
      _handleSingleFileSelection(input, options, completer);
    }).toJS;

    // Handle cancel
    input.addEventListener(
      'cancel',
      ((web.Event event) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
    );

    input.click();
  }

  Future<void> _handleSingleFileSelection(
    web.HTMLInputElement input,
    PickerOptions options,
    Completer<PickedImage?> completer,
  ) async {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      completer.complete(null);
      return;
    }
    final image = await _processFile(file, options);
    completer.complete(image);
  }

  Future<void> _handleMultipleFilesSelection(
    web.HTMLInputElement input,
    PickerOptions options,
    Completer<List<PickedImage>> completer,
  ) async {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete([]);
      return;
    }
    final images = <PickedImage>[];
    final maxCount = options.maxImages.clamp(0, files.length);
    for (var i = 0; i < maxCount; i++) {
      final file = files.item(i);
      if (file != null) {
        final image = await _processFile(file, options);
        if (image != null) {
          images.add(image);
        }
      }
    }
    completer.complete(images);
  }

  web.HTMLInputElement _createFileInput(
    PickerOptions options, {
    required bool multiple,
  }) {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = _buildAcceptString(options.allowedExtensions);
    if (multiple) {
      input.multiple = true;
    }
    return input;
  }

  String _buildAcceptString(List<String> extensions) {
    final mimeTypes = extensions.map((ext) {
      switch (ext.toLowerCase()) {
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
        default:
          return 'image/$ext';
      }
    }).toSet();
    return mimeTypes.join(',');
  }

  bool _hasMediaDevices() {
    try {
      // Try to access mediaDevices - if it throws, camera is not available
      // ignore: unnecessary_statements
      web.window.navigator.mediaDevices;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PickedImage?> _processFile(
    web.File file,
    PickerOptions options,
  ) async {
    final completer = Completer<PickedImage?>();
    final reader = web.FileReader();
    reader.onloadend = ((web.Event event) {
      final result = reader.result;
      if (result == null) {
        completer.complete(null);
        return;
      }
      final arrayBuffer = result as JSArrayBuffer;
      final bytes = arrayBuffer.toDart.asUint8List();
      completer.complete(
        PickedImage(
          bytes: bytes,
          name: file.name,
          mimeType: file.type,
          path: null, // Web doesn't have file paths
        ),
      );
    }).toJS;
    reader.onerror = ((web.Event event) {
      completer.complete(null);
    }).toJS;
    reader.readAsArrayBuffer(file);
    return completer.future;
  }
}
