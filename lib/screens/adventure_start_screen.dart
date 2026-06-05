import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../config/story_themes.dart';
import '../providers/providers.dart';
import 'player_screen.dart';

class AdventureStartScreen extends ConsumerStatefulWidget {
  const AdventureStartScreen({super.key});

  @override
  ConsumerState<AdventureStartScreen> createState() => _AdventureStartScreenState();
}

class _AdventureStartScreenState extends ConsumerState<AdventureStartScreen> {
  bool _isInitializing = true;
  bool _isStartingGame = false;
  String _statusText = 'Forbereder eventyret...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndStart();
  }

  Future<void> _initializeAndStart() async {
    try {
      setState(() {
        _statusText = 'Tænder kameraet...';
      });

      await ref.read(gameSessionProvider.notifier).initializeServices();

      setState(() {
        _isInitializing = false;
        _statusText = 'Klar til at starte eventyret!';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Der opstod en fejl: $e';
        });
      }
    }
  }

  Future<void> _continueToGame() async {
    if (_isStartingGame) return;

    setState(() {
      _isStartingGame = true;
      _errorMessage = null;
      _statusText = 'Starter eventyret...';
    });

    try {
      await ref.read(gameSessionProvider.notifier).startNewGame();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PlayerScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStartingGame = false;
        _errorMessage = 'Der opstod en fejl: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(parentConfigProvider);
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Theme emoji
              Text(
                config.theme.emoji,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                config.theme.displayName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.textLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Participant names
              if (config.participants.isNotEmpty) ...[
                Text(
                  'med ${config.participantNames}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 32),

              // Status
              if (_errorMessage != null) ...[
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tilbage'),
                ),
              ] else if (_isInitializing || _isStartingGame) ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentColor,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Ready to play
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentColor,
                  size: 48,
                ),
                const SizedBox(height: 24),
                Text(
                  'Eventyret venter!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tryk herunder for at begynde',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _continueToGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.primaryDark,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Gå på eventyr!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
