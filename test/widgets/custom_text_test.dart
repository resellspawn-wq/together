import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:together/core/models/alphabet.dart';
import 'package:together/core/models/glyph.dart';
import 'package:together/core/models/stroke.dart';
import 'package:together/widgets/custom_text/custom_text.dart';
import 'package:together/widgets/glyph/glyph_painter.dart';

const _stroke = Stroke(points: [
  StrokePoint(x: 1, y: 1, timestampMs: 0),
  StrokePoint(x: 5, y: 5, timestampMs: 10),
]);

Alphabet _alphabetWith(Iterable<String> drawnLetters) {
  var alphabet = Alphabet.blank();
  for (final letter in drawnLetters) {
    alphabet = alphabet.withGlyph(Glyph.empty(letter).copyWith(strokes: [_stroke]));
  }
  return alphabet;
}

int _glyphPaintCount(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((w) => w.painter is GlyphPainter)
      .length;
}

void main() {
  testWidgets('drawn A-Z letters render as custom glyphs, everything else stays normal text', (tester) async {
    // "Ciao amore ❤️ 123!" -> letters: C i a o a m o r e = 9 letter glyphs.
    final alphabet = _alphabetWith('CIAOMRE'.split(''));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomText(
            'Ciao amore ❤️ 123!',
            alphabet: alphabet,
          ),
        ),
      ),
    );

    expect(_glyphPaintCount(tester), 9);

    // Non-letters must remain literal, untouched text.
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('an un-drawn letter falls back to plain text instead of breaking', (tester) async {
    final alphabet = Alphabet.blank(); // nothing drawn yet

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomText('Hi', alphabet: alphabet),
        ),
      ),
    );

    expect(_glyphPaintCount(tester), 0);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('i'), findsOneWidget);
  });

  testWidgets('lowercase and uppercase both resolve to the same drawn glyph', (tester) async {
    final alphabet = _alphabetWith(['A']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomText('Aa', alphabet: alphabet),
        ),
      ),
    );

    expect(_glyphPaintCount(tester), 2);
  });

  testWidgets('disabling custom mode renders everything as plain text', (tester) async {
    final alphabet = _alphabetWith(kAlphabetLetters);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomText('Ciao ❤️ 123!', alphabet: alphabet, enabled: false),
        ),
      ),
    );

    expect(_glyphPaintCount(tester), 0);
    expect(find.text('Ciao ❤️ 123!'), findsOneWidget);
  });
}
