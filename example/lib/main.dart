import 'package:flutter/material.dart';
import 'package:flutter_image_picker/flutter_image_picker.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());
}

final logger = Logger();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Picker Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ImagePickerDemoPage(),
    );
  }
}

class ImagePickerDemoPage extends StatefulWidget {
  const ImagePickerDemoPage({super.key});

  @override
  State<ImagePickerDemoPage> createState() => _ImagePickerDemoPageState();
}

class _ImagePickerDemoPageState extends State<ImagePickerDemoPage> {
  final FlutterImagePicker _imagePicker = FlutterImagePicker();
  final List<PickedImage> _selectedImages = [];
  bool _isLoading = false;
  bool _isCameraAvailable = false;
  bool _allowMultiple = false;

  @override
  void initState() {
    super.initState();
    _checkPlatformCapabilities();
  }

  Future<void> _checkPlatformCapabilities() async {
    final cameraAvailable = await _imagePicker.isCameraAvailable();
    setState(() {
      _isCameraAvailable = cameraAvailable;
    });
  }

  Future<void> _pickFromGallery() async {
    logger.d('picking from gallery');
    setState(() => _isLoading = true);
    try {
      if (_allowMultiple) {
        logger.d('picking multiple images');
        final images = await _imagePicker.pickMultipleImages(maxImages: 10);
        logger.d('picked images: $images');
        setState(() {
          _selectedImages.addAll(images);
        });
      } else {
        logger.d('picking single image');
        final image = await _imagePicker.pickFromGallery();
        logger.d('picked image: $image');
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    if (!_isCameraAvailable) {
      _showError('Camera is not available on this platform');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Pass context for camera capture with live preview
      final image = await _imagePicker.pickFromCamera(context);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Image Picker'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllImages,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Column(
        children: [
          // Options Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Allow Multiple Selection'),
                  subtitle: const Text('Pick multiple images at once'),
                  value: _allowMultiple,
                  onChanged: (value) {
                    setState(() => _allowMultiple = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Buttons Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    isLoading: _isLoading,
                    onPressed: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    isLoading: _isLoading,
                    isEnabled: _isCameraAvailable,
                    onPressed: _pickFromCamera,
                  ),
                ),
              ],
            ),
          ),
          // Using Widget Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Or use the built-in widget:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ImagePickerWidget(
                  onImagePicked: (image) {
                    setState(() => _selectedImages.add(image));
                  },
                  onMultipleImagesPicked: (images) {
                    setState(() => _selectedImages.addAll(images));
                  },
                  onError: _showError,
                  allowMultiple: _allowMultiple,
                  showCameraOption: _isCameraAvailable,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Selected Images Section
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images selected',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      final image = _selectedImages[index];
                      return _ImageTile(
                        image: image,
                        onRemove: () => _removeImage(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onRemove});

  final PickedImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(image.bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Text(
              _formatSize(image.size),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
