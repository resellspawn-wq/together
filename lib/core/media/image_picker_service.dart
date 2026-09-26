export 'picked_image.dart';

/// Lets the user pick an image file from disk. Web-only in practice (see
/// image_picker_service_web.dart); the stub keeps non-web builds and
/// `flutter test` (Dart VM) compiling without touching `package:web`.
export 'image_picker_service_stub.dart' if (dart.library.js_interop) 'image_picker_service_web.dart';
