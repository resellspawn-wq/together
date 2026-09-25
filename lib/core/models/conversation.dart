import 'profile.dart';

/// A 1-to-1 conversation from the current user's point of view: the row
/// itself plus who the *other* member is (already resolved), which is
/// all the UI ever needs.
class Conversation {
  final String id;
  final DateTime createdAt;
  final Profile otherMember;

  const Conversation({
    required this.id,
    required this.createdAt,
    required this.otherMember,
  });
}
