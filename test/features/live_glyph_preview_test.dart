import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:together/core/models/alphabet.dart';
import 'package:together/core/models/glyph.dart';
import 'package:together/core/models/stroke.dart';
import 'package:together/features/conversations/live_glyph_preview.dart';
import 'package:together/widgets/glyph/glyph_painter.dart';

const _stroke = Stroke(points: [
  StrokePoint(x: 1, y: 1, timestampMs: 0),
  StrokePoint(x: 5, y: 5, timestampMs: 10),
]);

int _glyphPaintCount(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((w) => w.painter is GlyphPainter)
      .length;
}

void main() {
  testWidgets('typing updates the live preview with custom glyphs, not plain letters', (tester) async {
    final alphabet = Alphabet.blank().withGlyph(Glyph.empty('A').copyWith(strokes: [_stroke]));
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveGlyphPreview(controller: controller, alphabet: alphabet, customEnabled: true),
        ),
      ),
    );

    // Nothing typed yet: just the placeholder, no glyphs.
    expect(find.text('anteprima…'), findsOneWidget);
    expect(_glyphPaintCount(tester), 0);

    // The controller is the single source of truth: this is exactly what
    // the on-screen keyboard's insert logic does (see CustomKeyboard).
    controller.text = 'A1';
    await tester.pump();

    // The internal text stays plain...
    expect(controller.text, 'A1');
    // ...but the preview shows a hand-drawn glyph for A and leaves 1 as text.
    expect(_glyphPaintCount(tester), 1);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('anteprima…'), findsNothing);
  });

  testWidgets('custom mode off falls back to plain text in the live preview', (tester) async {
    final alphabet = Alphabet.blank().withGlyph(Glyph.empty('A').copyWith(strokes: [_stroke]));
    final controller = TextEditingController(text: 'A1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveGlyphPreview(controller: controller, alphabet: alphabet, customEnabled: false),
        ),
      ),
    );

    expect(_glyphPaintCount(tester), 0);
    expect(find.text('A1'), findsOneWidget);
  });
}
