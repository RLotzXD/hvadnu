# Hvad Nu?! — Claude Code Session Guide

Audio-first interactive storytelling app for Danish children (4-5 years). AI-powered, Flutter-based, cross-platform.

## Quick Start

```bash
cd /Users/lotzr/Library/CloudStorage/OneDrive-WPPCloud/VML\ MAP/Apps/HvadNu/hvad_nu
flutter pub get
flutter run
```

Ensure `.env` has valid API keys: `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`, `OPENAI_API_KEY` (optional).

## Architecture

```
lib/
├── config/          # Themes, environments, narrator profiles, API setup
├── models/          # GameSession, StoryState, PlayerAction, LLMResponse, ParentConfig
├── services/        # LLM (Gemini), TTS (ElevenLabs), STT (Whisper), Camera, Session Storage
├── providers/       # Riverpod dependency injection & reactive state
├── screens/         # Setup → Player → Victory flow + Permissions/Loading screens
├── widgets/         # Viewfinder, ActionButton, ProcessingOverlay, MagicParticles, ProgressIndicator
└── utils/           # PromptBuilder, ErrorHandler, Exceptions
```

## Key Concepts

### Game Flow
1. **Parent Setup** (`parent_setup_screen.dart`): Choose theme, environment, narrator, difficulty
2. **Story Intro** (`adventure_start_screen.dart`): AI narrator sets context
3. **Play Loop** (`player_screen.dart`): 
   - Listen to challenge
   - Child responds (photo OR voice)
   - Gemini validates & continues story
   - Repeat until victory
4. **Victory** (`victory_screen.dart`): Celebration, crown the hero

### Core Dependencies

| Layer | Library | Purpose |
|-------|---------|---------|
| State | `flutter_riverpod` | Dependency injection + reactive state |
| API | `dio` | HTTP client for Gemini, ElevenLabs, OpenAI |
| Storage | `hive` | Local session persistence |
| Media | `camera`, `just_audio`, `record` | Photo, playback, STT |
| UX | `google_fonts`, `flutter_animate`, `shimmer` | Typography, animations |

### API Costs (per 5-challenge session)
- **Gemini 1.5 Pro**: ~$0.10–0.20 (multimodal image analysis)
- **ElevenLabs TTS**: ~$0.15 (Danish voice)
- **Whisper STT** (optional): ~$0.05
- **Total**: ~$0.25–0.40/session

## Development Practices

### State Management
- Use Riverpod providers for all async operations (API calls, file I/O)
- Prefer `@riverpod` annotations + code generation (`build_runner`) over manual providers
- Keep providers focused & composable; avoid god-providers

### Error Handling
- All API failures must use `ErrorHandler` (`lib/utils/error_handler.dart`)
- Display user-friendly messages; log full stack traces to console
- Never leave users in a broken state—always offer retry or back navigation

### Prompting Gemini
- Use `PromptBuilder` (`lib/utils/prompt_builder.dart`) for consistent prompt construction
- Always include:
  - Story theme context (Dragon/Space/Pirate)
  - Current environment & narrator voice
  - Child's previous actions/photos
  - Tone: positive, encouraging, never reject child's input
- Validate `LLMResponse` structure before consuming

### Testing
- Unit tests: Core services (LLM, TTS, Session Storage)
- Widget tests: Screens & critical widgets (Viewfinder, ActionButton)
- Manual testing: Full game flow on device (permissions, audio, camera)
- Test files: `test/` directory; run with `flutter test`

### Permissions & Platform-Specific Code
- Camera & microphone permissions handled in `permission_request_widget.dart`
- Android: Uses `permission_handler` + runtime permission logic
- iOS: Requires `Info.plist` declarations (camera, microphone, photo library)
- Test on both platforms before merging

### Assets & Theming
- Themes stored in `assets/themes/` (Dragon/Space/Pirate configs)
- Fonts: Google Fonts via `google_fonts` package
- Audio clips: `assets/audio/` (if pre-recorded audio used)
- Load via Flutter asset manifest; no hard-coded paths

## Common Tasks

### Adding a New Story Theme
1. Create theme config in `lib/config/story_themes.dart`
2. Add narrator profile to `lib/config/narrator_profiles.dart`
3. Update `ParentConfig` model in `lib/models/parent_config.dart`
4. Extend `PromptBuilder` to include theme-specific context
5. Test full flow: Setup → Play → Victory

### Tweaking Gemini Prompts
- Edit prompt templates in `lib/utils/prompt_builder.dart`
- Test with `flutter run` + manual iteration on device
- Log full LLM requests/responses for debugging: check `dio` interceptors in `api_config.dart`

### Adding a New Narrator Voice
1. Create voice profile in `lib/config/narrator_profiles.dart` (ElevenLabs voice ID)
2. Update `ParentConfig` model choices
3. Pass voice ID to `TtsService` during playback
4. Test audio output on device

### Debugging API Issues
- Check `.env` has valid API keys
- Enable Dio debug logging in `lib/config/api_config.dart` to inspect requests/responses
- Use browser DevTools or Charles Proxy to inspect HTTPS traffic (if testing web)
- Gemini: Verify image format (JPEG/PNG) & size; check quota & billing in Google Cloud console
- ElevenLabs: Verify voice ID, text encoding (UTF-8), check API usage dashboard

## Code Style

- **Naming**: `camelCase` for variables/functions, `PascalCase` for classes/widgets
- **Imports**: Group by (dart:, flutter:, packages, relative paths); use `import as` for clarity
- **Formatting**: Run `flutter format lib/` before committing
- **Analysis**: `flutter analyze` should pass; check `analysis_options.yaml` for lint rules
- **Comments**: Only for *why*, not *what*; let code be self-documenting
- **Line Length**: Target <100 chars; break long chains at logical boundaries

## File Organization

- Keep files focused; one main class per file (except models/constants)
- Avoid circular dependencies; use Riverpod for dependency injection
- Use barrel exports (`widgets.dart`, `services.dart`) for clean imports
- Example: `import 'lib/widgets/widgets.dart'` instead of multiple specific imports

## Performance & Optimization

- **Image Handling**: Compress photos before sending to Gemini (reduce payload)
- **Audio**: Preload TTS audio; cache voice IDs to minimize API calls
- **UI**: Use `const` constructors where possible; memoize expensive builds with `Riverpod` selectors
- **Storage**: Hive is local; offload persistent sync to cloud separately if needed

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Camera permissions denied | Check iOS `Info.plist` + Android `AndroidManifest.xml`; test on device |
| Gemini API 401 errors | Verify `GEMINI_API_KEY` in `.env`; check Google Cloud API enabled |
| TTS audio stutters | Reduce text length; check network latency; test on different devices |
| Riverpod provider not rebuilding | Ensure mutation triggers `ref.invalidate()` or `.copyWith()` in model |
| Hive box not persisting | Ensure `await Hive.initFlutter()` called before opening boxes |

## External Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [Gemini API](https://ai.google.dev)
- [ElevenLabs TTS](https://elevenlabs.io/docs)
- [Hive Database](https://docs.hivedb.dev)

## CI/CD & Deployment

- Pre-commit: Run `flutter format` & `flutter analyze`
- Tests: `flutter test` must pass
- Build: `flutter build apk` (Android) or `flutter build ios` (iOS)
- Release: Follow app store guidelines (Google Play, Apple App Store)

---

**Last Updated**: 2026-06-01  
**Maintainers**: AI-assisted development  
**License**: Private / Commercial
