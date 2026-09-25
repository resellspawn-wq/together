import 'package:flutter/material.dart';

import '../../core/models/glyph.dart';

/// Paints a [Glyph]'s strokes scaled from their original drawing canvas
/// into whatever box this painter is given. Used everywhere a custom
/// letter needs to be shown: editor preview, keyboard keys, alphabet
/// grid, chat bubbles.
class GlyphPainter extends CustomPainter {
  final Glyph glyph;
  final Color color;
  final double strokeWidth;

  GlyphPainter({
    required this.glyph,
    required this.color,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glyph.strokes.isEmpty) return;

    final scaleX = size.width / glyph.width;
    final scaleY = size.height / glyph.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - glyph.width * scale) / 2;
    final offsetY = (size.height - glyph.height * scale) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in glyph.strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      final first = stroke.points.first;
      path.moveTo(offsetX + first.x * scale, offsetY + first.y * scale);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(offsetX + point.x * scale, offsetY + point.y * scale);
      }
      if (stroke.points.length == 1) {
        // A tap with no movement: draw a dot so it isn't invisible.
        canvas.drawCircle(
          Offset(offsetX + first.x * scale, offsetY + first.y * scale),
          paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlyphPainter oldDelegate) {
    return oldDelegate.glyph.updatedAt != glyph.updatedAt ||
        oldDelegate.glyph.strokes.length != glyph.strokes.length ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
