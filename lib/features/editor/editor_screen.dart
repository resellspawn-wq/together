import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../core/models/alphabet.dart';
import '../../theme/theme.dart';
import 'drawing_canvas.dart';
import 'editor_controller.dart';

/// The "Crea il tuo alfabeto" editor: one letter at a time, draw, clear,
/// undo/redo, save. Used both for the linear onboarding flow (A -> Z)
/// and for re-editing a single already-saved letter from the alphabet
/// preview screen.
class EditorScreen extends StatefulWidget {
  /// Index into [kAlphabetLetters] to start on.
  final int startIndex;

  /// Sequential (onboarding) mode auto-advances to the next letter after
  /// saving, and calls [onSequenceComplete] after Z is saved.
  final bool sequential;
  final VoidCallback? onSequenceComplete;

  const EditorScreen({
    super.key,
    this.startIndex = 0,
    this.sequential = false,
    this.onSequenceComplete,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late int _index;
  late EditorController _controller;

  String get _letter => kAlphabetLetters[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _controller = EditorController();
    _loadCurrentGlyph();
  }

  void _loadCurrentGlyph() {
    final alphabet = AppScope.readOf(context).alphabet;
    final glyph = alphabet.glyphFor(_letter);
    if (glyph != null) _controller.loadGlyph(glyph);
  }

  void _goTo(int newIndex) {
    if (newIndex < 0 || newIndex >= kAlphabetLetters.length) return;
    setState(() {
      _index = newIndex;
      _controller = EditorController();
      _loadCurrentGlyph();
    });
  }

  Future<void> _save() async {
    final state = AppScope.readOf(context);
    final backend = BackendScope.readOf(context);
    final glyph = _controller.buildGlyph(_letter);
    await state.saveGlyph(glyph);
    // Best-effort cloud sync so conversation partners see the update; the
    // local save above already succeeded regardless of network state.
    unawaited(backend.pushGlyph(glyph));
    if (!mounted) return;

    final isLast = _index == kAlphabetLetters.length - 1;
    if (widget.sequential && !isLast) {
      _goTo(_index + 1);
    } else if (widget.sequential && isLast) {
      widget.onSequenceComplete?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alphabet = AppScope.of(context).alphabet;
    final completed = alphabet.completedCount;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.sequential ? 'Crea il tuo alfabeto' : 'Modifica lettera',
            style: AppTypography.titleCompact(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      icon: const Icon(AppIcons.caretLeft),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppMotion.base,
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exit,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(_index),
                          children: [
                            Text(_letter, style: AppTypography.hero()),
                            Text(
                              '$_letter · ${_index + 1} / ${kAlphabetLetters.length}',
                              style: AppTypography.bodySmall(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _canGoNext(alphabet) ? () => _goTo(_index + 1) : null,
                      icon: const Icon(AppIcons.caretRight),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: completed / kAlphabetLetters.length,
                    backgroundColor: AppColors.mist,
                    color: AppColors.fuchsia,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Expanded(
                  child: Center(
                    child: DrawingCanvas(controller: _controller),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _controller.hasContent ? _controller.clear : null,
                          icon: const Icon(AppIcons.trash, size: 18),
                          label: const Text('Cancella'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      _RoundIconButton(
                        icon: AppIcons.arrowUUpLeft,
                        onPressed: _controller.canUndo ? _controller.undo : null,
                        tooltip: 'Annulla',
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      _RoundIconButton(
                        icon: AppIcons.arrowUUpRight,
                        onPressed: _controller.canRedo ? _controller.redo : null,
                        tooltip: 'Ripeti',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => FilledButton(
                      onPressed: _controller.hasContent ? _save : null,
                      child: Text(_primaryLabel()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// In sequential (onboarding) mode you can only step forward past a
  /// letter you've already drawn and saved — forward progress is driven
  /// by "SALVA E CONTINUA", not by skipping ahead to Z. Standalone
  /// editing (from the alphabet preview) has no such restriction.
  bool _canGoNext(Alphabet alphabet) {
    if (_index >= kAlphabetLetters.length - 1) return false;
    if (!widget.sequential) return true;
    return alphabet.glyphFor(kAlphabetLetters[_index + 1])?.hasStrokes ?? false;
  }

  String _primaryLabel() {
    if (!widget.sequential) return 'SALVA LETTERA';
    return _index == kAlphabetLetters.length - 1 ? 'COMPLETA' : 'SALVA E CONTINUA';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _RoundIconButton({required this.icon, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.chromeMid, width: 1.2),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.ink : AppColors.inkSoft.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
