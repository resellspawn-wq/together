import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/theme.dart';

/// The "mesh drift" effect (see shaders/mesh_background.frag): a handful
/// of soft colored blobs, in the app's own palette, slowly drifting and
/// blending into each other. Renders behind [child], optionally at
/// reduced opacity so content on top stays readable. Falls back to the
/// plain [AnimatedGradientBackground]-style flat gradient if the
/// fragment shader fails to load (older browsers / reduced motion).
class MeshBackground extends StatefulWidget {
  final Widget child;
  final double opacity;

  const MeshBackground({super.key, required this.child, this.opacity = 1});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/mesh_background.frag');
      if (!mounted) return;
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      setState(() => _shader = program.fragmentShader());
      if (!reduceMotion) {
        _ticker = createTicker((elapsed) {
          setState(() => _elapsed = elapsed);
        })
          ..start();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (_failed || shader == null) {
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: widget.child,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: widget.opacity,
            child: CustomPaint(
              painter: _MeshPainter(shader: shader, time: _elapsed.inMilliseconds / 1000),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _MeshPainter({required this.shader, required this.time});

  static const List<Color> _colors = [
    AppColors.blush,
    AppColors.mist,
    AppColors.mauve,
    AppColors.fuchsia,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);

    var index = 3;
    for (final color in _colors) {
      shader
        ..setFloat(index++, color.r)
        ..setFloat(index++, color.g)
        ..setFloat(index++, color.b);
    }

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => oldDelegate.time != time;
}
