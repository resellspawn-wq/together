import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';

class MessageRepository {
  final SupabaseClient _client;
  static final _random = Random.secure();

  MessageRepository(this._client);

  static String _randomFileId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

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

  /// Uploads a photo/video to the conversation's attachment folder and
  /// returns its public URL. Kept separate from [sendAttachment] so the
  /// caller can show upload progress before the message row exists.
  Future<String> uploadAttachment(
    String conversationId,
    Uint8List bytes, {
    required String extension,
  }) async {
    final path = '$conversationId/${_randomFileId()}.$extension';
    await _client.storage.from('attachments').uploadBinary(path, bytes);
    return _client.storage.from('attachments').getPublicUrl(path);
  }

  Future<void> sendAttachment({
    required String conversationId,
    required String senderId,
    required String attachmentUrl,
    required AttachmentType attachmentType,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType.name,
    });
  }

  /// "Svuota chat": deletes every message in the conversation for both
  /// members. The realtime stream from [watchConversation] reflects this
  /// immediately.
  Future<void> clearMessages(String conversationId) async {
    await _client.from('messages').delete().eq('conversation_id', conversationId);
  }

  /// Every photo/video ever sent in this conversation, newest first — for
  /// the media gallery screen.
  Future<List<Message>> fetchAttachments(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .not('attachment_url', 'is', null)
        .order('created_at', ascending: false);
    return rows.map(Message.fromRow).toList();
  }

  /// Deletes specific messages (used by the gallery's "delete
  /// selected/all"). Does not touch the underlying storage object — a
  /// dangling file is harmless clutter, not a correctness problem.
  Future<void> deleteMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await _client.from('messages').delete().filter('id', 'in', '(${messageIds.join(',')})');
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
