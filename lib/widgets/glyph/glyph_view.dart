import 'package:flutter/material.dart';

import '../../core/models/glyph.dart';
import 'glyph_painter.dart';

/// Renders a single letter as the user's hand-drawn glyph when one
/// exists, falling back to plain text otherwise (an un-drawn letter,
/// mid-onboarding, or an app-wide "custom off" preference — see
/// CustomText). This is the only place glyph pixels get painted; every
/// other widget in the app goes through here.
class GlyphView extends StatelessWidget {
  final Glyph? glyph;

  /// The literal character to fall back to (keeps original case).
  final String fallbackChar;
  final double size;
  final Color? color;

  const GlyphView({
    super.key,
    required this.glyph,
    required this.fallbackChar,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;

    if (glyph == null || !glyph!.hasStrokes) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            fallbackChar,
            style: TextStyle(
              fontSize: size * 0.72,
              color: resolvedColor,
              height: 1,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GlyphPainter(glyph: glyph!, color: resolvedColor),
      ),
    );
  }
}
