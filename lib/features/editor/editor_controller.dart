import 'package:flutter/material.dart';

import '../../core/models/glyph.dart';
import '../../core/models/stroke.dart';

/// Drives one letter's drawing surface: accumulates strokes as the user
/// draws, and supports clear / undo / redo before the letter is saved.
class EditorController extends ChangeNotifier {
  final double canvasSize;

  List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  List<StrokePoint> _liveStroke = [];

  EditorController({this.canvasSize = 280});

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  List<StrokePoint> get liveStroke => List.unmodifiable(_liveStroke);
  bool get hasContent => _strokes.isNotEmpty || _liveStroke.isNotEmpty;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void loadGlyph(Glyph glyph) {
    _strokes = List.of(glyph.strokes);
    _redoStack.clear();
    _liveStroke = [];
    notifyListeners();
  }

  void startStroke(Offset position) {
    _liveStroke = [
      StrokePoint(
        x: position.dx,
        y: position.dy,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    notifyListeners();
  }

  void appendPoint(Offset position) {
    if (_liveStroke.isEmpty) return;
    _liveStroke = [
      ..._liveStroke,
      StrokePoint(
        x: position.dx,
        y: position.dy,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    notifyListeners();
  }

  void endStroke() {
    if (_liveStroke.isEmpty) return;
    _strokes = [..._strokes, Stroke(points: _liveStroke)];
    _liveStroke = [];
    _redoStack.clear();
    notifyListeners();
  }

  /// "Cancella": wipes the canvas completely.
  void clear() {
    _strokes = [];
    _liveStroke = [];
    _redoStack.clear();
    notifyListeners();
  }

  /// "Annulla": removes the last stroke.
  void undo() {
    if (_strokes.isEmpty) return;
    final last = _strokes.last;
    _strokes = _strokes.sublist(0, _strokes.length - 1);
    _redoStack.add(last);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final stroke = _redoStack.removeLast();
    _strokes = [..._strokes, stroke];
    notifyListeners();
  }

  Glyph buildGlyph(String character) {
    return Glyph(
      character: character,
      strokes: _strokes,
      width: canvasSize,
      height: canvasSize,
      baseline: canvasSize * 0.82,
      updatedAt: DateTime.now(),
    );
  }
}
