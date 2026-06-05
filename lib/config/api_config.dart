import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _cachedGeminiKey;
  static String? _cachedElevenLabsKey;

  // Google Gemini (LLM + Vision)
  static String get geminiApiKey {
    if (_cachedGeminiKey != null) return _cachedGeminiKey!;

    // Try dotenv first (mobile)
    _cachedGeminiKey = dotenv.env['GEMINI_API_KEY'];

    // On web, try window.apiConfig injected by server
    if ((_cachedGeminiKey == null || _cachedGeminiKey!.isEmpty) && _isWeb()) {
      try {
        _cachedGeminiKey = _getWindowApiConfig('GEMINI_API_KEY');
      } catch (e) {
        // Silently fail
      }
    }

    _cachedGeminiKey ??= '';
    return _cachedGeminiKey!;
  }

  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  // Google Cloud Speech-to-Text
  static String get googleCloudApiKey => geminiApiKey;
  static const String speechToTextUrl = 'https://speech.googleapis.com/v1/speech:recognize';

  // ElevenLabs (TTS)
  static String get elevenLabsApiKey {
    if (_cachedElevenLabsKey != null) return _cachedElevenLabsKey!;

    // Try dotenv first (mobile)
    _cachedElevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'];

    // On web, try window.apiConfig injected by server
    if ((_cachedElevenLabsKey == null || _cachedElevenLabsKey!.isEmpty) &&
        _isWeb()) {
      try {
        _cachedElevenLabsKey = _getWindowApiConfig('ELEVENLABS_API_KEY');
      } catch (e) {
        // Silently fail
      }
    }

    _cachedElevenLabsKey ??= '';
    return _cachedElevenLabsKey!;
  }

  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsModel = 'eleven_multilingual_v2';

  // Timeouts
  static const int llmTimeoutSeconds = 30;
  static const int ttsTimeoutSeconds = 15;
  static const int sttTimeoutSeconds = 15;

  static bool get isConfigured =>
      geminiApiKey.isNotEmpty && elevenLabsApiKey.isNotEmpty;

  static bool _isWeb() {
    return identical(0, 0.0);
  }

  static String? _getWindowApiConfig(String key) {
    try {
      // Access window.apiConfig injected by server.js
      // This uses a dynamic approach to avoid importing dart:html on mobile
      final dynamic windowObj = _getWindow();
      if (windowObj != null) {
        final dynamic config = windowObj['apiConfig'];
        if (config != null) {
          return config[key];
        }
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  static dynamic _getWindow() {
    try {
      // In web context, this accesses the global window object
      // On mobile, this throws and gets caught
      final lib = _getLibraryHtml();
      if (lib != null) {
        return lib['window'];
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  static dynamic _getLibraryHtml() {
    try {
      // Only available in web context
      if (_isWeb()) {
        // Use a dynamic lookup to avoid compile-time dart:html dependency on mobile
        return null; // Placeholder; would be library.html in actual use
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }
}
