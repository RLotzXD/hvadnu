import 'package:uuid/uuid.dart';
import '../config/story_themes.dart';
import 'parent_config.dart';
import 'story_state.dart';
import 'player_action.dart';

enum GameSessionStatus {
  setup,
  playing,
  paused,
  completed,
}

class GameSession {
  final String id;
  final ParentConfig config;
  final StoryState storyState;
  final GameSessionStatus status;
  final DateTime? completedAt;

  const GameSession({
    required this.id,
    required this.config,
    required this.storyState,
    this.status = GameSessionStatus.playing,
    this.completedAt,
  });

  bool get isActive => status == GameSessionStatus.playing;

  bool get isVictoryConditionMet =>
      storyState.currentStep >= config.maxSteps;

  bool get isTimeExpired {
    final elapsed = DateTime.now().difference(storyState.sessionStartTime);
    return elapsed >= config.maxDuration;
  }

  bool get shouldEnd => isVictoryConditionMet || isTimeExpired;

  int get stepsRemaining => config.maxSteps - storyState.currentStep;

  double get progress => storyState.currentStep / config.maxSteps;

  Duration get timeRemaining {
    final elapsed = DateTime.now().difference(storyState.sessionStartTime);
    final remaining = config.maxDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  GameSession copyWith({
    String? id,
    ParentConfig? config,
    StoryState? storyState,
    GameSessionStatus? status,
    DateTime? completedAt,
  }) {
    return GameSession(
      id: id ?? this.id,
      config: config ?? this.config,
      storyState: storyState ?? this.storyState,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  GameSession updateStoryState(StoryState newState) {
    return copyWith(storyState: newState);
  }

  GameSession addNarrativeAndAction({
    required String narrative,
    required PlayerAction action,
    required String nextChallenge,
  }) {
    final updatedState = storyState
        .addNarrative(narrative)
        .addPlayerAction(action)
        .incrementStep()
        .updateChallenge(nextChallenge);

    return copyWith(storyState: updatedState);
  }

  GameSession markCompleted() {
    return copyWith(
      status: GameSessionStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  GameSession pause() {
    return copyWith(status: GameSessionStatus.paused);
  }

  GameSession resume() {
    return copyWith(status: GameSessionStatus.playing);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'config': config.toJson(),
        'storyState': storyState.toJson(),
        'status': status.name,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      config: ParentConfig.fromJson(json['config'] as Map<String, dynamic>),
      storyState:
          StoryState.fromJson(json['storyState'] as Map<String, dynamic>),
      status: GameSessionStatus.values
          .firstWhere((s) => s.name == json['status']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  factory GameSession.create(ParentConfig config) {
    final sessionId = const Uuid().v4();
    // For multiplayer, first challenge goes to first player
    final firstPlayerName = config.participants.length >= 2
        ? config.participants.first.name
        : config.participantNames;
    return GameSession(
      id: sessionId,
      config: config,
      storyState: StoryState.initial(
        sessionId: sessionId,
        initialChallenge: config.theme.getInitialChallenge(firstPlayerName, config.language),
      ),
      status: GameSessionStatus.playing,
    );
  }
}
