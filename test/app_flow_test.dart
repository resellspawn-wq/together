import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:together/core/app_scope.dart';
import 'package:together/core/app_state.dart';
import 'package:together/core/backend_scope.dart';
import 'package:together/core/storage/storage_service.dart';
import 'package:together/features/auth/auth_gate.dart';
import 'package:together/features/auth/login_screen.dart';
import 'package:together/features/editor/drawing_canvas.dart';
import 'package:together/features/onboarding/onboarding_welcome_screen.dart';
import 'package:together/theme/theme.dart';

import 'support/test_backend.dart';

void main() {
  testWidgets('signed out lands on the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final appState = AppState(storage);
    final session = buildTestSession(storage);

    await tester.pumpWidget(
      AppScope(
        state: appState,
        child: BackendScope(
          state: session,
          child: MaterialApp(theme: AppTheme.light, home: const AuthGate()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('onboarding: start, draw A, save, and land on B with progress updated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final appState = AppState(storage);
    final session = buildTestSession(storage);

    await tester.pumpWidget(
      AppScope(
        state: appState,
        child: BackendScope(
          state: session,
          child: MaterialApp(theme: AppTheme.light, home: const OnboardingWelcomeScreen()),
        ),
      ),
    );
    // Not pumpAndSettle: the welcome screen has an intentionally infinite
    // background drift + marquee animation, which would never "settle".
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('CREA IL TUO'), findsOneWidget);
    expect(find.text('alfabeto'), findsOneWidget);

    await tester.tap(find.text('INIZIA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    // We land on the editor for letter A.
    expect(find.text('A · 1 / 26'), findsOneWidget);

    final canvasCenter = tester.getCenter(find.byType(DrawingCanvas));
    final gesture = await tester.startGesture(canvasCenter);
    await gesture.moveBy(const Offset(40, 0));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('SALVA E CONTINUA'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('B · 2 / 26'), findsOneWidget);
    expect(appState.alphabet.glyphFor('A')!.hasStrokes, isTrue);
    expect(appState.alphabet.completedCount, 1);
  });
}
