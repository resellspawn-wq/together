import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'push_subscription_data.dart';

/// Real Web Push implementation, only ever compiled in on web builds (see
/// push_service.dart's conditional export).
abstract final class PushService {
  static Future<bool> isSupported() async {
    return web.window.navigator.has('serviceWorker') &&
        globalContext.has('PushManager') &&
        globalContext.has('Notification');
  }

  /// The current notification permission ('granted', 'denied', 'default'
  /// or 'unsupported'), without prompting the user.
  static Future<String> permission() async {
    if (!await isSupported()) return 'unsupported';
    return web.Notification.permission;
  }

  /// Asks the user for notification permission (if not already decided)
  /// and, once granted, subscribes this browser to Web Push. Returns null
  /// if unsupported, denied, or the user dismisses the prompt.
  static Future<PushSubscriptionData?> subscribe(String vapidPublicKey) async {
    if (!await isSupported()) return null;

    final result = await web.Notification.requestPermission().toDart;
    if (result.toDart != 'granted') return null;

    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final options = web.PushSubscriptionOptionsInit(
      userVisibleOnly: true,
      applicationServerKey: _urlBase64ToUint8Array(vapidPublicKey).toJS,
    );
    final subscription = await registration.pushManager.subscribe(options).toDart;

    final p256dh = subscription.getKey('p256dh');
    final auth = subscription.getKey('auth');
    if (p256dh == null || auth == null) return null;

    return PushSubscriptionData(
      endpoint: subscription.endpoint,
      p256dh: _base64UrlNoPad(p256dh.toDart.asUint8List()),
      auth: _base64UrlNoPad(auth.toDart.asUint8List()),
    );
  }

  static Future<bool> isSubscribed() async {
    if (!await isSupported()) return false;
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager.getSubscription().toDart;
    return subscription != null;
  }

  static Future<void> unsubscribe() async {
    if (!await isSupported()) return;
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager.getSubscription().toDart;
    if (subscription != null) {
      await subscription.unsubscribe().toDart;
    }
  }

  static Uint8List _urlBase64ToUint8Array(String base64String) {
    final padding = '=' * ((4 - base64String.length % 4) % 4);
    final normalized = (base64String + padding).replaceAll('-', '+').replaceAll('_', '/');
    return base64Decode(normalized);
  }

  static String _base64UrlNoPad(Uint8List bytes) => base64Url.encode(bytes).replaceAll('=', '');
}
