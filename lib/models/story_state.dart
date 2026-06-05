import 'player_action.dart';

class StoryState {
  final List<String> narrativeHistory;
  final List<PlayerAction> playerActions;
  final int currentStep;
  final String currentChallenge;
  final DateTime sessionStartTime;
  final String sessionId;

  const StoryState({
    required this.narrativeHistory,
    required this.playerActions,
    required this.currentStep,
    required this.currentChallenge,
    required this.sessionStartTime,
    required this.sessionId,
  });

  Duration get elapsed => DateTime.now().difference(sessionStartTime);

  StoryState copyWith({
    List<String>? narrativeHistory,
    List<PlayerAction>? playerActions,
    int? currentStep,
    String? currentChallenge,
    DateTime? sessionStartTime,
    String? sessionId,
  }) {
    return StoryState(
      narrativeHistory: narrativeHistory ?? this.narrativeHistory,
      playerActions: playerActions ?? this.playerActions,
      currentStep: currentStep ?? this.currentStep,
      currentChallenge: currentChallenge ?? this.currentChallenge,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  StoryState addNarrative(String narrative) {
    return copyWith(
      narrativeHistory: [...narrativeHistory, narrative],
    );
  }

  StoryState addPlayerAction(PlayerAction action) {
    return copyWith(
      playerActions: [...playerActions, action],
    );
  }

  StoryState incrementStep() {
    return copyWith(currentStep: currentStep + 1);
  }

  StoryState updateChallenge(String newChallenge) {
    return copyWith(currentChallenge: newChallenge);
  }

  Map<String, dynamic> toJson() => {
        'narrativeHistory': narrativeHistory,
        'playerActions': playerActions.map((a) => a.toJson()).toList(),
        'currentStep': currentStep,
        'currentChallenge': currentChallenge,
        'sessionStartTime': sessionStartTime.toIso8601String(),
        'sessionId': sessionId,
      };

  factory StoryState.fromJson(Map<String, dynamic> json) {
    return StoryState(
      narrativeHistory: List<String>.from(json['narrativeHistory'] as List),
      playerActions: (json['playerActions'] as List)
          .map((a) => PlayerAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      currentStep: json['currentStep'] as int,
      currentChallenge: json['currentChallenge'] as String,
      sessionStartTime: DateTime.parse(json['sessionStartTime'] as String),
      sessionId: json['sessionId'] as String,
    );
  }

  factory StoryState.initial({
    required String sessionId,
    required String initialChallenge,
  }) {
    return StoryState(
      narrativeHistory: [],
      playerActions: [],
      currentStep: 0,
      currentChallenge: initialChallenge,
      sessionStartTime: DateTime.now(),
      sessionId: sessionId,
    );
  }

  /// Get truncated history for LLM context (keeps last 5 turns)
  String getTruncatedHistoryForLLM() {
    if (narrativeHistory.length <= 5) {
      return narrativeHistory.join('\n\n');
    }

    final earlier = narrativeHistory.sublist(0, narrativeHistory.length - 5);
    final recent = narrativeHistory.sublist(narrativeHistory.length - 5);

    final summary =
        'Tidligere i eventyret: ${earlier.map((n) => n.split('.').first).join('. ')}.';

    return '$summary\n\nSeneste handlinger:\n${recent.join('\n\n')}';
  }
}
