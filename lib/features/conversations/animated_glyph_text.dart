import 'package:flutter/material.dart';

import '../../core/models/alphabet.dart';
import '../../core/models/glyph.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_text/custom_text.dart';

final RegExp _asciiLetter = RegExp(r'^[a-zA-Z]$');

/// Renders [text] exactly like [CustomText] — A-Z become the sender's
/// hand-drawn glyphs, everything else (digits, punctuation, emoji,
/// spaces) stays plain — but when [animate] is true, it plays the whole
/// message back in reading order as if it were being written live: each
/// letter's strokes draw progressively (PathMetrics), non-letters take a
/// brief beat of their own so the reveal stays in order.
///
/// Use `animate: true` only for a message that just appeared (sent or
/// received this session); history loaded when a conversation opens
/// should pass `animate: false`, which renders instantly via the plain,
/// unanimated [CustomText] — no AnimationController is even created in
/// that case, so a long scrollback stays cheap.
class AnimatedGlyphText extends StatefulWidget {
  final String text;
  final Alphabet alphabet;
  final bool enabled;
  final bool animate;
  final double fontSize;
  final Color? color;

  const AnimatedGlyphText(
    this.text, {
    super.key,
    required this.alphabet,
    this.enabled = true,
    this.animate = true,
    this.fontSize = 18,
    this.color,
  });

  @override
  State<AnimatedGlyphText> createState() => _AnimatedGlyphTextState();
}

class _AnimatedGlyphTextState extends State<AnimatedGlyphText> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<_Slot> _slots = const [];

  bool get _shouldAnimate => widget.animate && widget.enabled;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (!_shouldAnimate) return;

    _slots = _buildSlots(widget.text, widget.alphabet);
    final totalMs = _slots.fold<int>(0, (sum, s) => sum + s.durationMs);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs == 0 ? 1 : totalMs),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !_shouldAnimate) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller!.value = 1;
    } else {
      _controller!.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static List<_Slot> _buildSlots(String text, Alphabet alphabet) {
    final slots = <_Slot>[];
    var cumulativeMs = 0;

    for (final cluster in text.characters) {
      if (_asciiLetter.hasMatch(cluster)) {
        final glyph = alphabet.glyphFor(cluster.toUpperCase());
        final durationMs = _glyphDurationMs(glyph);
        slots.add(_Slot(
          character: cluster,
          glyph: (glyph?.hasStrokes ?? false) ? glyph : null,
          startMs: cumulativeMs,
          durationMs: durationMs,
        ));
        cumulativeMs += durationMs;
      } else {
        final durationMs = AppMotion.plainCharacterReveal.inMilliseconds;
        slots.add(_Slot(
          character: cluster,
          glyph: null,
          startMs: cumulativeMs,
          durationMs: durationMs,
        ));
        cumulativeMs += durationMs;
      }
    }
    return slots;
  }

  static int _glyphDurationMs(Glyph? glyph) {
    if (glyph == null || !glyph.hasStrokes) return AppMotion.plainCharacterReveal.inMilliseconds;
    final totalLength = _totalStrokeLength(glyph);
    final reference = (glyph.width + glyph.height); // rough per-glyph scale
    final normalized = (totalLength / (reference * 1.6)).clamp(0.0, 1.0);
    final min = AppMotion.letterDrawMin.inMilliseconds;
    final max = AppMotion.letterDrawMax.inMilliseconds;
    return (min + normalized * (max - min)).round();
  }

  static double _totalStrokeLength(Glyph glyph) {
    var total = 0.0;
    for (final stroke in glyph.strokes) {
      for (var i = 1; i < stroke.points.length; i++) {
        final a = stroke.points[i - 1];
        final b = stroke.points[i];
        total += (Offset(b.x, b.y) - Offset(a.x, a.y)).distance;
      }
      if (stroke.points.length == 1) total += 1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) {
      return CustomText(
        widget.text,
        alphabet: widget.alphabet,
        enabled: widget.enabled,
        fontSize: widget.fontSize,
        color: widget.color,
      );
    }

    final resolvedColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final controller = _controller!;
    final totalMs = controller.duration!.inMilliseconds;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final elapsedMs = controller.value * totalMs;

        // Group consecutive non-space slots into one Row per word, so the
        // outer Wrap only breaks lines between whole words (WhatsApp-style)
        // instead of between individual glyphs. Grouping is purely visual
        // — each slot's own reveal progress/timing is unaffected.
        final lineChildren = <Widget>[];
        var currentWord = <Widget>[];
        void flushWord() {
          if (currentWord.isEmpty) return;
          lineChildren.add(Row(mainAxisSize: MainAxisSize.min, children: currentWord));
          currentWord = [];
        }

        for (final slot in _slots) {
          final progress = ((elapsedMs - slot.startMs) / slot.durationMs).clamp(0.0, 1.0);
          if (slot.character == ' ') {
            flushWord();
            lineChildren.add(SizedBox(width: widget.fontSize * 0.45, height: widget.fontSize * 1.3));
          } else if (slot.glyph != null) {
            currentWord.add(_AnimatedGlyph(
              glyph: slot.glyph!,
              color: resolvedColor,
              size: widget.fontSize * 1.3,
              progress: progress,
            ));
          } else {
            currentWord.add(_RevealingChar(
              character: slot.character,
              fontSize: widget.fontSize,
              color: resolvedColor,
              progress: progress,
            ));
          }
        }
        flushWord();

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: lineChildren,
        );
      },
    );
  }
}

