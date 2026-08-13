import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

import '../config/api_config.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

class TTSService {
  final Dio _dio;
  final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  TTSService({Dio? dio, AudioPlayer? audioPlayer})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.elevenLabsBaseUrl,
              connectTimeout: const Duration(seconds: ApiConfig.ttsTimeoutSeconds),
              receiveTimeout:
                  const Duration(seconds: ApiConfig.ttsTimeoutSeconds * 2),
            )),
        _audioPlayer = audioPlayer ?? AudioPlayer();

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

      _isPlaying = false;
      onComplete?.call();
    } catch (e, stackTrace) {
      _isPlaying = false;
      onError?.call(e);
      throw _asTtsException(e, stackTrace, 'speakDanish');
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

      _isPlaying = false;
      onComplete?.call();
    } catch (e, stackTrace) {
      _isPlaying = false;
      onError?.call(e);
      throw _asTtsException(e, stackTrace, 'streamDanish');
    }
  }

  /// Narration failing must never end a child's turn, so callers are expected
  /// to catch this and continue in silence. It is thrown rather than swallowed
  /// so the failure is at least visible to the caller and the logs.
  AppException _asTtsException(Object e, StackTrace stackTrace, String where) {
    if (e is DioException) {
      final status = e.response?.statusCode;

      // 402 is quota_exceeded: the ElevenLabs account is out of credits. Dio's
      // built-in description for 402 says "bad syntax", which sends you looking
      // for a code bug that isn't there. Say what it actually means.
      if (status == 402) {
        ErrorHandler.log(
          'TTSService.$where',
          'ElevenLabs returned 402 (quota_exceeded) — the account is out of '
              'credits, so there will be no narration until it is topped up. '
              'Check the Subscription page at elevenlabs.io. This is a billing '
              'state, not a bug.',
        );
        return const TtsException(
          message: 'ElevenLabs quota exhausted (HTTP 402)',
          userFriendlyMessage: 'Fortælleren har mistet stemmen. Tjek ElevenLabs-kontoen.',
          userFriendlyMessageEn: 'The storyteller has lost their voice. Check the ElevenLabs account.',
        );
      }

      ErrorHandler.log('TTSService.$where', e, stackTrace);
      return ErrorHandler.toAppException(e, context: 'text-to-speech');
    }

    ErrorHandler.log('TTSService.$where', e, stackTrace);
    return TtsException(message: 'Playback failed in $where: $e', originalError: e);
  }

  /// Plays [bytes] and returns once playback has finished.
  ///
  /// The wait is bounded by the clip's own length plus a margin. This matters
  /// on the web: browsers block audio that isn't tied to a user gesture, and
  /// when that happens playback never reports completion. The old code waited
  /// two minutes for a completion event that would never arrive, which left
  /// `GamePhase.narrating` stuck and made the action button inert — the game
  /// looked frozen rather than merely silent.
  Future<void> _playAudioBytes(Uint8List bytes) async {
    final clipLength = await _audioPlayer.setAudioSource(_BytesAudioSource(bytes));
    final limit = (clipLength ?? const Duration(seconds: 20)) +
        const Duration(seconds: 5);

    // just_audio's play() completes when playback ends, pauses or stops.
    await _audioPlayer.play().timeout(limit, onTimeout: () {
      ErrorHandler.log(
        'TTSService',
        'Playback did not finish within $limit — continuing without audio. '
            'On web this usually means the browser blocked autoplay.',
      );
      return _audioPlayer.stop();
    });
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
