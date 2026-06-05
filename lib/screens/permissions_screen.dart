import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_theme.dart';
import '../widgets/permission_request_widget.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onAllGranted;

  const PermissionsScreen({
    super.key,
    required this.onAllGranted,
  });

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _microphoneGranted = micStatus.isGranted;
    });

    if (_cameraGranted && _microphoneGranted) {
      widget.onAllGranted();
    }
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
    _checkAllGranted();
  }

  Future<void> _requestMicrophone() async {
    final status = await Permission.microphone.request();
    setState(() => _microphoneGranted = status.isGranted);
    _checkAllGranted();
  }

  void _checkAllGranted() {
    if (_cameraGranted && _microphoneGranted) {
      widget.onAllGranted();
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
            child: Column(
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
                    child: const Icon(
                      Icons.security,
                      color: AppTheme.accentGold,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Tilladelser',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Vi har brug for disse tilladelser for at skabe magien',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                PermissionRequestWidget(
                  title: 'Kamera',
                  description: 'For at se hvad du finder på dit eventyr',
                  icon: Icons.camera_alt,
                  isGranted: _cameraGranted,
                  onRequestPermission: _requestCamera,
                ),
                PermissionRequestWidget(
                  title: 'Mikrofon',
                  description: 'For at høre hvad du siger til fortælleren',
                  icon: Icons.mic,
                  isGranted: _microphoneGranted,
                  onRequestPermission: _requestMicrophone,
                ),
                const Spacer(),
                if (_cameraGranted && _microphoneGranted)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onAllGranted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: AppTheme.primaryDark,
                      ),
                      child: const Text(
                        'Fortsæt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
