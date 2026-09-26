import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'picked_image.dart';

abstract final class ImagePickerService {
  /// Opens the browser's native file picker restricted to images, and
  /// resolves once the user picks a file (or null if they cancel — best
  /// effort, since browsers don't fire a reliable "cancelled" event: a
  /// stalled pick just never resolves, which is fine for a one-off tap).
  static Future<PickedImage?> pickImage() async {
    final picked = await _pick('image/*');
    if (picked == null) return null;
    return PickedImage(bytes: picked.$1, extension: picked.$2);
  }

  /// Same idea, but accepts photos or videos — for chat attachments. When
  /// [useCamera] is true, sets the `capture` attribute so mobile browsers
  /// open the device camera directly instead of the gallery/file picker
  /// (desktop browsers without a camera just ignore the hint and fall
  /// back to the normal picker).
  static Future<PickedMedia?> pickMedia({bool useCamera = false}) async {
    final picked = await _pick('image/*,video/*', capture: useCamera ? 'environment' : null);
    if (picked == null) return null;
    return PickedMedia(bytes: picked.$1, extension: picked.$2);
  }

  static Future<(Uint8List, String)?> _pick(String accept, {String? capture}) {
    final completer = Completer<(Uint8List, String)?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = accept;
    if (capture != null) input.capture = capture;

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
        completer.complete((buffer.asUint8List(), extension));
      }).toJS;
      reader.readAsArrayBuffer(file);
    }).toJS;

    input.click();
    return completer.future;
  }
}
