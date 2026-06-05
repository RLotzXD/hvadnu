import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../config/api_config.dart';
import '../models/player_action.dart';

class STTService {
  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio;
  String? _currentRecordingPath;
  bool _isRecording = false;

  STTService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.geminiBaseUrl,
          connectTimeout: Duration(seconds: ApiConfig.sttTimeoutSeconds),
          receiveTimeout: Duration(seconds: ApiConfig.sttTimeoutSeconds),
        ));

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Mikrofon-tilladelse mangler');
    }

    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath =
        '${tempDir.path}/hvadnu_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

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
  }

  Future<PlayerAction?> stopRecordingAndTranscribe() async {
    if (!_isRecording || _currentRecordingPath == null) {
      return null;
    }

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null) return null;

    try {
      final transcription = await _transcribeWithGemini(path);
      _cleanupRecording(path);

      if (transcription.isEmpty) {
        return null;
      }

      return PlayerAction.speech(transcription);
    } catch (e) {
      _cleanupRecording(path);
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path != null) {
        _cleanupRecording(path);
      }
    }
  }

  Future<String> _transcribeWithGemini(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Lydfil ikke fundet');
    }

    final bytes = await file.readAsBytes();
    final base64Audio = base64Encode(bytes);

    // Determine MIME type based on file extension
    String mimeType = 'audio/mp4';
    if (audioPath.endsWith('.mp3')) {
      mimeType = 'audio/mp3';
    } else if (audioPath.endsWith('.wav')) {
      mimeType = 'audio/wav';
    } else if (audioPath.endsWith('.m4a')) {
      mimeType = 'audio/mp4';
    }

    final response = await _dio.post(
      '/models/${ApiConfig.geminiModel}:generateContent',
      queryParameters: {'key': ApiConfig.geminiApiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': 'Transskriber denne lydfil til dansk tekst. '
                    'Returner KUN den transskriberede tekst, intet andet. '
                    'Hvis der ikke er tale eller lyden er uklar, returner en tom streng.'
              },
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Audio,
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
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final candidates = response.data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return '';
    }

    final content = candidates[0]['content']['parts'][0]['text'] as String?;
    return content?.trim() ?? '';
  }

  void _cleanupRecording(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    await _recorder.dispose();
  }
}
