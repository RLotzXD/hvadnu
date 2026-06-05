import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

class MagicParticles extends StatelessWidget {
  final Color color;
  final int particleCount;

  const MagicParticles({
    super.key,
    this.color = AppTheme.accentGold,
    this.particleCount = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(particleCount, (index) {
            final random = index / particleCount;
            return Positioned(
              left: random * MediaQuery.of(context).size.width,
              top: (random * 0.7 + 0.15) * MediaQuery.of(context).size.height,
              child: _buildParticle(random),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildParticle(double seed) {
    final size = 4.0 + seed * 8;
    final duration = Duration(milliseconds: (2000 + seed * 3000).toInt());

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3 + seed * 0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: size * 2,
            spreadRadius: size / 2,
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
          delay: Duration(milliseconds: (seed * 2000).toInt()),
        )
        .moveY(
          begin: 0,
          end: -50 - seed * 100,
          duration: duration,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: Duration(milliseconds: duration.inMilliseconds ~/ 4))
        .then()
        .fadeOut(
          duration: Duration(milliseconds: duration.inMilliseconds ~/ 4),
        );
  }
}
