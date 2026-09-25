import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named gradients built from [AppColors]. Screens should reach for these
/// instead of constructing a `LinearGradient` inline.
abstract final class AppGradients {
  /// The app's signature backdrop: soft blush fading into lavender mist,
  /// top to bottom. See `widgets/animated_background.dart` (added when a
  /// screen needs the slow-drifting version) for the animated variant —
  /// these stops are its start/end keyframe.
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.blush, AppColors.mist],
  );

  /// A slightly wider version of [background] used behind a drifting
  /// animated gradient, so the motion has room to move within believable
  /// bounds without ever leaving the palette.
  static const backgroundAlt = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.mist, AppColors.blush],
  );

  /// Strong splash backdrop (e.g. onboarding hero, splash screen).
  static const mauveSplash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.mauve, AppColors.blush],
  );

  /// Metallic chrome — thin borders, special icon fills (via ShaderMask),
  /// small decorative details. Never a large surface.
  static const chrome = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.chromeLight, AppColors.chromeMid, AppColors.chromeDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary action fill (buttons, send key) — a very subtle depth, not
  /// a loud gradient: fuchsia reads as a near-flat accent, per spec.
  static const fuchsiaPress = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.fuchsia, AppColors.berry],
  );
}
