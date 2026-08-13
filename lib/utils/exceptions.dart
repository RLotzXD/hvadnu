/// Base class for everything the app throws on purpose.
///
/// [message] is for logs and is never shown to a child. The two
/// `userFriendly*` fields are what a parent or child actually reads, so they
/// stay short, calm and blame-free.
class AppException implements Exception {
  final String message;
  final String? userFriendlyMessage;
  final String? userFriendlyMessageEn;
  final Object? originalError;

  const AppException({
    required this.message,
    this.userFriendlyMessage,
    this.userFriendlyMessageEn,
    this.originalError,
  });

  /// The child-facing message in [language] ('da' or 'en'), falling back to
  /// Danish and finally to the technical message.
  String localizedMessage(String language) {
    if (language == 'en') {
      return userFriendlyMessageEn ?? userFriendlyMessage ?? message;
    }
    return userFriendlyMessage ?? message;
  }

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.userFriendlyMessage = 'Ingen internetforbindelse. Prøv igen.',
    super.userFriendlyMessageEn = 'No internet connection. Try again.',
    super.originalError,
  });
}

class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required super.message,
    this.statusCode,
    super.userFriendlyMessage = 'Noget gik galt. Prøv igen.',
    super.userFriendlyMessageEn = 'Something went wrong. Try again.',
    super.originalError,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class CameraException extends AppException {
  const CameraException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke starte kameraet.',
    super.userFriendlyMessageEn = "Couldn't start the camera.",
    super.originalError,
  });
}

class MicrophoneException extends AppException {
  const MicrophoneException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke starte mikrofonen.',
    super.userFriendlyMessageEn = "Couldn't start the microphone.",
    super.originalError,
  });
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke gemme data.',
    super.userFriendlyMessageEn = "Couldn't save your progress.",
    super.originalError,
  });
}

/// Text-to-speech failed. Narration is best-effort: the game continues in
/// silence rather than stopping, so this is usually logged, not surfaced.
class TtsException extends AppException {
  const TtsException({
    required super.message,
    super.userFriendlyMessage = 'Fortælleren mistede stemmen et øjeblik.',
    super.userFriendlyMessageEn = 'The storyteller lost their voice for a moment.',
    super.originalError,
  });
}
