import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'exceptions.dart';

class ErrorHandler {
  static void showErrorSnackbar(BuildContext context, Object error) {
    String message;

    if (error is AppException) {
      message = error.userFriendlyMessage ?? error.message;
    } else {
      message = 'Noget gik galt. Prøv igen.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<T?> tryAsync<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? errorMessage,
  }) async {
    try {
      return await action();
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, e);
      }
      return null;
    }
  }
}
