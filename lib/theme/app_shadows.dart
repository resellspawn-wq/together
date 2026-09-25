import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft, diffused, pink-tinted shadows — never grey, never hard-edged.
/// Pick the smallest level that reads: most cards only need [soft].
abstract final class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.mauve.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: AppColors.mauve.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> strong = [
    BoxShadow(
      color: AppColors.berry.withValues(alpha: 0.18),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  /// A faint lift for the fuchsia "my message" bubble specifically —
  /// tinted with the accent itself rather than mauve.
  static List<BoxShadow> fuchsiaGlow = [
    BoxShadow(
      color: AppColors.fuchsia.withValues(alpha: 0.22),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
