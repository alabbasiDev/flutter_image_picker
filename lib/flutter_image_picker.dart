/// A cross-platform image picker plugin for Flutter.
///
/// This library provides a unified API for picking images from the gallery
/// or camera across all Flutter platforms (Android, iOS, Web, macOS, Windows, Linux).
library;

// Models
export 'src/models/picked_image.dart';
export 'src/models/image_source.dart';
export 'src/models/picker_options.dart';

// Core
export 'src/image_picker_platform.dart';
export 'src/image_picker.dart';

// Widgets
export 'src/widgets/image_picker_widget.dart';
export 'src/widgets/camera_capture_widget.dart'
    if (dart.library.io) 'src/widgets/camera_capture_widget.dart';

// Utils
export 'src/utils/permissions.dart'
    if (dart.library.io) 'src/utils/permissions.dart';
