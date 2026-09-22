import 'package:flutter/services.dart';

/// Haptic pulses; no-ops automatically on platforms without support (web).
class Haptics {
  Haptics._();

  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> success() => HapticFeedback.mediumImpact();
}