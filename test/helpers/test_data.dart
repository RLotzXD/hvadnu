import 'package:hvad_nu/config/environment_config.dart';
import 'package:hvad_nu/config/narrator_profiles.dart';
import 'package:hvad_nu/config/story_themes.dart';
import 'package:hvad_nu/models/models.dart';

/// Shared fixtures so tests describe the behaviour under test rather than
/// rebuilding a full config every time.
ParentConfig testConfig({
  List<String> participantNames = const ['Emma'],
  int maxSteps = 3,
  Duration maxDuration = const Duration(minutes: 10),
  String language = 'da',
  StoryTheme theme = StoryTheme.dragejagt,
}) {
  return ParentConfig(
    theme: theme,
    environment: Environment.house,
    maxSteps: maxSteps,
    maxDuration: maxDuration,
    narrator: NarratorProfile.wiseWizard,
    participants: [
      for (final name in participantNames)
        Participant(id: 'id-$name', name: name),
    ],
    language: language,
    createdAt: DateTime(2026, 1, 1),
  );
}

GameSession testSession({
  ParentConfig? config,
  int currentStep = 0,
}) {
  final resolvedConfig = config ?? testConfig();
  var session = GameSession.create(resolvedConfig);

  for (var i = 0; i < currentStep; i++) {
    session = session.addNarrativeAndAction(
      narrative: 'Narrative $i',
      action: PlayerAction.speech('answer $i'),
      nextChallenge: 'Challenge ${i + 1}',
    );
  }

  return session;
}

/// A well-formed Gemini `generateContent` response wrapping [text].
Map<String, dynamic> geminiResponse(String text) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    };

/// The JSON payload the prompt asks Gemini to return.
String storyJson({
  String storySegment = 'Dragen smiler til dig.',
  String nextChallenge = 'Kan du finde noget rødt?',
}) {
  return '{"validation_success": true, "story_segment": "$storySegment", '
      '"next_challenge": "$nextChallenge"}';
}
