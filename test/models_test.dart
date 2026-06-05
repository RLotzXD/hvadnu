import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/models/models.dart';
import 'package:hvad_nu/config/story_themes.dart';
import 'package:hvad_nu/config/environment_config.dart';
import 'package:hvad_nu/config/narrator_profiles.dart';

void main() {
  group('ParentConfig', () {
    test('creates default config with expected values', () {
      final config = ParentConfig.defaultConfig();

      expect(config.theme, StoryTheme.dragejagt);
      expect(config.environment, Environment.house);
      expect(config.maxSteps, 5);
      expect(config.maxDuration, const Duration(minutes: 10));
      expect(config.narrator, NarratorProfile.wiseWizard);
    });

    test('serializes and deserializes correctly', () {
      final original = ParentConfig(
        theme: StoryTheme.rumrejsen,
        environment: Environment.beach,
        maxSteps: 8,
        maxDuration: const Duration(minutes: 15),
        narrator: NarratorProfile.friendlyRobot,
        participants: [],
        language: 'da',
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      final json = original.toJson();
      final restored = ParentConfig.fromJson(json);

      expect(restored.theme, original.theme);
      expect(restored.environment, original.environment);
      expect(restored.maxSteps, original.maxSteps);
      expect(restored.maxDuration, original.maxDuration);
      expect(restored.narrator, original.narrator);
    });

    test('copyWith creates new instance with updated values', () {
      final original = ParentConfig.defaultConfig();
      final updated = original.copyWith(
        theme: StoryTheme.pirateventyret,
        maxSteps: 3,
      );

      expect(updated.theme, StoryTheme.pirateventyret);
      expect(updated.maxSteps, 3);
      expect(updated.environment, original.environment);
      expect(updated.narrator, original.narrator);
    });
  });

  group('PlayerAction', () {
    test('creates photo action correctly', () {
      final action = PlayerAction.photo('base64encodedimage');

      expect(action.type, 'photo');
      expect(action.content, 'base64encodedimage');
      expect(action.isPhoto, true);
      expect(action.isSpeech, false);
    });

    test('creates speech action correctly', () {
      final action = PlayerAction.speech('Jeg fandt en rød bold!');

      expect(action.type, 'speech');
      expect(action.content, 'Jeg fandt en rød bold!');
      expect(action.isPhoto, false);
      expect(action.isSpeech, true);
    });

    test('serializes and deserializes correctly', () {
      final original = PlayerAction.photo('testdata');
      final json = original.toJson();
      final restored = PlayerAction.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.content, original.content);
    });
  });

  group('StoryState', () {
    test('creates initial state correctly', () {
      final state = StoryState.initial(
        sessionId: 'test-session-123',
        initialChallenge: 'Find noget gult!',
      );

      expect(state.sessionId, 'test-session-123');
      expect(state.currentChallenge, 'Find noget gult!');
      expect(state.currentStep, 0);
      expect(state.narrativeHistory, isEmpty);
      expect(state.playerActions, isEmpty);
    });

    test('addNarrative appends to history', () {
      final state = StoryState.initial(
        sessionId: 'test',
        initialChallenge: 'Challenge 1',
      );

      final updated = state.addNarrative('Fantastisk! Du fandt det!');

      expect(updated.narrativeHistory.length, 1);
      expect(updated.narrativeHistory.first, 'Fantastisk! Du fandt det!');
    });

    test('incrementStep increases step count', () {
      final state = StoryState.initial(
        sessionId: 'test',
        initialChallenge: 'Challenge 1',
      );

      final updated = state.incrementStep().incrementStep();

      expect(updated.currentStep, 2);
    });

    test('getTruncatedHistoryForLLM truncates long history', () {
      var state = StoryState.initial(
        sessionId: 'test',
        initialChallenge: 'Start',
      );

      for (int i = 0; i < 8; i++) {
        state = state.addNarrative('Story segment $i.');
      }

      final truncated = state.getTruncatedHistoryForLLM();

      expect(truncated.contains('Tidligere'), true);
      expect(truncated.contains('Story segment 7'), true);
    });
  });

  group('GameSession', () {
    test('creates session with correct initial state', () {
      final config = ParentConfig.defaultConfig();
      final session = GameSession.create(config);

      expect(session.status, GameSessionStatus.playing);
      expect(session.isActive, true);
      expect(session.storyState.currentStep, 0);
      expect(session.completedAt, null);
    });

    test('isVictoryConditionMet returns true when steps completed', () {
      final config = ParentConfig.defaultConfig().copyWith(maxSteps: 2);
      var session = GameSession.create(config);

      expect(session.isVictoryConditionMet, false);

      session = session.copyWith(
        storyState: session.storyState.incrementStep().incrementStep(),
      );

      expect(session.isVictoryConditionMet, true);
    });

    test('progress calculates correctly', () {
      final config = ParentConfig.defaultConfig().copyWith(maxSteps: 4);
      var session = GameSession.create(config);

      expect(session.progress, 0.0);

      session = session.copyWith(
        storyState: session.storyState.incrementStep().incrementStep(),
      );

      expect(session.progress, 0.5);
    });

    test('markCompleted updates status', () {
      final session = GameSession.create(ParentConfig.defaultConfig());
      final completed = session.markCompleted();

      expect(completed.status, GameSessionStatus.completed);
      expect(completed.completedAt, isNotNull);
      expect(completed.isActive, false);
    });
  });

  group('LLMResponse', () {
    test('parses valid JSON correctly', () {
      final json = {
        'validation_success': true,
        'story_segment': 'Fantastisk fund!',
        'next_challenge': 'Find noget blåt.',
        'encouragement': null,
        'difficulty_adjustment': 1.0,
      };

      final response = LLMResponse.fromJson(json);

      expect(response.validationSuccess, true);
      expect(response.storySegment, 'Fantastisk fund!');
      expect(response.nextChallenge, 'Find noget blåt.');
      expect(response.difficultyAdjustment, 1.0);
    });

    test('fallback response creates valid response', () {
      final fallback = LLMResponse.fallback(actionType: 'photo');

      expect(fallback.validationSuccess, true);
      expect(fallback.storySegment.isNotEmpty, true);
      expect(fallback.nextChallenge.isNotEmpty, true);
    });

    test('fullNarration combines segments correctly', () {
      final response = LLMResponse(
        validationSuccess: true,
        storySegment: 'Du fandt det!',
        nextChallenge: 'Find nu noget rundt.',
        encouragement: 'Godt gået!',
      );

      expect(response.fullNarration, 'Du fandt det! Godt gået! Find nu noget rundt.');
    });
  });
}
