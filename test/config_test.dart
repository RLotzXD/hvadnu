import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/config/story_themes.dart';
import 'package:hvad_nu/config/environment_config.dart';
import 'package:hvad_nu/config/narrator_profiles.dart';

void main() {
  group('StoryTheme', () {
    test('all themes have display names', () {
      for (final theme in StoryTheme.values) {
        expect(theme.displayName.isNotEmpty, true);
        expect(theme.description.isNotEmpty, true);
        expect(theme.emoji.isNotEmpty, true);
      }
    });

    test('all themes have initial challenges in Danish', () {
      for (final theme in StoryTheme.values) {
        final challenge = theme.initialChallenge;
        expect(challenge.isNotEmpty, true);
        // Basic check that it's not English
        expect(challenge.contains('find') || challenge.contains('Find'), false);
      }
    });

    test('all themes have system prompt additions', () {
      for (final theme in StoryTheme.values) {
        expect(theme.systemPromptAddition.isNotEmpty, true);
        expect(theme.systemPromptAddition.contains('Finale'), true);
      }
    });
  });

  group('Environment', () {
    test('all environments have display names', () {
      for (final env in Environment.values) {
        expect(env.displayName.isNotEmpty, true);
        expect(env.description.isNotEmpty, true);
        expect(env.emoji.isNotEmpty, true);
      }
    });

    test('all environments have available objects', () {
      for (final env in Environment.values) {
        expect(env.availableObjects.isNotEmpty, true);
        expect(env.availableObjects.length >= 10, true);
      }
    });

    test('contextForLLM includes environment name and objects', () {
      final env = Environment.house;
      final context = env.contextForLLM;

      expect(context.contains('hjemme'), true);
      expect(context.contains('sokker'), true);
    });
  });

  group('NarratorProfile', () {
    test('all narrators have voice IDs', () {
      for (final narrator in NarratorProfile.values) {
        expect(narrator.elevenLabsVoiceId.isNotEmpty, true);
        expect(narrator.displayName.isNotEmpty, true);
        expect(narrator.voiceStylePrompt.isNotEmpty, true);
      }
    });

    test('voice style prompts are in Danish', () {
      for (final narrator in NarratorProfile.values) {
        final prompt = narrator.voiceStylePrompt;
        // Check for Danish words
        expect(
          prompt.contains('Tal') || prompt.contains('din') || prompt.contains('med'),
          true,
        );
      }
    });
  });
}
