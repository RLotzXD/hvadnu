import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import 'parent_setup_screen.dart';

class VictoryScreen extends ConsumerWidget {
  const VictoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameSessionProvider);
    final session = gameState.session;
    final isTimeExpired = gameState.phase == GamePhase.timeExpired;

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = session.config.theme;
    final gradient = AppTheme.getThemeGradient(theme.name);
    final stepsCompleted = session.storyState.currentStep;
    final isEnglish = session.config.language == 'en';

    final badgeInfo = _getBadgeInfo(theme.name, isEnglish, isTimeExpired);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big badge reveal
                  _buildBadgeReveal(badgeInfo, isTimeExpired),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    badgeInfo['subtitle']!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textMuted,
                          letterSpacing: 3,
                        ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 800),
                        duration: const Duration(milliseconds: 500),
                      ),
                  const SizedBox(height: 8),
                  Text(
                    badgeInfo['title']!,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: isTimeExpired ? AppTheme.textLight : AppTheme.accentGold,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 1000),
                        duration: const Duration(milliseconds: 500),
                      )
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                      ),
                  const SizedBox(height: 40),
                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isTimeExpired
                              ? (isEnglish ? 'So close!' : 'Så tæt på!')
                              : (isEnglish ? 'Adventure completed!' : 'Eventyr gennemført!'),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard(
                              context,
                              icon: Icons.flag,
                              value: '$stepsCompleted',
                              label: isEnglish ? 'Challenges' : 'Udfordringer',
                            ),
                            const SizedBox(width: 24),
                            _buildStatCard(
                              context,
                              icon: Icons.timer,
                              value:
                                  '${session.storyState.elapsed.inMinutes} min',
                              label: isEnglish ? 'Play time' : 'Spilletid',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 1300),
                        duration: const Duration(milliseconds: 500),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),
                  // Retry/New adventure button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(gameSessionProvider.notifier).resetGame();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ParentSetupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTimeExpired ? AppTheme.accentColor : AppTheme.accentGold,
                        foregroundColor: AppTheme.primaryDark,
                      ),
                      child: Text(
                        isTimeExpired
                            ? (isEnglish ? 'Try Again!' : 'Prøv igen!')
                            : (isEnglish ? 'New Adventure' : 'Nyt eventyr'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 1600),
                        duration: const Duration(milliseconds: 500),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeReveal(Map<String, String> badgeInfo, bool isTimeExpired) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect behind badge
        if (!isTimeExpired)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.5),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 800))
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 1000),
              ),
        // Badge circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTimeExpired
                ? AppTheme.secondaryDark
                : AppTheme.accentGold.withOpacity(0.2),
            border: Border.all(
              color: isTimeExpired ? AppTheme.textMuted : AppTheme.accentGold,
              width: 4,
            ),
          ),
          child: Center(
            child: Text(
              badgeInfo['badge']!,
              style: const TextStyle(fontSize: 80),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
            ),
        // Sparkles for victory
        if (!isTimeExpired) ...[
          Positioned(
            top: 0,
            right: 20,
            child: const Text('✨', style: TextStyle(fontSize: 32))
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .fadeIn(delay: const Duration(milliseconds: 600))
                .then()
                .shimmer(duration: const Duration(milliseconds: 1500)),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: const Text('⭐', style: TextStyle(fontSize: 28))
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .fadeIn(delay: const Duration(milliseconds: 800))
                .then()
                .shimmer(duration: const Duration(milliseconds: 1200)),
          ),
          Positioned(
            top: 30,
            left: 0,
            child: const Text('🌟', style: TextStyle(fontSize: 24))
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .fadeIn(delay: const Duration(milliseconds: 700))
                .then()
                .shimmer(duration: const Duration(milliseconds: 1800)),
          ),
        ],
      ],
    );
  }

  Map<String, String> _getBadgeInfo(String themeName, bool isEnglish, bool isTimeExpired) {
    if (isTimeExpired) {
      return {
        'badge': '⏰',
        'title': isEnglish ? 'BRAVE ADVENTURER' : 'MODIG EVENTURER',
        'subtitle': isEnglish ? 'TIME RAN OUT' : 'TIDEN L\u00D8B UD',
      };
    }

    switch (themeName) {
      case 'dragejagt':
        return {
          'badge': '🐉',
          'title': isEnglish ? 'DRAGON RIDER!' : 'DRAGERIDDER!',
          'subtitle': isEnglish ? 'YOU ARE A' : 'DU ER EN',
        };
      case 'rumrejsen':
        return {
          'badge': '🚀',
          'title': isEnglish ? 'SPACE HERO!' : 'RUMHELT!',
          'subtitle': isEnglish ? 'YOU ARE A' : 'DU ER EN',
        };
      case 'pirateventyret':
        return {
          'badge': '🏴‍☠️',
          'title': isEnglish ? 'PIRATE CAPTAIN!' : 'PIRATKAPTAJN!',
          'subtitle': isEnglish ? 'YOU ARE A' : 'DU ER EN',
        };
      case 'roadtrip':
        return {
          'badge': '🏆',
          'title': isEnglish ? 'ROAD TRIP CHAMPION!' : 'ROADTRIP-MESTER!',
          'subtitle': isEnglish ? 'YOU ARE A' : 'DU ER EN',
        };
      default:
        return {
          'badge': '🏆',
          'title': isEnglish ? 'HERO!' : 'HELT!',
          'subtitle': isEnglish ? 'YOU ARE A' : 'DU ER EN',
        };
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
              ),
        ),
      ],
    );
  }
}
