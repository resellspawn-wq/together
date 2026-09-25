import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:together/features/editor/drawing_canvas.dart';
import 'package:together/features/editor/editor_controller.dart';

void main() {
  testWidgets('dragging across the canvas records a stroke on the controller', (tester) async {
    final controller = EditorController(canvasSize: 240);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: DrawingCanvas(controller: controller)),
        ),
      ),
    );

    final canvasCenter = tester.getCenter(find.byType(DrawingCanvas));
    final gesture = await tester.startGesture(canvasCenter);
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.strokes, hasLength(1));
    expect(controller.hasContent, isTrue);
  });
}
