/// A user's public profile, mirrored from the `profiles` table. This is
/// intentionally small and public (username + display name only) — it's
/// what makes @username search possible.
class Profile {
  final String id;
  final String username;
  final String displayName;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
  });

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
        id: row['id'] as String,
        username: row['username'] as String,
        displayName: row['display_name'] as String,
      );
}
