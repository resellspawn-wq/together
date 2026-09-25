import 'push_subscription_data.dart';

/// Non-web fallback: Web Push isn't available (or this is the Dart VM
/// test runner), so every operation is a safe no-op.
abstract final class PushService {
  static Future<bool> isSupported() async => false;
  static Future<String> permission() async => 'unsupported';
  static Future<bool> isSubscribed() async => false;
  static Future<PushSubscriptionData?> subscribe(String vapidPublicKey) async => null;
  static Future<void> unsubscribe() async {}
}
