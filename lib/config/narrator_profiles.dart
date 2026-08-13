enum NarratorProfile {
  wiseWizard,
  oldSeaCaptain,
  friendlyRobot,
}

extension NarratorProfileExtension on NarratorProfile {
  String get displayName {
    switch (this) {
      case NarratorProfile.wiseWizard:
        return 'Den Vise Troldmand';
      case NarratorProfile.oldSeaCaptain:
        return 'Den Gamle Søkaptajn';
      case NarratorProfile.friendlyRobot:
        return 'Den Venlige Robot';
    }
  }

  String getDisplayName(String lang) {
    if (lang == 'en') {
      switch (this) {
        case NarratorProfile.wiseWizard:
          return 'The Wise Wizard';
        case NarratorProfile.oldSeaCaptain:
          return 'The Old Sea Captain';
        case NarratorProfile.friendlyRobot:
          return 'The Friendly Robot';
      }
    }
    return displayName;
  }

  String get description {
    switch (this) {
      case NarratorProfile.wiseWizard:
        return 'Mystisk og magisk stemme';
      case NarratorProfile.oldSeaCaptain:
        return 'Eventyrlig og varm stemme';
      case NarratorProfile.friendlyRobot:
        return 'Sjov og mekanisk stemme';
    }
  }

  String get emoji {
    switch (this) {
      case NarratorProfile.wiseWizard:
        return '🧙';
      case NarratorProfile.oldSeaCaptain:
        return '🧔';
      case NarratorProfile.friendlyRobot:
        return '🤖';
    }
  }

  /// ElevenLabs voice for this narrator.
  ///
  /// These must all be **premade** voices. A free ElevenLabs plan cannot use
  /// *library* (community) voices through the API — the request comes back
  /// 402 `paid_plan_required`, "Free users cannot use library voices via the
  /// API", and the child hears nothing. The old Sea Captain voice (Josh,
  /// `TxGEqnHWrfWFTfGW9XjX`) was a library voice and failed exactly this way,
  /// silently, on every platform.
  ///
  /// Before changing any of these, confirm the ID appears in
  /// `GET https://api.elevenlabs.io/v1/voices` for the account whose key is in
  /// `.env`, with category `premade`. Note that ElevenLabs reuses IDs across
  /// renames: `EXAVITQu4vr4xnSDxMaL` was Bella and is now Sarah.
  String get elevenLabsVoiceId {
    switch (this) {
      case NarratorProfile.wiseWizard:
        return 'pqHfZKP75CvOlQylNhV4'; // Bill — wise, mature, balanced
      case NarratorProfile.oldSeaCaptain:
        return 'JBFqnCBsd6RMkjVDRZzb'; // George — warm, captivating storyteller
      case NarratorProfile.friendlyRobot:
        return 'FGY2WhTYpPnrIDTdsKH5'; // Laura — enthusiastic, quirky
    }
  }

  String get voiceStylePrompt => getVoiceStylePrompt('da');

  String getVoiceStylePrompt(String lang) {
    if (lang == 'en') {
      switch (this) {
        case NarratorProfile.wiseWizard:
          return 'Speak slowly and mysteriously, with dramatic pauses. Your voice is deep and full of wisdom.';
        case NarratorProfile.oldSeaCaptain:
          return 'Speak warmly and adventurously, as if telling stories by the fire. Use expressions like "Ahoy" and "By all the depths of the sea".';
        case NarratorProfile.friendlyRobot:
          return 'Speak kindly and enthusiastically, with a bit of mechanical charm. Use expressions like "Beep boop" and "Scanning complete".';
      }
    }
    switch (this) {
      case NarratorProfile.wiseWizard:
        return 'Tal langsomt og mystisk, med dramatiske pauser. Din stemme er dyb og fuld af visdom.';
      case NarratorProfile.oldSeaCaptain:
        return 'Tal varmt og eventyrlystent, som om du fortæller historier ved bålet. Brug udtryk som "Ahoy" og "Ved alle havets dybder".';
      case NarratorProfile.friendlyRobot:
        return 'Tal venligt og entusiastisk, med en smule mekanisk charme. Brug udtryk som "Beep boop" og "Scanning complete".';
    }
  }
}
