import 'package:supabase_flutter/supabase_flutter.dart';

import '../push/push_service.dart';

class PushRepository {
  final SupabaseClient _client;

  PushRepository(this._client);

  Future<void> saveSubscription(String userId, PushSubscriptionData sub) async {
    await _client.from('push_subscriptions').upsert({
      'user_id': userId,
      'endpoint': sub.endpoint,
      'p256dh': sub.p256dh,
      'auth': sub.auth,
    }, onConflict: 'endpoint');
  }

  Future<void> removeSubscription(String endpoint) async {
    await _client.from('push_subscriptions').delete().eq('endpoint', endpoint);
  }
}
