import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../utils/prompt_builder.dart';

class LLMService {
  final Dio _dio;

  LLMService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.geminiBaseUrl,
          connectTimeout: Duration(seconds: ApiConfig.llmTimeoutSeconds),
          receiveTimeout: Duration(seconds: ApiConfig.llmTimeoutSeconds),
        ));

  Future<LLMResponse> processPlayerAction({
    required GameSession session,
    required PlayerAction action,
  }) async {
    try {
      final systemPrompt = PromptBuilder.buildSystemPrompt(session.config);
      final userMessage = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: action.content,
        inputType: action.type,
      );

      final contents = <Map<String, dynamic>>[];

      if (action.isPhoto) {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$systemPrompt\n\n$userMessage'},
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': action.content,
              },
            },
          ],
        });
      } else {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$systemPrompt\n\n$userMessage'},
          ],
        });
      }

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent',
        queryParameters: {'key': ApiConfig.geminiApiKey},
        data: {
          'contents': contents,
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 2000,
            'topP': 0.95,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
          ],
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return LLMResponse.fallback(actionType: action.type);
      }

      final content = candidates[0]['content']['parts'][0]['text'] as String;
      return _parseResponse(content, action.type);
    } catch (e) {
      return LLMResponse.fallback(actionType: action.type);
    }
  }

  Future<LLMResponse> generateVictoryNarration(GameSession session) async {
    try {
      final systemPrompt = PromptBuilder.buildSystemPrompt(session.config);
      final victoryPrompt = PromptBuilder.buildVictoryPrompt(session);

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent',
        queryParameters: {'key': ApiConfig.geminiApiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\n$victoryPrompt'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 1500,
            'topP': 0.95,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return LLMResponse.victory(
          theme: session.config.theme.name,
          storyContext: session.storyState.narrativeHistory.join(' '),
        );
      }

      final content = candidates[0]['content']['parts'][0]['text'] as String;
      return _parseResponse(content, 'victory');
    } catch (e) {
      return LLMResponse.victory(
        theme: session.config.theme.name,
        storyContext: session.storyState.narrativeHistory.join(' '),
      );
    }
  }

  Future<LLMResponse> generateTimeExpiredNarration(GameSession session) async {
    try {
      final systemPrompt = PromptBuilder.buildSystemPrompt(session.config);
      final timeExpiredPrompt = PromptBuilder.buildTimeExpiredPrompt(session);

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent',
        queryParameters: {'key': ApiConfig.geminiApiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\n$timeExpiredPrompt'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 1000,
            'topP': 0.95,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return LLMResponse.timeExpired(language: session.config.language);
      }

      final content = candidates[0]['content']['parts'][0]['text'] as String;
      return _parseResponse(content, 'timeExpired');
    } catch (e) {
      return LLMResponse.timeExpired(language: session.config.language);
    }
  }

  LLMResponse _parseResponse(String content, String actionType) {
    try {
      String jsonStr = content;

      // Extract JSON from markdown code blocks if present
      final jsonMatch = RegExp(r'```json?\s*([\s\S]*?)\s*```').firstMatch(content);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1)!;
      } else {
        // Try to find raw JSON object
        final rawJsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (rawJsonMatch != null) {
          jsonStr = rawJsonMatch.group(0)!;
        }
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LLMResponse.fromJson(json);
    } catch (e) {
      // If parsing fails, try to extract story content manually
      return _extractFromPlainText(content, actionType);
    }
  }

  LLMResponse _extractFromPlainText(String content, String actionType) {
    // Fallback: if Gemini returns plain text instead of JSON,
    // try to use it as the story segment
    final cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      return LLMResponse.fallback(actionType: actionType);
    }

    // Split into sentences and use first 2-3 as story, last as challenge
    final sentences = cleanContent.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();

    if (sentences.length >= 2) {
      final storyParts = sentences.sublist(0, sentences.length - 1).take(3);
      final challenge = sentences.last.trim();

      return LLMResponse(
        validationSuccess: true,
        storySegment: '${storyParts.join('. ')}.',
        nextChallenge: challenge.endsWith('?') ? challenge : '$challenge?',
      );
    }

    return LLMResponse.fallback(actionType: actionType);
  }
}
