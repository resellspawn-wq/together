import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_welcome_screen.dart';
import 'login_screen.dart';

/// Decides what the user sees at the root of the app: signed out ->
/// login; signed in -> the existing local onboarding-or-home flow,
/// untouched.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = BackendScope.of(context);
    if (!session.isSignedIn) return const LoginScreen();

    final appState = AppScope.of(context);
    // A complete alphabet counts as onboarded even if `onboardingComplete`
    // was never set on this device — e.g. it was just pulled from the
    // cloud on a new device (see _pullAlphabetIfLocalIsEmpty in main.dart),
    // which fills in the glyphs but doesn't flip that local flag.
    final onboarded = appState.settings.onboardingComplete || appState.alphabet.isComplete;
    return onboarded ? const HomeScreen() : const OnboardingWelcomeScreen();
  }
}
