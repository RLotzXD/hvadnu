import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Google Gemini (LLM + Vision)
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  // Google Cloud Speech-to-Text
  static String get googleCloudApiKey => geminiApiKey;
  static const String speechToTextUrl = 'https://speech.googleapis.com/v1/speech:recognize';

  // ElevenLabs (TTS)
  static String get elevenLabsApiKey {
    return dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  }
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsModel = 'eleven_multilingual_v2';

  // Timeouts
  static const int llmTimeoutSeconds = 30;
  static const int ttsTimeoutSeconds = 15;
  static const int sttTimeoutSeconds = 15;

  static bool get isConfigured =>
      geminiApiKey.isNotEmpty && elevenLabsApiKey.isNotEmpty;
}
