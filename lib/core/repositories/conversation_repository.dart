import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../models/profile.dart';

class ConversationRepository {
  final SupabaseClient _client;

  ConversationRepository(this._client);

  /// All 1-to-1 conversations the current user is part of, newest first,
  /// each resolved with who the *other* member is.
  Future<List<Conversation>> listConversations(String currentUserId) async {
    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, conversations(id, created_at)')
        .eq('user_id', currentUserId);

    final conversations = <Conversation>[];
    for (final m in memberships) {
      final conversationId = m['conversation_id'] as String;
      final createdAt = DateTime.parse((m['conversations']['created_at'] as String));

      final otherRows = await _client
          .from('conversation_members')
          .select('user_id, profiles(id, username, display_name)')
          .eq('conversation_id', conversationId)
          .neq('user_id', currentUserId)
          .limit(1);
      if (otherRows.isEmpty) continue; // shouldn't happen for a 1-1 chat

      final otherProfileRow = (otherRows.first['profiles'] as Map).cast<String, dynamic>();
      conversations.add(Conversation(
        id: conversationId,
        createdAt: createdAt,
        otherMember: Profile.fromRow(otherProfileRow),
      ));
    }

    conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return conversations;
  }

  /// Starts (or reuses) a 1-to-1 conversation with the given @username.
  /// Throws if the username doesn't exist.
  Future<String> startConversationWith(String username) async {
    final id = await _client.rpc('start_conversation_with_username', params: {
      'target_username': username,
    });
    return id as String;
  }
}
