import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/models/models.dart';
import 'package:hvad_nu/providers/providers.dart';
import 'package:hvad_nu/services/services.dart';
import 'package:hvad_nu/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_data.dart';

class _MockLLMService extends Mock implements LLMService {}

class _MockTTSService extends Mock implements TTSService {}

class _MockSTTService extends Mock implements STTService {}

class _MockCameraService extends Mock implements CameraService {}

class _MockSessionStorageService extends Mock implements SessionStorageService {}

void main() {
  late _MockLLMService llm;
  late _MockTTSService tts;
  late _MockSTTService stt;
  late _MockCameraService camera;
  late _MockSessionStorageService storage;

  setUpAll(() {
    registerFallbackValue(testSession());
    registerFallbackValue(testConfig());
    registerFallbackValue(PlayerAction.speech('fallback'));
  });

  setUp(() {
    llm = _MockLLMService();
    tts = _MockTTSService();
    stt = _MockSTTService();
    camera = _MockCameraService();
    storage = _MockSessionStorageService();

    when(() => tts.speakDanish(
          text: any(named: 'text'),
          voiceId: any(named: 'voiceId'),
        )).thenAnswer((_) async {});
    when(() => storage.saveActiveSession(any())).thenAnswer((_) async {});
    when(() => storage.saveLastConfig(any())).thenAnswer((_) async {});
    when(() => storage.clearActiveSession()).thenAnswer((_) async {});
    when(() => camera.initialize()).thenAnswer((_) async {});
    when(() => camera.hasCamera).thenReturn(true);
    when(() => stt.hasPermission()).thenAnswer((_) async => true);
    when(() => stt.cancelRecording()).thenAnswer((_) async {});
    when(() => tts.stop()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer({ParentConfig? config}) {
    final container = ProviderContainer(
      overrides: [
        llmServiceProvider.overrideWithValue(llm),
        ttsServiceProvider.overrideWithValue(tts),
        sttServiceProvider.overrideWithValue(stt),
        cameraServiceProvider.overrideWithValue(camera),
        sessionStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    if (config != null) {
      container.read(parentConfigProvider.notifier).loadConfig(config);
    }
    return container;
  }

  GameSessionNotifier notifierOf(ProviderContainer c) =>
      c.read(gameSessionProvider.notifier);

  group('initializeServices', () {
    test('reports a device with no camera as not camera-ready', () async {
      when(() => camera.hasCamera).thenReturn(false);

      final container = makeContainer();
      await notifierOf(container).initializeServices();

      final state = container.read(gameSessionProvider);
      expect(state.isCameraReady, isFalse);
      expect(state.isMicReady, isTrue);
      expect(state.phase, GamePhase.idle);
    });

    test('a camera failure does not put the game into the error phase',
        () async {
      // CameraService swallows its own failures so voice-only play still works.
      when(() => camera.hasCamera).thenReturn(false);
      when(() => stt.hasPermission()).thenAnswer((_) async => true);

      final container = makeContainer();
      await notifierOf(container).initializeServices();

      expect(container.read(gameSessionProvider).phase, isNot(GamePhase.error));
    });
  });

  group('startNewGame', () {
    test('creates a session, narrates the first challenge and listens',
        () async {
      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();

      final state = container.read(gameSessionProvider);
      expect(state.session, isNotNull);
      expect(state.phase, GamePhase.listening);
      verify(() => tts.speakDanish(
            text: any(named: 'text'),
            voiceId: any(named: 'voiceId'),
          )).called(1);
      verify(() => storage.saveActiveSession(any())).called(1);
    });

    test('still starts when narration fails', () async {
      when(() => tts.speakDanish(
            text: any(named: 'text'),
            voiceId: any(named: 'voiceId'),
          )).thenThrow(const TtsException(message: 'ElevenLabs down'));

      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();

      // Silence is acceptable; a stuck screen is not.
      expect(container.read(gameSessionProvider).phase, GamePhase.listening);
    });
  });

  group('capturePhoto', () {
    test('advances the story and returns to listening', () async {
      when(() => camera.capturePhoto())
          .thenAnswer((_) async => PlayerAction.photo('IMG'));
      when(() => llm.processPlayerAction(
            session: any(named: 'session'),
            action: any(named: 'action'),
          )).thenAnswer((_) async => const LLMResponse(
            validationSuccess: true,
            storySegment: 'Godt set!',
            nextChallenge: 'Find noget grønt.',
          ));

      final container = makeContainer(config: testConfig(maxSteps: 3));
      await notifierOf(container).startNewGame();
      await notifierOf(container).capturePhoto();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.listening);
      expect(state.session!.storyState.currentStep, 1);
      expect(state.session!.storyState.currentChallenge, 'Find noget grønt.');
    });

    test('surfaces a child-safe message and re-listens when the camera fails',
        () async {
      when(() => camera.capturePhoto()).thenThrow(const CameraException(
        message: 'takePicture blew up',
        userFriendlyMessage: 'Kameraet er ikke klar endnu.',
      ));

      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();
      await notifierOf(container).capturePhoto();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.listening);
      expect(state.errorMessage, 'Kameraet er ikke klar endnu.');
      // Technical detail must not leak to the screen.
      expect(state.errorMessage, isNot(contains('takePicture')));
    });

    test('is ignored unless the game is listening', () async {
      final container = makeContainer(config: testConfig());
      await notifierOf(container).capturePhoto();

      verifyNever(() => camera.capturePhoto());
    });
  });

  group('recording', () {
    test('transcribes in the session language', () async {
      when(() => stt.startRecording()).thenAnswer((_) async {});
      when(() => stt.stopRecordingAndTranscribe(
            language: any(named: 'language'),
          )).thenAnswer((_) async => PlayerAction.speech('a red car'));
      when(() => llm.processPlayerAction(
            session: any(named: 'session'),
            action: any(named: 'action'),
          )).thenAnswer((_) async => const LLMResponse(
            validationSuccess: true,
            storySegment: 'Great!',
            nextChallenge: 'Find something blue.',
          ));

      final container = makeContainer(config: testConfig(language: 'en'));
      await notifierOf(container).startNewGame();
      await notifierOf(container).startRecording();
      await notifierOf(container).stopRecording();

      verify(() => stt.stopRecordingAndTranscribe(language: 'en')).called(1);
      expect(container.read(gameSessionProvider).phase, GamePhase.listening);
    });

    test('hands the turn back silently when nothing was said', () async {
      when(() => stt.startRecording()).thenAnswer((_) async {});
      when(() => stt.stopRecordingAndTranscribe(
            language: any(named: 'language'),
          )).thenAnswer((_) async => null);

      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();
      await notifierOf(container).startRecording();
      await notifierOf(container).stopRecording();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.listening);
      expect(state.errorMessage, isNull);
      verifyNever(() => llm.processPlayerAction(
            session: any(named: 'session'),
            action: any(named: 'action'),
          ));
    });

    test('a denied microphone leaves the child able to try again', () async {
      when(() => stt.startRecording()).thenThrow(const MicrophoneException(
        message: 'permission denied',
      ));

      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();
      await notifierOf(container).startRecording();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.listening);
      expect(state.errorMessage, 'Kunne ikke starte mikrofonen.');
    });
  });

  group('victory', () {
    test('the final step ends the game and clears the saved session', () async {
      when(() => camera.capturePhoto())
          .thenAnswer((_) async => PlayerAction.photo('IMG'));
      when(() => llm.generateVictoryNarration(any()))
          .thenAnswer((_) async => LLMResponse.victory(
                theme: 'dragejagt',
                storyContext: '',
              ));

      final container = makeContainer(config: testConfig(maxSteps: 1));
      await notifierOf(container).startNewGame();
      await notifierOf(container).capturePhoto();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.victory);
      expect(state.session!.status, GameSessionStatus.completed);
      verify(() => storage.clearActiveSession()).called(1);
      // The victory prompt, not the ordinary turn prompt, must be used.
      verifyNever(() => llm.processPlayerAction(
            session: any(named: 'session'),
            action: any(named: 'action'),
          ));
    });

    test('resetGame actually drops the session', () async {
      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();
      expect(container.read(gameSessionProvider).session, isNotNull);

      await notifierOf(container).resetGame();

      final state = container.read(gameSessionProvider);
      expect(state.session, isNull);
      expect(state.phase, GamePhase.idle);
    });

    test('endGame completes the session and stops the timer', () async {
      final container = makeContainer(config: testConfig());
      await notifierOf(container).startNewGame();
      await notifierOf(container).endGame();

      final state = container.read(gameSessionProvider);
      expect(state.phase, GamePhase.victory);
      expect(state.session!.status, GameSessionStatus.completed);
    });
  });

  group('derived providers', () {
    test('expose progress and the current player', () async {
      when(() => camera.capturePhoto())
          .thenAnswer((_) async => PlayerAction.photo('IMG'));
      when(() => llm.processPlayerAction(
            session: any(named: 'session'),
            action: any(named: 'action'),
          )).thenAnswer((_) async => const LLMResponse(
            validationSuccess: true,
            storySegment: 'Ja!',
            nextChallenge: 'Videre.',
          ));

      final container = makeContainer(
        config: testConfig(participantNames: ['Emma', 'Noah'], maxSteps: 4),
      );
      await notifierOf(container).startNewGame();

      expect(container.read(isMultiplayerProvider), isTrue);
      expect(container.read(currentPlayerProvider)?.name, 'Emma');
      expect(container.read(progressProvider), 0.0);

      await notifierOf(container).capturePhoto();

      expect(container.read(currentPlayerProvider)?.name, 'Noah');
      expect(container.read(currentStepProvider), 1);
      expect(container.read(progressProvider), 0.25);
    });
  });
}
