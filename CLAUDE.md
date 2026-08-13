# Hvad Nu?! — Claude Code Session Guide

Audio-first interactive storytelling app for young children (ages 4–5), in Danish and English.
AI-powered, Flutter-based. Ships to iOS, Android, and web (Vercel).

## Quick Start

```bash
cd /Users/lotzr/Library/CloudStorage/OneDrive-WPPCloud/VML\ MAP/Apps/HvadNu/hvad_nu
flutter pub get
flutter run
```

`.env` needs exactly two keys (see `.env.example`):

```
GEMINI_API_KEY=...      # LLM + vision + speech-to-text
ELEVENLABS_API_KEY=...  # Danish/English TTS
```

There is no OpenAI dependency. Speech-to-text goes through Gemini, not Whisper.

## Architecture

```
lib/
├── config/          # api_config, app_theme, story_themes, environment_config, narrator_profiles
├── models/          # GameSession, StoryState, PlayerAction, LLMResponse, ParentConfig, Participant
├── services/        # LLM (Gemini), TTS (ElevenLabs), STT (Gemini audio), Camera, SessionStorage, Haptic
├── providers/       # Riverpod: config_provider, game_session_provider, service_providers
├── screens/         # Splash → Loading → Permissions → ParentSetup → AdventureStart → Player → Victory
├── widgets/         # ThemedViewfinder, ActionButton, ProcessingOverlay, MagicParticles,
│                    # StoryProgressIndicator, PermissionRequestWidget
└── utils/           # PromptBuilder, ErrorHandler, exceptions
```

Every directory has a barrel export (`models.dart`, `services.dart`, …). Import the barrel.

## Key Concepts

### Game Flow

Navigation is split between two mechanisms — know which one you're in:

- `AppNavigator` in `main.dart` is a `switch` over the `AppScreen` enum and covers
  **splash → loading → permissions → setup**.
- From `ParentSetupScreen` onward it's `Navigator.pushReplacement`:
  **ParentSetup → AdventureStart → Player → Victory → (back to ParentSetup)**.

1. **Parent Setup** (`parent_setup_screen.dart`) — language, participant names, theme,
   environment, narrator, step count, duration.
2. **Adventure Start** (`adventure_start_screen.dart`) — calls `initializeServices()`
   (camera + mic permission), then `startNewGame()`.
3. **Play Loop** (`player_screen.dart`) — tap the action button for a photo, long-press to
   record speech. Gemini continues the story, ElevenLabs narrates, repeat.
4. **Victory** (`victory_screen.dart`) — badge, stats, restart.

### Game Phases

`GamePhase` (in `game_session_provider.dart`) drives the whole UI:
`idle → narrating → listening → recording/processing → narrating → … → victory | timeExpired | error`.

A session ends on whichever comes first: `maxSteps` reached, or `maxDuration` elapsed.
The time limit is polled by a 30-second `Timer.periodic`, so timeout is detected with up to
30s of slack — that is intentional, not a bug.

### Content Dimensions

- **Themes** (`StoryTheme`): `dragejagt`, `rumrejsen`, `pirateventyret`, `roadtrip` — four, not three.
- **Environments** (`Environment`): `house`, `playground`, `beach`, `forest`, `sailboat`, `car`.
- **Narrators** (`NarratorProfile`): `wiseWizard`, `oldSeaCaptain`, `friendlyRobot` — each maps to
  an ElevenLabs voice ID.
- **Languages**: `da` and `en`. Every prompt in `PromptBuilder` exists in both.

### Turn-Taking

With 2+ participants, the active child is `currentStep % participants.length`.
`GameSession.currentPlayer` / `GameSession.nextPlayer` are the single source of truth —
`PromptBuilder` and `PlayerScreen` both read them. Don't recompute the index inline.

### Core Dependencies

| Layer | Library | Purpose |
|-------|---------|---------|
| State | `flutter_riverpod` | DI + reactive state |
| API | `dio` | Gemini + ElevenLabs HTTP |
| Storage | `hive` | Local session persistence |
| Media | `camera`, `just_audio`, `record`, `image` | Photo, playback, recording, compression |
| UX | `google_fonts`, `flutter_animate`, `shimmer` | Typography, animation |
| Test | `mocktail` | Service and notifier mocks |

### Models & Endpoints

| Purpose | Provider | Model / Endpoint |
|---------|----------|------------------|
| Story + vision | Gemini | `gemini-2.5-flash` via `generativelanguage.googleapis.com/v1beta` |
| Speech-to-text | Gemini | same endpoint, audio sent as inline base64 |
| Text-to-speech | ElevenLabs | `eleven_multilingual_v2` |

