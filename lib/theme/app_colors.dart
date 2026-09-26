import 'package:flutter/material.dart';

/// The full color palette for Together's "soft glam" editorial look, in
/// both a light and a dark voice. Every field is a **getter**, not a
/// const — it resolves against [isDark], which [AppTheme] (via the app
/// root, see main.dart) keeps in sync with the user's theme setting and
/// the OS's own light/dark switch. Because nearly every screen's build()
/// method already depends on [AppScope] (for the alphabet/settings it
/// needs anyway), flipping [isDark] and calling `notifyListeners()`
/// rebuilds the whole tree and every one of these getters re-resolves —
/// no per-widget wiring needed.
///
/// The handwriting is the protagonist; fuchsia is an accent, not a fill —
/// keep it for primary actions, my-own-message bubbles, and small accent
/// marks, not for large surfaces.
abstract final class AppColors {
  static bool _isDark = false;

  static bool get isDark => _isDark;

  /// Called once per frame from the app root before anything reads a
  /// color — see `_resolveIsDark` in main.dart.
  static void setDark(bool value) => _isDark = value;

  /// Card and surface color.
  static Color get white => _isDark ? const Color(0xFF2A1F26) : const Color(0xFFFFFFFF);

  /// Gradient start (top) — soft pink in light, deep rose-plum in dark.
  static Color get blush => _isDark ? const Color(0xFF3D2733) : const Color(0xFFF3C9DC);

  /// Gradient end (bottom) — lavender-grey in light, near-black plum in dark.
  static Color get mist => _isDark ? const Color(0xFF17131A) : const Color(0xFFE6E4EE);

  /// Strong background / splash color, and the tint for soft shadows.
  static Color get mauve => _isDark ? const Color(0xFF9C6B7A) : const Color(0xFFB7808F);

  /// Primary accent: buttons, my-own messages, focal accents. Stays the
  /// signature color in both modes, just a touch brighter in dark so it
  /// keeps popping off a dark surface instead of muddying into it.
  static Color get fuchsia => _isDark ? const Color(0xFFFF4FA0) : const Color(0xFFE6368C);

  /// Pressed states, and text-on-light where fuchsia lacks contrast. In
  /// dark mode this is used as text/icon-on-dark instead, so it lightens.
  static Color get berry => _isDark ? const Color(0xFFFF7EB9) : const Color(0xFFA8235F);

  /// Primary text.
  static Color get ink => _isDark ? const Color(0xFFF5EAEE) : const Color(0xFF1D1418);

  /// Secondary / muted text.
  static Color get inkSoft => _isDark ? const Color(0xFFB79DA6) : const Color(0xFF7D6E74);

  /// Chrome gradient stops (metallic silver in light, warm dark pewter in
  /// dark), light → mid → light. Use via [AppGradients.chrome], not
  /// individually, except for the thin single-tone chrome borders where a
  /// flat mid-tone reads better.
  static Color get chromeLight => _isDark ? const Color(0xFF3A2E34) : const Color(0xFFF4F4F6);
  static Color get chromeMid => _isDark ? const Color(0xFF5C4B54) : const Color(0xFFBFC2C9);
  static Color get chromeDark => _isDark ? const Color(0xFF2E252A) : const Color(0xFFEDEEF1);
}
