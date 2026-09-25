import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alphabet.dart';
import '../models/glyph.dart';
import '../models/stroke.dart';

/// Syncs [Alphabet]/[Glyph] — the exact same models the local-only editor
/// already uses — to/from Supabase. The editor itself is untouched: it
/// keeps reading/writing through [AppState]/StorageService as before,
/// this repository only pushes saved glyphs up and pulls other users'
/// alphabets down so their messages can be rendered with their own
/// handwriting.
class RemoteAlphabetRepository {
  final SupabaseClient _client;

  RemoteAlphabetRepository(this._client);

  /// Returns the id of `userId`'s alphabets row, creating a blank one if
  /// they don't have one yet remotely.
  Future<String> ensureAlphabetId(String userId) async {
    final existing = await _client.from('alphabets').select('id').eq('user_id', userId).limit(1);
    if (existing.isNotEmpty) return existing.first['id'] as String;

    final inserted =
        await _client.from('alphabets').insert({'user_id': userId, 'name': 'Il mio alfabeto'}).select('id').single();
    return inserted['id'] as String;
  }

  Future<void> pushGlyph(String alphabetId, Glyph glyph) async {
    if (!glyph.hasStrokes) return;
    await _client.from('glyphs').upsert({
      'alphabet_id': alphabetId,
      'character': glyph.character,
      'strokes': glyph.strokes.map((s) => s.toJson()).toList(),
      'width': glyph.width,
      'height': glyph.height,
      'baseline': glyph.baseline,
      'updated_at': glyph.updatedAt.toIso8601String(),
    }, onConflict: 'alphabet_id,character');
  }

  /// Fetches `userId`'s full alphabet from Supabase. Returns a blank
  /// alphabet if they have none yet (e.g. haven't drawn anything remotely).
  Future<Alphabet> fetchAlphabet(String userId) async {
    final alphabetRows = await _client.from('alphabets').select().eq('user_id', userId).limit(1);
    if (alphabetRows.isEmpty) return Alphabet.blank(id: userId);

    final row = alphabetRows.first;
    final alphabetId = row['id'] as String;
    final glyphRows = await _client.from('glyphs').select().eq('alphabet_id', alphabetId);

    var alphabet = Alphabet.blank(id: alphabetId, name: row['name'] as String? ?? 'Il mio alfabeto');
    for (final g in glyphRows) {
      alphabet = alphabet.withGlyph(_glyphFromRow(g));
    }
    return alphabet;
  }

  /// Live updates for a single alphabet's glyphs (used to keep a
  /// conversation partner's handwriting fresh while a chat is open).
  Stream<Glyph> watchGlyphs(String alphabetId) {
    return _client
        .from('glyphs')
        .stream(primaryKey: ['id'])
        .eq('alphabet_id', alphabetId)
        .map((rows) => rows.map(_glyphFromRow).toList())
        .expand((glyphs) => glyphs);
  }

  Glyph _glyphFromRow(Map<String, dynamic> row) {
    final strokesRaw = row['strokes'] as List;
    return Glyph(
      character: row['character'] as String,
      strokes: strokesRaw.map((s) => Stroke.fromJson((s as Map).cast<String, dynamic>())).toList(),
      width: (row['width'] as num).toDouble(),
      height: (row['height'] as num).toDouble(),
      baseline: (row['baseline'] as num).toDouble(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
