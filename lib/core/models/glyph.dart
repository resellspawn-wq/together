import 'stroke.dart';

/// A hand-drawn letter: the vector strokes the user drew, kept as data
/// (not an image, not a compiled font) so they can be re-rendered at any
/// size and re-edited later.
class Glyph {
  /// Always the uppercase form of the letter, e.g. "A".."Z".
  final String character;
  final List<Stroke> strokes;

  /// Logical size of the canvas the strokes were drawn on.
  final double width;
  final double height;

  /// Baseline offset from the top of [height], used to align glyphs with
  /// normal text when they're mixed together.
  final double baseline;

  final Map<String, dynamic>? metadata;
  final DateTime updatedAt;

  const Glyph({
    required this.character,
    required this.strokes,
    required this.width,
    required this.height,
    required this.baseline,
    required this.updatedAt,
    this.metadata,
  });

  bool get hasStrokes => strokes.isNotEmpty;

  Glyph copyWith({
    List<Stroke>? strokes,
    DateTime? updatedAt,
  }) {
    return Glyph(
      character: character,
      strokes: strokes ?? this.strokes,
      width: width,
      height: height,
      baseline: baseline,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'character': character,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'width': width,
        'height': height,
        'baseline': baseline,
        'updatedAt': updatedAt.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  factory Glyph.fromJson(Map<String, dynamic> json) => Glyph(
        character: json['character'] as String,
        strokes: (json['strokes'] as List)
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        baseline: (json['baseline'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );

  factory Glyph.empty(String character, {double size = 240}) => Glyph(
        character: character,
        strokes: const [],
        width: size,
        height: size,
        baseline: size * 0.82,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}
