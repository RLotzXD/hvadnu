import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback].
///
/// Exists so call sites read as intent ("photo captured") rather than
/// intensity, and so the no-op cases live in one place: haptics are silently
/// skipped on web, and platform-channel failures are never allowed to
/// interrupt a turn.
class HapticService {
  static void lightTap() => _run(HapticFeedback.lightImpact);
  static void mediumTap() => _run(HapticFeedback.mediumImpact);
  static void heavyTap() => _run(HapticFeedback.heavyImpact);
  static void selectionChanged() => _run(HapticFeedback.selectionClick);

  static void photoCapture() => _run(HapticFeedback.mediumImpact);
  static void recordingStart() => _run(HapticFeedback.heavyImpact);
  static void recordingStop() => _run(HapticFeedback.lightImpact);

  static void success() {
    _run(HapticFeedback.mediumImpact);
    _runDelayed(const Duration(milliseconds: 100), HapticFeedback.lightImpact);
  }

  static void error() {
    _run(HapticFeedback.heavyImpact);
    _runDelayed(const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
  }

  /// Three rising taps to punctuate the victory screen.
  static void victory() {
    for (var i = 0; i < 3; i++) {
      _runDelayed(
        Duration(milliseconds: i * 150),
        HapticFeedback.mediumImpact,
      );
    }
  }

  static void _run(Future<void> Function() feedback) {
    if (kIsWeb) return;
    // Fire and forget: a missing vibrator must not surface as an error.
    feedback().catchError((_) {});
  }

  static void _runDelayed(Duration delay, Future<void> Function() feedback) {
    if (kIsWeb) return;
    Future.delayed(delay, () => _run(feedback));
  }
}
