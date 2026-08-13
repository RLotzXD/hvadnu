import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../config/environment_config.dart';
import '../config/narrator_profiles.dart';
import '../config/story_themes.dart';
import '../providers/providers.dart';
import '../services/haptic_service.dart';
import 'adventure_start_screen.dart';

class ParentSetupScreen extends ConsumerStatefulWidget {
  const ParentSetupScreen({super.key});

  @override
  ConsumerState<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends ConsumerState<ParentSetupScreen> {
  final _participantController = TextEditingController();

  @override
  void dispose() {
    _participantController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isEmpty) return;

    HapticService.lightTap();
    ref.read(parentConfigProvider.notifier).addParticipant(name);
    _participantController.clear();
  }

  /// Every setup choice gives the same selection tick, so a parent tapping
  /// through the form gets consistent feedback.
  void _select(VoidCallback apply) {
    HapticService.selectionChanged();
    apply();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(parentConfigProvider);
    final stepOptions = ref.watch(stepOptionsProvider);
    final durationOptions = ref.watch(durationOptionsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.getThemeGradient(config.theme.name),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildParticipantsSection(context, config),
                const SizedBox(height: 24),
                _buildThemeSelector(context, ref, config),
                const SizedBox(height: 24),
                _buildEnvironmentSelector(context, ref, config),
                const SizedBox(height: 24),
                _buildNarratorSelector(context, ref, config),
                const SizedBox(height: 24),
                _buildStepSelector(context, ref, config, stepOptions),
                const SizedBox(height: 24),
                _buildDurationSelector(context, ref, config, durationOptions),
                const SizedBox(height: 48),
                _buildStartButton(context, ref),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final config = ref.watch(parentConfigProvider);
    final isEnglish = config.language == 'en';

    return Center(
      child: Column(
        children: [
          // Language toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLanguageButton('DA', 'da', config.language),
              const SizedBox(width: 16),
              _buildLanguageButton('EN', 'en', config.language),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish ? 'What Now?!' : 'Hvad Nu?!',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.accentColor,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish ? 'Set up the adventure' : 'Opsæt eventyret',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String label, String langCode, String currentLang) {
    final isSelected = currentLang == langCode;
    return GestureDetector(
      onTap: () => _select(
          () => ref.read(parentConfigProvider.notifier).setLanguage(langCode)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : AppTheme.textMuted,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildParticipantsSection(BuildContext context, dynamic config) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Who is playing?' : 'Hvem skal spille?'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _participantController,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: isEnglish ? 'Enter name...' : 'Skriv navn...',
                ),
                onSubmitted: (_) => _addParticipant(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _addParticipant,
              icon: const Icon(Icons.add_circle, size: 32),
              color: AppTheme.accentColor,
            ),
          ],
        ),
        if (config.participants.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: config.participants.map<Widget>((participant) {
              return Chip(
                label: Text(
                  participant.name,
                  style: const TextStyle(color: AppTheme.primaryDark),
                ),
                backgroundColor: AppTheme.accentColor,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.primaryDark,
                ),
                onDeleted: () => _select(() => ref
                    .read(parentConfigProvider.notifier)
                    .removeParticipant(participant.id)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
  ) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Choose the adventure' : 'Vælg eventyret'),
        SizedBox(
          // 120 clipped the label by 10px once a theme name wrapped to two
          // lines ("Pirateventyret"), which Flutter reports as an overflow.
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: StoryTheme.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final theme = StoryTheme.values[index];
              final isSelected = config.theme == theme;
              return GestureDetector(
                onTap: () => _select(() =>
                    ref.read(parentConfigProvider.notifier).setTheme(theme)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        theme.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          theme.getDisplayName(config.language),
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textLight
                                : AppTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
  ) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Where are you?' : 'Hvor er I?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Environment.values.map((env) {
            final isSelected = config.environment == env;
            return GestureDetector(
              onTap: () => _select(() =>
                  ref.read(parentConfigProvider.notifier).setEnvironment(env)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentColor.withOpacity(0.2)
                      : AppTheme.secondaryDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(env.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      env.getDisplayName(config.language),
                      style: TextStyle(
                        color:
                            isSelected ? AppTheme.textLight : AppTheme.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNarratorSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
  ) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Choose narrator' : 'Vælg fortæller'),
        ...NarratorProfile.values.map((narrator) {
          final isSelected = config.narrator == narrator;
          return GestureDetector(
            onTap: () => _select(() =>
                ref.read(parentConfigProvider.notifier).setNarrator(narrator)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentColor.withOpacity(0.15)
                    : AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(narrator.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          narrator.getDisplayName(config.language),
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textLight
                                : AppTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          narrator.description,
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.accentColor,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
    List<int> options,
  ) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Number of challenges' : 'Antal udfordringer'),
        Row(
          children: options.map((steps) {
            final isSelected = config.maxSteps == steps;
            return Expanded(
              child: GestureDetector(
                onTap: () => _select(() =>
                    ref.read(parentConfigProvider.notifier).setMaxSteps(steps)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$steps',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.textLight
                              : AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        isEnglish ? 'steps' : 'skridt',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
    List<Duration> options,
  ) {
    final isEnglish = config.language == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, isEnglish ? 'Maximum time' : 'Maksimal tid'),
        Row(
          children: options.map((duration) {
            final isSelected = config.maxDuration == duration;
            final minutes = duration.inMinutes;
            return Expanded(
              child: GestureDetector(
                onTap: () => _select(() => ref
                    .read(parentConfigProvider.notifier)
                    .setMaxDuration(duration)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$minutes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.textLight
                              : AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        'min',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    final config = ref.watch(parentConfigProvider);
    final isEnglish = config.language == 'en';
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const AdventureStartScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: AppTheme.primaryDark,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, size: 32),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Start Adventure' : 'Start Eventyr',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
