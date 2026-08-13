import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/utils/prompt_builder.dart';

import 'helpers/test_data.dart';

void main() {
  group('GameSession turn rotation', () {
    test('a single child is always the current player', () {
      final session = testSession(
        config: testConfig(participantNames: ['Emma'], maxSteps: 5),
        currentStep: 3,
      );

      expect(session.isMultiplayer, isFalse);
      expect(session.currentPlayer?.name, 'Emma');
      expect(session.nextPlayer?.name, 'Emma');
    });

    test('two children alternate on every step', () {
      final config = testConfig(
        participantNames: ['Emma', 'Noah'],
        maxSteps: 6,
      );

      expect(testSession(config: config, currentStep: 0).currentPlayer?.name,
          'Emma');
      expect(testSession(config: config, currentStep: 1).currentPlayer?.name,
          'Noah');
      expect(testSession(config: config, currentStep: 2).currentPlayer?.name,
          'Emma');
    });

    test('three children rotate and wrap around', () {
      final config = testConfig(
        participantNames: ['Emma', 'Noah', 'Ida'],
        maxSteps: 9,
      );

      expect(testSession(config: config, currentStep: 2).currentPlayer?.name,
          'Ida');
      expect(testSession(config: config, currentStep: 3).currentPlayer?.name,
          'Emma');
    });

    test('nextPlayer is the one after the current player', () {
      final session = testSession(
        config: testConfig(participantNames: ['Emma', 'Noah'], maxSteps: 6),
        currentStep: 0,
      );

      expect(session.currentPlayer?.name, 'Emma');
      expect(session.nextPlayer?.name, 'Noah');
    });

    test('no participants means no player rather than a crash', () {
      final session = testSession(
        config: testConfig(participantNames: [], maxSteps: 3),
      );

      expect(session.currentPlayer, isNull);
      expect(session.nextPlayer, isNull);
      expect(session.isMultiplayer, isFalse);
    });
  });

  group('PromptBuilder agrees with the session', () {
    test('names the next child in the turn instruction', () {
      final session = testSession(
        config: testConfig(participantNames: ['Emma', 'Noah'], maxSteps: 6),
        currentStep: 0,
      );

      final message = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: 'en rød bil',
        inputType: 'speech',
      );

      expect(message, contains(session.nextPlayer!.name));
      expect(message, contains('NÆSTE TUR'));
    });

    test('uses a gentle placeholder when nobody was named', () {
      final session = testSession(
        config: testConfig(participantNames: []),
      );

      // The name only appears on the photo branch, which narrates who took
      // the picture.
      final message = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: 'BASE64',
        inputType: 'photo',
      );

      expect(message, contains('lille ven'));
    });

    test('English sessions get the English placeholder', () {
      final session = testSession(
        config: testConfig(participantNames: [], language: 'en'),
      );

      final message = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: 'BASE64',
        inputType: 'photo',
      );

      expect(message, contains('little friend'));
    });
  });
}
