import 'package:flutter/material.dart';

import '../../core/models/alphabet.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_text/custom_text.dart';

/// The fix for "while typing, the field shows plain letters instead of
/// the custom alphabet": this widget sits above the real (plain-text)
/// input field and mirrors its content live, through [CustomText], as
/// the user types. It never touches [controller]'s text — it only reads
/// it — so editing (cursor, selection, backspace, the on-screen keyboard)
/// keeps working exactly as before, unmodified.
///
/// Deliberately instant (no stroke-draw animation) — it redraws on every
/// keystroke, so animating it would fight itself. Only posted messages
/// in the chat list get the handwriting reveal (see AnimatedGlyphText).
class LiveGlyphPreview extends StatelessWidget {
  final TextEditingController controller;
  final Alphabet alphabet;
  final bool customEnabled;

  const LiveGlyphPreview({
    super.key,
    required this.controller,
    required this.alphabet,
    required this.customEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.blush.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.chromeLight, width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: value.text.isEmpty
              ? Text('anteprima…', style: AppTypography.label(color: AppColors.inkSoft))
              : CustomText(value.text, alphabet: alphabet, enabled: customEnabled, fontSize: 20),
        );
      },
    );
  }
}
