import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

class SessionStorageService {
  static const String _boxName = 'hvadnu_sessions';
  static const String _activeSessionKey = 'active_session';
  static const String _configKey = 'last_config';

  Box<String>? _box;

  bool get isInitialized => _box?.isOpen ?? false;

  /// Throws [StorageException] if Hive can't be opened — `LoadingScreen`
  /// surfaces that, since a session that silently fails to save is worse than
  /// a visible error at startup.
  ///
  /// [path] bypasses `initFlutter()` (which needs the path_provider plugin) so
  /// tests can point Hive at a temp directory.
  Future<void> initialize({String? path}) async {
    if (isInitialized) return;

    try {
      if (path == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(path);
      }
      _box = await Hive.openBox<String>(_boxName);
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.initialize', e, stackTrace);
      throw StorageException(
        message: 'Could not open Hive box "$_boxName": $e',
        originalError: e,
      );
    }
  }

  Future<void> saveActiveSession(GameSession session) =>
      _write(_activeSessionKey, session.toJson());

  Future<GameSession?> loadActiveSession() async {
    final json = _read(_activeSessionKey);
    if (json == null) return null;
    try {
      return GameSession.fromJson(json);
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.loadActiveSession', e, stackTrace);
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    if (!isInitialized) return;
    try {
      await _box!.delete(_activeSessionKey);
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.clearActiveSession', e, stackTrace);
    }
  }

  Future<void> saveLastConfig(ParentConfig config) =>
      _write(_configKey, config.toJson());

  Future<ParentConfig?> loadLastConfig() async {
    final json = _read(_configKey);
    if (json == null) return null;
    try {
      return ParentConfig.fromJson(json);
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.loadLastConfig', e, stackTrace);
      return null;
    }
  }

  /// Writes are best-effort: losing a checkpoint should never interrupt play.
  Future<void> _write(String key, Map<String, dynamic> value) async {
    if (!isInitialized) return;
    try {
      await _box!.put(key, jsonEncode(value));
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.write($key)', e, stackTrace);
    }
  }

  /// Corrupt or stale JSON is discarded rather than crashing startup — the
  /// worst case is the child starts a fresh adventure.
  Map<String, dynamic>? _read(String key) {
    if (!isInitialized) return null;

    final raw = _box!.get(key);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.log('SessionStorageService.read($key)', e, stackTrace);
      return null;
    }
  }

  Future<void> close() async {
    if (isInitialized) await _box!.close();
    _box = null;
  }
}
