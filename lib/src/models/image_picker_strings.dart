/// Strings used in the widget for localization.
class ImagePickerStrings {
  const ImagePickerStrings({
    this.galleryLabel = 'Gallery',
    this.cameraLabel = 'Camera',
    this.selectImageTitle = 'Select Image Source',
    this.selectImagesLabel = 'Select Images',
    this.selectImageLabel = 'Select Image',
    this.cameraPermissionRequiredTitle = 'Camera Permission Required',
    this.cameraPermissionRequiredMessage =
        'Camera permission is required to take photos. '
        'Please enable it in your device settings.',
    this.cameraPermissionTitle = 'Camera Permission',
    this.cameraPermissionMessage =
        'We need camera access to let you take photos. '
        'Would you like to grant camera permission?',
    this.cameraPermissionDeniedMessage =
        'Camera permission was denied. '
        'Please enable it in your device settings to use the camera.',
    this.photosPermissionRequiredTitle = 'Photos Permission Required',
    this.photosPermissionRequiredMessage =
        'Photos permission is required to select images. '
        'Please enable it in your device settings.',
    this.photosPermissionTitle = 'Photos Permission',
    this.photosPermissionMessage =
        'We need access to your photos to let you select images. '
        'Would you like to grant photos permission?',
    this.photosPermissionDeniedMessage =
        'Photos permission was denied. '
        'Please enable it in your device settings to select images.',
    this.openSettings = 'Open Settings',
    this.cancel = 'Cancel',
    this.continueLabel = 'Continue',
    this.goBack = 'Go Back',
    this.initializingCamera = 'Initializing camera...',
    this.noCamerasAvailable = 'No cameras available on this device',
    this.cameraInitializationFailed = 'Failed to initialize camera',
    this.captureFailed = 'Failed to capture image',
  });

  final String galleryLabel;
  final String cameraLabel;
  final String selectImageTitle;
  final String selectImagesLabel;
  final String selectImageLabel;

  final String cameraPermissionRequiredTitle;
  final String cameraPermissionRequiredMessage;
  final String cameraPermissionTitle;
  final String cameraPermissionMessage;
  final String cameraPermissionDeniedMessage;

  final String photosPermissionRequiredTitle;
  final String photosPermissionRequiredMessage;
  final String photosPermissionTitle;
  final String photosPermissionMessage;
  final String photosPermissionDeniedMessage;

  final String openSettings;
  final String cancel;
  final String continueLabel;
  final String goBack;
  final String initializingCamera;
  final String noCamerasAvailable;
  final String cameraInitializationFailed;
  final String captureFailed;
}
