import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppTheme.secondaryDark,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildSubtitle(),
              const SizedBox(height: 64),
              _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass emoji as base
          const Text(
            '🧭',
            style: TextStyle(fontSize: 80),
          ),
          // Question mark overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentColor,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildTitle() {
    return const Text(
      'Hvad Nu?!',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentColor,
        letterSpacing: 4,
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 500),
        )
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSubtitle() {
    return const Text(
      'Magiske eventyr venter...',
      style: TextStyle(
        fontSize: 16,
        color: AppTheme.textMuted,
        letterSpacing: 2,
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 600),
          duration: const Duration(milliseconds: 500),
        );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
              delay: Duration(milliseconds: index * 200),
            )
            .scale(
              duration: const Duration(milliseconds: 600),
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
            )
            .then()
            .scale(
              duration: const Duration(milliseconds: 600),
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.5, 0.5),
            );
      }),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 900),
          duration: const Duration(milliseconds: 300),
        );
  }
}
