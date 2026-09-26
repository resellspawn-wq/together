import 'package:supabase_flutter/supabase_flutter.dart';

/// A lightweight, ephemeral "is typing" signal for one conversation.
/// Deliberately NOT stored in the database — it's broadcast-only
/// (Supabase Realtime broadcast, no Postgres row), so there's nothing to
/// clean up and nothing for anyone but the two people in the chat to see.
class TypingChannel {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  TypingChannel(this._client);

  /// Joins the conversation's typing channel. [onTyping] fires whenever
  /// *any* member (including possibly ourselves, depending on the
  /// server's broadcast-echo setting) reports a typing state change —
  /// callers should ignore events from their own user id.
  void connect({
    required String conversationId,
    required void Function(String userId, bool typing) onTyping,
  }) {
    _channel = _client.channel('typing:$conversationId')
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          final userId = payload['user_id'] as String?;
          final typing = payload['typing'] as bool? ?? false;
          if (userId != null) onTyping(userId, typing);
        },
      ).subscribe();
  }

  void sendTyping(String userId, bool typing) {
    _channel?.sendBroadcastMessage(event: 'typing', payload: {'user_id': userId, 'typing': typing});
  }

  void dispose() {
    final channel = _channel;
    if (channel != null) _client.removeChannel(channel);
  }
}
