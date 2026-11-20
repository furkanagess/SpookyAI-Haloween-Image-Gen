import 'dart:math';

import '../theme/seasons/season_theme.dart';

/// A coherent environment: where, how it is lit, and what drifts in the air.
///
/// Setting, lighting and effect are authored TOGETHER so they never
/// contradict each other (the old design picked all three independently, so
/// a pumpkin field could arrive with "candle-lit corridor" lighting).
class SceneKit {
  const SceneKit({
    required this.id,
    required this.setting,
    required this.lighting,
    required this.effect,
    required this.tags,
    this.faceFriendly = true,
  });

  final String id;

  /// Starts with an article so it reads after "set in …".
  final String setting;
  final String lighting;
  final String effect;

  /// Concepts this scene suits; matched against the prompt's tags/keywords.
  final Set<String> tags;

  /// Light that flatters a real face. Image-to-image only picks these:
  /// saturated colored light would tint skin and break the likeness.
  final bool faceFriendly;
}

/// Chooses the best-fitting [SceneKit] for a prompt.
///
///  * every kit is tagged with the concepts it suits;
///  * the prompt contributes tags (from the shipped library entry) plus
///    keywords found in its text;
///  * generic tags (horror, fantasy…) count 0.3, specific ones 1.0, and
///    generic-only kits are dropped whenever a specific match exists;
///  * the best-scoring kit is always used (no random draw), so a prompt
///    lands in the same fitting place every time;
///  * library prompts write their own place into the text (ownsScene), so
///    kits only apply to free-text prompts.
class SceneKits {
  SceneKits._();

  /// Kept for test compatibility; scene picking is deterministic.
  static Random random = Random();

  static List<SceneKit> forSeason(SeasonId season) => switch (season) {
    SeasonId.christmas => _christmas,
    SeasonId.halloween => _halloween,
  };

  /// Tags that fit almost any scene of the season. They break ties but must
  /// not outweigh a specific match (otherwise a ghost bride's generic
  /// "supernatural" tag would pull her into a witch's cottage).
  static const Set<String> _generic = {
    'horror',
    'supernatural',
    'fantasy',
    'vintage',
  };
  static const double _genericWeight = 0.3;

  static double _overlap(SceneKit kit, Set<String> tags) {
    var score = 0.0;
    for (final t in kit.tags.intersection(tags)) {
      score += _generic.contains(t) ? _genericWeight : 1.0;
    }
    return score;
  }

