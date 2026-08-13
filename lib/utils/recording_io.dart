/// Platform-specific file handling for audio recordings.
///
/// Exists so `STTService` never imports `dart:io` directly — doing so breaks
/// the web build, since `dart:io` is unavailable there.
library;

export 'recording_io_web.dart' if (dart.library.io) 'recording_io_io.dart';
