class LLMResponse {
  final bool validationSuccess;
  final String storySegment;
  final String nextChallenge;
  final String? encouragement;
  final double difficultyAdjustment;

  const LLMResponse({
    required this.validationSuccess,
    required this.storySegment,
    required this.nextChallenge,
    this.encouragement,
    this.difficultyAdjustment = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'validation_success': validationSuccess,
        'story_segment': storySegment,
        'next_challenge': nextChallenge,
        'encouragement': encouragement,
        'difficulty_adjustment': difficultyAdjustment,
      };

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      validationSuccess: json['validation_success'] as bool? ?? true,
      storySegment: json['story_segment'] as String? ?? '',
      nextChallenge: json['next_challenge'] as String? ?? '',
      encouragement: json['encouragement'] as String?,
      difficultyAdjustment:
          (json['difficulty_adjustment'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Fallback response when LLM fails
  factory LLMResponse.fallback({required String actionType}) {
    if (actionType == 'photo') {
      return const LLMResponse(
        validationSuccess: true,
        storySegment:
            'Åh, hvor spændende! Jeg kan se noget helt magisk dér! Det passer perfekt til vores eventyr.',
        nextChallenge: 'Kan du nu finde noget i en anden farve?',
      );
    }
    return const LLMResponse(
      validationSuccess: true,
      storySegment:
          'Ja, helt rigtigt! Du er en sand eventurer! Lad os fortsætte vores magiske rejse.',
      nextChallenge: 'Hvad kan du opdage nu?',
    );
  }

  /// Victory response for the final step
  factory LLMResponse.victory({
    required String theme,
    required String storyContext,
  }) {
    return LLMResponse(
      validationSuccess: true,
      storySegment:
          'FANTASTISK! Du har gjort det! Du har gennemført hele eventyret og reddet alle! Du er en SAND HELT!',
      nextChallenge: 'Eventyret er slut. Du vandt! Tillykke, lille eventurer!',
    );
  }

  /// Time expired response when the timer runs out
  factory LLMResponse.timeExpired({required String language}) {
    if (language == 'en') {
      return const LLMResponse(
        validationSuccess: true,
        storySegment:
            'Oh no! The magic hourglass has run out of sand! But wait - you were SO brave and SO clever! The adventure will remember you!',
        nextChallenge: 'Time ran out! But you were amazing! Want to try again?',
      );
    }
    return const LLMResponse(
      validationSuccess: true,
      storySegment:
          'Åh nej! Det magiske timeglas er løbet tørt for sand! Men vent - du var SÅ modig og SÅ klog! Eventyret vil huske dig!',
      nextChallenge: 'Tiden løb ud! Men du var fantastisk! Vil du prøve igen?',
    );
  }

  String get fullNarration {
    if (encouragement != null && encouragement!.isNotEmpty) {
      return '$storySegment $encouragement $nextChallenge';
    }
    return '$storySegment $nextChallenge';
  }
}
