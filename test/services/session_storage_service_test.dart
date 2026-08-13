import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hvad_nu/config/story_themes.dart';
import 'package:hvad_nu/services/session_storage_service.dart';

import '../helpers/test_data.dart';

void main() {
  late Directory tempDir;
  late SessionStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hvadnu_test');
    storage = SessionStorageService();
    await storage.initialize(path: tempDir.path);
  });

  tearDown(() async {
    await storage.close();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('round-trips an active session', () async {
    final session = testSession(
      config: testConfig(participantNames: ['Emma', 'Noah'], maxSteps: 8),
      currentStep: 2,
    );

    await storage.saveActiveSession(session);
    final loaded = await storage.loadActiveSession();

    expect(loaded, isNotNull);
    expect(loaded!.id, session.id);
    expect(loaded.storyState.currentStep, 2);
    expect(loaded.config.maxSteps, 8);
    expect(loaded.config.participants.map((p) => p.name), ['Emma', 'Noah']);
    expect(loaded.storyState.currentChallenge,
        session.storyState.currentChallenge);
  });

  test('round-trips the last config', () async {
    final config = testConfig(
      language: 'en',
      theme: StoryTheme.rumrejsen,
      maxDuration: const Duration(minutes: 15),
    );

    await storage.saveLastConfig(config);
    final loaded = await storage.loadLastConfig();

    expect(loaded!.language, 'en');
    expect(loaded.theme, StoryTheme.rumrejsen);
    expect(loaded.maxDuration, const Duration(minutes: 15));
  });

  test('returns null when nothing has been saved', () async {
    expect(await storage.loadActiveSession(), isNull);
    expect(await storage.loadLastConfig(), isNull);
  });

  test('clearActiveSession removes the session but keeps the config', () async {
    await storage.saveActiveSession(testSession());
    await storage.saveLastConfig(testConfig());

    await storage.clearActiveSession();

    expect(await storage.loadActiveSession(), isNull);
    expect(await storage.loadLastConfig(), isNotNull);
  });

  test('discards corrupt data instead of throwing', () async {
    // A malformed record must degrade to "start a fresh adventure", never to
    // a crash on startup.
    final box = Hive.box<String>('hvadnu_sessions');
    await box.put('active_session', 'this is not json');

    expect(await storage.loadActiveSession(), isNull);
  });

  test('discards structurally valid JSON that is not a session', () async {
    final box = Hive.box<String>('hvadnu_sessions');
    await box.put('active_session', '{"unexpected": true}');

    expect(await storage.loadActiveSession(), isNull);
  });

  test('writes are no-ops before initialize', () async {
    final uninitialized = SessionStorageService();

    expect(uninitialized.isInitialized, isFalse);
    await uninitialized.saveActiveSession(testSession());
    expect(await uninitialized.loadActiveSession(), isNull);
  });

  test('initialize is idempotent', () async {
    await storage.initialize(path: tempDir.path);
    expect(storage.isInitialized, isTrue);
  });
}
