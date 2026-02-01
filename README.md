# Flutter Image Picker

A cross-platform image picker plugin for Flutter that works on **Android, iOS, Web, macOS, Windows, and Linux**.

## Features

- ✅ Pick images from gallery (all platforms)
- ✅ Capture images from camera with **live preview** (Android, iOS, Web)
- ✅ Front/rear camera switching
- ✅ Single and multiple image selection
- ✅ **Automatic permission handling** with user-friendly dialogs
- ✅ Ready-to-use widget with customizable UI
- ✅ Type-safe API with proper models
- ✅ HEIC/HEIF image support

## Platform Support

| Feature | Android | iOS | Web | macOS | Windows | Linux |
|---------|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
| Gallery | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Camera (live preview) | ✅ | ✅ | - | - | - | - |
| Camera (HTML5) | - | - | ✅ | - | - | - |
| Multiple Selection | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Front/Rear Switch | ✅ | ✅ | ✅ | - | - | - |
| Permission Handling | ✅ | ✅ | N/A | N/A | N/A | N/A |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_image_picker:
    path: ../flutter_image_picker  # or from pub.dev when published
```

## Platform Setup

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

Also, set the minimum SDK version in `android/app/build.gradle`:

```gradle
minSdkVersion 21
```

### iOS

Add the following keys to your `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos.</string>
```

### Web

No additional setup required. Works out of the box!

### Desktop (macOS, Windows, Linux)

No additional setup required for gallery access. Camera is not supported on desktop platforms.

## Usage

### Basic Usage

```dart
import 'package:flutter_image_picker/flutter_image_picker.dart';

final imagePicker = FlutterImagePicker();

// Pick a single image from gallery
final image = await imagePicker.pickFromGallery();
if (image != null) {
  print('Selected: ${image.name}');
  print('Size: ${image.size} bytes');
}

// Capture from camera with live preview (requires context)
// Permissions are automatically handled with user-friendly dialogs
final photo = await imagePicker.pickFromCamera(context);

// Pick multiple images
final images = await imagePicker.pickMultipleImages(maxImages: 5);
```

### Using the Widget

The package includes a ready-to-use widget with bottom sheet source picker:

```dart
ImagePickerWidget(
  onImagePicked: (PickedImage image) {
    setState(() {
      _selectedImage = image;
    });
  },
  onMultipleImagesPicked: (List<PickedImage> images) {
    setState(() {
      _selectedImages = images;
    });
  },
  onError: (String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
  allowMultiple: true,
  showCameraOption: true,
  showGalleryOption: true,
)
```

### Camera Capture Widget

For direct camera access with a full-screen preview:

```dart
// Using the helper class (auto-handles permissions)
final image = await CameraCapture.capture(
  context,
  options: PickerOptions(
    preferredCameraDevice: CameraDevice.front,
  ),
);

// Skip automatic permission dialog
final image = await CameraCapture.capture(
  context,
  requestPermission: false, // Handle permissions yourself
);
```

### Permission Handling

The package automatically handles permissions with user-friendly dialogs. You can also manage permissions manually:

```dart
// Check if camera permission is granted
final hasPermission = await ImagePickerPermissions.hasCameraPermission();

// Request camera permission with dialog
final granted = await ImagePickerPermissions.requestCameraWithDialog(context);

// Request storage/photos permission with dialog
final storageGranted = await ImagePickerPermissions.requestStorageWithDialog(context);

// Open app settings (for permanently denied permissions)
await ImagePickerPermissions.openSettings();
```

### Custom Widget

You can also provide your own UI:

```dart
ImagePickerWidget(
  onImagePicked: (image) => handleImage(image),
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(Icons.upload, size: 48),
        Text('Tap to select image'),
      ],
    ),
  ),
)
```

### With Options

```dart
final image = await imagePicker.pickImage(
  options: PickerOptions(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
    allowedExtensions: ['jpg', 'png', 'heic'],
  ),
);
```

## API Reference

### FlutterImagePicker

| Method | Description |
|--------|-------------|
| `pickImage({PickerOptions options})` | Pick a single image |
| `pickFromGallery({...})` | Pick from gallery |
| `pickFromCamera(BuildContext context, {...})` | Capture with live preview (mobile) |
| `pickMultipleImages({...})` | Pick multiple images |
| `isCameraAvailable()` | Check camera availability |
| `isGalleryAvailable()` | Check gallery availability |

### PickedImage

| Property | Type | Description |
|----------|------|-------------|
| `bytes` | `Uint8List` | Image data |
| `name` | `String` | File name |
| `mimeType` | `String?` | MIME type |
| `path` | `String?` | File path (null on web) |
| `size` | `int` | Size in bytes |

### PickerOptions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `source` | `ImageSource` | `gallery` | Image source |
| `allowMultiple` | `bool` | `false` | Allow multiple selection |
| `maxImages` | `int` | `10` | Max images for multiple |
| `maxWidth` | `double?` | - | Max width |
| `maxHeight` | `double?` | - | Max height |
| `imageQuality` | `int?` | - | Quality (0-100) |
| `preferredCameraDevice` | `CameraDevice` | `rear` | Camera to use |
| `allowedExtensions` | `List<String>` | `[jpg, jpeg, png, gif, webp, bmp, heic, heif]` | Allowed extensions |

### CameraCapture

| Method | Description |
|--------|-------------|
| `capture(context, {options, requestPermission})` | Opens camera preview and captures image |
| `isAvailable()` | Returns true if camera is available |
| `hasPermission()` | Check if camera permission is granted |
| `requestPermission()` | Request camera permission (no dialog) |

### ImagePickerPermissions

| Method | Description |
|--------|-------------|
| `hasCameraPermission()` | Check if camera permission is granted |
| `hasStoragePermission()` | Check if storage/photos permission is granted |
| `requestCameraPermission()` | Request camera permission (returns status) |
| `requestStoragePermission()` | Request storage permission (returns status) |
| `requestCameraWithDialog(context)` | Request camera permission with user-friendly dialog |
| `requestStorageWithDialog(context)` | Request storage permission with user-friendly dialog |
| `openSettings()` | Open app settings for permission management |

## Example

Check out the [example](example/) directory for a complete demo application.

```bash
cd example
flutter run
```

## Dependencies

- `file_picker` - For cross-platform file selection
- `camera` - For live camera preview on mobile
- `permission_handler` - For runtime permission management
- `web` - For web platform support

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a PR.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

