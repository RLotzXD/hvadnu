enum StoryTheme {
  dragejagt,
  rumrejsen,
  pirateventyret,
  roadtrip,
}

extension StoryThemeExtension on StoryTheme {
  String get displayName {
    switch (this) {
      case StoryTheme.dragejagt:
        return 'Dragejagt';
      case StoryTheme.rumrejsen:
        return 'Rumrejsen';
      case StoryTheme.pirateventyret:
        return 'Pirateventyret';
      case StoryTheme.roadtrip:
        return 'Roadtrip';
    }
  }

  String getDisplayName(String lang) {
    if (lang == 'en') {
      switch (this) {
        case StoryTheme.dragejagt:
          return 'Dragon Hunt';
        case StoryTheme.rumrejsen:
          return 'Space Journey';
        case StoryTheme.pirateventyret:
          return 'Pirate Adventure';
        case StoryTheme.roadtrip:
          return 'Road Trip';
      }
    }
    return displayName;
  }

  String get description {
    switch (this) {
      case StoryTheme.dragejagt:
        return 'Fantasi, trylleri og venlige drager';
      case StoryTheme.rumrejsen:
        return 'Astronauter, venlige rumvæsener og stjerner';
      case StoryTheme.pirateventyret:
        return 'Skibe, skattekort og talende papegøjer';
      case StoryTheme.roadtrip:
        return 'Find ting ud af vinduet på jeres biltur';
    }
  }

  String get emoji {
    switch (this) {
      case StoryTheme.dragejagt:
        return '🐉';
      case StoryTheme.rumrejsen:
        return '🚀';
      case StoryTheme.pirateventyret:
        return '🏴‍☠️';
      case StoryTheme.roadtrip:
        return '🚗';
    }
  }

  String getSystemPromptAddition(String lang) {
    if (lang == 'en') {
      switch (this) {
        case StoryTheme.dragejagt:
          return '''
You tell the story of hunting friendly dragons in a magical adventure land.
Words to use: magic spells, enchanted objects, friendly dragons, deep forest, throne of stars.
Tone: Mystical, slightly exciting but always safe.
Finale: The child becomes a DRAGON RIDER.''';
        case StoryTheme.rumrejsen:
          return '''
You tell about astronauts exploring space and meeting friendly aliens.
Words to use: rocket, stars, robot friends, planets, galaxy, anti-gravity socks.
Tone: Whimsical, full of wonder.
Finale: The child becomes a SPACE HERO.''';
        case StoryTheme.pirateventyret:
          return '''
You tell about pirates seeking treasure on the blue seas.
Words to use: pirate ship, hidden treasures, parrots, silver coins, pirate code.
Tone: Adventurous, slightly mischievous, friendly.
Finale: The child becomes a PIRATE CAPTAIN.''';
        case StoryTheme.roadtrip:
          return '''
You guide a car journey adventure where kids spot things through the window.
The child is in a car and can ONLY find things visible through the window while driving.
Ask for: colors of cars, road signs, animals in fields, buildings, trucks, trees, clouds, bridges.
NEVER ask for things inside the car or things that require stopping.
Tone: Excited, playful, like a fun car game.
Finale: The child becomes a ROAD TRIP CHAMPION.''';
      }
    }
    return systemPromptAddition;
  }

  String get systemPromptAddition {
    switch (this) {
      case StoryTheme.dragejagt:
        return '''
Du fortæller historien om at jage gode drager i et eventyrland fyldt af magi.
Ord at bruge: trylleformularer, magiske genstande, venlige drager, skovdyb, trone af stjerner.
Tone: Mystisk, lidt spændende men altid tryg.
Finale: Barnet bliver DRAGERIDDER.''';
      case StoryTheme.rumrejsen:
        return '''
Du fortæller om astronauter der udforsker rummet og møder venlige rumvæsener.
Ord at bruge: raket, stjerner, robotvenner, planeterne, galaksen, anti-gravity-sokker.
Tone: Underfundig, fuld af undren.
Finale: Barnet bliver RUMHELT.''';
      case StoryTheme.pirateventyret:
        return '''
Du fortæller om sørøvere der søger skatte på de blå have.
Ord at bruge: sørøverskib, skjulte skatte, papegøjer, sølvmønter, sørøver-kodeks.
Tone: Eventyrligt, lidt skælmsk, venligt.
Finale: Barnet bliver PIRATKAPTAJN.''';
      case StoryTheme.roadtrip:
        return '''
Du guider et bileventyr hvor børnene finder ting ud af vinduet mens de kører.
Barnet sidder i en bil og kan KUN finde ting der er synlige gennem vinduet under kørslen.
Bed om: farver på biler, vejskilte, dyr på marker, bygninger, lastbiler, træer, skyer, broer.
BED ALDRIG om ting inde i bilen eller ting der kræver at man stopper.
Tone: Begejstret, legende, som et sjovt bilspil.
Finale: Barnet bliver ROADTRIP-MESTER.''';
    }
  }

  String getInitialChallenge(String participantNames, String lang) {
    final hasNames = participantNames.isNotEmpty;

    if (lang == 'en') {
      final greeting = hasNames ? 'Hey, $participantNames!' : 'Hey, little adventurer!';
      switch (this) {
        case StoryTheme.dragejagt:
          return '$greeting I am an old wizard, and I need your help. Can you find something golden for me? We need it to lure the dragon out!';
        case StoryTheme.rumrejsen:
          return '$greeting Welcome aboard the space station! I am your space captain. Before we can fly to the stars, we need to find something round – like a planet! Can you find something round?';
        case StoryTheme.pirateventyret:
          return '$greeting Ahoy! I am the captain of this ship, and we need to find a treasure! But first – can you find something that glitters or shines? It could be gold!';
        case StoryTheme.roadtrip:
          return '$greeting We are on a road trip adventure! Look out the window – can you spot a red car driving by? Point at it when you see one!';
      }
    }

    final greeting = hasNames ? 'Hej, $participantNames!' : 'Hej, lille eventurer!';
    switch (this) {
      case StoryTheme.dragejagt:
        return '$greeting Jeg er en gammel tryllemand, og jeg har brug for din hjælp. Kan du finde noget gyldent til mig? Det skal vi bruge til at lokke dragen frem!';
      case StoryTheme.rumrejsen:
        return '$greeting Velkommen ombord på rumstationen! Jeg er din rumkaptajn. Før vi kan flyve til stjernerne, skal vi finde noget rundt – som en planet! Kan du finde noget rundt?';
      case StoryTheme.pirateventyret:
        return '$greeting Ahoy! Jeg er kaptajn på dette skib, og vi skal finde en skat! Men først – kan du finde noget der glimter eller skinner? Det kunne være guld!';
      case StoryTheme.roadtrip:
        return '$greeting Vi er på roadtrip-eventyr! Kig ud af vinduet – kan du se en rød bil køre forbi? Peg på den når du ser en!';
    }
  }

  String get initialChallenge => getInitialChallenge('', 'da');
}
