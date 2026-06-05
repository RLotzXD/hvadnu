import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

class ApiConfig {
  static String? _cachedGeminiKey;
  static String? _cachedElevenLabsKey;
  static bool _fetchedWebConfig = false;

  // Google Gemini (LLM + Vision)
  static String get geminiApiKey {
    if (_cachedGeminiKey != null) return _cachedGeminiKey!;
    _cachedGeminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
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
    _cachedElevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
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

  // Fetch config from server on web
  static Future<void> fetchWebConfig() async {
    if (_fetchedWebConfig || !_isWeb()) return;

    try {
      final dio = Dio();
      final response = await dio.get('/api/config',
          options: Options(
            validateStatus: (status) => status! < 500,
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
          ));

      if (response.statusCode == 200 && response.data is Map) {
        _cachedGeminiKey = response.data['GEMINI_API_KEY'] ?? '';
        _cachedElevenLabsKey = response.data['ELEVENLABS_API_KEY'] ?? '';
      }
    } catch (e) {
      debugPrint('Failed to fetch web config: $e');
    }

    _fetchedWebConfig = true;
  }

  static bool _isWeb() {
    return identical(0, 0.0);
  }

  static void debugPrint(String msg) {
    // Use print for web, debugPrint for mobile
    print(msg);
  }
}
