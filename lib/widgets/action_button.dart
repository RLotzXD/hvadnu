import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_session_provider.dart';

class ActionButton extends StatefulWidget {
  final GamePhase phase;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final Color themeColor;

  const ActionButton({
    super.key,
    required this.phase,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.themeColor,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isEnabled =>
      widget.phase == GamePhase.listening || widget.phase == GamePhase.recording;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isEnabled ? _handleTap : null,
      onLongPressStart: _isEnabled ? (_) => _handleLongPressStart() : null,
      onLongPressEnd: _isEnabled ? (_) => _handleLongPressEnd() : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseScale =
              widget.phase == GamePhase.listening ? 1.0 + (_pulseController.value * 0.05) : 1.0;

          return Transform.scale(
            scale: _isPressed ? 0.95 : pulseScale,
            child: _buildButton(),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final isRecording = widget.phase == GamePhase.recording;
    final isProcessing =
        widget.phase == GamePhase.processing || widget.phase == GamePhase.narrating;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isRecording
              ? [
                  Colors.red.shade400,
                  Colors.red.shade700,
                ]
              : [
                  widget.themeColor.withOpacity(0.8),
                  widget.themeColor,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isRecording ? Colors.red : widget.themeColor)
                .withOpacity(0.5),
            blurRadius: _isPressed ? 10 : 20,
            spreadRadius: _isPressed ? 0 : 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          if (isProcessing)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else if (isRecording)
            _buildRecordingIndicator()
          else
            _buildCameraIcon(),
        ],
      ),
    );
  }

  Widget _buildCameraIcon() {
    return Icon(
      Icons.camera_alt,
      color: Colors.white.withOpacity(_isEnabled ? 1.0 : 0.5),
      size: 40,
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          duration: const Duration(milliseconds: 500),
          begin: const Offset(1, 1),
          end: const Offset(0.8, 0.8),
        )
        .then()
        .scale(
          duration: const Duration(milliseconds: 500),
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
        );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleLongPressStart() {
    setState(() => _isPressed = true);
    widget.onLongPressStart();
  }

  void _handleLongPressEnd() {
    setState(() => _isPressed = false);
    widget.onLongPressEnd();
  }
}
