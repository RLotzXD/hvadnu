class AppException implements Exception {
  final String message;
  final String? userFriendlyMessage;
  final Object? originalError;

  const AppException({
    required this.message,
    this.userFriendlyMessage,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.userFriendlyMessage = 'Ingen internetforbindelse. Prøv igen.',
    super.originalError,
  });
}

class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required super.message,
    this.statusCode,
    super.userFriendlyMessage = 'Noget gik galt. Prøv igen.',
    super.originalError,
  });
}

class CameraException extends AppException {
  const CameraException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke starte kameraet.',
    super.originalError,
  });
}

class MicrophoneException extends AppException {
  const MicrophoneException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke starte mikrofonen.',
    super.originalError,
  });
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.userFriendlyMessage = 'Kunne ikke gemme data.',
    super.originalError,
  });
}
