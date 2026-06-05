enum Environment {
  house,
  playground,
  beach,
  forest,
  sailboat,
  car,
}

extension EnvironmentExtension on Environment {
  String get displayName {
    switch (this) {
      case Environment.house:
        return 'Hjemme';
      case Environment.playground:
        return 'Legeplads';
      case Environment.beach:
        return 'Strand';
      case Environment.forest:
        return 'Skov';
      case Environment.sailboat:
        return 'Sejlbåd';
      case Environment.car:
        return 'I bilen';
    }
  }

  String getDisplayName(String lang) {
    if (lang == 'en') {
      switch (this) {
        case Environment.house:
          return 'At Home';
        case Environment.playground:
          return 'Playground';
        case Environment.beach:
          return 'Beach';
        case Environment.forest:
          return 'Forest';
        case Environment.sailboat:
          return 'Sailboat';
        case Environment.car:
          return 'In the Car';
      }
    }
    return displayName;
  }

  String get description {
    switch (this) {
      case Environment.house:
        return 'Sokker, puder, skeer, farver';
      case Environment.playground:
        return 'Sand, rutsjebaner, gynger, blade';
      case Environment.beach:
        return 'Skaller, sand, sten, tang';
      case Environment.forest:
        return 'Kviste, kogler, mos, sten';
      case Environment.sailboat:
        return 'Reb, redningsveste, metal, vand';
      case Environment.car:
        return 'Ting ud af vinduet';
    }
  }

  String get emoji {
    switch (this) {
      case Environment.house:
        return '🏠';
      case Environment.playground:
        return '🛝';
      case Environment.beach:
        return '🏖️';
      case Environment.forest:
        return '🌲';
      case Environment.sailboat:
        return '⛵';
      case Environment.car:
        return '🚗';
    }
  }

  List<String> get availableObjects {
    switch (this) {
      case Environment.house:
        return [
          'sokker', 'puder', 'skeer', 'kopper', 'bøger', 'legetøj', 'tæpper',
          'stole', 'borde', 'lamper', 'billeder', 'planter', 'tallerkener',
          'gafler', 'knive', 'glas', 'flasker', 'æbler', 'bananer', 'brød',
          'ost', 'mælk', 'tegninger', 'papir', 'blyanter', 'farver', 'bamser',
          'dukker', 'biler', 'klodser',
        ];
      case Environment.playground:
        return [
          'sand', 'rutsjebane', 'gynge', 'blade', 'græs', 'sten', 'pinde',
          'blomster', 'bænke', 'hegn', 'bolde', 'skovle', 'spande',
          'klatrestativ', 'vippe', 'sandkasse', 'træer', 'buske', 'fugle', 'insekter',
        ];
      case Environment.beach:
        return [
          'skaller', 'sand', 'sten', 'tang', 'vand', 'bølger', 'muslingeskaller',
          'sneglehuse', 'drivtømmer', 'fjer', 'reb', 'net', 'spand', 'skovl',
          'håndklæde', 'solcreme', 'briller', 'hat', 'sandaler', 'is',
        ];
      case Environment.forest:
        return [
          'kviste', 'kogler', 'mos', 'sten', 'blade', 'svampe', 'træer',
          'stammer', 'rødder', 'bark', 'nødder', 'bær', 'blomster', 'græs',
          'jord', 'mudder', 'fugle', 'insekter', 'edderkopper', 'snegle',
        ];
      case Environment.sailboat:
        return [
          'reb', 'redningsvest', 'metal', 'vand', 'sejl', 'mast', 'ror',
          'kompas', 'anker', 'bøje', 'fender', 'tovværk', 'knob', 'vindmåler',
          'kort', 'kikkert', 'fiskestang', 'net', 'spand', 'livring',
        ];
      case Environment.car:
        return [
          'biler', 'lastbiler', 'busser', 'motorcykler', 'cykler', 'træer',
          'huse', 'bygninger', 'broer', 'tunneller', 'skilte', 'lyskryds',
          'fodgængere', 'dyr', 'køer', 'heste', 'får', 'fugle', 'skyer',
          'solen', 'månen', 'vindmøller', 'kirker', 'tankstationer',
        ];
    }
  }

  String get contextForLLM => getContextForLLM('da');

  String getContextForLLM(String lang) {
    if (lang == 'en') {
      if (this == Environment.car) {
        return '''
The child is in a moving car and can ONLY spot things visible through the window.
Available objects to spot: ${availableObjects.join(', ')}.
IMPORTANT: Only ask for things that can be seen while driving - cars, trucks, buildings, signs, animals in fields, colors, shapes.
NEVER ask for things inside the car or things requiring the car to stop.''';
      }
      return '''
The child is located: ${getDisplayName(lang).toLowerCase()}.
Available objects in this environment include: ${availableObjects.join(', ')}.
Adapt your challenges to objects that can realistically be found in this environment.''';
    }

    if (this == Environment.car) {
      return '''
Barnet sidder i en kørende bil og kan KUN finde ting der er synlige gennem vinduet.
Tilgængelige genstande at spotte: ${availableObjects.join(', ')}.
VIGTIGT: Bed kun om ting der kan ses mens bilen kører - biler, lastbiler, bygninger, skilte, dyr på marker, farver, former.
BED ALDRIG om ting inde i bilen eller ting der kræver at bilen stopper.''';
    }
    return '''
Barnet befinder sig: ${displayName.toLowerCase()}.
Tilgængelige genstande i dette miljø inkluderer: ${availableObjects.join(', ')}.
Tilpas dine udfordringer til genstande, der realistisk kan findes i dette miljø.''';
  }
}
