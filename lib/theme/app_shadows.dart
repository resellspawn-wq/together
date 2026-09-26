import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft, diffused, pink-tinted shadows — never grey, never hard-edged.
/// Pick the smallest level that reads: most cards only need [soft].
abstract final class AppShadows {
  // Getters, not static fields: a plain `static List<...> x = [...]`
  // initializer runs once and caches forever, which would freeze these
  // in whichever light/dark colors were live the first time anything
  // read them — see AppColors' doc comment.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.mauve.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.mauve.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get strong => [
        BoxShadow(
          color: AppColors.berry.withValues(alpha: 0.18),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  /// A faint lift for the fuchsia "my message" bubble specifically —
  /// tinted with the accent itself rather than mauve.
  static List<BoxShadow> get fuchsiaGlow => [
        BoxShadow(
          color: AppColors.fuchsia.withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