class _Slot {
  final String character;
  final Glyph? glyph;
  final int startMs;
  final int durationMs;

  const _Slot({required this.character, required this.glyph, required this.startMs, required this.durationMs});
}

class _RevealingChar extends StatelessWidget {
  final String character;
  final double fontSize;
  final Color color;
  final double progress;

  const _RevealingChar({
    required this.character,
    required this.fontSize,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Text(
          character,
          style: AppTypography.messageText(color: color).copyWith(fontSize: fontSize, height: 1),
        ),
      ),
    );
  }
}

class _AnimatedGlyph extends StatelessWidget {
  final Glyph glyph;
  final Color color;
  final double size;
  final double progress;

  const _AnimatedGlyph({
    required this.glyph,
    required this.color,
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrokeRevealPainter(glyph: glyph, color: color, progress: progress),
      ),
    );
  }
}

/// Paints a glyph's strokes progressively, in order, budgeting
/// [progress] * total path length across strokes — a multi-stroke
/// letter draws stroke by stroke rather than all at once.
class _StrokeRevealPainter extends CustomPainter {
  final Glyph glyph;
  final Color color;
  final double progress;

  _StrokeRevealPainter({required this.glyph, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (glyph.strokes.isEmpty || progress <= 0) return;

    final scaleX = size.width / glyph.width;
    final scaleY = size.height / glyph.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - glyph.width * scale) / 2;
    final offsetY = (size.height - glyph.height * scale) / 2;

    // strokeWidth is NOT pre-multiplied by `scale` here: canvas.scale()
    // below already scales stroke widths for everything drawn after it,
    // so doing both would square the scale factor (e.g. 0.08 * 0.08),
    // shrinking the line to a fraction of a pixel — invisible.
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    final paths = <Path>[];
    final lengths = <double>[];
    var total = 0.0;
    for (final stroke in glyph.strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      var len = 0.0;
      for (final metric in path.computeMetrics()) {
        len += metric.length;
      }
      if (len == 0) len = 1;
      paths.add(path);
      lengths.add(len);
      total += len;
    }
    if (total == 0) total = 1;

    var budget = progress * total;
    for (var i = 0; i < paths.length; i++) {
      if (budget <= 0) break;
      final len = lengths[i];
      final stroke = glyph.strokes[i];
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(stroke.points.first.x, stroke.points.first.y),
          paint.strokeWidth / 2,
          Paint()..color = color,
        );
        budget -= len;
        continue;
      }
      if (budget >= len) {
        canvas.drawPath(paths[i], paint);
        budget -= len;
      } else {
        var remaining = budget;
        for (final metric in paths[i].computeMetrics()) {
          if (remaining <= 0) break;
          final take = remaining.clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(0, take), paint);
          remaining -= take;
        }
        budget = 0;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StrokeRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.glyph.updatedAt != glyph.updatedAt || oldDelegate.color != color;
  }
}
