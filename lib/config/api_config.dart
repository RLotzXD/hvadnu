import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_config_stub.dart' if (dart.library.js_interop) 'api_config_web.dart';

/// Central place for API endpoints, models, timeouts and credentials.
///
/// Keys come from `.env` on mobile and from the `window.apiConfig` object on
/// web. Resolution is cached after the first read.
class ApiConfig {
  static String? _cachedGeminiKey;
  static String? _cachedElevenLabsKey;

  // ---------------------------------------------------------------- Gemini

  static String get geminiApiKey =>
      _cachedGeminiKey ?? _resolveAndCache('GEMINI_API_KEY');

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  // ------------------------------------------------------------ ElevenLabs

  static String get elevenLabsApiKey =>
      _cachedElevenLabsKey ?? _resolveAndCache('ELEVENLABS_API_KEY');

  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsModel = 'eleven_multilingual_v2';

  // -------------------------------------------------------------- Timeouts

  static const int llmTimeoutSeconds = 30;
  static const int ttsTimeoutSeconds = 15;
  static const int sttTimeoutSeconds = 15;

  static bool get isConfigured =>
      geminiApiKey.isNotEmpty && elevenLabsApiKey.isNotEmpty;

  /// Clears cached credentials so the next read re-resolves them.
  ///
  /// Used by the retry button on `LoadingScreen` and by tests.
  static void resetCache() {
    _cachedGeminiKey = null;
    _cachedElevenLabsKey = null;
  }

  /// Caches only a successful resolution.
  ///
  /// Caching an empty result would make a first-run miss permanent for the
  /// process, which would defeat the retry button on `LoadingScreen`.
  static String _resolveAndCache(String name) {
    final value = _resolveKey(name);
    if (value.isEmpty) return '';

    if (name == 'GEMINI_API_KEY') {
      _cachedGeminiKey = value;
    } else {
      _cachedElevenLabsKey = value;
    }
    return value;
  }

  static String _resolveKey(String name) {
    final fromEnv = _readDotEnv(name);
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      final fromWindow = readWebApiConfig(name);
      if (fromWindow != null && fromWindow.isNotEmpty) return fromWindow;
    }

    return '';
  }

  /// `dotenv.env` throws when `load()` was never called, which is the normal
  /// state on web and in tests, so this is deliberately defensive.
  static String? _readDotEnv(String name) {
    if (kIsWeb) return null;
    try {
      if (!dotenv.isInitialized) return null;
      return dotenv.env[name];
    } catch (_) {
      return null;
    }
  }
}
