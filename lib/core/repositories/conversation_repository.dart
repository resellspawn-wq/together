import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../models/profile.dart';

class ConversationRepository {
  final SupabaseClient _client;

  ConversationRepository(this._client);

  /// All 1-to-1 conversations the current user is part of, newest first,
  /// each resolved with who the *other* member is.
  ///
  /// One query for every membership row of every conversation the user is
  /// part of (mine and the other person's), instead of one query per
  /// conversation — simpler and avoids any per-row ordering surprises
  /// from doing a separate `.limit(1)` lookup per conversation.
  Future<List<Conversation>> listConversations(String currentUserId) async {
    final myMemberships = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', currentUserId);
    final conversationIds = myMemberships.map((r) => r['conversation_id'] as String).toList();
    if (conversationIds.isEmpty) return const [];

    final rows = await _client
        .from('conversation_members')
        .select('conversation_id, user_id, nickname, profiles(id, username, display_name, avatar_url), conversations(created_at)')
        .inFilter('conversation_id', conversationIds);

    // One query for the unread badge on every conversation at once,
    // counted client-side — PostgREST has no GROUP BY, and this is a
    // small, personal-scale table.
    final unreadRows = await _client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', conversationIds)
        .neq('sender_id', currentUserId)
        .filter('read_at', 'is', null);
    final unreadCounts = <String, int>{};
    for (final row in unreadRows) {
      final cid = row['conversation_id'] as String;
      unreadCounts[cid] = (unreadCounts[cid] ?? 0) + 1;
    }

    final byConversation = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      byConversation.putIfAbsent(row['conversation_id'] as String, () => []).add(row);
    }

    final conversations = <Conversation>[];
    for (final entry in byConversation.entries) {
      final members = entry.value;
      final otherCandidates = members.where((m) => m['user_id'] != currentUserId);
      if (otherCandidates.isEmpty) continue; // shouldn't happen for a 1-1 chat
      final other = otherCandidates.first;

      final mineCandidates = members.where((m) => m['user_id'] == currentUserId);
      final mine = mineCandidates.isEmpty ? null : mineCandidates.first;
      final otherProfileRow = (other['profiles'] as Map).cast<String, dynamic>();
      final createdAt = DateTime.parse((other['conversations']['created_at'] as String));
      final nickname = (mine?['nickname'] as String?)?.trim();

      var profile = Profile.fromRow(otherProfileRow);
      if (nickname != null && nickname.isNotEmpty) {
        profile = Profile(id: profile.id, username: profile.username, displayName: nickname, avatarUrl: profile.avatarUrl);
      }

      conversations.add(Conversation(
        id: entry.key,
        createdAt: createdAt,
        otherMember: profile,
        unreadCount: unreadCounts[entry.key] ?? 0,
      ));
    }

    conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return conversations;
  }

  /// Starts (or reuses) a 1-to-1 conversation with the given @username,
  /// optionally saving [nickname] as what the *current* user calls this
  /// contact. Throws if the username doesn't exist.
  Future<String> startConversationWith(String username, {String? nickname}) async {
    final id = await _client.rpc('start_conversation_with_username', params: {
      'target_username': username,
      'p_nickname': nickname,
    });
    return id as String;
  }

  /// Renames the current user's own side of a conversation (does not
  /// affect what the other member calls it).
  Future<void> renameConversation({
    required String conversationId,
    required String currentUserId,
    required String nickname,
  }) async {
    await _client
        .from('conversation_members')
        .update({'nickname': nickname.trim().isEmpty ? null : nickname.trim()})
        .eq('conversation_id', conversationId)
        .eq('user_id', currentUserId);
  }

  /// Deletes the conversation outright for both members (messages and
  /// membership rows cascade with it).
  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }
}
