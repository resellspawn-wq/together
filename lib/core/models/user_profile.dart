/// The single local user. Kept minimal for the MVP (no accounts, no auth)
/// but shaped so a future phase can add multiple alphabets/profiles.
class UserProfile {
  final String id;
  final String name;
  final String activeAlphabetId;

  const UserProfile({
    required this.id,
    required this.name,
    required this.activeAlphabetId,
  });

  factory UserProfile.local({String activeAlphabetId = 'default'}) => UserProfile(
        id: 'local-user',
        name: 'Tu',
        activeAlphabetId: activeAlphabetId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'activeAlphabetId': activeAlphabetId,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        activeAlphabetId: json['activeAlphabetId'] as String,
      );
}
