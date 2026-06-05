import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

final llmServiceProvider = Provider<LLMService>((ref) {
  return LLMService();
});

final ttsServiceProvider = Provider<TTSService>((ref) {
  final service = TTSService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sttServiceProvider = Provider<STTService>((ref) {
  final service = STTService();
  ref.onDispose(() => service.dispose());
  return service;
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sessionStorageProvider = Provider<SessionStorageService>((ref) {
  final service = SessionStorageService();
  ref.onDispose(() => service.close());
  return service;
});