Timeouts live in `ApiConfig`: LLM 30s, TTS 15s, STT 15s.

### API Costs

Not re-measured since the move from Gemini 1.5 Pro to 2.5 Flash. Flash is dramatically cheaper
per session, so **ElevenLabs TTS now dominates the per-session cost**. Treat any figure here as
unverified until someone checks the billing dashboards against a real 5-challenge session.

## Development Practices

### State Management

- All providers are **manually declared** (`StateNotifierProvider`, `Provider`). Although
  `riverpod_generator` and `build_runner` are in `dev_dependencies`, **no code generation is
  wired up and there are no `.g.dart` files**. Follow the manual pattern; don't introduce
  `@riverpod` annotations without converting the whole `providers/` directory.
- Services are exposed via `service_providers.dart` with `ref.onDispose` cleanup.
- `GameSessionNotifier` owns the game loop. Keep API calls in services, orchestration here.

### Error Handling

- Services throw typed exceptions from `lib/utils/exceptions.dart` (`ApiException`,
  `NetworkException`, `CameraException`, `MicrophoneException`, `StorageException`).
- UI surfaces them with `ErrorHandler.showErrorSnackbar` / `ErrorHandler.tryAsync`.
  `ErrorHandler.describe` turns any error into a child-safe message without needing a
  `BuildContext`, which is what the notifier uses.
- The game loop must **never** dead-end. `LLMService` and `GameSessionNotifier` fall back to
  canned narration rather than propagating failures to the child. TTS failure is logged and
  swallowed so play continues in silence.
- Use `debugPrint`, not `print`.

### Prompting Gemini

- All prompt construction goes through `PromptBuilder` (`lib/utils/prompt_builder.dart`,
  the largest file in the project at ~480 lines).
- `buildSystemPrompt` covers persona, safety rails, theme, environment, narrator, and
  turn-taking. `buildUserMessage` adds the current turn. There are also `buildVictoryPrompt`
  and `buildTimeExpiredPrompt`.
- Each theme carries ~10 challenge categories to keep challenges from repeating.
- Gemini is asked for JSON. `LLMService._parseResponse` handles fenced JSON, bare JSON, and
  falls back to `_extractFromPlainText`. Any change to the response contract needs all three
  paths updated.
- **Do not remove `thinkingConfig: {thinkingBudget: 0}`.** `gemini-2.5-flash` reasons before
  answering by default and those thinking tokens count against `maxOutputTokens`. At this
  budget thinking can consume all of it, returning a candidate with *no parts*, which sends
  every turn down the canned-fallback path — the narrator keeps talking but stops describing
  the child's photo. Storytelling doesn't need reasoning, and latency matters here.
- Safety thresholds are `BLOCK_ONLY_HIGH`. `BLOCK_NONE` is a restricted setting that isn't
  granted to every API key and 400s the whole request.
- `LLMService._extractText` is deliberately verbose about *why* a response was unusable
  (`finishReason`, `blockReason`, `usageMetadata`). Fallbacks are invisible to the child by
  design, so the log is the only place a regression here will show up.
- Story context is truncated by `StoryState.getTruncatedHistoryForLLM()` (last 5 turns).
- Tone: always positive, never reject the child's input.

### Testing

```bash
flutter test
```

`test/` covers models, config enums, `PromptBuilder`, services, the game-session notifier,
and a few widgets. `mocktail` is the mocking library — use it rather than hand-rolled fakes.

Service tests inject a `Dio` instance so HTTP can be stubbed. **Service constructors take an
optional `Dio` parameter for exactly this reason — preserve it.**

Still uncovered and worth adding: `PlayerScreen` and `VictoryScreen` widget tests, and an
end-to-end pass through the full game flow on a device.

### Permissions & Platform

- `PermissionsScreen` sits between Loading and Setup in `AppNavigator`, and is skipped on web
  (browsers prompt on first use instead).
- Android: `permission_handler` + runtime requests. iOS: `Info.plist` needs camera, microphone,
  and photo library entries.
- Use `kIsWeb` from `package:flutter/foundation.dart`. Do **not** re-derive it with
  `identical(0, 0.0)`, and never import `dart:io` from code reachable on web.

### Assets & Theming

- Theme configs in `assets/themes/`, audio in `assets/audio/`, both registered in `pubspec.yaml`.
- Gradients and accent colours per theme come from `AppTheme.getThemeGradient` /
  `getThemeAccentColor`, keyed by `StoryTheme.name`.

## Web / Vercel Deployment

