/// A browser's Web Push subscription, in the shape the server needs to
/// send it a notification.
class PushSubscriptionData {
  final String endpoint;
  final String p256dh;
  final String auth;

  const PushSubscriptionData({required this.endpoint, required this.p256dh, required this.auth});
}
