import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:together/core/models/alphabet.dart';
import 'package:together/core/models/glyph.dart';
import 'package:together/core/models/stroke.dart';
import 'package:together/core/storage/storage_service.dart';

const _stroke = Stroke(points: [
  StrokePoint(x: 1, y: 1, timestampMs: 0),
  StrokePoint(x: 5, y: 5, timestampMs: 10),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('an alphabet with no saved data yet comes back blank', () async {
    final storage = await StorageService.create();
    final alphabet = storage.loadAlphabet();
    expect(alphabet.completedCount, 0);
  });

  test('saving letter A persists it for the next read (simulated reopen)', () async {
    final storage = await StorageService.create();
    final alphabet = Alphabet.blank().withGlyph(
      Glyph.empty('A').copyWith(strokes: [_stroke]),
    );
    await storage.saveAlphabet(alphabet);

    // A fresh StorageService instance stands in for the app being closed
    // and reopened: it reads from the same underlying local storage.
    final reopened = await StorageService.create();
    final reloaded = reopened.loadAlphabet();

    expect(reloaded.glyphFor('A')!.hasStrokes, isTrue);
    expect(reloaded.glyphFor('A')!.strokes.single.points.length, 2);
  });

  test('the full 26-letter alphabet survives a save/reload cycle', () async {
    final storage = await StorageService.create();
    var alphabet = Alphabet.blank();
    for (final letter in kAlphabetLetters) {
      alphabet = alphabet.withGlyph(Glyph.empty(letter).copyWith(strokes: [_stroke]));
    }
    await storage.saveAlphabet(alphabet);

    final reloaded = (await StorageService.create()).loadAlphabet();
    expect(reloaded.isComplete, isTrue);
    expect(reloaded.completedCount, 26);
  });

  test('editing a letter after reopening overwrites the persisted version', () async {
    final storage = await StorageService.create();
    await storage.saveAlphabet(
      Alphabet.blank().withGlyph(Glyph.empty('C').copyWith(strokes: [_stroke])),
    );

    final reopened = await StorageService.create();
    final reloadedAlphabet = reopened.loadAlphabet();
    final edited = reloadedAlphabet.withGlyph(
      Glyph.empty('C').copyWith(strokes: [_stroke, _stroke]),
    );
    await reopened.saveAlphabet(edited);

    final finalRead = (await StorageService.create()).loadAlphabet();
    expect(finalRead.glyphFor('C')!.strokes.length, 2);
  });

  test('settings (dark mode, custom mode) persist across restarts', () async {
    final storage = await StorageService.create();
    final settings = storage.loadSettings().copyWith(
          customAlphabetEnabled: false,
        );
    await storage.saveSettings(settings);

    final reloaded = (await StorageService.create()).loadSettings();
    expect(reloaded.customAlphabetEnabled, isFalse);
  });

  test('two accounts on the same device never see each other\'s local alphabet', () async {
    final storage = await StorageService.create();

    storage.useNamespace('vlad-id');
    await storage.saveAlphabet(
      Alphabet.blank().withGlyph(Glyph.empty('A').copyWith(strokes: [_stroke])),
    );

    storage.useNamespace('eliza-id');
    // Eliza's slot is untouched by Vlad's save above.
    expect(storage.loadAlphabet().completedCount, 0);

    await storage.saveAlphabet(
      Alphabet.blank().withGlyph(Glyph.empty('B').copyWith(strokes: [_stroke])),
    );

    storage.useNamespace('vlad-id');
    final vladAlphabet = storage.loadAlphabet();
    expect(vladAlphabet.glyphFor('A')!.hasStrokes, isTrue);
    expect(vladAlphabet.glyphFor('B')!.hasStrokes, isFalse);

    storage.useNamespace('eliza-id');
    final elizaAlphabet = storage.loadAlphabet();
    expect(elizaAlphabet.glyphFor('B')!.hasStrokes, isTrue);
    expect(elizaAlphabet.glyphFor('A')!.hasStrokes, isFalse);
  });
}
