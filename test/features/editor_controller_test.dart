import 'package:flutter_test/flutter_test.dart';
import 'package:together/features/editor/editor_controller.dart';

void main() {
  group('EditorController', () {
    test('drawing a stroke adds it once the gesture ends', () {
      final controller = EditorController();
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(10, 10));
      controller.appendPoint(const Offset(20, 5));
      controller.endStroke();

      expect(controller.strokes, hasLength(1));
      expect(controller.strokes.single.points, hasLength(3));
      expect(controller.hasContent, isTrue);
    });

    test('clear ("Cancella") wipes every stroke', () {
      final controller = EditorController();
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(5, 5));
      controller.endStroke();

      controller.clear();

      expect(controller.strokes, isEmpty);
      expect(controller.hasContent, isFalse);
    });

    test('undo ("Annulla") removes only the last stroke', () {
      final controller = EditorController();
      for (var i = 0; i < 2; i++) {
        controller.startStroke(Offset(i.toDouble(), 0));
        controller.appendPoint(Offset(i.toDouble(), 10));
        controller.endStroke();
      }
      expect(controller.strokes, hasLength(2));

      controller.undo();

      expect(controller.strokes, hasLength(1));
      expect(controller.canRedo, isTrue);
    });

    test('redo brings back an undone stroke', () {
      final controller = EditorController();
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(1, 1));
      controller.endStroke();

      controller.undo();
      expect(controller.strokes, isEmpty);

      controller.redo();
      expect(controller.strokes, hasLength(1));
    });

    test('drawing a new stroke after an undo clears the redo stack', () {
      final controller = EditorController();
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(1, 1));
      controller.endStroke();
      controller.undo();

      controller.startStroke(const Offset(5, 5));
      controller.appendPoint(const Offset(6, 6));
      controller.endStroke();

      expect(controller.canRedo, isFalse);
    });

    test('buildGlyph produces a glyph for the requested character', () {
      final controller = EditorController(canvasSize: 200);
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(50, 50));
      controller.endStroke();

      final glyph = controller.buildGlyph('A');

      expect(glyph.character, 'A');
      expect(glyph.width, 200);
      expect(glyph.hasStrokes, isTrue);
    });

    test('loading an existing glyph seeds the canvas for re-editing', () {
      final controller = EditorController();
      controller.startStroke(const Offset(0, 0));
      controller.appendPoint(const Offset(1, 1));
      controller.endStroke();
      final glyph = controller.buildGlyph('D');

      final fresh = EditorController();
      fresh.loadGlyph(glyph);

      expect(fresh.strokes, hasLength(1));
      expect(fresh.canRedo, isFalse);
    });
  });
}
