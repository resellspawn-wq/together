import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'picked_image.dart';

abstract final class ImagePickerService {
  /// Opens the browser's native file picker restricted to images, and
  /// resolves once the user picks a file (or null if they cancel — best
  /// effort, since browsers don't fire a reliable "cancelled" event: a
  /// stalled pick just never resolves, which is fine for a one-off tap).
  static Future<PickedImage?> pickImage() {
    final completer = Completer<PickedImage?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*';

    input.onchange = ((web.Event _) {
      final files = input.files;
      final file = (files != null && files.length > 0) ? files.item(0) : null;
      if (file == null) {
        completer.complete(null);
        return;
      }
      final reader = web.FileReader();
      reader.onload = ((web.Event _) {
        final buffer = (reader.result! as JSArrayBuffer).toDart;
        final name = file.name;
        final extension = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
        completer.complete(PickedImage(bytes: buffer.asUint8List(), extension: extension));
      }).toJS;
      reader.readAsArrayBuffer(file);
    }).toJS;

    input.click();
    return completer.future;
  }
}
