import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Every text style in the app, in three voices — never Roboto or a
/// default Material style:
///
/// - **Titles** (Bricolage Grotesque, weight 200-300): huge, thin,
///   uppercase editorial headlines. Flutter has no text-transform, so
///   callers pass already-uppercased strings (`'CIAO'.toUpperCase()` or
///   just type it uppercase) — these styles don't do it for you.
/// - **Accent** (Yellowtail, fuchsia): a single cursive word set beside
///   or overlapping a title (e.g. "CIAO" + "Eliza"). Use at most once or
///   twice per screen — it's a flourish, not body text.
/// - **UI text** (Manrope): everything else — body copy, labels,
///   buttons, message bubbles.
abstract final class AppTypography {
  // ---------------------------------------------------------------------
  // Titles — Bricolage Grotesque
  // ---------------------------------------------------------------------

  /// The largest headline size, for splash/hero moments. ~64px, w200.
  static TextStyle hero({Color color = AppColors.ink}) => GoogleFonts.bricolageGrotesque(
        fontSize: 64,
        fontWeight: FontWeight.w200,
        letterSpacing: -2.2,
        height: 0.95,
        color: color,
      );

  /// A screen-level title (e.g. a chat header, a login headline). ~40px, w300.
  static TextStyle display({Color color = AppColors.ink}) => GoogleFonts.bricolageGrotesque(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.4,
        height: 1.0,
        color: color,
      );

  /// A section heading within a screen. ~24px, w300.
  static TextStyle sectionTitle({Color color = AppColors.ink}) => GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.6,
        height: 1.05,
        color: color,
      );

  /// A compact title for list rows / app bars that still want the
  /// editorial voice at a small size. ~19px, w300.
  static TextStyle titleCompact({Color color = AppColors.ink}) => GoogleFonts.bricolageGrotesque(
        fontSize: 19,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.3,
        height: 1.1,
        color: color,
      );

  // ---------------------------------------------------------------------
  // Accent — Yellowtail cursive
  // ---------------------------------------------------------------------

  /// The single cursive accent word. Size it to sit visually with the
  /// title style it's paired with (script fonts read smaller at the same
  /// px size, so this defaults larger than [display]).
  static TextStyle accent({double fontSize = 44, Color color = AppColors.fuchsia}) => GoogleFonts.yellowtail(
        fontSize: fontSize,
        color: color,
        height: 1.0,
      );

  // ---------------------------------------------------------------------
  // UI text — Manrope
  // ---------------------------------------------------------------------

  static TextStyle body({Color color = AppColors.ink}) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.inkSoft}) => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color,
      );

  /// Small uppercase-style label/eyebrow text (kickers, field labels).
  static TextStyle label({Color color = AppColors.inkSoft}) => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      );

  static TextStyle button({Color color = AppColors.white}) => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color,
      );

  /// Text set inside a chat bubble (plain-text fallback / non-A-Z runs
  /// alongside handwritten glyphs — see CustomText).
  static TextStyle messageText({Color color = AppColors.ink}) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: color,
      );

  /// The thin scrolling marquee line ("scritto a mano · solo per te ·").
  static TextStyle marquee({Color color = AppColors.inkSoft}) => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
      );

  // ---------------------------------------------------------------------
  // Full TextTheme for ThemeData
  // ---------------------------------------------------------------------

  static TextTheme textTheme(ColorScheme scheme) => TextTheme(
        displayLarge: hero(color: scheme.onSurface),
        displayMedium: display(color: scheme.onSurface),
        displaySmall: sectionTitle(color: scheme.onSurface),
        headlineLarge: display(color: scheme.onSurface),
        headlineMedium: sectionTitle(color: scheme.onSurface),
        headlineSmall: titleCompact(color: scheme.onSurface),
        titleLarge: sectionTitle(color: scheme.onSurface),
        titleMedium: titleCompact(color: scheme.onSurface),
        titleSmall: label(color: scheme.onSurfaceVariant),
        bodyLarge: body(color: scheme.onSurface),
        bodyMedium: body(color: scheme.onSurface),
        bodySmall: bodySmall(color: scheme.onSurfaceVariant),
        labelLarge: button(color: scheme.onPrimary),
        labelMedium: label(color: scheme.onSurfaceVariant),
        labelSmall: label(color: scheme.onSurfaceVariant),
      );
}
