import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  final VoidCallback onReady;
  final VoidCallback onError;

  const LoadingScreen({
    super.key,
    required this.onReady,
    required this.onError,
  });

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  String _statusMessage = 'Forbereder magi...';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _setStatus('Tjekker konfiguration...', 0.25);
      await Future.delayed(const Duration(milliseconds: 300));

      if (!ApiConfig.isConfigured) {
        throw const AppException(
          message: 'GEMINI_API_KEY or ELEVENLABS_API_KEY missing',
          userFriendlyMessage:
              'API-nøglerne mangler. Tjek .env filen (eller servermiljøet på web).',
          userFriendlyMessageEn:
              'API keys are missing. Check the .env file (or the server env on web).',
        );
      }

      _setStatus('Indlæser gemte eventyr...', 0.5);
      final storage = ref.read(sessionStorageProvider);
      await storage.initialize();

      _setStatus('Finder dine indstillinger...', 0.75);
      final lastConfig = await storage.loadLastConfig();
      if (lastConfig != null) {
        ref.read(parentConfigProvider.notifier).loadConfig(lastConfig);
      }

      // Camera and microphone are deliberately NOT initialised here — doing so
      // fires the OS permission prompts before PermissionsScreen has explained
      // why we need them. AdventureStartScreen initialises them instead.

      _setStatus('Klar til eventyr!', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      widget.onReady();
    } catch (e, stackTrace) {
      ErrorHandler.log('LoadingScreen.initialize', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = ErrorHandler.describe(e);
        _statusMessage = 'Noget gik galt...';
      });
      widget.onError();
    }
  }

  void _setStatus(String message, double progress) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondaryDark,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 48),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  _buildStatusText(),
                  if (_hasError) ...[
                    const SizedBox(height: 32),
                    _buildErrorDetails(),
                    const SizedBox(height: 24),
                    _buildRetryButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_hasError) {
      return const Icon(
        Icons.error_outline,
        color: AppTheme.error,
        size: 80,
      ).animate().shake();
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentGold,
          width: 3,
        ),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: AppTheme.accentGold,
        size: 48,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .rotate(duration: const Duration(seconds: 3));
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.secondaryDark,
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasError ? AppTheme.error : AppTheme.accentGold,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progress * 100).toInt()}%',
          style: TextStyle(
            color: _hasError ? AppTheme.error : AppTheme.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    return Text(
      _statusMessage,
      style: TextStyle(
        color: _hasError ? AppTheme.error : AppTheme.textLight,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn();
  }

  Widget _buildErrorDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Fejl:',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Ukendt fejl',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // Drop any cached credentials, otherwise a first-run miss is
        // permanent for the process and retrying can never succeed.
        ApiConfig.resetCache();
        setState(() {
          _hasError = false;
          _errorMessage = null;
          _progress = 0;
          _statusMessage = 'Prøver igen...';
        });
        _initializeApp();
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Prøv igen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }
}
