import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import '../config/api_config.dart';

class TTSService {
  final Dio _dio;
  final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  TTSService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.elevenLabsBaseUrl,
          connectTimeout: Duration(seconds: ApiConfig.ttsTimeoutSeconds),
          receiveTimeout: Duration(seconds: ApiConfig.ttsTimeoutSeconds * 2),
        )),
        _audioPlayer = AudioPlayer();

  bool get isPlaying => _isPlaying;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> speakDanish({
    required String text,
    required String voiceId,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(Object error)? onError,
  }) async {
    if (text.isEmpty) return;

    try {
      _isPlaying = true;
      onStart?.call();

      final response = await _dio.post(
        '/text-to-speech/$voiceId',
        data: {
          'text': text,
          'model_id': ApiConfig.elevenLabsModel,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
            'style': 0.5,
            'use_speaker_boost': true,
          },
        },
        options: Options(
          headers: {
            'xi-api-key': ApiConfig.elevenLabsApiKey,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
          responseType: ResponseType.bytes,
        ),
      );

      final audioBytes = response.data as List<int>;
      await _playAudioBytes(Uint8List.fromList(audioBytes));

      await _audioPlayer.playerStateStream
          .firstWhere((state) =>
              state.processingState == ProcessingState.completed ||
              state.processingState == ProcessingState.idle)
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () => _audioPlayer.playerState,
          );

      _isPlaying = false;
      onComplete?.call();
    } catch (e) {
      _isPlaying = false;
      onError?.call(e);
    }
  }

  Future<void> streamDanish({
    required String text,
    required String voiceId,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(Object error)? onError,
  }) async {
    if (text.isEmpty) return;

    try {
      _isPlaying = true;
      onStart?.call();

      final response = await _dio.post(
        '/text-to-speech/$voiceId/stream',
        data: {
          'text': text,
          'model_id': ApiConfig.elevenLabsModel,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        },
        options: Options(
          headers: {
            'xi-api-key': ApiConfig.elevenLabsApiKey,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
          responseType: ResponseType.stream,
        ),
      );

      final audioChunks = <int>[];
      final responseStream = response.data.stream as Stream<List<int>>;

      bool startedPlaying = false;

      await for (final chunk in responseStream) {
        audioChunks.addAll(chunk);

        if (!startedPlaying && audioChunks.length > 4096) {
          startedPlaying = true;
          _playAudioBytes(Uint8List.fromList(audioChunks));
        }
      }

      if (!startedPlaying && audioChunks.isNotEmpty) {
        await _playAudioBytes(Uint8List.fromList(audioChunks));
      }

      await _audioPlayer.playerStateStream
          .firstWhere((state) =>
              state.processingState == ProcessingState.completed)
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () => _audioPlayer.playerState,
          );

      _isPlaying = false;
      onComplete?.call();
    } catch (e) {
      _isPlaying = false;
      onError?.call(e);
    }
  }

  Future<void> _playAudioBytes(Uint8List bytes) async {
    final audioSource = _BytesAudioSource(bytes);
    await _audioPlayer.setAudioSource(audioSource);
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
