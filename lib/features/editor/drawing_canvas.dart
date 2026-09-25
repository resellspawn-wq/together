import 'package:flutter/material.dart';

import '../../core/models/stroke.dart';
import '../../theme/theme.dart';
import 'editor_controller.dart';

/// The touch surface for drawing one letter. Captures raw finger
/// movement as a list of points per stroke (not a screenshot), so the
/// data stays fully vector and re-editable.
class DrawingCanvas extends StatelessWidget {
  final EditorController controller;

  const DrawingCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GestureDetector(
          onPanStart: (details) => controller.startStroke(details.localPosition),
          onPanUpdate: (details) => controller.appendPoint(details.localPosition),
          onPanEnd: (_) => controller.endStroke(),
          onPanCancel: controller.endStroke,
          child: Container(
            width: controller.canvasSize,
            height: controller.canvasSize,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: AppColors.chromeMid, width: 1.2),
              boxShadow: AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: controller.strokes,
                  liveStroke: controller.liveStroke,
                  color: AppColors.ink,
                ),
                size: Size(controller.canvasSize, controller.canvasSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<StrokePoint> liveStroke;
  final Color color;

  _CanvasPainter({
    required this.strokes,
    required this.liveStroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawPoints(List<StrokePoint> points) {
      if (points.isEmpty) return;
      if (points.length == 1) {
        canvas.drawCircle(
          Offset(points.first.x, points.first.y),
          paint.strokeWidth / 2,
          Paint()..color = color,
        );
        return;
      }
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (final p in points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawPoints(stroke.points);
    }
    drawPoints(liveStroke);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.liveStroke.length != liveStroke.length ||
        oldDelegate.color != color;
  }
}
