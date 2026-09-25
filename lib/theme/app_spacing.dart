/// Spacing scale. Multiples of 4, named instead of magic numbers.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const huge = 64.0;
}

/// Corner radii. [bubble] is the spec'd 22px for chat bubbles; the rest
/// follow the same soft-editorial scale.
abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;

  /// Chat bubbles — spec'd exactly.
  static const bubble = 22.0;

  static const xl = 28.0;
  static const pill = 999.0;
}
