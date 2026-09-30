import 'package:flutter/services.dart';

class HapticsUtils {
  static Future<void> vibrateShort({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> vibrateSuccess({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
