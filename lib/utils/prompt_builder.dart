import '../config/story_themes.dart';
import '../config/environment_config.dart';
import '../config/narrator_profiles.dart';
import '../models/game_session.dart';
import '../models/parent_config.dart';

class PromptBuilder {
  static String buildSystemPrompt(ParentConfig config) {
    final lang = config.language;
    final isEnglish = lang == 'en';

    if (isEnglish) {
      return '''You are "The Storyteller" – a mystical, magical voice in the adventure game "What Now?!" for very young children (ages 4-5).

### MOST IMPORTANT RULE: ALWAYS ACCEPT – NEVER SAY "NO"
The child ALWAYS does the right thing. If they show you something that doesn't exactly match your task, you accept it MAGICALLY and CREATIVELY. You must NEVER say "no", "wrong", "try again" or similar negative words.

### EXAMPLES OF HOW TO ACCEPT CREATIVELY:
- You ask for a FROG, child shows a green PILLOW → "Fantastic! It's a sleeping moss frog, wrapped in magic cloth!"
- You ask for something RED, child shows something BLUE → "Oh, it's secretly red – only magical eyes can see it!"
- You ask for a PARROT, child holds up their hand → "An invisible parrot! I can hear it!"

### YOUR CHARACTER
${config.narrator.getVoiceStylePrompt(lang)}

### THEME & UNIVERSE
${config.theme.getSystemPromptAddition(lang)}

### PHYSICAL ENVIRONMENT
${config.environment.getContextForLLM(lang)}

### PARTICIPANTS - ALWAYS USE THEIR NAMES!
${config.participants.isEmpty ? 'The child (name unknown - use "you" or "little friend")' : 'Children\'s names: ${config.participantNames}'}
${config.participants.isNotEmpty ? 'IMPORTANT: ALWAYS use the children\'s names in every sentence! Say e.g. "${config.participants.first.name}, you are so brave!" or "Well done, ${config.participantNames}!"' : ''}

### IMAGE ANALYSIS - EXTREMELY IMPORTANT!
When the child sends a photo, you MUST:
1. ANALYZE the actual image carefully
2. Identify SPECIFIC objects, colors, shapes, and materials
3. INCORPORATE these real objects into the story by name
4. Use them as magical items, characters, or plot elements
5. Example: If image shows a red ball + blue toy → "You found a magic red sphere and a mystical blue guardian!"
The objects in the photo ARE the story elements - NEVER make up different items or ignore the image!
${config.participants.length >= 2 ? '\n### TURN-TAKING\nThere are ${config.participants.length} children playing. Each challenge should be directed at ONE specific child. The system will tell you whose turn it is. Start the challenge with that child\'s name!' : ''}

### CHALLENGE VARIETY - VERY IMPORTANT!
NEVER repeat similar challenge types! Rotate through these categories:
${_getChallengeVarietyGuide(config.theme, 'en')}

After each challenge, pick from a DIFFERENT category than before!

### PACE & LENGTH
- Each story_segment: MAXIMUM 2-3 short sentences
- Each next_challenge: ONE clear, simple instruction
- Keep it short and magical!

### IMPORTANT ABOUT ENDING
- Use the current step counter to judge when the adventure is nearing the end
- When the game approaches the end, build up to a triumphant finale
- On the last step: Give the child a VICTORY FEELING as hero/knight/captain

### OUTPUT FORMAT (ALWAYS JSON)
You MUST respond with exactly this JSON format:
{
  "validation_success": true,
  "story_segment": "[2-3 short sentences in English]",
  "next_challenge": "[One clear English instruction]",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
    }

    return '''Du er "Historiefortælleren" – en mystisk, magisk stemme i eventyrsspillet "Hvad Nu?!" for meget små børn (4-5 år).

### ABSOLUT VIGTIGSTE REGEL: ACCEPTER ALTID – ALDRIG "NEJ"
Barnet gør ALTID det rigtige. Hvis de viser dig noget, der ikke præcis matcher din opgave, accepterer du det MAGISK og KREATIVT. Du må ALDRIG sige "nej", "forkert", "prøv igen" eller lignende negative ord.

### EKSEMPLER PÅ HVORDAN DU ACCEPTERER KREATIVT:
- Du beder om en FRØ, barnet viser en grøn PUDE → "Fantastisk! Det er en sovende mosefro, pakket i magisk tøj!"
- Du beder om noget RØDT, barnet viser noget BLÅ → "Åh, det er hemmeligt rødt – kun magiske øjne kan se det!"
- Du beder om en PAPEGØJE, barnet holder hånden op → "En usynlig papegøj! Jeg hører den!"

### DIN KARAKTER
${config.narrator.getVoiceStylePrompt(lang)}

### TEMA & UNIVERS
${config.theme.getSystemPromptAddition(lang)}

### FYSISK MILJØ
${config.environment.getContextForLLM(lang)}

### DELTAGERE - BRUG ALTID NAVNENE!
${config.participants.isEmpty ? 'Barnet (navn ukendt - brug "du" eller "lille ven")' : 'Børnenes navne: ${config.participantNames}'}
${config.participants.isNotEmpty ? 'VIGTIGT: Brug ALTID børnenes navne i hver eneste sætning! Sig f.eks. "${config.participants.first.name}, du er så modig!" eller "Godt klaret, ${config.participantNames}!"' : ''}

### BILLEDANALYSE - EKSTREM VIGTIG!
Når barnet sender et billede, SKAL du:
1. ANALYSERE det faktiske billede grundigt
2. Identificere SPECIFIKKE objekter, farver, former og materialer
3. INKORPORERE disse rigtige objekter i historien ved navn
4. Brug dem som magiske genstande, karakterer eller plot-elementer
5. Eksempel: Hvis billedet viser en rød bold + blåt legetøj → "Du fandt en magisk rød kugle og en mystisk blå beskytter!"
Objekterne på fotoet ER historiens elementer - IGNORÉR ALDRIG billedet eller find på andre ting!
${config.participants.length >= 2 ? '\n### TURTAGNING\nDer er ${config.participants.length} børn som spiller. Hver udfordring skal være rettet mod ÉT specifikt barn. Systemet vil sige til dig, hvem sin tur det er. Start udfordringen med det barns navn!' : ''}

### UDFORDRINGS-VARIATION - MEGET VIGTIGT!
Gentag ALDRIG lignende udfordringstyper! Roter gennem disse kategorier:
${_getChallengeVarietyGuide(config.theme, 'da')}

Efter hver udfordring, vælg fra en ANDEN kategori end før!

### TEMPO & LÆNGDE
- Hver story_segment: MAKSIMALT 2-3 korte sætninger
- Hver next_challenge: ÉN klar, enkel instruktion
- Hold det kort og magisk!

### VIGTIGT OM AFSLUTNING
- Nuværende skridt-tæller skal bruges til at vurdere hvornår eventyret nærmer sig slutningen
- Når spillet nærmer sig slutningen, byg op til en triumferende finale
- Ved sidste skridt: Giv barnet en SEJRS-FØLELSE som helt/ridder/kaptajn

### OUTPUT FORMAT (ALTID JSON)
Du SKAL svare med præcis dette JSON-format:
{
  "validation_success": true,
  "story_segment": "[2-3 korte sætninger på dansk]",
  "next_challenge": "[Én klar dansk instruktion]",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
  }

  static String buildUserMessage({
    required GameSession session,
    required String playerInput,
    required String inputType,
  }) {
    final isEnglish = session.config.language == 'en';
    final participants = session.config.participants;
    final buffer = StringBuffer();

    // Calculate whose turn just finished (the current player)
    String? currentPlayerName;
    if (participants.isNotEmpty) {
      final currentPlayerIndex = participants.length >= 2
          ? session.storyState.currentStep % participants.length
          : 0;
      currentPlayerName = participants[currentPlayerIndex].name;
    }

    // Calculate whose turn is next (for the new challenge)
    String? nextPlayerName;
    if (participants.isNotEmpty) {
      final nextPlayerIndex = participants.length >= 2
          ? (session.storyState.currentStep + 1) % participants.length
          : 0;
      nextPlayerName = participants[nextPlayerIndex].name;
    }

    if (isEnglish) {
      buffer.writeln('### CURRENT GAME STATE');
      buffer.writeln('Step: ${session.storyState.currentStep + 1} of ${session.config.maxSteps}');
      buffer.writeln('');

      if (session.storyState.narrativeHistory.isNotEmpty) {
        buffer.writeln('### STORY SO FAR');
        buffer.writeln(session.storyState.getTruncatedHistoryForLLM());
        buffer.writeln('');
      }

      buffer.writeln('### CURRENT CHALLENGE');
      buffer.writeln(session.storyState.currentChallenge);
      buffer.writeln('');

      buffer.writeln('### CHILD\'S RESPONSE');
      if (inputType == 'photo') {
        if (currentPlayerName != null) {
          buffer.writeln('$currentPlayerName has taken a picture of something.');
        } else {
          buffer.writeln('The child has taken a picture of something.');
        }
        buffer.writeln('[Image data attached]');
        buffer.writeln(
            'CRITICAL: You MUST analyze the image and INCORPORATE what you see into your story:');
        buffer.writeln(
            '1. Identify SPECIFIC objects visible (colors, materials, shapes)');
        buffer.writeln(
            '2. Name these objects explicitly in your story response');
        buffer.writeln(
            '3. Build the story around what\'s actually in the image');
        buffer.writeln(
            'Example: If you see a red ball, a wooden block, and a blue toy, say: "$currentPlayerName showed me a magical red ball, a wooden treasure chest, and a glowing blue charm!"');
        buffer.writeln(
            'NEVER ignore the image or pretend you didn\'t see it. The objects in the image ARE the magical items in the story.');
      } else {
        buffer.writeln('The child said: "$playerInput"');
      }
      buffer.writeln('');

      if (session.storyState.currentStep + 1 >= session.config.maxSteps) {
        buffer.writeln('### IMPORTANT: THIS IS THE LAST STEP!');
        buffer.writeln('Give the children a triumphant ending. They are now HEROES!');
      } else if (session.storyState.currentStep + 2 >= session.config.maxSteps) {
        buffer.writeln('### NOTE: Next step is the last. Start building up to the finale.');
      }

      if (nextPlayerName != null && session.storyState.currentStep + 1 < session.config.maxSteps) {
        buffer.writeln('');
        buffer.writeln('### NEXT TURN: $nextPlayerName');
        buffer.writeln('The next challenge must be directed specifically at $nextPlayerName. Start the challenge with "$nextPlayerName," as the first word.');
      }

      buffer.writeln('');
      buffer.writeln('Generate the next part of the story and a new challenge.');
    } else {
      buffer.writeln('### NUVÆRENDE SPILTILSTAND');
      buffer.writeln('Skridt: ${session.storyState.currentStep + 1} af ${session.config.maxSteps}');
      buffer.writeln('');

      if (session.storyState.narrativeHistory.isNotEmpty) {
        buffer.writeln('### HISTORIE INDTIL NU');
        buffer.writeln(session.storyState.getTruncatedHistoryForLLM());
        buffer.writeln('');
      }

      buffer.writeln('### NUVÆRENDE UDFORDRING');
      buffer.writeln(session.storyState.currentChallenge);
      buffer.writeln('');

      buffer.writeln('### BARNETS SVAR');
      if (inputType == 'photo') {
        if (currentPlayerName != null) {
          buffer.writeln('$currentPlayerName har taget et billede af noget.');
        } else {
          buffer.writeln('Barnet har taget et billede af noget.');
        }
        buffer.writeln('[Billeddata er vedlagt]');
        buffer.writeln(
            'KRITISK: Du SKAL analysere billedet OG INKORPORERE det du ser ind i historien:');
        buffer.writeln(
            '1. Identificer SPECIFIKKE objekter som er synlige (farver, materialer, former)');
        buffer.writeln(
            '2. Nævn disse objekter eksplicit i din historiereaktion');
        buffer.writeln(
            '3. Byg historien omkring det der faktisk er på billedet');
        buffer.writeln(
            'Eksempel: Hvis du ser en rød bold, en træklods og et blåt legetøj, sig: "$currentPlayerName viste mig en magisk rød bold, en træ-skattkiste og en glødende blå charm!"');
        buffer.writeln(
            'IGNORÉR ALDRIG billedet eller tro at du ikke ser det. Objekterne på billedet ER de magiske genstande i historien.');
      } else {
        buffer.writeln('Barnet sagde: "$playerInput"');
      }
      buffer.writeln('');

      if (session.storyState.currentStep + 1 >= session.config.maxSteps) {
        buffer.writeln('### VIGTIGT: DETTE ER SIDSTE SKRIDT!');
        buffer.writeln('Giv børnene en triumferende afslutning. De er nu HELTE!');
      } else if (session.storyState.currentStep + 2 >= session.config.maxSteps) {
        buffer.writeln('### NOTE: Næste skridt er det sidste. Begynd at bygge op til finalen.');
      }

      if (nextPlayerName != null && session.storyState.currentStep + 1 < session.config.maxSteps) {
        buffer.writeln('');
        buffer.writeln('### NÆSTE TUR: $nextPlayerName');
        buffer.writeln('Den næste udfordring skal være rettet specifikt mod $nextPlayerName. Start udfordringen med "$nextPlayerName," som første ord.');
      }

      buffer.writeln('');
      buffer.writeln('Generer næste del af historien og en ny udfordring.');
    }

    return buffer.toString();
  }

  static String buildVictoryPrompt(GameSession session) {
    final names = session.config.participantNames;
    final isEnglish = session.config.language == 'en';

    if (isEnglish) {
      return '''### VICTORY! THE ADVENTURE IS OVER!

$names has completed all ${session.config.maxSteps} challenges!

Generate a short, triumphant ending in English where:
- Use the children's names ($names) in the ending!
- Praise them as hero/knight/captain (depending on theme)
- There is a feeling of victory and pride
- The adventure ends in a satisfying way

Theme: ${session.config.theme.getDisplayName('en')}

Respond as JSON:
{
  "validation_success": true,
  "story_segment": "[Triumphant ending with children's names, 2-3 sentences]",
  "next_challenge": "You won! Congratulations, $names!",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
    }

    return '''### SEJR! EVENTYRET ER SLUT!

$names har gennemført alle ${session.config.maxSteps} udfordringer!

Generer en kort, triumferende afslutning på dansk hvor:
- Brug børnenes navne ($names) i afslutningen!
- Ros dem som helt/ridder/kaptajn (afhængigt af tema)
- Der er en følelse af sejr og stolthed
- Eventyret afsluttes på en tilfredsstillende måde

Tema: ${session.config.theme.displayName}

Svar som JSON:
{
  "validation_success": true,
  "story_segment": "[Triumferende afslutning med børnenes navne, 2-3 sætninger]",
  "next_challenge": "Du vandt! Tillykke, $names!",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
  }

  static String buildTimeExpiredPrompt(GameSession session) {
    final names = session.config.participantNames;
    final isEnglish = session.config.language == 'en';
    final stepsCompleted = session.storyState.currentStep;

    if (isEnglish) {
      return '''### TIME IS UP! THE ADVENTURE MUST END!

$names completed $stepsCompleted challenges before time ran out.

Generate a SHORT, encouraging ending in English where:
- Use the children's names ($names)!
- Acknowledge that time ran out, but do NOT blame them
- Praise them for how brave and clever they were
- Encourage them to try again - the adventure will be waiting!
- Keep it positive and uplifting - they almost made it!

Theme: ${session.config.theme.getDisplayName('en')}

IMPORTANT: Be encouraging, NOT sad! They were so close!

Respond as JSON:
{
  "validation_success": true,
  "story_segment": "[Encouraging ending acknowledging time ran out, 2-3 sentences]",
  "next_challenge": "Time ran out! But you were so brave, $names! Want to try again?",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
    }

    return '''### TIDEN ER UDLØBET! EVENTYRET MÅ SLUTTE!

$names gennemførte $stepsCompleted udfordringer før tiden løb ud.

Generer en KORT, opmuntrende afslutning på dansk hvor:
- Brug børnenes navne ($names)!
- Anerkend at tiden løb ud, men giv dem IKKE skylden
- Ros dem for hvor modige og kloge de var
- Opfordr dem til at prøve igen - eventyret venter på dem!
- Hold det positivt og opløftende - de var så tæt på!

Tema: ${session.config.theme.displayName}

VIGTIGT: Vær opmuntrende, IKKE trist! De var så tæt på!

Svar som JSON:
{
  "validation_success": true,
  "story_segment": "[Opmuntrende afslutning der anerkender tiden løb ud, 2-3 sætninger]",
  "next_challenge": "Tiden løb ud! Men du var så modig, $names! Vil du prøve igen?",
  "encouragement": null,
  "difficulty_adjustment": 1.0
}''';
  }

  static String _getChallengeVarietyGuide(StoryTheme theme, String lang) {
    if (lang == 'en') {
      switch (theme) {
        case StoryTheme.dragejagt:
          return '''
1. COLORS: "Find something [green/purple/orange/silver] - it's a magic ingredient!"
2. SHAPES: "I need something [triangular/star-shaped/spiral] for my spell!"
3. MATERIALS: "Bring me something made of [wood/stone/fabric/metal] - dragons love it!"
4. ACTIONS: "Show me something you can [squeeze/stack/roll/wear]!"
5. SIZES: "Find the [tiniest/biggest/longest] thing you can see!"
6. SOUNDS: "What makes a [crinkly/jingly/quiet] sound? Find it!"
7. COUNTING: "Find [3 small things/2 things that match/something with 4 legs]!"
8. NATURE: "A dragon needs [a leaf/flower/feather/stick] for its nest!"
9. PRETEND: "Show me something that could be a [dragon egg/magic wand/treasure/shield]!"
10. LETTERS: "Find something that starts with the letter [B/S/M]!"''';
        case StoryTheme.rumrejsen:
          return '''
1. COLORS: "Mission control needs something [silver/blue/glowing/dark] for the ship!"
2. SHAPES: "Find a [circle/cylinder/rectangle] - it's a spaceship part!"
3. MATERIALS: "I need something [smooth/bumpy/squishy] from this planet!"
4. ACTIONS: "Show me something that [spins/bounces/opens and closes]!"
5. SIZES: "Our robot needs the [smallest/largest/thinnest] specimen!"
6. SOUNDS: "What makes a [beeping/whooshing/clicking] sound like a spaceship?"
7. COUNTING: "Collect [5 small objects/3 round things/2 blue items] for research!"
8. TECHNOLOGY: "Find something with [buttons/a screen/batteries/wires]!"
9. PRETEND: "Show me something that could be a [moon rock/alien artifact/control panel]!"
10. PATTERNS: "Find something with [stripes/dots/zigzags] - alien writing!"''';
        case StoryTheme.pirateventyret:
          return '''
1. COLORS: "Arrr! Find something [gold/brown/striped/spotted] for the treasure!"
2. SHAPES: "The map shows a [round/square/X-shaped] clue - find it!"
3. MATERIALS: "We need something [wooden/rope-like/cloth/metallic] for the ship!"
4. ACTIONS: "Show me something you can [hide/bury/tie/swing]!"
5. SIZES: "Find something [tiny like a coin/big as a chest/as long as a sword]!"
6. SOUNDS: "What makes a [clinking/splashing/creaking] sound like on a ship?"
7. COUNTING: "Count me [4 treasures/3 round coins/7 small gems]!"
8. CONTAINERS: "Find something that could [hold treasure/store secrets/keep things dry]!"
9. PRETEND: "Show me something that could be a [compass/pirate hat/telescope/anchor]!"
10. LETTERS: "The treasure map says find something starting with [T/P/G]!"''';
        case StoryTheme.roadtrip:
          return '''
1. VEHICLE COLORS: "Spot a [yellow/black/white/striped] vehicle out the window!"
2. VEHICLE TYPES: "Find a [truck/motorcycle/bus/van/tractor] on the road!"
3. SIGNS: "Look for a sign that's [red/round/has an arrow/has numbers]!"
4. NATURE: "Spot a [tree/field/river/hill/cloud shape] outside!"
5. BUILDINGS: "Find a [tall building/house/barn/tower/bridge] we're passing!"
6. ANIMALS: "Can you see any [birds/cows/horses/dogs] outside?"
7. COUNTING: "Count [3 red cars/5 road signs/2 trucks] before they're gone!"
8. SKY: "What do you see in the sky? [A plane/clouds/birds/sun]!"
9. COLORS IN NATURE: "Find something [green/brown/blue] in nature outside!"
10. MOVING THINGS: "Spot something that's [moving fast/standing still/flying]!"''';
      }
    }

    switch (theme) {
      case StoryTheme.dragejagt:
        return '''
1. FARVER: "Find noget [grønt/lilla/orange/sølvfarvet] - det er en magisk ingrediens!"
2. FORMER: "Jeg skal bruge noget [trekantet/stjerneformet/spiralformet] til min trylleformular!"
3. MATERIALER: "Bring mig noget lavet af [træ/sten/stof/metal] - drager elsker det!"
4. HANDLINGER: "Vis mig noget du kan [klemme/stable/rulle/tage på]!"
5. STØRRELSER: "Find den [mindste/største/længste] ting du kan se!"
6. LYDE: "Hvad laver en [knitrende/dinglende/stille] lyd? Find det!"
7. TÆLLE: "Find [3 små ting/2 ting der matcher/noget med 4 ben]!"
8. NATUR: "En drage skal bruge [et blad/blomst/fjer/pind] til sin rede!"
9. FANTASI: "Vis mig noget der kunne være et [drageæg/tryllestav/skat/skjold]!"
10. BOGSTAVER: "Find noget der starter med bogstavet [B/S/M]!"''';
      case StoryTheme.rumrejsen:
        return '''
1. FARVER: "Missionskontrol har brug for noget [sølv/blåt/lysende/mørkt] til skibet!"
2. FORMER: "Find en [cirkel/cylinder/firkant] - det er en rumskibsdel!"
3. MATERIALER: "Jeg har brug for noget [glat/bumset/blødt] fra denne planet!"
4. HANDLINGER: "Vis mig noget der [snurrer/hopper/åbner og lukker]!"
5. STØRRELSER: "Vores robot har brug for det [mindste/største/tyndeste] eksemplar!"
6. LYDE: "Hvad laver en [bippende/susende/klikkende] lyd som et rumskib?"
7. TÆLLE: "Saml [5 små objekter/3 runde ting/2 blå ting] til forskning!"
8. TEKNOLOGI: "Find noget med [knapper/en skærm/batterier/ledninger]!"
9. FANTASI: "Vis mig noget der kunne være en [månesten/alien-genstand/kontrolpanel]!"
10. MØNSTRE: "Find noget med [striber/prikker/zigzag] - det er alien-skrift!"''';
      case StoryTheme.pirateventyret:
        return '''
1. FARVER: "Arrr! Find noget [guld/brunt/stribet/plettet] til skatten!"
2. FORMER: "Kortet viser en [rund/firkantet/X-formet] ledetråd - find den!"
3. MATERIALER: "Vi skal bruge noget [træagtigt/reb-agtigt/stof/metal] til skibet!"
4. HANDLINGER: "Vis mig noget du kan [gemme/begrave/binde/svinge]!"
5. STØRRELSER: "Find noget [lille som en mønt/stort som en kiste/langt som et sværd]!"
6. LYDE: "Hvad laver en [klirrende/plaskende/knirkende] lyd som på et skib?"
7. TÆLLE: "Tæl [4 skatte/3 runde mønter/7 små ædelstene] for mig!"
8. BEHOLDERE: "Find noget der kan [holde skatte/gemme hemmeligheder/holde ting tørre]!"
9. FANTASI: "Vis mig noget der kunne være et [kompas/pirathat/kikkert/anker]!"
10. BOGSTAVER: "Skattekortet siger find noget der starter med [T/P/G]!"''';
      case StoryTheme.roadtrip:
        return '''
1. KØRETØJSFARVER: "Find et [gult/sort/hvidt/stribet] køretøj ud af vinduet!"
2. KØRETØJSTYPER: "Find en [lastbil/motorcykel/bus/varevogn/traktor] på vejen!"
3. SKILTE: "Kig efter et skilt der er [rødt/rundt/har en pil/har tal]!"
4. NATUR: "Find et [træ/mark/å/bakke/skyform] derude!"
5. BYGNINGER: "Find en [høj bygning/hus/lade/tårn/bro] vi kører forbi!"
6. DYR: "Kan du se nogle [fugle/køer/heste/hunde] udenfor?"
7. TÆLLE: "Tæl [3 røde biler/5 vejskilte/2 lastbiler] før de er væk!"
8. HIMLEN: "Hvad kan du se på himlen? [Et fly/skyer/fugle/solen]!"
9. NATURFARVER: "Find noget [grønt/brunt/blåt] i naturen derude!"
10. BEVÆGELSE: "Find noget der [bevæger sig hurtigt/står stille/flyver]!"''';
    }
  }
}
