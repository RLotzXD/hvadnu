import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/haptic_service.dart';
import '../utils/error_handler.dart';
import '../widgets/action_button.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/themed_viewfinder.dart';
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
      if (!context.mounted) return;

      final finished = next.phase == GamePhase.victory ||
          next.phase == GamePhase.timeExpired;
      if (finished) {
        if (next.phase == GamePhase.victory) HapticService.victory();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VictoryScreen()),
        );
        return;
      }

      // Errors were previously stored on the state and never shown to anyone.
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        HapticService.error();
        ErrorHandler.showErrorSnackbar(
          context,
          message,
          language: next.session?.config.language ?? 'da',
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
                  _buildTurnBadge(session, gameState.phase),
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

  /// Shows whose turn it is when more than one child is playing. The name
  /// comes from `GameSession.currentPlayer`, the same source `PromptBuilder`
  /// uses, so the badge can't contradict the narrator.
  Widget _buildTurnBadge(GameSession session, GamePhase phase) {
    final player = session.currentPlayer;
    if (!session.isMultiplayer || player == null) {
      return const SizedBox.shrink();
    }

    final isEnglish = session.config.language == 'en';
    final label = isEnglish ? "${player.name}'s turn" : 'Det er ${player.name}s tur';
    final accent = AppTheme.getThemeAccentColor(session.config.theme.name);
    final isActive = phase == GamePhase.listening || phase == GamePhase.recording;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withOpacity(0.6), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(GameSession session) {
    final current = session.storyState.currentStep;
    final max = session.config.maxSteps;

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
    if (ref.read(gameSessionProvider).phase != GamePhase.listening) return;
    HapticService.photoCapture();
    ref.read(gameSessionProvider.notifier).capturePhoto();
  }

  void _handleLongPressStart() {
    if (ref.read(gameSessionProvider).phase != GamePhase.listening) return;
    HapticService.recordingStart();
    ref.read(gameSessionProvider.notifier).startRecording();
  }

  void _handleLongPressEnd() {
    if (ref.read(gameSessionProvider).phase != GamePhase.recording) return;
    HapticService.recordingStop();
    ref.read(gameSessionProvider.notifier).stopRecording();
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
              HapticService.mediumTap();
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
