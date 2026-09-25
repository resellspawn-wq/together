import 'package:flutter/material.dart';

/// The full color palette for Together's "soft glam" editorial look.
/// This is the only place a raw color value should exist — every screen
/// reads from here (or from [ThemeData]/[ColorScheme] built on top of it
/// in `app_theme.dart`), never a literal `Color(0x...)` inline.
///
/// The handwriting is the protagonist; fuchsia is an accent, not a fill —
/// keep it for primary actions, my-own-message bubbles, and small accent
/// marks, not for large surfaces.
abstract final class AppColors {
  /// Card and surface white.
  static const white = Color(0xFFFFFFFF);

  /// Gradient start (top) — soft pink.
  static const blush = Color(0xFFF3C9DC);

  /// Gradient end (bottom) — lavender-grey.
  static const mist = Color(0xFFE6E4EE);

  /// Strong background / splash color.
  static const mauve = Color(0xFFB7808F);

  /// Primary accent: buttons, my-own messages, focal accents.
  static const fuchsia = Color(0xFFE6368C);

  /// Pressed states, and text-on-light where fuchsia lacks contrast.
  static const berry = Color(0xFFA8235F);

  /// Primary text.
  static const ink = Color(0xFF1D1418);

  /// Secondary / muted text.
  static const inkSoft = Color(0xFF7D6E74);

  /// Chrome gradient stops (metallic silver), light → mid → light.
  /// Use via [AppGradients.chrome], not individually, except for the
  /// thin single-tone chrome borders where a flat mid-tone reads better.
  static const chromeLight = Color(0xFFF4F4F6);
  static const chromeMid = Color(0xFFBFC2C9);
  static const chromeDark = Color(0xFFEDEEF1);
}
