import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';
import '../utils/error_handler.dart';
import '../widgets/permission_request_widget.dart';

/// Asks for camera and microphone up front, before the parent invests time in
/// setup. Shown on mobile only — see `AppNavigator`.
///
/// Neither permission is mandatory: camera-only and voice-only are both
/// playable, so the parent can always continue.
class PermissionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onAllGranted;
  final VoidCallback onSkipped;

  const PermissionsScreen({
    super.key,
    required this.onAllGranted,
    required this.onSkipped,
  });

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  bool _cameraPermanentlyDenied = false;
  bool _microphonePermanentlyDenied = false;
  bool _checking = true;

  bool get _allGranted => _cameraGranted && _microphoneGranted;
  bool get _anyGranted => _cameraGranted || _microphoneGranted;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final camera = await Permission.camera.status;
      final microphone = await Permission.microphone.status;
      if (!mounted) return;

      setState(() {
        _cameraGranted = camera.isGranted;
        _microphoneGranted = microphone.isGranted;
        _cameraPermanentlyDenied = camera.isPermanentlyDenied;
        _microphonePermanentlyDenied = microphone.isPermanentlyDenied;
        _checking = false;
      });

      // Already set up from a previous run — don't make them tap through.
      if (_allGranted) widget.onAllGranted();
    } catch (e, stackTrace) {
      ErrorHandler.log('PermissionsScreen.check', e, stackTrace);
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  Future<void> _request(Permission permission) async {
    try {
      final status = await permission.request();
      if (!mounted) return;

      setState(() {
        if (permission == Permission.camera) {
          _cameraGranted = status.isGranted;
          _cameraPermanentlyDenied = status.isPermanentlyDenied;
        } else {
          _microphoneGranted = status.isGranted;
          _microphonePermanentlyDenied = status.isPermanentlyDenied;
        }
      });

      if (_allGranted) widget.onAllGranted();
    } catch (e, stackTrace) {
      ErrorHandler.log('PermissionsScreen.request', e, stackTrace);
      if (mounted) ErrorHandler.showErrorSnackbar(context, e);
    }
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
            colors: [AppTheme.secondaryDark, AppTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _checking
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentGold),
                  )
                : _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, color: AppTheme.accentGold, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Tilladelser',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppTheme.textLight),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Vi har brug for disse tilladelser for at skabe magien',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        PermissionRequestWidget(
          title: 'Kamera',
          description: 'For at se hvad du finder på dit eventyr',
          icon: Icons.camera_alt,
          isGranted: _cameraGranted,
          onRequestPermission: () => _cameraPermanentlyDenied
              ? openAppSettings()
              : _request(Permission.camera),
        ),
        PermissionRequestWidget(
          title: 'Mikrofon',
          description: 'For at høre hvad du siger til fortælleren',
          icon: Icons.mic,
          isGranted: _microphoneGranted,
          onRequestPermission: () => _microphonePermanentlyDenied
              ? openAppSettings()
              : _request(Permission.microphone),
        ),
        if (_cameraPermanentlyDenied || _microphonePermanentlyDenied)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Slå tilladelserne til i Indstillinger for at bruge dem.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            ),
          ),
        const Spacer(),
        _buildContinueButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContinueButton() {
    // Voice-only or camera-only are both real ways to play, so the only case
    // worth blocking on is having neither.
    final label = _allGranted
        ? 'Fortsæt'
        : _anyGranted
            ? 'Fortsæt uden alle tilladelser'
            : 'Spring over';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _allGranted ? widget.onAllGranted : widget.onSkipped,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _anyGranted ? AppTheme.accentGold : AppTheme.secondaryDark,
          foregroundColor:
              _anyGranted ? AppTheme.primaryDark : AppTheme.textMuted,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
