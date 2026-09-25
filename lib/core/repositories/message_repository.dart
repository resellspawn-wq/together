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
}
