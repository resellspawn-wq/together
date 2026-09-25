import 'package:flutter/material.dart';

import '../../core/models/alphabet.dart';
import '../../theme/theme.dart';
import '../../widgets/glyph/glyph_view.dart';

enum _KeyboardTab { letters, symbols, emoji }

const List<String> _row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
const List<String> _row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
const List<String> _row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];
const List<String> _numberRow = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
const List<String> _punctuation = ['.', ',', '?', '!', "'", '"', '-', ':', ';', '/', '(', ')', '@', '#', '%', '&'];
const List<String> _emoji = [
  '😀', '😂', '😍', '😘', '😊', '😉', '😢', '😮', '👍', '👎',
  '❤️', '🔥', '🎉', '🙏', '👋', '✨', '💯', '😴', '🤔', '😎',
];

/// The app's own in-app keyboard (section 7 of the spec): tapping a
/// letter key inserts the plain character "A" into the text field — the
/// glyph shown on the key is purely visual, the underlying text stays
/// normal so [CustomText] can render it anywhere later.
class CustomKeyboard extends StatefulWidget {
  final Alphabet alphabet;
  final bool showCustomGlyphs;
  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  const CustomKeyboard({
    super.key,
    required this.alphabet,
    required this.onCharacter,
    required this.onBackspace,
    required this.onEnter,
    this.showCustomGlyphs = true,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  _KeyboardTab _tab = _KeyboardTab.letters;
  bool _shift = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: switch (_tab) {
                _KeyboardTab.letters => _buildLetters(),
                _KeyboardTab.symbols => _buildSymbols(),
                _KeyboardTab.emoji => _buildEmoji(),
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildLetters() {
    return Column(
      key: const ValueKey('letters'),
      children: [
        _keyRow(_row1.map(_letterKey).toList()),
        const SizedBox(height: AppSpacing.sm),
        _keyRow(_row2.map(_letterKey).toList()),
        const SizedBox(height: AppSpacing.sm),
        _keyRow([
          _iconKey(
            icon: AppIcons.arrowFatUp,
            onTap: () => setState(() => _shift = !_shift),
            highlighted: _shift,
          ),
          ..._row3.map(_letterKey),
          _iconKey(icon: AppIcons.backspace, onTap: widget.onBackspace),
        ]),
      ],
    );
  }

  Widget _buildSymbols() {
    return Column(
      key: const ValueKey('symbols'),
      children: [
        _keyRow(_numberRow.map((c) => _charKey(c)).toList()),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _punctuation.map((c) => _charKey(c, flexWidth: 40)).toList(),
        ),
      ],
    );
  }

  Widget _buildEmoji() {
    return Wrap(
      key: const ValueKey('emoji'),
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _emoji.map((e) => _charKey(e, flexWidth: 40)).toList(),
    );
  }

  // No "invio" key here — sending is handled by the single send button
  // next to the live preview above the keyboard, so there's only ever
  // one way to send a message on screen. The tab switcher sits as a
  // compact group on the left; an invisible spacer of the same width on
  // the right balances it out, so the spacebar between them lands truly
  // centered — like the space bar on iOS' own keyboard.
  Widget _buildBottomRow() {
    return Row(
      children: [
        _tabToggle(_KeyboardTab.letters, 'ABC'),
        _tabToggle(_KeyboardTab.symbols, '123'),
        _tabToggle(_KeyboardTab.emoji, '🙂'),
        Expanded(
          flex: 14,
          child: _key(
            onTap: () => widget.onCharacter(' '),
            child: Text('spazio', style: AppTypography.label(color: AppColors.inkSoft)),
          ),
        ),
        const Expanded(flex: 6, child: SizedBox.shrink()),
      ],
    );
  }

  Widget _tabToggle(_KeyboardTab tab, String label) {
    final selected = _tab == tab;
    return Expanded(
      flex: 2,
      child: _key(
        onTap: () => setState(() => _tab = tab),
        highlighted: selected,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.label(color: selected ? AppColors.berry : AppColors.inkSoft),
          ),
        ),
      ),
    );
  }

  Widget _letterKey(String lower) {
    final display = _shift ? lower.toUpperCase() : lower;
    return Expanded(
      child: _key(
        onTap: () => widget.onCharacter(display),
        child: widget.showCustomGlyphs
            ? GlyphView(
                glyph: widget.alphabet.glyphFor(lower),
                fallbackChar: display,
                size: 28,
              )
            : Text(display, style: AppTypography.body()),
      ),
    );
  }

  Widget _charKey(String char, {double? flexWidth}) {
    final key = _key(onTap: () => widget.onCharacter(char), child: Text(char, style: AppTypography.body()));
    if (flexWidth != null) return SizedBox(width: flexWidth, height: 44, child: key);
    return Expanded(child: key);
  }

  Widget _iconKey({required IconData icon, required VoidCallback onTap, bool highlighted = false}) {
    return Expanded(
      child: _key(onTap: onTap, highlighted: highlighted, child: Icon(icon, size: 18)),
    );
  }

  Widget _key({required VoidCallback onTap, required Widget child, bool highlighted = false, bool filled = false}) {
    final backgroundColor = filled
        ? AppColors.fuchsia
        : highlighted
            ? AppColors.blush
            : AppColors.white;
    final foregroundColor = filled ? AppColors.white : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: filled ? null : Border.all(color: AppColors.chromeMid, width: 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            // Fires on touch-down rather than waiting for the full tap
            // gesture to resolve on release — shaves the recognition
            // delay off every keystroke, which matters a lot when typing
            // fast. onTap is kept (as a no-op trigger already handled by
            // onTapDown) purely so the ink ripple still plays normally.
            onTapDown: (_) => onTap(),
            onTap: () {},
            child: SizedBox(
              height: 44,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: foregroundColor),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: foregroundColor),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyRow(List<Widget> children) {
    return Row(children: children);
  }
}
