import 'package:flutter/material.dart';

/// Every animation duration and curve in the app. Nothing bounces —
/// stick to the `enter`/`emphasized` curves below, 250-600ms. Always
/// route a duration through [AppMotion.scaled] (or check
/// `MediaQuery.disableAnimations` yourself) before using it, so a
/// reduce-motion request actually removes motion.
abstract final class AppMotion {
  // ---------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------

  static const fast = Duration(milliseconds: 250);
  static const base = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 600);

  /// Stagger step between successive entrance animations in a list
  /// (40-60ms per spec).
  static const staggerStep = Duration(milliseconds: 50);

  /// A composed message bubble rising from the keyboard into the chat.
  static const messageRise = Duration(milliseconds: 450);

  /// Screen-to-screen transitions (SharedAxis / FadeThrough).
  static const screenTransition = Duration(milliseconds: 350);

  /// One full cycle of the slow background gradient drift (15-20s per
  /// spec — almost imperceptible).
  static const backgroundDrift = Duration(seconds: 18);

  /// Per-letter duration range for the handwriting "draw" animation —
  /// pick a value in this range per letter (e.g. weighted by stroke
  /// length) rather than a single fixed number, so it reads natural.
  static const letterDrawMin = Duration(milliseconds: 40);
  static const letterDrawMax = Duration(milliseconds: 80);

  /// A non-letter character's (digit/punctuation/emoji/space) turn in
  /// the same left-to-right handwriting reveal sequence — it doesn't
  /// draw strokes, just takes a brief beat so the message still reveals
  /// in reading order instead of letters animating while everything
  /// else has already popped in.
  static const plainCharacterReveal = Duration(milliseconds: 30);

  // ---------------------------------------------------------------------
  // Curves — smooth only, never bouncy/elastic
  // ---------------------------------------------------------------------

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Curves.easeOutQuint;

  // ---------------------------------------------------------------------
  // Motion distances
  // ---------------------------------------------------------------------

  /// Slide-in offset for fade+slide entrances (10-20px per spec).
  static const entranceSlideOffset = 16.0;

  /// Marquee scroll speed, in logical pixels per second — slow & constant.
  static const marqueeSpeedPxPerSecond = 26.0;

  // ---------------------------------------------------------------------
  // Reduce-motion helper
  // ---------------------------------------------------------------------

  /// Returns [duration] normally, or [Duration.zero] when the platform
  /// (or the user, via OS accessibility settings) requests reduced
  /// motion. Wrap every animation duration in this.
  static Duration scaled(BuildContext context, Duration duration) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return reduceMotion ? Duration.zero : duration;
  }
}
