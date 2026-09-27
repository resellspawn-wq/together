/// Populated once at app start from the page URL (e.g. `?c=<id>`, the way
/// a push notification's service-worker click handler opens the app —
/// see web/custom_sw.js and HomeScreen). `Uri.base` reflects the browser's
/// address bar on web and is harmlessly static elsewhere.
String? _pendingConversationId = Uri.base.queryParameters['c'];

/// Consumed exactly once by whoever handles it first (HomeScreen), so a
/// later rebuild doesn't keep re-opening the same chat.
String? consumePendingConversationId() {
  final id = _pendingConversationId;
  _pendingConversationId = null;
  return id;
}
