import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling image picker related permissions.
///
/// This class provides methods to check and request camera and storage
/// permissions on mobile platforms.
class ImagePickerPermissions {
  ImagePickerPermissions._();

  /// Checks if camera permission is granted.
  ///
  /// Returns `true` on web or desktop platforms where permissions
  /// are handled differently.
  static Future<bool> hasCameraPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Checks if storage/photos permission is granted.
  ///
  /// Returns `true` on web or desktop platforms where permissions
  /// are handled differently.
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      final photos = await Permission.photos.status;
      if (photos.isGranted) return true;
      // Fallback to storage for older Android versions
      final storage = await Permission.storage.status;
      return storage.isGranted;
    }
    // iOS uses photos permission
    final photos = await Permission.photos.status;
    return photos.isGranted;
  }

  /// Requests camera permission.
  ///
  /// Returns the permission status after the request.
  static Future<PermissionStatus> requestCameraPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    if (!Platform.isAndroid && !Platform.isIOS) return PermissionStatus.granted;
    return Permission.camera.request();
  }

  /// Requests storage/photos permission.
  ///
  /// Returns the permission status after the request.
  static Future<PermissionStatus> requestStoragePermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    if (!Platform.isAndroid && !Platform.isIOS) return PermissionStatus.granted;
    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      final photos = await Permission.photos.request();
      if (photos.isGranted) return photos;
      // Fallback to storage for older Android versions
      return Permission.storage.request();
    }
    // iOS uses photos permission
    return Permission.photos.request();
  }

  /// Requests camera permission with a user-friendly dialog.
  ///
  /// Shows a dialog explaining why the permission is needed before requesting.
  /// If the permission is permanently denied, offers to open app settings.
  ///
  /// Returns `true` if permission was granted.
  static Future<bool> requestCameraWithDialog(BuildContext context) async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    // Check current status
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    // Check if context is still valid
    if (!context.mounted) return false;
    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      return _showSettingsDialog(
        context,
        title: 'Camera Permission Required',
        message:
            'Camera permission is required to take photos. '
            'Please enable it in your device settings.',
      );
    }
    // Show explanation dialog before requesting
    final shouldRequest = await _showExplanationDialog(
      context,
      title: 'Camera Permission',
      message:
          'We need camera access to let you take photos. '
          'Would you like to grant camera permission?',
    );
    if (!shouldRequest) return false;
    // Request permission
    status = await Permission.camera.request();
    if (status.isGranted) return true;
    // Check if context is still valid before showing dialog
    if (!context.mounted) return false;
    // If denied after request, check if permanently denied
    if (status.isPermanentlyDenied) {
      return _showSettingsDialog(
        context,
        title: 'Camera Permission Required',
        message:
            'Camera permission was denied. '
            'Please enable it in your device settings to use the camera.',
      );
    }
    return false;
  }

  /// Requests storage permission with a user-friendly dialog.
  ///
  /// Shows a dialog explaining why the permission is needed before requesting.
  /// If the permission is permanently denied, offers to open app settings.
  ///
  /// Returns `true` if permission was granted.
  static Future<bool> requestStorageWithDialog(BuildContext context) async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    // Check current status
    var status = await _getStorageStatus();
    if (status.isGranted) return true;
    // Check if context is still valid
    if (!context.mounted) return false;
    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      return _showSettingsDialog(
        context,
        title: 'Photos Permission Required',
        message:
            'Photos permission is required to select images. '
            'Please enable it in your device settings.',
      );
    }
    // Show explanation dialog before requesting
    final shouldRequest = await _showExplanationDialog(
      context,
      title: 'Photos Permission',
      message:
          'We need access to your photos to let you select images. '
          'Would you like to grant photos permission?',
    );
    if (!shouldRequest) return false;
    // Request permission
    status = await requestStoragePermission();
    if (status.isGranted) return true;
    // Check if context is still valid before showing dialog
    if (!context.mounted) return false;
    // If denied after request, check if permanently denied
    if (status.isPermanentlyDenied) {
      return _showSettingsDialog(
        context,
        title: 'Photos Permission Required',
        message:
            'Photos permission was denied. '
            'Please enable it in your device settings to select images.',
      );
    }
    return false;
  }

  static Future<PermissionStatus> _getStorageStatus() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.status;
      if (photos.isGranted) return photos;
      return Permission.storage.status;
    }
    return Permission.photos.status;
  }

  static Future<bool> _showExplanationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(true);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Opens the app settings page where users can manage permissions.
  static Future<bool> openSettings() => openAppSettings();
}
