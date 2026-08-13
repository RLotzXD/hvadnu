import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';
import '../utils/prompt_builder.dart';

/// Gemini-backed story generation.
///
/// Every public method is total: on any failure it returns a canned narration
/// rather than throwing, because a four-year-old mid-adventure cannot be shown
/// an error. Failures are logged via [ErrorHandler] instead — if the narrator
/// starts sounding generic, the log is where the reason will be.
class LLMService {
  final Dio _dio;

  LLMService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.geminiBaseUrl,
              connectTimeout: const Duration(seconds: ApiConfig.llmTimeoutSeconds),
              receiveTimeout: const Duration(seconds: ApiConfig.llmTimeoutSeconds),
            ));

  Future<LLMResponse> processPlayerAction({
    required GameSession session,
    required PlayerAction action,
  }) async {
    final participants = session.config.participants;
    final fallbackName = participants.isNotEmpty
        ? participants.first.name
        : (session.config.language == 'en' ? 'little friend' : 'lille ven');

    try {
      final systemPrompt = PromptBuilder.buildSystemPrompt(session.config);
      final userMessage = PromptBuilder.buildUserMessage(
        session: session,
        playerInput: action.content,
        inputType: action.type,
      );

      // Text before image is what Google recommends for a single-image prompt.
      final parts = <Map<String, dynamic>>[
        {'text': '$systemPrompt\n\n$userMessage'},
      ];

      if (action.isPhoto) {
        if (action.content.trim().isEmpty) {
          throw const ApiException(
            message: 'Empty image payload — refusing to call Gemini',
          );
        }
        parts.add({
          'inlineData': {
            'mimeType': 'image/jpeg',
            'data': action.content,
          },
        });
      }

      final text = await _generate(parts: parts, label: 'processPlayerAction');
      return _parseResponse(text, action.type);
    } catch (e, stackTrace) {
      ErrorHandler.log('LLMService.processPlayerAction', e, stackTrace);
      return LLMResponse.fallback(
        actionType: action.type,
        participantName: fallbackName,
        language: session.config.language,
      );
    }
  }

  Future<LLMResponse> generateVictoryNarration(GameSession session) async {
    try {
      final text = await _generate(
        parts: [
          {
            'text': '${PromptBuilder.buildSystemPrompt(session.config)}\n\n'
                '${PromptBuilder.buildVictoryPrompt(session)}',
          },
        ],
        label: 'generateVictoryNarration',
      );
      return _parseResponse(text, 'victory');
    } catch (e, stackTrace) {
      ErrorHandler.log('LLMService.generateVictoryNarration', e, stackTrace);
      return LLMResponse.victory(
        theme: session.config.theme.name,
        storyContext: session.storyState.narrativeHistory.join(' '),
      );
    }
  }

  Future<LLMResponse> generateTimeExpiredNarration(GameSession session) async {
    try {
      final text = await _generate(
        parts: [
          {
            'text': '${PromptBuilder.buildSystemPrompt(session.config)}\n\n'
                '${PromptBuilder.buildTimeExpiredPrompt(session)}',
          },
        ],
        label: 'generateTimeExpiredNarration',
      );
      return _parseResponse(text, 'timeExpired');
    } catch (e, stackTrace) {
      ErrorHandler.log('LLMService.generateTimeExpiredNarration', e, stackTrace);
      return LLMResponse.timeExpired(language: session.config.language);
    }
  }

  // ------------------------------------------------------------- Requests

  /// One place that knows how to talk to Gemini, so generation settings can't
  /// drift between the turn, victory and timeout prompts.
  Future<String> _generate({
    required List<Map<String, dynamic>> parts,
    required String label,
  }) async {
    try {
      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent',
        queryParameters: {'key': ApiConfig.geminiApiKey},
        data: {
          'contents': [
            {'role': 'user', 'parts': parts},
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': _maxOutputTokens,
            'topP': 0.95,
            'topK': 40,
            // gemini-2.5-flash reasons before answering by default, and those
            // thinking tokens are billed against maxOutputTokens. On a budget
            // this size thinking can consume all of it, leaving a candidate
            // with no parts at all — which is why the narrator was silently
            // dropping to canned lines instead of describing the photo.
            // Storytelling here does not need reasoning; latency does matter,
            // because a child is holding a camera up and waiting.
            'thinkingConfig': {'thinkingBudget': 0},
          },
          'safetySettings': _safetySettings,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return _extractText(response.data, label);
    } on DioException catch (e) {
      // Gemini explains 4xx failures in the body; without this the reason is
      // lost and every turn just looks like "something went wrong".
      ErrorHandler.log(
        'LLMService.$label',
        'HTTP ${e.response?.statusCode} ${e.response?.data}',
      );
      throw ErrorHandler.toAppException(e, context: label);
    }
  }

  static const int _maxOutputTokens = 2000;

  /// BLOCK_NONE is a restricted setting that is not granted to every API key
  /// and makes the whole request 400. BLOCK_ONLY_HIGH is universally accepted,
  /// and for a game aimed at four-year-olds it is the better default anyway.
  static const List<Map<String, String>> _safetySettings = [
    {
      'category': 'HARM_CATEGORY_HARASSMENT',
      'threshold': 'BLOCK_ONLY_HIGH',
    },
    {
      'category': 'HARM_CATEGORY_HATE_SPEECH',
      'threshold': 'BLOCK_ONLY_HIGH',
    },
    {
      'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      'threshold': 'BLOCK_ONLY_HIGH',
    },
    {
      'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
      'threshold': 'BLOCK_ONLY_HIGH',
    },
  ];

  // -------------------------------------------------------------- Parsing

  /// Pulls the model's text out of a `generateContent` response.
  ///
  /// Written defensively and verbosely because the previous one-liner
  /// (`candidates[0]['content']['parts'][0]['text']`) threw a bare type error
  /// on every non-happy path, and the catch upstream turned that into silent
  /// canned narration. Each failure mode now names itself in the log.
  String _extractText(dynamic body, String label) {
    if (body is! Map) {
      throw ApiException(message: '$label: unexpected response type '
          '${body.runtimeType}');
    }

    final blockReason = body['promptFeedback']?['blockReason'];
    if (blockReason != null) {
      throw ApiException(
        message: '$label: prompt blocked by safety filter ($blockReason)',
      );
    }

    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw ApiException(message: '$label: response contained no candidates');
    }

    final candidate = candidates.first as Map;
    final finishReason = candidate['finishReason'];
    final parts = (candidate['content'] as Map?)?['parts'] as List?;

    if (parts == null || parts.isEmpty) {
      final usage = body['usageMetadata'];
      throw ApiException(
        message: '$label: candidate had no parts '
            '(finishReason: $finishReason, usage: $usage). '
            'If finishReason is MAX_TOKENS, thinking consumed the output '
            'budget — check thinkingConfig.',
      );
    }

    // Thought summaries arrive as parts flagged `thought: true`; they are not
    // narration and must not reach the child.
    final text = parts
        .whereType<Map>()
        .where((p) => p['thought'] != true)
        .map((p) => p['text'])
        .whereType<String>()
        .join()
        .trim();

    if (text.isEmpty) {
      throw ApiException(
        message: '$label: candidate parts held no text '
            '(finishReason: $finishReason)',
      );
    }

    if (finishReason != null && finishReason != 'STOP') {
      // Usable but suspicious — worth knowing about without failing the turn.
      ErrorHandler.log('LLMService.$label', 'finishReason was $finishReason');
    }

    return text;
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
      // Gemini ignored the JSON contract; salvage prose instead of failing.
      ErrorHandler.log('LLMService.parse', 'Non-JSON response, falling back: $e');
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
