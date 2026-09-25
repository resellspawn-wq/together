/// A message row from the `messages` table. `text` is always plain,
/// normal Unicode text (e.g. "Ciao amore ❤️") — never an image, never
/// glyph data. Only the sender's alphabet, resolved separately, decides
/// how it's *drawn* on screen.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  /// True for a message this device sent but hasn't confirmed as
  /// persisted on the server yet (offline / in-flight).
  final bool pending;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.pending = false,
  });

  factory Message.fromRow(Map<String, dynamic> row) => Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        text: row['text'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  Message copyWith({bool? pending}) => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
        pending: pending ?? this.pending,
      );

  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Message.fromCacheJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
