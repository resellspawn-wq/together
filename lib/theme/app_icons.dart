import 'package:flutter/widgets.dart';

/// Thin (Phosphor "Light") icons, used everywhere instead of Material's
/// default icon set.
///
/// This deliberately does NOT `import 'package:phosphor_flutter/...'`.
/// The phosphor_flutter 2.1.0 Dart API (`PhosphorIconData extends
/// IconData`) fails to compile on current Flutter/Dart — `IconData`
/// became a `final class`, which can no longer be subclassed outside
/// its own library (dart:ui/material). The bundled *font asset* is
/// unaffected by that, though: phosphor_flutter's own pubspec declares
/// the "PhosphorLight" font family, which Flutter includes automatically
/// because the app depends on the package. So these are built as plain
/// [IconData] pointing at that font — same glyphs, no broken subclass.
/// Codepoints are taken from phosphor_flutter's phosphor_icons_light.dart.
abstract final class AppIcons {
  static const _family = 'PhosphorLight';
  static const _package = 'phosphor_flutter';

  static const arrowLeft = IconData(0xe058, fontFamily: _family, fontPackage: _package);
  static const arrowRight = IconData(0xe06c, fontFamily: _family, fontPackage: _package);
  static const arrowFatUp = IconData(0xe52e, fontFamily: _family, fontPackage: _package);
  static const arrowClockwise = IconData(0xe036, fontFamily: _family, fontPackage: _package);
  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _family, fontPackage: _package);
  static const backspace = IconData(0xe0ae, fontFamily: _family, fontPackage: _package);
  static const caretLeft = IconData(0xe138, fontFamily: _family, fontPackage: _package);
  static const caretRight = IconData(0xe13a, fontFamily: _family, fontPackage: _package);
  static const chatCircleDots = IconData(0xe16c, fontFamily: _family, fontPackage: _package);
  static const chatCircleText = IconData(0xe16e, fontFamily: _family, fontPackage: _package);
  static const camera = IconData(0xe10e, fontFamily: _family, fontPackage: _package);
  static const check = IconData(0xe182, fontFamily: _family, fontPackage: _package);
  static const checks = IconData(0xe53a, fontFamily: _family, fontPackage: _package);
  static const clock = IconData(0xe19a, fontFamily: _family, fontPackage: _package);
  static const cloudSlash = IconData(0xe1b6, fontFamily: _family, fontPackage: _package);
  static const dotsThreeVertical = IconData(0xe208, fontFamily: _family, fontPackage: _package);
  static const envelopeSimple = IconData(0xe218, fontFamily: _family, fontPackage: _package);
  static const eye = IconData(0xe220, fontFamily: _family, fontPackage: _package);
  static const eyeSlash = IconData(0xe224, fontFamily: _family, fontPackage: _package);
  static const gearSix = IconData(0xe272, fontFamily: _family, fontPackage: _package);
  static const gridFour = IconData(0xe296, fontFamily: _family, fontPackage: _package);
  static const heart = IconData(0xe2a8, fontFamily: _family, fontPackage: _package);
  static const keyboard = IconData(0xe2d8, fontFamily: _family, fontPackage: _package);
  static const lockSimple = IconData(0xe308, fontFamily: _family, fontPackage: _package);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _family, fontPackage: _package);
  static const arrowUUpLeft = IconData(0xe08a, fontFamily: _family, fontPackage: _package);
  static const arrowUUpRight = IconData(0xe08c, fontFamily: _family, fontPackage: _package);
  static const paperPlaneTilt = IconData(0xe398, fontFamily: _family, fontPackage: _package);
  static const pencilSimple = IconData(0xe3b4, fontFamily: _family, fontPackage: _package);
  static const plusCircle = IconData(0xe3d6, fontFamily: _family, fontPackage: _package);
  static const signOut = IconData(0xe42a, fontFamily: _family, fontPackage: _package);
  static const smileyWink = IconData(0xe666, fontFamily: _family, fontPackage: _package);
  static const trash = IconData(0xe4a6, fontFamily: _family, fontPackage: _package);
  static const userCircle = IconData(0xe4c4, fontFamily: _family, fontPackage: _package);
}
