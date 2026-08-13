import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'exceptions.dart';

/// Single funnel for turning any thrown object into something safe to show,
/// and for logging the technical detail that we deliberately don't show.
class ErrorHandler {
  /// Child-safe message for [error] in [language] ('da' or 'en').
  ///
  /// Context-free on purpose: the game notifier needs this without a
  /// `BuildContext`.
  static String describe(Object error, {String language = 'da'}) {
    // Callers sometimes hold an already-localised message rather than the
    // original throwable (e.g. GameState.errorMessage).
    if (error is String) return error;

    if (error is AppException) return error.localizedMessage(language);

    if (error is DioException) {
      return toAppException(error).localizedMessage(language);
    }

    return language == 'en'
        ? 'Something went wrong. Try again.'
        : 'Noget gik galt. Prøv igen.';
  }

  /// Normalises a [DioException] into the app's own exception types so that
  /// timeouts read as connection problems rather than generic failures.
  static AppException toAppException(DioException error, {String? context}) {
    final where = context == null ? '' : ' ($context)';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Network failure$where: ${error.type.name}',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return ApiException(
          message: 'HTTP $status$where: ${error.response?.statusMessage}',
          statusCode: status,
          originalError: error,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(
          message: 'Request failed$where: ${error.message}',
          originalError: error,
        );
    }
  }

  /// Logs the full technical detail. Never called with anything child-facing.
  static void log(String where, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$where] $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }

  static void showErrorSnackbar(
    BuildContext context,
    Object error, {
    String language = 'da',
  }) {
    _show(
      context,
      message: describe(error, language: language),
      icon: Icons.error_outline,
      background: AppTheme.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      background: AppTheme.success,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color background,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
  }

  static Future<T?> tryAsync<T>(
    BuildContext context,
    Future<T> Function() action, {
    String where = 'tryAsync',
    String language = 'da',
  }) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      log(where, e, stackTrace);
      if (context.mounted) {
        showErrorSnackbar(context, e, language: language);
      }
      return null;
    }
  }
}
