enum AttachmentType {
  image,
  video;

  static AttachmentType? fromName(String? name) {
    if (name == null) return null;
    for (final value in AttachmentType.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// A message row from the `messages` table. `text` is always plain,
/// normal Unicode text (e.g. "Ciao amore ❤️") — never glyph data. Only
/// the sender's alphabet, resolved separately, decides how it's *drawn*
/// on screen. A message can also carry a photo/video instead of (or
/// alongside) text — [attachmentUrl]/[attachmentType] describe that.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final DateTime createdAt;

  final String? attachmentUrl;
  final AttachmentType? attachmentType;

  /// Set once the recipient's device has received this message (their
  /// realtime stream saw it). Null for a message not yet delivered.
  final DateTime? deliveredAt;

  /// Set once the recipient has actually opened the conversation and seen
  /// this message. Null for a message not yet read.
  final DateTime? readAt;

  /// True for a message this device sent but hasn't confirmed as
  /// persisted on the server yet (offline / in-flight).
  final bool pending;

  bool get hasAttachment => attachmentUrl != null;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.deliveredAt,
    this.readAt,
    this.pending = false,
  });

  factory Message.fromRow(Map<String, dynamic> row) => Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        text: row['text'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        attachmentUrl: row['attachment_url'] as String?,
        attachmentType: AttachmentType.fromName(row['attachment_type'] as String?),
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
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
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
        'attachmentUrl': attachmentUrl,
        'attachmentType': attachmentType?.name,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  factory Message.fromCacheJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentType: AttachmentType.fromName(json['attachmentType'] as String?),
        deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      );
}
