import 'package:flutter/services.dart';

class HapticService {
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  static void selectionChanged() {
    HapticFeedback.selectionClick();
  }

  static void photoCapture() {
    HapticFeedback.mediumImpact();
  }

  static void recordingStart() {
    HapticFeedback.heavyImpact();
  }

  static void recordingStop() {
    HapticFeedback.lightImpact();
  }

  static void victory() {
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        HapticFeedback.mediumImpact();
      });
    }
  }
}