  /// Candidate kits for a prompt, best fit first, with their scores.
  /// When nothing matches, every kit of the season is returned with score 0.
  static List<(SceneKit, double)> ranked({
    required SeasonId season,
    required Set<String> tags,
    required bool forFace,
  }) {
    final kits = forSeason(
      season,
    ).where((k) => !forFace || k.faceFriendly).toList();

    bool hasSpecific(SceneKit k) =>
        k.tags.intersection(tags).any((t) => !_generic.contains(t));

    var scored = <(SceneKit, double)>[
      for (final k in kits) (k, _overlap(k, tags)),
    ].where((e) => e.$2 > 0).toList();

    // When something matches on a specific concept, kits that only share a
    // generic tag (horror, fantasy…) are not candidates at all.
    if (kits.any(hasSpecific)) {
      scored = scored.where((e) => hasSpecific(e.$1)).toList();
    }
    if (scored.isEmpty) return [for (final k in kits) (k, 0.0)];

    // Stable order: higher score first, ties keep authoring order.
    final indexed = [for (var i = 0; i < scored.length; i++) (i, scored[i])];
    indexed.sort((a, b) {
      final c = b.$2.$2.compareTo(a.$2.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  static SceneKit pick({
    required SeasonId season,
    required Set<String> tags,
    required bool forFace,
  }) {
    // Deterministic: the best-fitting scene, never a random draw.
    return ranked(season: season, tags: tags, forFace: forFace).first.$1;
  }

  /// Concepts found in free text (for prompts not in the library).
  static Set<String> tagsFromText(String text) {
    final t = text.toLowerCase();
    final out = <String>{};
    _keywords.forEach((tag, words) {
      if (words.any(t.contains)) out.add(tag);
    });
    return out;
  }

  static const Map<String, List<String>> _keywords = {
    'graveyard': ['graveyard', 'tombstone', 'cemetery', 'gravestone'],
    'forest': ['forest', 'woods', 'woodland', 'fairy'],
    'pumpkin': ['pumpkin', 'jack-o', 'scarecrow', 'harvest'],
    'moon': ['moon', 'werewolf', 'howl'],
    'ghosts': ['ghost', 'spectral', 'translucent', 'phantom', 'spirit'],
    'vampire': ['vampire', 'fangs', 'dracula'],
    'witch': ['witch', 'potion', 'cauldron', 'spell', 'sorcer', 'apothecary'],
    'skeletons': ['skeleton', 'bone', 'skull'],
    'zombie': ['zombie', 'undead'],
    'mummy': ['mummy', 'bandage', 'hieroglyph', 'pharaoh'],
    'gothic': [
      'gothic',
      'victorian',
      'velvet',
      'lace',
      'raven',
      'masquerade',
      'mourning',
    ],
    'nobility': [
      'king',
      'queen',
      'crown',
      'royal',
      'throne',
      'noble',
      'aristocrat',
    ],
    'house': [
      'mansion',
      'castle',
      'chandelier',
      'ballroom',
      'staircase',
      'manor',
    ],
    'vintage': ['vintage', 'antique', 'doll', 'retro', 'old-fashioned'],
    'cozy': [
      'cozy',
      'sweater',
      'knit',
      'autumn',
      'blanket',
      'mug',
      'fireplace',
    ],
    'party': [
      'party',
      'carnival',
      'fairground',
      'circus',
      'festival',
      'balloon',
    ],
    'clown': ['clown', 'circus'],
    'necromancer': ['necromancer', 'crypt', 'hooded', 'dark magic'],
    'street': ['street', 'alley', 'corridor', 'hallway', 'lamp'],
    // Christmas
    'snow': ['snow', 'frost', 'ice', 'winter', 'icicle'],
    'santa': ['santa', 'claus', 'noel'],
    'elf': ['elf', 'workshop', 'toy', 'nutcracker', 'gingerbread'],
    'tree': ['christmas tree', 'ornament', 'tinsel', 'wreath', 'garland'],
    'market': ['market', 'stall', 'cider', 'mulled'],
    'cabin': ['cabin', 'chimney', 'log '],
    'family': ['family', 'card', 'holiday photo'],
  };

  // ------------------------------------------------------------ Halloween

  static const List<SceneKit> _halloween = [
    SceneKit(
      id: 'graveyard_moon',
      setting:
          'an old graveyard with weathered, leaning tombstones under a full moon',
      lighting: 'soft cold moonlight with a gentle warm lantern glow',
      effect: 'low mist and a few faint embers',
      tags: {
        'graveyard',
        'moon',
        'ghosts',
        'horror',
        'supernatural',
        'vampire',
        'gothic',
        'skeletons',
        'werewolf',
      },
    ),
    SceneKit(
      id: 'haunted_forest',
      setting: 'a dark haunted forest with twisted trees and drifting mist',
      lighting: 'pale diffused moonlight filtering through the branches',
      effect: 'soft light rays through thin fog',
      tags: {
        'forest',
        'witch',
        'fantasy',
        'moon',
        'horror',
        'supernatural',
        'werewolf',
        'necromancer',
      },
    ),
    SceneKit(
      id: 'pumpkin_dusk',
      setting: 'a pumpkin field at dusk with glowing jack-o\'-lanterns',
      lighting: 'soft golden-hour light fading into purple twilight',
      effect: 'a few floating embers and light fog',
      tags: {'pumpkin', 'cozy', 'party', 'fantasy', 'witch', 'vintage'},
    ),
    SceneKit(
      id: 'candlelit_mansion',
      setting:
          'a candle-lit Victorian mansion hall with dusty chandeliers and cobwebs',
      lighting: 'soft warm candle light with gentle shadows',
      effect: 'faint floating dust motes',
      tags: {
        'house',
        'gothic',
        'nobility',
        'vampire',
        'ghosts',
        'vintage',
        'horror',
      },
    ),
    SceneKit(
      id: 'witch_cottage',
      setting:
          'a cozy witch\'s cottage with hanging herbs and shelves of glowing bottles',
      lighting: 'soft amber lamplight with gentle shadows',
      effect: 'curling steam and a few drifting sparkles',
      tags: {'witch', 'fantasy', 'cozy', 'vintage', 'supernatural'},
    ),
    SceneKit(
      id: 'foggy_alley',
      setting: 'a foggy cobblestone alley at night lit by old street lamps',
      lighting: 'soft cool ambient light with warm pools of lamp glow',
      effect: 'thin fog along the ground',
      tags: {
        'street',
        'liminal',
        'horror',
        'zombie',
        'ghosts',
        'retro',
        'supernatural',
      },
    ),
    SceneKit(
      id: 'autumn_path',
      setting: 'a golden autumn woodland path covered in fallen leaves',
      lighting: 'soft warm golden-hour backlight',
      effect: 'gently falling leaves and a light haze',
      tags: {'cozy', 'pumpkin', 'party', 'vintage', 'fantasy'},
    ),
    SceneKit(
      id: 'stone_crypt',
      setting: 'an ancient stone crypt with carved arches and iron lanterns',
      lighting: 'soft flickering torch light with gentle shadows',
      effect: 'a few wisps of smoke',
      tags: {
        'skeletons',
        'mummy',
        'necromancer',
        'horror',
        'supernatural',
        'gothic',
        'zombie',
      },
    ),
    SceneKit(
      id: 'neon_carnival',
      setting: 'an abandoned carnival at night with faded striped tents',
      lighting: 'colorful neon glow softened by haze',
      effect: 'low fog and warm string lights',
      tags: {'party', 'retro', 'clown', 'horror', 'vaporwave'},
      faceFriendly: false, // saturated colored light tints skin
    ),
  ];

  // ------------------------------------------------------------ Christmas

  static const List<SceneKit> _christmas = [
    SceneKit(
      id: 'snowy_village',
      setting:
          'a snowy village street at dusk with decorated houses and glowing windows',
      lighting: 'warm golden window light against cool blue twilight',
      effect: 'gently falling snowflakes',
      tags: {'street', 'snow', 'cozy', 'party', 'family', 'vintage'},
    ),
    SceneKit(
      id: 'fireplace_room',
      setting:
          'a cozy living room with a decorated tree and a crackling fireplace',
      lighting: 'warm amber fireplace light with soft tree-light bokeh',
      effect: 'a few floating golden sparkles',
      tags: {'cozy', 'tree', 'family', 'santa', 'vintage', 'party'},
    ),
    SceneKit(
      id: 'frosty_forest',
      setting: 'a frosty pine forest with fresh snowfall and fairy lights',
      lighting: 'cool blue winter twilight with warm string-light accents',
      effect: 'sparkling snow in the air',
      tags: {'forest', 'snow', 'fantasy', 'elf', 'nobility'},
    ),
    SceneKit(
      id: 'winter_market',
      setting: 'a festive winter market with wooden stalls and lanterns',
      lighting: 'warm lantern glow with soft bokeh',
      effect: 'light snow and drifting steam',
      tags: {'market', 'street', 'party', 'cozy', 'snow'},
    ),
    SceneKit(
      id: 'snow_cabin',
      setting: 'a snow-covered log cabin with smoke rising from the chimney',
      lighting: 'warm window light on blue snow',
      effect: 'slowly falling snow',
      tags: {'cabin', 'cozy', 'snow', 'family', 'forest'},
    ),
    SceneKit(
      id: 'toy_workshop',
      setting: 'a toy workshop with wooden shelves, ribbons and glowing lamps',
      lighting: 'warm tungsten light with soft shadows',
      effect: 'faint floating glitter',
      tags: {'elf', 'santa', 'fantasy', 'vintage', 'cozy'},
    ),
    SceneKit(
      id: 'ice_palace',
      setting: 'a glittering ice palace with frozen columns',
      lighting: 'soft cool white-blue light',
      effect: 'drifting frost crystals',
      tags: {'snow', 'fantasy', 'nobility', 'gothic'},
    ),
  ];
}
