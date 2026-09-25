export 'push_subscription_data.dart';

/// Platform surface for Web Push. Only ever has a real implementation on
/// web (push_service_web.dart) — this conditionally exports a no-op stub
/// everywhere else, so non-web builds and `flutter test` (which runs on
/// the Dart VM, not a browser) compile and run without ever touching
/// `package:web` / `dart:js_interop`.
export 'push_service_stub.dart' if (dart.library.js_interop) 'push_service_web.dart';
