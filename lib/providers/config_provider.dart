import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/story_themes.dart';
import '../config/environment_config.dart';
import '../config/narrator_profiles.dart';
import '../models/models.dart';

class ParentConfigNotifier extends StateNotifier<ParentConfig> {
  ParentConfigNotifier() : super(ParentConfig.defaultConfig());

  void setTheme(StoryTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void setEnvironment(Environment environment) {
    state = state.copyWith(environment: environment);
  }

  void setMaxSteps(int steps) {
    state = state.copyWith(maxSteps: steps);
  }

  void setMaxDuration(Duration duration) {
    state = state.copyWith(maxDuration: duration);
  }

  void setNarrator(NarratorProfile narrator) {
    state = state.copyWith(narrator: narrator);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void addParticipant(String name) {
    if (name.trim().isEmpty) return;
    final newParticipant = Participant(
      id: const Uuid().v4(),
      name: name.trim(),
    );
    state = state.copyWith(
      participants: [...state.participants, newParticipant],
    );
  }

  void removeParticipant(String id) {
    state = state.copyWith(
      participants: state.participants.where((p) => p.id != id).toList(),
    );
  }

  void updateParticipantName(String id, String newName) {
    if (newName.trim().isEmpty) return;
    state = state.copyWith(
      participants: state.participants.map((p) {
        if (p.id == id) {
          return Participant(id: p.id, name: newName.trim());
        }
        return p;
      }).toList(),
    );
  }

  void loadConfig(ParentConfig config) {
    state = config.copyWith(createdAt: DateTime.now());
  }

  void reset() {
    state = ParentConfig.defaultConfig();
  }

  ParentConfig finalize() {
    state = state.copyWith(createdAt: DateTime.now());
    return state;
  }
}

final parentConfigProvider =
    StateNotifierProvider<ParentConfigNotifier, ParentConfig>((ref) {
  return ParentConfigNotifier();
});

final stepOptionsProvider = Provider<List<int>>((ref) {
  return [3, 5, 8];
});

final durationOptionsProvider = Provider<List<Duration>>((ref) {
  return [
    const Duration(minutes: 5),
    const Duration(minutes: 10),
    const Duration(minutes: 15),
  ];
});
