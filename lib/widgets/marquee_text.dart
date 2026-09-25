import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A thin, slow, constant-speed horizontal scrolling line — the
/// "scritto a mano · solo per te · together" touch on key screens
/// (splash/home). Two copies of the text are placed back to back and
/// scrolled together, so the loop is seamless. Falls back to a static,
/// truncated line when reduced motion is requested.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText(this.text, {super.key, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppTypography.marquee();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final content = '${widget.text}    ';

    if (reduceMotion) {
      return Text(content, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final painter = TextPainter(
      text: TextSpan(text: content, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = painter.width;

    final duration = Duration(
      milliseconds: (textWidth / AppMotion.marqueeSpeedPxPerSecond * 1000).round().clamp(4000, 60000),
    );
    if (_controller.duration != duration) {
      _controller.duration = duration;
    }

    return ClipRect(
      child: SizedBox(
        height: painter.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dx = -_controller.value * textWidth;
            return Stack(
              children: [
                Positioned(left: dx, top: 0, child: Text(content, style: style, maxLines: 1)),
                Positioned(left: dx + textWidth, top: 0, child: Text(content, style: style, maxLines: 1)),
              ],
            );
          },
        ),
      ),
    );
  }
}
