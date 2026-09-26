import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/custom_text/custom_text.dart';

/// Drop-in replacement for [Text] used for the app's own UI chrome
/// (titles, buttons, labels, menu items — anything that isn't a chat
/// message, which already renders through [CustomText]/`AnimatedGlyphText`
/// with the *sender's* alphabet). When "Alfabeto personalizzato" is on and
/// the signed-in user has a complete alphabet, every one of these labels
/// is drawn with their own handwriting too, not just messages.
///
/// Falls back to plain [Text] otherwise, so nothing changes for anyone
/// who hasn't finished drawing their alphabet or has the setting off.
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final useCustom = appState.settings.customAlphabetEnabled && appState.alphabet.isComplete;
    if (!useCustom) {
      return Text(
        data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }

    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return CustomText(
      data,
      alphabet: appState.alphabet,
      fontSize: effectiveStyle.fontSize ?? 16,
      color: effectiveStyle.color,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
