import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:record/record.dart';

import '../config/api_config.dart';
import '../models/player_action.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';
import '../utils/recording_io.dart';

/// Speech-to-text via Gemini's audio input. There is no Whisper dependency.
class STTService {
  final AudioRecorder _recorder;
  final Dio _dio;

  String? _currentRecordingPath;
  bool _isRecording = false;

  STTService({Dio? dio, AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.geminiBaseUrl,
              connectTimeout: const Duration(seconds: ApiConfig.sttTimeoutSeconds),
              receiveTimeout: const Duration(seconds: ApiConfig.sttTimeoutSeconds),
            ));

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e, stackTrace) {
      ErrorHandler.log('STTService.hasPermission', e, stackTrace);
      return false;
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    if (!await hasPermission()) {
      throw const MicrophoneException(
        message: 'Microphone permission not granted',
        userFriendlyMessage: 'Mikrofonen er ikke slået til.',
        userFriendlyMessageEn: 'The microphone is not turned on.',
      );
    }

    try {
      _currentRecordingPath = await createRecordingPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );
      _isRecording = true;
    } catch (e, stackTrace) {
      ErrorHandler.log('STTService.startRecording', e, stackTrace);
      // The recorder may have started before the throw. Leaving it running
      // would make the next startRecording() fail too, so stop it explicitly.
      try {
        await _recorder.stop();
      } catch (_) {
        // Already stopped, or never started.
      }
      _isRecording = false;
      _currentRecordingPath = null;
      throw MicrophoneException(
        message: 'Recorder failed to start: $e',
        originalError: e,
      );
    }
  }

  /// Returns null when there was nothing to transcribe (no recording in
  /// progress, or the child said nothing intelligible). Throws on API failure.
  ///
  /// [language] picks the transcription prompt — passing 'da' for an English
  /// session makes Gemini try to render English speech as Danish.
  Future<PlayerAction?> stopRecordingAndTranscribe({
    String language = 'da',
  }) async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    _currentRecordingPath = null;

    if (path == null || path.isEmpty) return null;

    try {
      final transcription = await _transcribeWithGemini(path, language);
      if (transcription.isEmpty) return null;
      return PlayerAction.speech(transcription);
    } finally {
      await deleteRecording(path);
    }
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    _isRecording = false;
    _currentRecordingPath = null;
    if (path != null && path.isNotEmpty) {
      await deleteRecording(path);
    }
  }

  Future<String> _transcribeWithGemini(String audioPath, String language) async {
    final bytes = await readRecordingBytes(audioPath);
    if (bytes.isEmpty) return '';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/models/${ApiConfig.geminiModel}:generateContent',
        queryParameters: {'key': ApiConfig.geminiApiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': _transcriptionPrompt(language)},
                {
                  'inlineData': {
                    'mimeType': _mimeTypeFor(audioPath),
                    'data': base64Encode(bytes),
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 500,
          },
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final candidates = response.data?['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';

      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      return text?.trim() ?? '';
    } on DioException catch (e, stackTrace) {
      ErrorHandler.log('STTService.transcribe', e, stackTrace);
      throw ErrorHandler.toAppException(e, context: 'speech-to-text');
    }
  }

  static String _transcriptionPrompt(String language) {
    if (language == 'en') {
      return 'Transcribe this audio to English text. '
          'Return ONLY the transcribed text, nothing else. '
          'If there is no speech or the audio is unclear, return an empty string.';
    }
    return 'Transskriber denne lydfil til dansk tekst. '
        'Returner KUN den transskriberede tekst, intet andet. '
        'Hvis der ikke er tale eller lyden er uklar, returner en tom streng.';
  }

  /// `AudioEncoder.aacLc` writes an MP4 container, so `audio/mp4` is the
  /// correct default even though the bytes are AAC.
  static String _mimeTypeFor(String path) {
    if (path.endsWith('.mp3')) return 'audio/mp3';
    if (path.endsWith('.wav')) return 'audio/wav';
    if (path.endsWith('.ogg')) return 'audio/ogg';
    if (path.endsWith('.webm')) return 'audio/webm';
    return 'audio/mp4';
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    await _recorder.dispose();
  }
}
