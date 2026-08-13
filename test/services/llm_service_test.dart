import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/models/models.dart';
import 'package:hvad_nu/services/llm_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_data.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late LLMService service;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    service = LLMService(dio: dio);
  });

  void stubPost(String responseText) {
    when(() => dio.post(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((invocation) async => Response(
          requestOptions: RequestOptions(path: invocation.positionalArguments.first as String),
          statusCode: 200,
          data: geminiResponse(responseText),
        ));
  }

  void stubFailure(DioExceptionType type) {
    when(() => dio.post(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: type,
        ));
  }

  group('processPlayerAction response parsing', () {
    test('parses a bare JSON object', () async {
      stubPost(storyJson(
        storySegment: 'Dragen nikker.',
        nextChallenge: 'Find noget blåt!',
      ));

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      expect(response.storySegment, 'Dragen nikker.');
      expect(response.nextChallenge, 'Find noget blåt!');
      expect(response.validationSuccess, isTrue);
    });

    test('parses JSON wrapped in a markdown code fence', () async {
      stubPost('```json\n${storyJson(storySegment: 'Indpakket.')}\n```');

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      expect(response.storySegment, 'Indpakket.');
    });

    test('parses JSON surrounded by chatter', () async {
      stubPost('Here you go!\n${storyJson(storySegment: 'Omgivet.')}\nHope that helps.');

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      expect(response.storySegment, 'Omgivet.');
    });

    test('salvages prose when Gemini ignores the JSON contract', () async {
      stubPost('Dragen er glad. Den vifter med halen. Kan du finde en pind?');

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      expect(response.storySegment, contains('Dragen er glad'));
      expect(response.nextChallenge, contains('Kan du finde en pind'));
    });

    test('falls back when the response has no candidates', () async {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 200,
            data: <String, dynamic>{'candidates': <dynamic>[]},
          ));

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      expect(response.storySegment, contains('Emma'));
      expect(response.nextChallenge, isNotEmpty);
    });
  });

  group('failure handling', () {
    test('returns a usable fallback instead of throwing on network error', () async {
      stubFailure(DioExceptionType.connectionTimeout);

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      // A four-year-old mid-adventure must never see an error, so every
      // failure path still produces narration to speak.
      expect(response.storySegment, isNotEmpty);
      expect(response.nextChallenge, isNotEmpty);
      expect(response.storySegment, contains('Emma'));
    });

    test('fallback respects the session language', () async {
      stubFailure(DioExceptionType.connectionError);

      final response = await service.processPlayerAction(
        session: testSession(config: testConfig(language: 'en')),
        action: PlayerAction.photo('abc123'),
      );

      expect(response.storySegment, contains('Emma'));
      expect(response.nextChallenge, contains('color'));
    });

    test('refuses to call Gemini with an empty image and falls back', () async {
      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('   '),
      );

      verifyNever(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
      expect(response.storySegment, isNotEmpty);
    });

    test('victory narration falls back on failure', () async {
      stubFailure(DioExceptionType.badResponse);

      final response = await service.generateVictoryNarration(testSession());

      expect(response.storySegment, isNotEmpty);
      expect(response.nextChallenge, isNotEmpty);
    });

    test('time-expired narration falls back in the session language', () async {
      stubFailure(DioExceptionType.badResponse);

      final response = await service.generateTimeExpiredNarration(
        testSession(config: testConfig(language: 'en')),
      );

      expect(response.storySegment, contains('Oh no'));
    });
  });

  group('degenerate Gemini responses', () {
    // Each of these used to throw a bare type error out of
    // candidates[0]['content']['parts'][0]['text'] and get swallowed into
    // canned narration, which is what made the narrator ignore photos.
    void stubRaw(Map<String, dynamic> body) {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 200,
            data: body,
          ));
    }

    test('thinking consuming the whole budget falls back cleanly', () async {
      stubRaw({
        'candidates': [
          {'content': <String, dynamic>{}, 'finishReason': 'MAX_TOKENS'},
        ],
        'usageMetadata': {'thoughtsTokenCount': 2000, 'candidatesTokenCount': 0},
      });

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('IMG'),
      );

      expect(response.storySegment, isNotEmpty);
      expect(response.nextChallenge, isNotEmpty);
    });

    test('a safety-blocked prompt falls back cleanly', () async {
      stubRaw({
        'promptFeedback': {'blockReason': 'SAFETY'},
      });

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('IMG'),
      );

      expect(response.storySegment, isNotEmpty);
    });

    test('thought-only parts are not narrated to the child', () async {
      stubRaw({
        'candidates': [
          {
            'content': {
              'parts': [
                {'thought': true, 'text': 'The user wants a dragon story...'},
              ],
            },
            'finishReason': 'MAX_TOKENS',
          },
        ],
      });

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('IMG'),
      );

      expect(response.storySegment, isNot(contains('The user wants')));
      expect(response.storySegment, contains('Emma'));
    });

    test('narration text is used even when a thought part precedes it',
        () async {
      stubRaw({
        'candidates': [
          {
            'content': {
              'parts': [
                {'thought': true, 'text': 'Reasoning...'},
                {'text': storyJson(storySegment: 'Jeg ser en rød bold!')},
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      final response = await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('IMG'),
      );

      expect(response.storySegment, 'Jeg ser en rød bold!');
    });
  });

  group('request shape', () {
    test('disables the thinking budget', () async {
      stubPost(storyJson());

      await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('IMG'),
      );

      final captured = verify(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      final config = captured['generationConfig'] as Map<String, dynamic>;
      expect(config['thinkingConfig'], {'thinkingBudget': 0});
    });

    test('never sends the restricted BLOCK_NONE threshold', () async {
      stubPost(storyJson());

      await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en sten'),
      );

      final captured = verify(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      final thresholds = (captured['safetySettings'] as List)
          .map((s) => (s as Map)['threshold'])
          .toSet();

      expect(thresholds, {'BLOCK_ONLY_HIGH'});
    });

    test('sends the photo as inline base64 JPEG', () async {
      stubPost(storyJson());

      await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.photo('BASE64DATA'),
      );

      final captured = verify(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      final parts = (captured['contents'] as List).first['parts'] as List;
      final inlineData = parts.last['inlineData'] as Map<String, dynamic>;

      expect(inlineData['mimeType'], 'image/jpeg');
      expect(inlineData['data'], 'BASE64DATA');
    });

    test('sends speech as text only, with no image part', () async {
      stubPost(storyJson());

      await service.processPlayerAction(
        session: testSession(),
        action: PlayerAction.speech('en rød bil'),
      );

      final captured = verify(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      final parts = (captured['contents'] as List).first['parts'] as List;

      expect(parts, hasLength(1));
      expect(parts.first.containsKey('text'), isTrue);
    });
  });
}
