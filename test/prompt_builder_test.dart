import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/utils/prompt_builder.dart';
import 'package:hvad_nu/models/models.dart';
import 'package:hvad_nu/config/story_themes.dart';
import 'package:hvad_nu/config/environment_config.dart';
import 'package:hvad_nu/config/narrator_profiles.dart';

void main() {
  group('PromptBuilder', () {
    late ParentConfig testConfig;
    late GameSession testSession;

    setUp(() {
      testConfig = ParentConfig(
        theme: StoryTheme.dragejagt,
        environment: Environment.forest,
        maxSteps: 5,
        maxDuration: const Duration(minutes: 10),
        narrator: NarratorProfile.wiseWizard,
        participants: [],
        language: 'da',
        createdAt: DateTime.now(),
      );
      testSession = GameSession.create(testConfig);
    });

    test('buildSystemPrompt includes key instructions', () {
      final prompt = PromptBuilder.buildSystemPrompt(testConfig);

      // Core rules must be present
      expect(prompt.contains('ACCEPTER ALTID'), true);
      expect(prompt.contains('ALDRIG'), true);
      expect(prompt.contains('JSON'), true);

      // Theme must be included
      expect(prompt.contains('Dragejagt') || prompt.contains('dragejagt'), true);

      // Environment context
      expect(prompt.contains('forest') || prompt.contains('skov'), true);
    });

    test('buildSystemPrompt is in Danish', () {
      final prompt = PromptBuilder.buildSystemPrompt(testConfig);

      // Should contain Danish words
      expect(prompt.contains('barnet') || prompt.contains('Barnet'), true);
      expect(prompt.contains('eventyr') || prompt.contains('Eventyr'), true);
    });

    test('buildUserMessage includes step information', () {
      final message = PromptBuilder.buildUserMessage(
        session: testSession,
        playerInput: 'test input',
        inputType: 'speech',
      );

      expect(message.contains('Skridt'), true);
      expect(message.contains('1'), true); // First step
    });

    test('buildUserMessage handles photo input', () {
      final message = PromptBuilder.buildUserMessage(
        session: testSession,
        playerInput: 'base64data',
        inputType: 'photo',
      );

      expect(message.contains('billede'), true);
    });

    test('buildUserMessage handles speech input', () {
      final message = PromptBuilder.buildUserMessage(
        session: testSession,
        playerInput: 'Jeg fandt en rød svamp!',
        inputType: 'speech',
      );

      expect(message.contains('sagde'), true);
      expect(message.contains('Jeg fandt en rød svamp!'), true);
    });

    test('buildUserMessage indicates last step', () {
      // Create session at step 4 of 5
      var session = testSession;
      for (int i = 0; i < 4; i++) {
        session = session.copyWith(
          storyState: session.storyState.incrementStep(),
        );
      }

      final message = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: 'test',
        inputType: 'speech',
      );

      expect(message.contains('SIDSTE SKRIDT'), true);
    });

    test('buildVictoryPrompt creates celebration prompt', () {
      final prompt = PromptBuilder.buildVictoryPrompt(testSession);

      expect(prompt.contains('SEJR'), true);
      expect(prompt.contains('gennemført'), true);
      expect(prompt.contains('triumferende'), true);
    });
  });
}
