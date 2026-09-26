import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';

class MessageRepository {
  final SupabaseClient _client;

  MessageRepository(this._client);

  /// A live, always-sorted view of a conversation's messages. Supabase's
  /// `.stream()` does the heavy lifting here: it fetches the current rows
  /// immediately, then keeps them in sync in real time (inserts, and any
  /// future edits/deletes), reconnecting automatically if the socket
  /// drops — so this single stream covers loading, realtime updates and
  /// reconnection without any extra bookkeeping, and there is exactly one
  /// row per message id so duplicates can't appear.
  Stream<List<Message>> watchConversation(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(Message.fromRow).toList());
  }

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
    });
  }

  /// "Svuota chat": deletes every message in the conversation for both
  /// members. The realtime stream from [watchConversation] reflects this
  /// immediately.
  Future<void> clearMessages(String conversationId) async {
    await _client.from('messages').delete().eq('conversation_id', conversationId);
  }

  /// Stamps delivered_at on messages from someone else that this device
  /// has just received but never marked delivered yet.
  Future<void> markDelivered(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await _client
        .from('messages')
        .update({'delivered_at': DateTime.now().toUtc().toIso8601String()})
        .filter('id', 'in', '(${messageIds.join(',')})')
        .filter('delivered_at', 'is', null);
  }

  /// Stamps read_at on messages from someone else once the conversation
  /// screen has actually shown them.
  Future<void> markRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .filter('id', 'in', '(${messageIds.join(',')})')
        .filter('read_at', 'is', null);
  }
}
