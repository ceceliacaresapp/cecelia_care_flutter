// lib/utils/haptic_utils.dart
//
// Centralized haptic feedback helpers. No file needs to import
// flutter/services.dart directly — call these instead.

import 'package:flutter/services.dart';

class HapticUtils {
  HapticUtils._();

  /// Medium impact — form saves, quick-log taps, successful actions.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Heavy impact — badge tier-ups, streak milestones, level-ups, confetti moments.
  static Future<void> celebration() => HapticFeedback.heavyImpact();

  /// Light impact — delete confirmations, warnings, dismissals.
  static Future<void> warning() => HapticFeedback.lightImpact();

  /// Selection click — tab switches, segment toggles, picker changes.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Lightest tap — tile presses, list item taps, micro-interactions.
  static Future<void> tap() => HapticFeedback.lightImpact();
}
