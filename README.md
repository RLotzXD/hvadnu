# Hvad Nu?! 🐉🚀🏴‍☠️

Audio-first interactive storytelling app for children ages 4-5, powered by AI.

## Overview

"Hvad Nu" (meaning "What Now?!") is a magical storytelling experience where children explore their physical surroundings while a dynamic AI narrator guides them through adventures in Danish.

## Features

- **Three Story Themes**: Dragon Hunting, Space Journey, Pirate Adventure
- **Five Environments**: Home, Playground, Beach, Forest, Sailboat
- **Three Narrator Voices**: Wise Wizard, Old Sea Captain, Friendly Robot
- **Multimodal AI**: Gemini 1.5 Pro analyzes photos children take
- **Danish TTS**: ElevenLabs provides expressive Danish narration
- **Forgiving Gameplay**: AI never says "no" - always accepts creatively

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management
- **Gemini 1.5 Pro** - Multimodal LLM for story generation
- **Whisper** - Speech-to-text for Danish (optional)
- **ElevenLabs** - Text-to-speech (eleven_multilingual_v2)
- **Hive** - Local session persistence

## Setup

### Prerequisites

- Flutter SDK 3.0+
- iOS 12+ or Android 6.0+
- Google Gemini API key
- ElevenLabs API key
- OpenAI API key (optional, for Whisper STT)

### Installation

1. Clone the repository:
```bash
cd hvad_nu
```

2. Copy environment template:
```bash
cp .env.example .env
```

3. Add your API keys to `.env`:
```
GEMINI_API_KEY=your-gemini-key
ELEVENLABS_API_KEY=your-elevenlabs-key
OPENAI_API_KEY=sk-your-key  # Optional
```

4. Install dependencies:
```bash
flutter pub get
```

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/          # API config, themes, environments, narrators
├── models/          # Data models (GameSession, StoryState, etc.)
├── services/        # API integrations (LLM, TTS, STT, Camera)
├── providers/       # Riverpod state management
├── screens/         # UI screens (Setup, Player, Victory)
├── widgets/         # Custom widgets (Viewfinder, ActionButton)
└── utils/           # Prompt builder, helpers
```

## Game Flow

1. **Parent Setup**: Choose theme, environment, steps, duration, narrator
2. **Start Game**: AI narrator introduces the story and first challenge
3. **Play Loop**:
   - Child listens to challenge
   - Child takes photo OR speaks answer
   - AI validates (always positively!) and continues story
4. **Victory**: After all challenges, child is crowned hero

## API Usage

### Estimated Costs (per session, 5 challenges)
- Gemini 1.5 Pro: ~$0.10-0.20 (much cheaper than GPT-4o!)
- Whisper: ~$0.05 (optional)
- ElevenLabs: ~$0.15
- **Total**: ~$0.25-0.40/session

## License

Private / Commercial
