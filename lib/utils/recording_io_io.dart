import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'exceptions.dart';

/// Path in the temp directory for a new recording.
///
/// The extension is `.m4a` because `AudioEncoder.aacLc` produces an MP4/AAC
/// container — naming it `.mp3` would make us report the wrong MIME type
/// to Gemini.
Future<String> createRecordingPath() async {
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().millisecondsSinceEpoch;
  return '${dir.path}/hvadnu_audio_$stamp.m4a';
}

Future<Uint8List> readRecordingBytes(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw const MicrophoneException(
      message: 'Recording file not found at the expected path',
      userFriendlyMessage: 'Kunne ikke finde optagelsen. Prøv igen.',
      userFriendlyMessageEn: "Couldn't find the recording. Try again.",
    );
  }
  return file.readAsBytes();
}

Future<void> deleteRecording(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  } catch (_) {
    // A leftover temp file is harmless; never fail a turn over cleanup.
  }
}
