import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../models/player_action.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('No cameras found');
        _isInitialized = true; // Mark as initialized anyway for web fallback
        return;
      }

      final rearCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!kIsWeb) {
        await _controller!.setFlashMode(FlashMode.off);
      }

      _isInitialized = true;
    } catch (e) {
      print('Camera initialization error: $e');
      _isInitialized = true; // Allow game to continue without camera
    }
  }

  Future<PlayerAction> capturePhoto() async {
    if (_controller == null || !(_controller!.value.isInitialized)) {
      throw Exception('Kamera er ikke klar endnu');
    }

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      final compressedBytes = await _compressImage(bytes);
      final base64Image = base64Encode(compressedBytes);

      if (base64Image.isEmpty) {
        throw Exception('Kunne ikke læse billeddata');
      }

      return PlayerAction.photo(base64Image);
    } catch (e) {
      print('Photo capture error: $e');
      throw Exception('Kunne ikke tage billede: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final resized = img.copyResize(
      image,
      width: 800,
      height: (800 * image.height / image.width).round(),
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
