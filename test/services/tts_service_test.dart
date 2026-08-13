import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/config/api_config.dart';
import 'package:hvad_nu/services/tts_service.dart';
import 'package:hvad_nu/utils/exceptions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakeAudioSource extends Fake implements AudioSource {}

void main() {
  late _MockDio dio;
  late _MockAudioPlayer player;
  late TTSService service;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(_FakeAudioSource());
  });

  setUp(() {
    dio = _MockDio();
    player = _MockAudioPlayer();
    service = TTSService(dio: dio, audioPlayer: player);

    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.playerStateStream).thenAnswer(
      (_) => Stream.value(PlayerState(false, ProcessingState.completed)),
    );
  });

  void stubAudioResponse() {
    when(() => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: Uint8List.fromList(List.filled(64, 1)),
        ));
  }

  test('does nothing at all for empty text', () async {
    await service.speakDanish(text: '', voiceId: 'voice-1');

    verifyNever(() => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ));
  });

  test('posts to the voice endpoint with the multilingual model', () async {
    stubAudioResponse();

    await service.speakDanish(text: 'Hej med dig', voiceId: 'voice-1');

    final call = verify(() => dio.post(
          captureAny(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        )).captured;

    expect(call[0], '/text-to-speech/voice-1');
    final body = call[1] as Map<String, dynamic>;
    expect(body['text'], 'Hej med dig');
    expect(body['model_id'], ApiConfig.elevenLabsModel);
  });

  test('plays the returned audio and reports itself finished', () async {
    stubAudioResponse();

    await service.speakDanish(text: 'Hej', voiceId: 'voice-1');

    verify(() => player.setAudioSource(any())).called(1);
    verify(() => player.play()).called(1);
    expect(service.isPlaying, isFalse);
  });

  test('invokes onStart and onComplete around playback', () async {
    stubAudioResponse();
    var started = false;
    var completed = false;

    await service.speakDanish(
      text: 'Hej',
      voiceId: 'voice-1',
      onStart: () => started = true,
      onComplete: () => completed = true,
    );

    expect(started, isTrue);
    expect(completed, isTrue);
  });

  test('surfaces a network failure as NetworkException and clears isPlaying',
      () async {
    when(() => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionTimeout,
    ));

    Object? reported;
    await expectLater(
      service.speakDanish(
        text: 'Hej',
        voiceId: 'voice-1',
        onError: (e) => reported = e,
      ),
      throwsA(isA<NetworkException>()),
    );

    expect(reported, isNotNull);
    expect(service.isPlaying, isFalse);
  });

  test('maps an HTTP error to ApiException carrying the status code',
      () async {
    when(() => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 401,
      ),
    ));

    await expectLater(
      service.speakDanish(text: 'Hej', voiceId: 'voice-1'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
  });
}
