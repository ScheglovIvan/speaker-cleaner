import 'package:flutter/services.dart';

/// Centralised haptic feedback for the app's interactive controls.
///
/// The native Speaker Cleaner reinforces every tap, tab switch and routine
/// start/stop with a short haptic. Routing all feedback through one helper (in
/// place of scattered [HapticFeedback] calls) keeps the intensity choices
/// consistent across screens: a light tap for navigation, a selection click for
/// tab/channel changes, a medium impact for primary actions, and a heavy impact
/// to mark a completed routine.
///
/// All calls are best-effort — platforms with no haptics engine (notably the
/// headless web preview) silently ignore them, so callers never need to guard.
class Haptics {
  const Haptics._();

  /// Light tap — card taps, back buttons, secondary navigation.
  static void tap() => HapticFeedback.lightImpact();

  /// Selection change — bottom-tab switches, channel toggles.
  static void select() => HapticFeedback.selectionClick();

  /// Medium impact — primary CTAs (start/stop a routine, subscribe).
  static void impact() => HapticFeedback.mediumImpact();

  /// Heavy impact — a routine finished / a task completed.
  static void success() => HapticFeedback.heavyImpact();
}
