import 'picked_image.dart';

abstract final class ImagePickerService {
  static Future<PickedImage?> pickImage() async => null;
  static Future<PickedMedia?> pickMedia({bool useCamera = false}) async => null;
}
