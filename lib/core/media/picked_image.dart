import 'dart:typed_data';

class PickedImage {
  final Uint8List bytes;
  final String extension;

  const PickedImage({required this.bytes, required this.extension});
}

const _videoExtensions = {'mp4', 'mov', 'webm', 'm4v', 'avi', 'mkv'};

class PickedMedia {
  final Uint8List bytes;
  final String extension;

  const PickedMedia({required this.bytes, required this.extension});

  bool get isVideo => _videoExtensions.contains(extension.toLowerCase());
}
