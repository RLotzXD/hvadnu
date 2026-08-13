import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/utils/error_handler.dart';
import 'package:hvad_nu/utils/exceptions.dart';

void main() {
  group('describe', () {
    test('prefers the Danish child-facing message', () {
      const error = CameraException(message: 'takePicture threw SIGSEGV');

      final message = ErrorHandler.describe(error);

      expect(message, 'Kunne ikke starte kameraet.');
      expect(message, isNot(contains('SIGSEGV')));
    });

    test('uses the English message for English sessions', () {
      const error = MicrophoneException(message: 'denied');

      expect(
        ErrorHandler.describe(error, language: 'en'),
        "Couldn't start the microphone.",
      );
    });

    test('falls back to Danish when no English text exists', () {
      const error = AppException(
        message: 'internal',
        userFriendlyMessage: 'Kun dansk her.',
      );

      expect(ErrorHandler.describe(error, language: 'en'), 'Kun dansk her.');
    });

    test('never leaks the detail of an unknown error', () {
      final message = ErrorHandler.describe(
        StateError('database handle 0x7ffe corrupted'),
      );

      expect(message, 'Noget gik galt. Prøv igen.');
      expect(message, isNot(contains('0x7ffe')));
    });

    test('passes through an already-localised string', () {
      expect(ErrorHandler.describe('Kameraet er ikke klar endnu.'),
          'Kameraet er ikke klar endnu.');
    });
  });

  group('toAppException', () {
    DioException dioError(DioExceptionType type, {int? statusCode}) {
      return DioException(
        requestOptions: RequestOptions(path: '/'),
        type: type,
        response: statusCode == null
            ? null
            : Response(
                requestOptions: RequestOptions(path: '/'),
                statusCode: statusCode,
              ),
      );
    }

    test('timeouts read as a connection problem, not a generic failure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final result = ErrorHandler.toAppException(dioError(type));
        expect(result, isA<NetworkException>(), reason: '$type');
        expect(result.localizedMessage('da'), contains('internetforbindelse'));
      }
    });

    test('HTTP errors keep their status code for the logs', () {
      final result = ErrorHandler.toAppException(
        dioError(DioExceptionType.badResponse, statusCode: 429),
      );

      expect(result, isA<ApiException>());
      expect((result as ApiException).statusCode, 429);
      expect(result.message, contains('429'));
    });

    test('the context label reaches the log message but not the child', () {
      final result = ErrorHandler.toAppException(
        dioError(DioExceptionType.badResponse, statusCode: 500),
        context: 'text-to-speech',
      );

      expect(result.message, contains('text-to-speech'));
      expect(result.localizedMessage('da'), isNot(contains('text-to-speech')));
    });
  });
}
