# Hvad Nu?! 🐉🚀🏴‍☠️

Audio-first interactive storytelling app for children ages 4–5, powered by AI.

## Overview

"Hvad Nu?!" (meaning "What Now?!") is a magical storytelling experience where children explore
their physical surroundings while a dynamic AI narrator guides them through an adventure. The
child answers each challenge by photographing something they've found or saying it out loud;
the narrator weaves whatever they offer into the story and never tells them they're wrong.

Available in Danish and English. Runs on iOS, Android and web.

## Features

- **Four story themes**: Dragon Hunt, Space Journey, Pirate Adventure, Road Trip
- **Six environments**: Home, Playground, Beach, Forest, Sailboat, Car
- **Three narrator voices**: Wise Wizard, Old Sea Captain, Friendly Robot
- **Two languages**: Danish and English, with every prompt written in both
- **Multimodal AI**: Gemini analyses the photos children take and names what it sees
- **Expressive TTS**: ElevenLabs `eleven_multilingual_v2`
- **Turn-taking**: two or more children alternate turns, by name
- **Forgiving gameplay**: the narrator always accepts an answer, creatively
- **Never dead-ends**: API failures fall back to canned narration rather than showing a child
  an error

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter |
| State | Riverpod (manually declared providers, no code generation) |
| Story + vision | Gemini `gemini-2.5-flash` |
| Speech-to-text | Gemini, audio sent inline — **not** Whisper |
| Text-to-speech | ElevenLabs `eleven_multilingual_v2` |
| HTTP | Dio |
| Storage | Hive |
| Testing | flutter_test + mocktail |

## Setup

### Prerequisites

- Flutter SDK 3.19+ (Dart 3.3+, required by `dart:js_interop` in the web config shim)
- iOS 12+ or Android 6.0+
- A Google Gemini API key
- An ElevenLabs API key

There is no OpenAI dependency.

### Installation

1. Copy the environment template:

```bash
cp .env.example .env
```

2. Add your two keys to `.env`:

```
GEMINI_API_KEY=your-gemini-key
ELEVENLABS_API_KEY=your-elevenlabs-key
```

3. Install dependencies and run:

```bash
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── config/          # API config, themes, environments, narrators
├── models/          # GameSession, StoryState, PlayerAction, ParentConfig
├── services/        # Gemini LLM + STT, ElevenLabs TTS, camera, storage, haptics
├── providers/       # Riverpod state management
├── screens/         # Splash → Loading → Permissions → Setup → Play → Victory
├── widgets/         # Viewfinder, ActionButton, overlays
└── utils/           # PromptBuilder, ErrorHandler, exceptions
```

## Game Flow

1. **Parent setup** — language, who's playing, theme, environment, narrator, length
2. **Adventure start** — camera and microphone come up, the story begins
3. **Play loop** — tap for a photo, hold to speak; Gemini continues the story, ElevenLabs
   narrates it, repeat
4. **Victory** — a badge, the session stats, and the option to go again

A session ends at whichever comes first: the step count, or the time limit.

## Web Deployment

Deployed to Vercel. `vercel.json` runs `node build.js`, which fetches the Flutter SDK, builds
for web, and injects the API keys into `public/index.html` as `window.apiConfig`. The keys come
from the `GEMINI_API_KEY` and `ELEVENLABS_API_KEY` environment variables on the Vercel project.

`public/` is generated and gitignored — don't commit it.

> ⚠️ **The web build ships both API keys to every visitor in plain text.** This is unavoidable
> when calling Gemini and ElevenLabs directly from the browser. Before making the site properly
> public, proxy these calls through a server so the keys stay server-side.

## API Costs

Not re-measured since the move from Gemini 1.5 Pro to 2.5 Flash. Flash is dramatically cheaper
per session, so ElevenLabs TTS now dominates the per-session cost. Check the billing dashboards
against a real 5-challenge session before quoting a figure.

## License

Private / Commercial
