import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';
import '../providers/game_session_provider.dart';

class ProcessingOverlay extends StatelessWidget {
  final GamePhase phase;
  final Color themeColor;

  const ProcessingOverlay({
    super.key,
    required this.phase,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedIcon(),
            const SizedBox(height: 32),
            _buildStatusText(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildAnimatedIcon() {
    final isNarrating = phase == GamePhase.narrating;

    if (isNarrating) {
      return _buildSpeakingIndicator();
    }

    return Shimmer.fromColors(
      baseColor: themeColor,
      highlightColor: themeColor.withOpacity(0.5),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: themeColor, width: 4),
        ),
        child: Icon(
          Icons.auto_awesome,
          color: themeColor,
          size: 48,
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .rotate(
          duration: const Duration(seconds: 3),
        );
  }

  Widget _buildSpeakingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 12,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(6),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              delay: Duration(milliseconds: index * 100),
            )
            .scaleY(
              duration: const Duration(milliseconds: 400),
              begin: 0.3,
              end: 1.0,
              curve: Curves.easeInOut,
            );
      }),
    );
  }

  Widget _buildStatusText() {
    final text = phase == GamePhase.processing
        ? 'Fortælleren tænker...'
        : 'Fortælleren taler...';

    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textLight,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .fadeIn(duration: const Duration(milliseconds: 500))
        .then()
        .fadeOut(
          delay: const Duration(milliseconds: 1500),
          duration: const Duration(milliseconds: 500),
        );
  }
}
