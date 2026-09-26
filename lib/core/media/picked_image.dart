import 'dart:typed_data';

class PickedImage {
  final Uint8List bytes;
  final String extension;

  const PickedImage({required this.bytes, required this.extension});
}
