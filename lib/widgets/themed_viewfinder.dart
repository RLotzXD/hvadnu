import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../config/story_themes.dart';
import '../config/app_theme.dart';

class ThemedViewfinder extends StatelessWidget {
  final StoryTheme theme;
  final CameraController? cameraController;
  final bool isActive;

  const ThemedViewfinder({
    super.key,
    required this.theme,
    required this.cameraController,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getThemeAccentColor(theme.name).withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getThemeAccentColor(theme.name).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraPreview(),
            _buildThemeOverlay(),
            if (isActive) _buildCornerDecorations(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container(
        color: AppTheme.primaryDark,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                color: AppTheme.textMuted,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Kamera starter...',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(cameraController!);
  }

  Widget _buildThemeOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              AppTheme.primaryDark.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerDecorations() {
    final accentColor = AppTheme.getThemeAccentColor(theme.name);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: _buildCorner(accentColor, 0),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildCorner(accentColor, 90),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildCorner(accentColor, 180),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildCorner(accentColor, 270),
          ),
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                theme.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color, double rotation) {
    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(
          painter: _CornerPainter(color: color),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
