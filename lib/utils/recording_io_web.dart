import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'exceptions.dart';

/// On web the `record` package ignores the path argument and hands back a
/// `blob:` URL from `stop()`, so there is nothing to pre-allocate.
Future<String> createRecordingPath() async => '';

/// Fetches the bytes behind the `blob:` URL that `record` returned.
Future<Uint8List> readRecordingBytes(String path) async {
  if (path.isEmpty) {
    throw const MicrophoneException(
      message: 'Empty recording URL returned by the recorder',
      userFriendlyMessage: 'Kunne ikke finde optagelsen. Prøv igen.',
      userFriendlyMessageEn: "Couldn't find the recording. Try again.",
    );
  }

  final response = await Dio().get<List<int>>(
    path,
    options: Options(responseType: ResponseType.bytes),
  );
  return Uint8List.fromList(response.data ?? const []);
}

/// Blob URLs are reclaimed when the page unloads; nothing to do per-recording.
Future<void> deleteRecording(String path) async {}