**Vercel is the only deployment path.** The GitHub Actions workflows were deleted: one
committed a keyless `public/` that clobbered the Vercel build, the other published a blank
Pages site from a wrong `--base-href`. Don't reintroduce a second path without deciding which
one owns `public/`.

| File | Role |
|------|------|
| `vercel.json` | `buildCommand: node build.js`, output `public/` |
| `build.js` | Downloads the Flutter SDK, runs `flutter build web`, injects the API keys |
| `build.sh` | Older shell equivalent, kept for local use |
| `server.js` | Only for running the build locally under Express; Vercel never executes it |
| `public/` | Generated build output — **gitignored**, regenerated on every deploy |

On web there is no `.env`. `ApiConfig` reads `window.apiConfig` through a conditional import
(`api_config_web.dart` on web, `api_config_stub.dart` elsewhere) so mobile never pulls in
`dart:js_interop`. `build.js` writes that object into `public/index.html` at build time from
the `GEMINI_API_KEY` and `ELEVENLABS_API_KEY` Vercel environment variables — the static output
means `server.js`'s request-time injection never runs. If keys are missing, `LoadingScreen`
shows the configuration error.

**The web build ships both API keys to every visitor in plain text.** That is inherent to
calling Gemini and ElevenLabs directly from the browser. Anything genuinely public should
proxy these calls through a server instead.

Camera is skipped on web — `CameraService.initialize()` returns successfully with a null
controller, and `ThemedViewfinder` must tolerate that.

## Common Tasks

### Adding a Story Theme

1. Add the enum case + display data in `lib/config/story_themes.dart`.
2. Add gradient and accent colour in `lib/config/app_theme.dart`.
3. Add the theme's challenge-category block to `PromptBuilder`, **in both Danish and English**.
4. Add a victory badge in `victory_screen.dart`.
5. Play the full flow: Setup → Play → Victory.

### Adding a Narrator Voice

1. Add the profile + ElevenLabs voice ID in `lib/config/narrator_profiles.dart`.
2. It flows automatically through `ParentConfig.elevenLabsVoiceId` into `TTSService`.
3. **The voice must be `premade`.** On a free ElevenLabs plan, *library* (community)
   voices return 402 `paid_plan_required` through the API — "Free users cannot use library
   voices via the API" — even though they work fine on the ElevenLabs website and the
   credit balance is untouched. Narration then fails silently. Check the ID first:

   ```bash
   KEY=$(grep '^ELEVENLABS_API_KEY=' .env | cut -d= -f2-)
   curl -s -H "xi-api-key: $KEY" https://api.elevenlabs.io/v1/voices \
     | python3 -c "import sys,json;[print(v['voice_id'], v['name'], v.get('category')) for v in json.load(sys.stdin)['voices']]"
   ```

   IDs are also reused across renames — `EXAVITQu4vr4xnSDxMaL` was Bella and is now Sarah,
   so don't trust the name in a comment.
4. Verify the voice actually supports the target language.

### Debugging API Issues

- Confirm `.env` keys load (mobile) or `window.apiConfig` is present (web).
- `ApiConfig.isConfigured` gates startup in `LoadingScreen`.
- Gemini: check the image is non-empty JPEG base64; check quota in the Google Cloud console.
- ElevenLabs: check voice ID and UTF-8 encoding; watch the usage dashboard.

## Code Style

- `camelCase` members, `PascalCase` types. One main class per file.
- Group imports: `dart:`, `package:flutter`, other packages, then relative.
- `flutter format lib/` and `flutter analyze` before committing; lints in `analysis_options.yaml`.
- Comments explain *why*, not *what*. Target <100 char lines.
- `const` constructors wherever possible.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Camera permission denied | Check iOS `Info.plist` + Android `AndroidManifest.xml`; test on device |
| Gemini 401 / 403 | Verify `GEMINI_API_KEY`; confirm the API is enabled in Google Cloud |
| Web build fails on `dart:io` | Something in the import graph pulled in `dart:io`; use conditional imports |
| Web has no API keys | `server.js` isn't injecting `window.apiConfig` — check the deploy env vars |
| TTS stutters | Shorten text; try `streamDanish()`; check network latency |
| Provider not rebuilding | State is immutable — mutate via `copyWith()`, or `ref.invalidate()` |
| Hive box not persisting | `SessionStorageService.initialize()` must run before any read/write |

## External Resources

- [Flutter](https://flutter.dev/docs) · [Riverpod](https://riverpod.dev) ·
  [Gemini API](https://ai.google.dev) · [ElevenLabs](https://elevenlabs.io/docs) ·
  [Hive](https://docs.hivedb.dev)

---

**Last Updated**: 2026-08-12
**Maintainers**: AI-assisted development
**License**: Private / Commercial
