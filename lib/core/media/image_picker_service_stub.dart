import 'picked_image.dart';

abstract final class ImagePickerService {
  static Future<PickedImage?> pickImage() async => null;
  static Future<PickedMedia?> pickMedia() async => null;
}
