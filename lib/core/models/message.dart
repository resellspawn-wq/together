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

  /// Set once the recipient's device has received this message (their
  /// realtime stream saw it). Null for a message not yet delivered.
  final DateTime? deliveredAt;

  /// Set once the recipient has actually opened the conversation and seen
  /// this message. Null for a message not yet read.
  final DateTime? readAt;

  /// True for a message this device sent but hasn't confirmed as
  /// persisted on the server yet (offline / in-flight).
  final bool pending;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.pending = false,
  });

  factory Message.fromRow(Map<String, dynamic> row) => Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        text: row['text'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        deliveredAt: (row['delivered_at'] as String?) != null
            ? DateTime.parse(row['delivered_at'] as String).toLocal()
            : null,
        readAt: (row['read_at'] as String?) != null ? DateTime.parse(row['read_at'] as String).toLocal() : null,
      );

  Message copyWith({bool? pending, DateTime? deliveredAt, DateTime? readAt}) => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        pending: pending ?? this.pending,
      );

  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  factory Message.fromCacheJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      );
}
