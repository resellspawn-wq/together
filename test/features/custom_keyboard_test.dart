import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:together/core/models/alphabet.dart';
import 'package:together/features/keyboard/custom_keyboard.dart';
import 'package:together/theme/theme.dart';

void main() {
  testWidgets('tapping a letter key inserts the plain lowercase character', (tester) async {
    String? inserted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomKeyboard(
            alphabet: Alphabet.blank(),
            onCharacter: (c) => inserted = c,
            onBackspace: () {},
            onEnter: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('a').first);
    await tester.pump();

    expect(inserted, 'a');
  });

  testWidgets('shift makes the next letter tap insert an uppercase character', (tester) async {
    String? inserted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomKeyboard(
            alphabet: Alphabet.blank(),
            onCharacter: (c) => inserted = c,
            onBackspace: () {},
            onEnter: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(AppIcons.arrowFatUp));
    await tester.pump();
    // Once shifted, the key itself now shows the uppercase letter.
    await tester.tap(find.text('A').first);
    await tester.pump();

    expect(inserted, 'A');
  });

  testWidgets('backspace and enter fire their callbacks', (tester) async {
    var backspaceCount = 0;
    var enterCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomKeyboard(
            alphabet: Alphabet.blank(),
            onCharacter: (_) {},
            onBackspace: () => backspaceCount++,
            onEnter: () => enterCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(AppIcons.backspace));
    await tester.tap(find.byIcon(AppIcons.paperPlaneTilt));
    await tester.pump();

    expect(backspaceCount, 1);
    expect(enterCount, 1);
  });

  testWidgets('switching to the numbers tab shows digits and punctuation, not letters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomKeyboard(
            alphabet: Alphabet.blank(),
            onCharacter: (_) {},
            onBackspace: () {},
            onEnter: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('123'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);
  });
}
