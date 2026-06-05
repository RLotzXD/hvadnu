import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PermissionRequestWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onRequestPermission;
  final bool isGranted;

  const PermissionRequestWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onRequestPermission,
    this.isGranted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppTheme.success.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppTheme.success.withOpacity(0.2)
                  : AppTheme.accentGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? AppTheme.success : AppTheme.accentGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            ElevatedButton(
              onPressed: onRequestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Tillad'),
            ),
        ],
      ),
    );
  }
}
