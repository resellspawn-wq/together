import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the single [ThemeData] for Together's "soft glam" editorial
/// look — in whichever of its light/dark voices [AppColors.isDark]
/// currently resolves to. Screens must read colors/type/spacing/radii/
/// motion from the theme (`Theme.of(context)`) and the sibling token
/// classes (AppColors/AppGradients/AppTypography/AppSpacing/AppRadii/
/// AppShadows/AppMotion) — never a hardcoded `Color(...)`, font, or raw
/// duration.
abstract final class AppTheme {
  /// Always call this fresh (never cache the result) — it reflects
  /// whatever [AppColors.isDark] is *right now*, which main.dart updates
  /// before every rebuild of the app root.
  static ThemeData get current {
    final scheme = _colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.mist,
      splashFactory: InkSparkle.splashFactory,
      textTheme: AppTypography.textTheme(scheme),

      // Screen-to-screen navigation defaults to a shared-axis transition
      // everywhere, so individual routes don't need to opt in by hand.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleCompact(),
        iconTheme: IconThemeData(color: AppColors.ink, weight: 300),
      ),

      // Cards render flat here; screens apply AppShadows themselves via
      // BoxDecoration so shadows stay soft/tinted instead of Material's
      // default grey elevation shadow.
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.fuchsia,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.mauve.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
          textStyle: AppTypography.button(),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.berry.withValues(alpha: 0.15)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.chromeMid, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
          textStyle: AppTypography.button(color: AppColors.ink),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.fuchsia,
          textStyle: AppTypography.body(color: AppColors.fuchsia),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ink),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppTypography.body(color: AppColors.inkSoft),
        labelStyle: AppTypography.bodySmall(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: AppColors.chromeMid, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: AppColors.chromeMid, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: AppColors.fuchsia, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: AppColors.berry, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.chromeMid,
        thickness: 0.6,
        space: AppSpacing.xl,
      ),

      iconTheme: IconThemeData(color: AppColors.ink),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.body(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.fuchsia,
      ),
    );
  }

  static ColorScheme get _colorScheme => ColorScheme(
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.fuchsia,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.blush,
        onPrimaryContainer: AppColors.berry,
        secondary: AppColors.mauve,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.mist,
        onSecondaryContainer: AppColors.ink,
        tertiary: AppColors.chromeMid,
        onTertiary: AppColors.ink,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.mist,
        onSurfaceVariant: AppColors.inkSoft,
        outline: AppColors.chromeMid,
        outlineVariant: AppColors.chromeLight,
        error: AppColors.berry,
        onError: AppColors.white,
        errorContainer: AppColors.blush,
        onErrorContainer: AppColors.berry,
        shadow: AppColors.mauve,
        scrim: AppColors.ink,
        inverseSurface: AppColors.ink,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.blush,
      );
}
