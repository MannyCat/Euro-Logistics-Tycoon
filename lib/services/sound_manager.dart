import 'package:flutter/services.dart';

/// Simple UI sound manager using system haptic feedback and audio.
/// Sound files are in assets/sounds/ (optional — falls back to haptics).
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool v) => _enabled = v;

  /// Subtle tap/click feedback — light haptic
  void tap() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Success confirmation — medium haptic
  void success() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Error/warning — heavy haptic
  void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Achievement unlock — distinct pattern
  void achievement() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }
}
