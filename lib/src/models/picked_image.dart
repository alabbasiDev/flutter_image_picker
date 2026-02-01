import 'dart:typed_data';

/// Represents a picked image with its data and metadata.
class PickedImage {
  /// Creates a [PickedImage] instance.
  const PickedImage({
    required this.bytes,
    required this.name,
    this.mimeType,
    this.path,
  });

  /// The image data as bytes.
  final Uint8List bytes;

  /// The original file name.
  final String name;

  /// The MIME type of the image (e.g., 'image/jpeg', 'image/png').
  final String? mimeType;

  /// The local file path (may be null on web platform).
  final String? path;

  /// The size of the image in bytes.
  int get size => bytes.length;

  /// Creates a copy of this [PickedImage] with the given fields replaced.
  PickedImage copyWith({
    Uint8List? bytes,
    String? name,
    String? mimeType,
    String? path,
  }) {
    return PickedImage(
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      path: path ?? this.path,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PickedImage &&
        other.name == name &&
        other.mimeType == mimeType &&
        other.path == path &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(name, mimeType, path, size);

  @override
  String toString() {
    return 'PickedImage(name: $name, mimeType: $mimeType, size: $size, path: $path)';
  }
}
