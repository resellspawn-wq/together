import 'package:flutter_test/flutter_test.dart';
import 'package:together/core/models/alphabet.dart';
import 'package:together/core/models/glyph.dart';
import 'package:together/core/models/stroke.dart';

Stroke _sampleStroke() => const Stroke(points: [
      StrokePoint(x: 10, y: 10, timestampMs: 0),
      StrokePoint(x: 20, y: 40, timestampMs: 16),
      StrokePoint(x: 30, y: 60, timestampMs: 32),
    ]);

void main() {
  group('Glyph', () {
    test('an empty glyph has no strokes', () {
      final glyph = Glyph.empty('A');
      expect(glyph.hasStrokes, isFalse);
    });

    test('creating letter A: a stroke makes the glyph "created"', () {
      final glyph = Glyph.empty('A').copyWith(strokes: [_sampleStroke()]);
      expect(glyph.hasStrokes, isTrue);
      expect(glyph.strokes.single.points, hasLength(3));
    });

    test('round-trips through JSON without losing stroke data', () {
      final original = Glyph.empty('B').copyWith(strokes: [_sampleStroke()]);
      final restored = Glyph.fromJson(original.toJson());
      expect(restored.character, 'B');
      expect(restored.strokes.single.points.first.x, 10);
      expect(restored.strokes.single.points.last.y, 60);
    });
  });

  group('Alphabet', () {
    test('a blank alphabet has all 26 letters but none completed', () {
      final alphabet = Alphabet.blank();
      expect(alphabet.glyphs.keys.toSet(), kAlphabetLetters.toSet());
      expect(alphabet.completedCount, 0);
      expect(alphabet.isComplete, isFalse);
    });

    test('saving letter A updates only A', () {
      final alphabet = Alphabet.blank();
      final withA = alphabet.withGlyph(
        Glyph.empty('A').copyWith(strokes: [_sampleStroke()]),
      );
      expect(withA.completedCount, 1);
      expect(withA.glyphFor('A')!.hasStrokes, isTrue);
      expect(withA.glyphFor('B')!.hasStrokes, isFalse);
    });

    test('creating all 26 letters completes the alphabet', () {
      var alphabet = Alphabet.blank();
      for (final letter in kAlphabetLetters) {
        alphabet = alphabet.withGlyph(
          Glyph.empty(letter).copyWith(strokes: [_sampleStroke()]),
        );
      }
      expect(alphabet.completedCount, 26);
      expect(alphabet.isComplete, isTrue);
    });

    test('re-editing an already-saved letter overwrites its glyph in place', () {
      var alphabet = Alphabet.blank().withGlyph(
        Glyph.empty('A').copyWith(strokes: [_sampleStroke()]),
      );
      final firstVersionStrokeCount = alphabet.glyphFor('A')!.strokes.length;

      alphabet = alphabet.withGlyph(
        Glyph.empty('A').copyWith(strokes: [_sampleStroke(), _sampleStroke()]),
      );

      expect(alphabet.glyphFor('A')!.strokes.length, isNot(firstVersionStrokeCount));
      expect(alphabet.glyphFor('A')!.strokes.length, 2);
      // Still a single source of truth: no duplicate letters were created.
      expect(alphabet.glyphs.length, 26);
    });

    test('alphabet round-trips through JSON', () {
      final alphabet = Alphabet.blank().withGlyph(
        Glyph.empty('Z').copyWith(strokes: [_sampleStroke()]),
      );
      final restored = Alphabet.fromJson(alphabet.toJson());
      expect(restored.glyphFor('Z')!.hasStrokes, isTrue);
      expect(restored.completedCount, 1);
    });
  });
}
