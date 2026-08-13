import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart' hide CameraException;
import 'package:camera/camera.dart' as cam show CameraException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

import '../models/player_action.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// True once initialisation has run and produced a usable preview.
  /// False on web and on devices with no camera — callers should fall back to
  /// voice input rather than treating this as an error.
  bool get hasCamera => _controller?.value.isInitialized ?? false;

  /// Never throws. A missing camera is a degraded mode, not a failure: the
  /// child can still play with voice, so the game must be allowed to start.
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        ErrorHandler.log('CameraService', 'No cameras available on this device');
        _isInitialized = true;
        return;
      }

      final rearCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // `medium` is ~720x480, which _compressImage was then upscaling to
      // 800px wide — more bytes, no more detail, and less for Gemini to
      // recognise in the photo. Capture above the target and downscale.
      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!kIsWeb) {
        await controller.setFlashMode(FlashMode.off);
      }

      _controller = controller;
      _isInitialized = true;
    } on cam.CameraException catch (e, stackTrace) {
      ErrorHandler.log('CameraService.initialize', e, stackTrace);
      _isInitialized = true;
    } catch (e, stackTrace) {
      ErrorHandler.log('CameraService.initialize', e, stackTrace);
      _isInitialized = true;
    }
  }

  /// Throws [CameraException] when there is no usable camera or the shot
  /// fails, so the caller can put the child back into the listening phase.
  Future<PlayerAction> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraException(
        message: 'capturePhoto called before the controller was ready',
        userFriendlyMessage: 'Kameraet er ikke klar endnu.',
        userFriendlyMessageEn: 'The camera is not ready yet.',
      );
    }

    try {
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();
      final base64Image = base64Encode(await _compressImage(bytes));

      if (base64Image.isEmpty) {
        throw const CameraException(
          message: 'Encoded image was empty after compression',
          userFriendlyMessage: 'Billedet blev tomt. Prøv igen.',
          userFriendlyMessageEn: 'The photo came out empty. Try again.',
        );
      }

      return PlayerAction.photo(base64Image);
    } on CameraException {
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.log('CameraService.capturePhoto', e, stackTrace);
      throw CameraException(
        message: 'takePicture failed: $e',
        userFriendlyMessage: 'Kunne ikke tage billedet. Prøv igen.',
        userFriendlyMessageEn: "Couldn't take the photo. Try again.",
        originalError: e,
      );
    }
  }

  /// Longest edge Gemini gets. Big enough to recognise household objects,
  /// small enough that upload latency stays tolerable on mobile data.
  static const int _maxEdge = 1024;

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Only ever shrink. Upscaling a small capture adds bytes and blur without
    // adding anything the model can actually recognise.
    final longestEdge = image.width > image.height ? image.width : image.height;
    final resized = longestEdge <= _maxEdge
        ? image
        : img.copyResize(
            image,
            width: image.width >= image.height ? _maxEdge : null,
            height: image.height > image.width ? _maxEdge : null,
            interpolation: img.Interpolation.average,
          );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
