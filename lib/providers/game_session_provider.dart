import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/error_handler.dart';
import 'config_provider.dart';
import 'service_providers.dart';

enum GamePhase {
  idle,
  listening,
  recording,
  processing,
  narrating,
  victory,
  timeExpired,
  error,
}

class GameState {
  final GameSession? session;
  final GamePhase phase;
  final String? errorMessage;
  final bool isCameraReady;
  final bool isMicReady;

  const GameState({
    this.session,
    this.phase = GamePhase.idle,
    this.errorMessage,
    this.isCameraReady = false,
    this.isMicReady = false,
  });

  /// [errorMessage] is intentionally not `??`-merged: omitting it clears the
  /// error, so a state change always supersedes the previous message.
  /// [clearSession] exists because `session: null` cannot mean "remove" while
  /// it also means "leave unchanged".
  GameState copyWith({
    GameSession? session,
    GamePhase? phase,
    String? errorMessage,
    bool? isCameraReady,
    bool? isMicReady,
    bool clearSession = false,
  }) {
    return GameState(
      session: clearSession ? null : (session ?? this.session),
      phase: phase ?? this.phase,
      errorMessage: errorMessage,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isMicReady: isMicReady ?? this.isMicReady,
    );
  }

  /// Playable as soon as there's a session and at least one way for the child
  /// to answer. A device with no camera (or web) is voice-only, not broken.
  bool get isReady => session != null && (isCameraReady || isMicReady);
  bool get isPlaying => phase == GamePhase.listening || phase == GamePhase.recording;
  bool get isProcessing => phase == GamePhase.processing || phase == GamePhase.narrating;
}

class GameSessionNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  Timer? _sessionTimer;

  GameSessionNotifier(this._ref) : super(const GameState());

  LLMService get _llmService => _ref.read(llmServiceProvider);
  TTSService get _ttsService => _ref.read(ttsServiceProvider);
  STTService get _sttService => _ref.read(sttServiceProvider);
  CameraService get _cameraService => _ref.read(cameraServiceProvider);
  SessionStorageService get _storage => _ref.read(sessionStorageProvider);

  String get _language => state.session?.config.language ??
      _ref.read(parentConfigProvider).language;

  Future<void> initializeServices() async {
    try {
      await _cameraService.initialize();
      state = state.copyWith(isCameraReady: _cameraService.hasCamera);

      final hasMicPermission = await _sttService.hasPermission();
      state = state.copyWith(isMicReady: hasMicPermission);
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.initializeServices', e, stackTrace);
      state = state.copyWith(
        errorMessage: ErrorHandler.describe(e, language: _language),
        phase: GamePhase.error,
      );
    }
  }

  Future<void> startNewGame() async {
    final config = _ref.read(parentConfigProvider);
    final session = GameSession.create(config);

    state = state.copyWith(
      session: session,
      phase: GamePhase.narrating,
    );

    await _storage.saveActiveSession(session);
    await _storage.saveLastConfig(config);

    await _playNarration(session.storyState.currentChallenge);

    state = state.copyWith(phase: GamePhase.listening);

    _startSessionTimer();
  }

  Future<void> resumeGame(GameSession session) async {
    state = state.copyWith(
      session: session.resume(),
      phase: GamePhase.listening,
    );
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkTimeLimit();
    });
  }

  void _checkTimeLimit() {
    final session = state.session;
    if (session != null && session.isTimeExpired) {
      _handleTimeExpired(session);
    }
  }

  Future<void> _handleTimeExpired(GameSession session) async {
    _sessionTimer?.cancel();

    state = state.copyWith(phase: GamePhase.narrating);

    try {
      final response = await _llmService.generateTimeExpiredNarration(session);
      await _playNarration(response.fullNarration);
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.handleTimeExpired', e, stackTrace);
      final isEnglish = session.config.language == 'en';
      final fallback = isEnglish
          ? "Oh no! Time has run out! But don't worry - you were so brave! Want to try again?"
          : 'Åh nej! Tiden er løbet ud! Men bare rolig - du var så modig! Vil du prøve igen?';
      await _playNarration(fallback);
    }

    final completedSession = session.markCompleted();
    state = state.copyWith(
      session: completedSession,
      phase: GamePhase.timeExpired,
    );

    await _storage.clearActiveSession();
  }

  Future<void> capturePhoto() async {
    if (state.phase != GamePhase.listening) return;

    state = state.copyWith(phase: GamePhase.processing);

    try {
      final action = await _cameraService.capturePhoto();
      await _processPlayerAction(action);
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.capturePhoto', e, stackTrace);
      state = state.copyWith(
        phase: GamePhase.listening,
        errorMessage: ErrorHandler.describe(e, language: _language),
      );
    }
  }

  Future<void> startRecording() async {
    if (state.phase != GamePhase.listening) return;

    try {
      await _sttService.startRecording();
      state = state.copyWith(phase: GamePhase.recording);
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.startRecording', e, stackTrace);
      state = state.copyWith(
        phase: GamePhase.listening,
        errorMessage: ErrorHandler.describe(e, language: _language),
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.phase != GamePhase.recording) return;

    state = state.copyWith(phase: GamePhase.processing);

    try {
      final action = await _sttService.stopRecordingAndTranscribe(
        language: _language,
      );
      if (action != null) {
        await _processPlayerAction(action);
      } else {
        // Nothing intelligible was said; silently hand the turn back.
        state = state.copyWith(phase: GamePhase.listening);
      }
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.stopRecording', e, stackTrace);
      state = state.copyWith(
        phase: GamePhase.listening,
        errorMessage: ErrorHandler.describe(e, language: _language),
      );
    }
  }

  Future<void> _processPlayerAction(PlayerAction action) async {
    final session = state.session;
    if (session == null) return;

    final participants = session.config.participants;
    final fallbackName = participants.isNotEmpty
        ? participants.first.name
        : (session.config.language == 'en' ? 'little friend' : 'lille ven');

    state = state.copyWith(phase: GamePhase.processing);

    try {
      final isLastStep =
          session.storyState.currentStep + 1 >= session.config.maxSteps;

      LLMResponse response;
      if (isLastStep) {
        response = await _llmService.generateVictoryNarration(session);
      } else {
        response = await _llmService.processPlayerAction(
          session: session,
          action: action,
        );
      }

      final updatedSession = session.addNarrativeAndAction(
        narrative: response.storySegment,
        action: action,
        nextChallenge: response.nextChallenge,
      );

      state = state.copyWith(
        session: updatedSession,
        phase: GamePhase.narrating,
      );

      await _storage.saveActiveSession(updatedSession);

      await _playNarration(response.fullNarration);

      if (updatedSession.shouldEnd) {
        await _handleVictory(updatedSession);
      } else {
        state = state.copyWith(phase: GamePhase.listening);
      }
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.processPlayerAction', e, stackTrace);
      final fallback = LLMResponse.fallback(
        actionType: action.type,
        participantName: fallbackName,
        language: session.config.language,
      );
      await _playNarration(fallback.fullNarration);
      state = state.copyWith(phase: GamePhase.listening);
    }
  }

  /// Narration is best-effort. If ElevenLabs is down the adventure continues
  /// in silence rather than stranding the child on a dead screen.
  Future<void> _playNarration(String text) async {
    final session = state.session;
    if (session == null) return;

    try {
      await _ttsService.speakDanish(
        text: text,
        voiceId: session.config.elevenLabsVoiceId,
      );
    } catch (e, stackTrace) {
      ErrorHandler.log('GameSession.playNarration', e, stackTrace);
    }
  }

  Future<void> _handleVictory(GameSession session) async {
    _sessionTimer?.cancel();

    final completedSession = session.markCompleted();
    state = state.copyWith(
      session: completedSession,
      phase: GamePhase.victory,
    );

    await _storage.clearActiveSession();
  }

  Future<void> endGame() async {
    _sessionTimer?.cancel();

    final session = state.session;
    if (session != null) {
      final completedSession = session.markCompleted();
      state = state.copyWith(
        session: completedSession,
        phase: GamePhase.victory,
      );
    }

    await _storage.clearActiveSession();
  }

  Future<void> resetGame() async {
    _sessionTimer?.cancel();
    await _ttsService.stop();
    await _sttService.cancelRecording();

    state = state.copyWith(
      clearSession: true,
      phase: GamePhase.idle,
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameState>((ref) {
  return GameSessionNotifier(ref);
});

final currentStepProvider = Provider<int>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.storyState.currentStep ?? 0;
});

final maxStepsProvider = Provider<int>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.config.maxSteps ?? 5;
});

final progressProvider = Provider<double>((ref) {
  final current = ref.watch(currentStepProvider);
  final max = ref.watch(maxStepsProvider);
  return current / max;
});

final timeRemainingProvider = Provider<Duration>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.timeRemaining ?? Duration.zero;
});

final currentChallengeProvider = Provider<String>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.storyState.currentChallenge ?? '';
});

/// The child whose turn it is, or null when nobody was named at setup.
final currentPlayerProvider = Provider<Participant?>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.currentPlayer;
});

/// True only when turns actually rotate, so single-child games don't get a
/// pointless "your turn" badge.
final isMultiplayerProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameSessionProvider);
  return gameState.session?.isMultiplayer ?? false;
});
