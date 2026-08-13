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

    test('all themes have initial challenges in both languages', () {
      // The old version of this test asserted the Danish challenge did not
      // contain "find" as a proxy for "not English" — but "find"/"finde" is
      // ordinary Danish, so it failed on every theme that used it.
      for (final theme in StoryTheme.values) {
        final danish = theme.getInitialChallenge('Emma', 'da');
        final english = theme.getInitialChallenge('Emma', 'en');

        expect(danish.isNotEmpty, true, reason: '${theme.name} da');
        expect(english.isNotEmpty, true, reason: '${theme.name} en');
        expect(danish == english, false, reason: '${theme.name} not translated');

        // Each greets the child by name in its own language.
        expect(danish.contains('Hej, Emma!'), true, reason: '${theme.name} da');
        expect(english.contains('Hey, Emma!'), true, reason: '${theme.name} en');
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
      const env = Environment.house;
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
