import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/themed_viewfinder.dart';
import '../widgets/action_button.dart';
import '../widgets/processing_overlay.dart';
import 'victory_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionProvider);
    final session = gameState.session;
    final cameraService = ref.watch(cameraServiceProvider);

    ref.listen<GameState>(gameSessionProvider, (previous, next) {
      if ((next.phase == GamePhase.victory || next.phase == GamePhase.timeExpired) && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const VictoryScreen(),
          ),
        );
      }
    });

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    final theme = session.config.theme;
    final gradient = AppTheme.getThemeGradient(theme.name);

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
          child: Stack(
            children: [
              Column(
                children: [
                  _buildProgressBar(session),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ThemedViewfinder(
                        theme: theme,
                        cameraController: cameraService.controller,
                        isActive: gameState.phase == GamePhase.listening ||
                            gameState.phase == GamePhase.recording,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ActionButton(
                      phase: gameState.phase,
                      onTap: _handleTap,
                      onLongPressStart: _handleLongPressStart,
                      onLongPressEnd: _handleLongPressEnd,
                      themeColor: AppTheme.getThemeAccentColor(theme.name),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
              if (gameState.phase == GamePhase.processing ||
                  gameState.phase == GamePhase.narrating)
                ProcessingOverlay(
                  phase: gameState.phase,
                  themeColor: AppTheme.getThemeAccentColor(theme.name),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: _showExitDialog,
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textMuted,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(dynamic session) {
    final progress = session.progress as double;
    final current = session.storyState.currentStep as int;
    final max = session.config.maxSteps as int;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(max, (index) {
              final isCompleted = index < current;
              final isCurrent = index == current;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.accentGold
                        : isCurrent
                            ? AppTheme.accentGold.withOpacity(0.5)
                            : AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _handleTap() {
    final phase = ref.read(gameSessionProvider).phase;
    if (phase == GamePhase.listening) {
      ref.read(gameSessionProvider.notifier).capturePhoto();
    }
  }

  void _handleLongPressStart() {
    final phase = ref.read(gameSessionProvider).phase;
    if (phase == GamePhase.listening) {
      HapticFeedback.mediumImpact();
      ref.read(gameSessionProvider.notifier).startRecording();
    }
  }

  void _handleLongPressEnd() {
    final phase = ref.read(gameSessionProvider).phase;
    if (phase == GamePhase.recording) {
      HapticFeedback.lightImpact();
      ref.read(gameSessionProvider.notifier).stopRecording();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text(
          'Afslut eventyr?',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: const Text(
          'Er du sikker på, at du vil stoppe eventyret?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fortsæt',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameSessionProvider.notifier).endGame();
            },
            child: const Text(
              'Afslut',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
