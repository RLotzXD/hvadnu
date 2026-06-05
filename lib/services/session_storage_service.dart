import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class SessionStorageService {
  static const String _boxName = 'hvadnu_sessions';
  static const String _activeSessionKey = 'active_session';
  static const String _configKey = 'last_config';

  late Box<String> _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _isInitialized = true;
  }

  Future<void> saveActiveSession(GameSession session) async {
    if (!_isInitialized) return;
    await _box.put(_activeSessionKey, jsonEncode(session.toJson()));
  }

  Future<GameSession?> loadActiveSession() async {
    if (!_isInitialized) return null;

    final jsonStr = _box.get(_activeSessionKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GameSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    if (!_isInitialized) return;
    await _box.delete(_activeSessionKey);
  }

  Future<void> saveLastConfig(ParentConfig config) async {
    if (!_isInitialized) return;
    await _box.put(_configKey, jsonEncode(config.toJson()));
  }

  Future<ParentConfig?> loadLastConfig() async {
    if (!_isInitialized) return null;

    final jsonStr = _box.get(_configKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ParentConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
    }
  }
}
