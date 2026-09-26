import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/models/alphabet.dart';
import '../../widgets/custom_text/custom_text.dart';
import '../../widgets/glyph/glyph_view.dart';
import '../editor/editor_screen.dart';
import '../../widgets/app_text.dart';

/// Shows the whole A-Z grid with each letter's own glyph, a live "prova a
/// scrivere" field, and lets the user tap any letter to jump into the
/// editor and redraw it — writing straight back into the single shared
/// [Alphabet], so every other screen picks up the change immediately.
class AlphabetPreviewScreen extends StatefulWidget {
  final bool focusTryField;

  const AlphabetPreviewScreen({super.key, this.focusTryField = false});

  @override
  State<AlphabetPreviewScreen> createState() => _AlphabetPreviewScreenState();
}

class _AlphabetPreviewScreenState extends State<AlphabetPreviewScreen> {
  final TextEditingController _tryController = TextEditingController(text: 'Ciao amore ❤️ 123!');
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.focusTryField) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _tryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _editLetter(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(startIndex: index, sequential: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final alphabet = state.alphabet;

    return Scaffold(
      appBar: AppBar(title: const AppText('Il tuo alfabeto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kAlphabetLetters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final letter = kAlphabetLetters[index];
                final glyph = alphabet.glyphFor(letter);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _editLetter(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: (glyph?.hasStrokes ?? false)
                          ? null
                          : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: GlyphView(glyph: glyph, fallbackChar: letter, size: 44),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            AppText('Prova a scrivere qualcosa', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _tryController,
              focusNode: _focusNode,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Scrivi qui...'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(
                _tryController.text,
                alphabet: alphabet,
                enabled: state.settings.customAlphabetEnabled,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
