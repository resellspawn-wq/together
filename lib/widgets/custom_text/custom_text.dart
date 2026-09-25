import 'package:flutter/material.dart';

import '../../core/models/alphabet.dart';
import '../glyph/glyph_view.dart';

final RegExp _asciiLetter = RegExp(r'^[a-zA-Z]$');

/// The custom renderer described in the spec: text is kept as plain,
/// semantically normal text everywhere (state, storage, text fields) and
/// only turned into hand-drawn glyphs at the very last step, for display.
///
/// - a-z / A-Z -> the user's glyph for that letter (falls back to plain
///   text if that letter hasn't been drawn yet).
/// - everything else (digits, punctuation, symbols, emoji, whitespace) ->
///   left completely untouched.
///
/// When [enabled] is false (the "Normal / Custom" setting), this renders
/// as plain text, which also doubles as the accessibility fallback.
class CustomText extends StatelessWidget {
  final String text;
  final Alphabet alphabet;
  final bool enabled;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  const CustomText(
    this.text, {
    super.key,
    required this.alphabet,
    this.enabled = true,
    this.fontSize = 20,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, color: color),
      );
    }

    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    final clusters = text.characters;

    final children = <Widget>[];
    for (final cluster in clusters) {
      if (_asciiLetter.hasMatch(cluster)) {
        final upper = cluster.toUpperCase();
        final glyph = alphabet.glyphFor(upper);
        children.add(
          GlyphView(
            glyph: glyph,
            fallbackChar: cluster,
            size: fontSize * 1.3,
            color: resolvedColor,
          ),
        );
      } else if (cluster == ' ') {
        children.add(SizedBox(width: fontSize * 0.45, height: fontSize * 1.3));
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              cluster,
              style: TextStyle(fontSize: fontSize, color: resolvedColor, height: 1),
            ),
          ),
        );
      }
    }

    return Wrap(
      alignment: switch (textAlign) {
        TextAlign.center => WrapAlignment.center,
        TextAlign.end || TextAlign.right => WrapAlignment.end,
        _ => WrapAlignment.start,
      },
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: children,
    );
  }
}
