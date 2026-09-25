import 'package:flutter_test/flutter_test.dart';
import 'package:together/core/models/message.dart';

void main() {
  group('Message', () {
    test('fromRow parses a Supabase messages row, converting the timestamp to local time', () {
      final message = Message.fromRow({
        'id': 'm1',
        'conversation_id': 'c1',
        'sender_id': 'vlad',
        'text': 'Ciao amore ❤️ 123!',
        'created_at': '2026-01-01T12:00:00Z',
      });

      expect(message.id, 'm1');
      expect(message.conversationId, 'c1');
      expect(message.senderId, 'vlad');
      expect(message.text, 'Ciao amore ❤️ 123!');
      expect(message.pending, isFalse);
    });

    test('round-trips through the local offline cache format', () {
      final original = Message(
        id: 'm2',
        conversationId: 'c1',
        senderId: 'eliza',
        text: 'Ti amo ❤️',
        createdAt: DateTime(2026, 1, 2, 9, 30),
      );

      final restored = Message.fromCacheJson(original.toCacheJson());

      expect(restored.id, original.id);
      expect(restored.senderId, 'eliza');
      expect(restored.text, 'Ti amo ❤️');
      expect(restored.createdAt, original.createdAt);
    });

    test('copyWith(pending: false) clears the pending/in-flight flag', () {
      final pending = Message(
        id: 'm3',
        conversationId: 'c1',
        senderId: 'vlad',
        text: 'ciao',
        createdAt: DateTime(2026, 1, 1),
        pending: true,
      );

      expect(pending.copyWith(pending: false).pending, isFalse);
    });
  });
}
