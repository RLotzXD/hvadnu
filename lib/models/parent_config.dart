import '../config/story_themes.dart';
import '../config/environment_config.dart';
import '../config/narrator_profiles.dart';

class Participant {
  final String id;
  final String name;

  const Participant({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class ParentConfig {
  final StoryTheme theme;
  final Environment environment;
  final int maxSteps;
  final Duration maxDuration;
  final NarratorProfile narrator;
  final List<Participant> participants;
  final String language; // 'da' or 'en'
  final DateTime createdAt;

  const ParentConfig({
    required this.theme,
    required this.environment,
    required this.maxSteps,
    required this.maxDuration,
    required this.narrator,
    required this.participants,
    required this.language,
    required this.createdAt,
  });

  String get elevenLabsVoiceId => narrator.elevenLabsVoiceId;

  String get participantNames {
    if (participants.isEmpty) return language == 'en' ? 'the child' : 'barnet';
    return participants.map((p) => p.name).join(language == 'en' ? ' and ' : ' og ');
  }

  bool get isDanish => language == 'da';
  bool get isEnglish => language == 'en';

  ParentConfig copyWith({
    StoryTheme? theme,
    Environment? environment,
    int? maxSteps,
    Duration? maxDuration,
    NarratorProfile? narrator,
    List<Participant>? participants,
    String? language,
    DateTime? createdAt,
  }) {
    return ParentConfig(
      theme: theme ?? this.theme,
      environment: environment ?? this.environment,
      maxSteps: maxSteps ?? this.maxSteps,
      maxDuration: maxDuration ?? this.maxDuration,
      narrator: narrator ?? this.narrator,
      participants: participants ?? this.participants,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'environment': environment.name,
        'maxSteps': maxSteps,
        'maxDurationSeconds': maxDuration.inSeconds,
        'narrator': narrator.name,
        'participants': participants.map((p) => p.toJson()).toList(),
        'language': language,
        'elevenLabsVoiceId': elevenLabsVoiceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ParentConfig.fromJson(Map<String, dynamic> json) {
    return ParentConfig(
      theme: StoryTheme.values.firstWhere((e) => e.name == json['theme']),
      environment:
          Environment.values.firstWhere((e) => e.name == json['environment']),
      maxSteps: json['maxSteps'] as int,
      maxDuration: Duration(seconds: json['maxDurationSeconds'] as int),
      narrator: NarratorProfile.values
          .firstWhere((e) => e.name == json['narrator']),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      language: json['language'] as String? ?? 'da',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory ParentConfig.defaultConfig() {
    return ParentConfig(
      theme: StoryTheme.dragejagt,
      environment: Environment.house,
      maxSteps: 5,
      maxDuration: const Duration(minutes: 10),
      narrator: NarratorProfile.wiseWizard,
      participants: [],
      language: 'da',
      createdAt: DateTime.now(),
    );
  }
}
