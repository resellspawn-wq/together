import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named gradients built from [AppColors]. Screens should reach for these
/// instead of constructing a `LinearGradient` inline. Getters, not const
/// fields — [AppColors] resolves light/dark at read time, so these must
/// too (a `const` gradient would freeze in whichever colors were live the
/// moment Dart first evaluated it).
abstract final class AppGradients {
  /// The app's signature backdrop: soft blush fading into lavender mist,
  /// top to bottom. See `widgets/animated_background.dart` (added when a
  /// screen needs the slow-drifting version) for the animated variant —
  /// these stops are its start/end keyframe.
  static LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.blush, AppColors.mist],
      );

  /// A slightly wider version of [background] used behind a drifting
  /// animated gradient, so the motion has room to move within believable
  /// bounds without ever leaving the palette.
  static LinearGradient get backgroundAlt => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.mist, AppColors.blush],
      );

  /// Strong splash backdrop (e.g. onboarding hero, splash screen).
  static LinearGradient get mauveSplash => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.mauve, AppColors.blush],
      );

  /// Metallic chrome — thin borders, special icon fills (via ShaderMask),
  /// small decorative details. Never a large surface.
  static LinearGradient get chrome => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.chromeLight, AppColors.chromeMid, AppColors.chromeDark],
        stops: const [0.0, 0.55, 1.0],
      );

  /// Primary action fill (buttons, send key) — a very subtle depth, not
  /// a loud gradient: fuchsia reads as a near-flat accent, per spec.
  static LinearGradient get fuchsiaPress => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.fuchsia, AppColors.berry],
      );
}
