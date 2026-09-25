import 'glyph.dart';

const List<String> kAlphabetLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

/// The user's personal alphabet: one glyph per A-Z letter.
class Alphabet {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Keyed by uppercase letter, e.g. glyphs['A'].
  final Map<String, Glyph> glyphs;

  const Alphabet({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.glyphs,
  });

  factory Alphabet.blank({String id = 'default', String name = 'Il mio alfabeto'}) {
    final now = DateTime.now();
    return Alphabet(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
      glyphs: {for (final l in kAlphabetLetters) l: Glyph.empty(l)},
    );
  }

  int get completedCount =>
      kAlphabetLetters.where((l) => glyphs[l]?.hasStrokes ?? false).length;

  bool get isComplete => completedCount == kAlphabetLetters.length;

  Glyph? glyphFor(String letter) => glyphs[letter.toUpperCase()];

  Alphabet withGlyph(Glyph glyph) {
    final updated = Map<String, Glyph>.from(glyphs);
    updated[glyph.character] = glyph;
    return Alphabet(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      glyphs: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'glyphs': glyphs.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Alphabet.fromJson(Map<String, dynamic> json) {
    final rawGlyphs = (json['glyphs'] as Map).cast<String, dynamic>();
    final glyphs = <String, Glyph>{
      for (final letter in kAlphabetLetters)
        letter: rawGlyphs.containsKey(letter)
            ? Glyph.fromJson((rawGlyphs[letter] as Map).cast<String, dynamic>())
            : Glyph.empty(letter),
    };
    return Alphabet(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      glyphs: glyphs,
    );
  }
}
