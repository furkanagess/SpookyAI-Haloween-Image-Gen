import 'dart:math';

import '../theme/seasons/season_palette.dart';
import '../theme/seasons/season_theme.dart';

/// Data model for Halloween-themed prompt elements
class HalloweenPromptData {
  static final Random _random = Random();

  // Every setting starts with an article so it reads naturally after
  // "set in …" / "Place the scene in …".
  static const List<String> _halloweenSettings = [
    'a haunted forest with drifting mist and long shadows',
    'a spooky graveyard with weathered, leaning tombstones',
    'an eerie old room with vintage furniture and cobwebs',
    'a pumpkin field glowing under the full moon',
    'a ghostly candle-lit corridor with peeling wallpaper',
  ];

  static const List<String> _halloweenLighting = [
    'warm orange and cool purple cinematic lighting',
    'candle-lit warm glow with deep creepy shadows',
    'cold blue moonlight through a foggy atmosphere',
    'a faint green spectral glow with soft highlights',
  ];

  // Atmosphere only: nothing that asks the model to draw "AI", glitch or
  // digital artifacts (the old list did, which hurt photorealism).
  static const List<String> _halloweenEffects = [
    'drifting mist and floating embers',
    'volumetric light rays cutting through fog',
    'soft floating dust motes and faint glowing particles',
    'a subtle spectral glow in the background',
  ];

  static const List<String> _christmasSettings = [
    'a cozy snowy village street at dusk with decorated houses',
    'a living room with a glowing Christmas tree and a crackling fireplace',
    'a frosty pine forest with fresh snowfall and fairy lights',
    'a festive winter market with wooden stalls and lanterns',
    'a snow-covered cabin with smoke rising from the chimney',
  ];

  static const List<String> _christmasLighting = [
    'warm golden string-light glow with soft bokeh',
    'amber fireplace light with gentle shadows',
    'cool blue winter twilight with sparkling snow',
    'red and green festive lighting with cinematic contrast',
  ];

  static const List<String> _christmasEffects = [
    'gently falling snowflakes and floating golden sparkles',
    'frosted glass texture with delicate ice crystals',
    'magical glitter dust swirling around the subject',
    'soft glowing ornaments and ribbons framing the scene',
  ];

  /// Options of the currently active season.
  static List<String> get settings => switch (SeasonPalette.current.id) {
    SeasonId.halloween => _halloweenSettings,
    SeasonId.christmas => _christmasSettings,
  };

  static List<String> get lighting => switch (SeasonPalette.current.id) {
    SeasonId.halloween => _halloweenLighting,
    SeasonId.christmas => _christmasLighting,
  };

  static List<String> get effects => switch (SeasonPalette.current.id) {
    SeasonId.halloween => _halloweenEffects,
    SeasonId.christmas => _christmasEffects,
  };

  /// Gets a random setting from the settings list
  static String getRandomSetting() {
    return settings[_random.nextInt(settings.length)];
  }

  /// Gets a random lighting from the lighting list
  static String getRandomLighting() {
    return lighting[_random.nextInt(lighting.length)];
  }

  /// Gets a random effect from the effects list
  static String getRandomEffect() {
    return effects[_random.nextInt(effects.length)];
  }

  /// Gets all random elements at once
  static Map<String, String> getRandomElements() {
    return {
      'setting': getRandomSetting(),
      'lighting': getRandomLighting(),
      'effect': getRandomEffect(),
    };
  }

  /// Gets a specific setting by index
  static String getSetting(int index) {
    return settings[index.clamp(0, settings.length - 1)];
  }

  /// Gets a specific lighting by index
  static String getLighting(int index) {
    return lighting[index.clamp(0, lighting.length - 1)];
  }

  /// Gets a specific effect by index
  static String getEffect(int index) {
    return effects[index.clamp(0, effects.length - 1)];
  }

  /// Gets all available options
  static Map<String, List<String>> getAllOptions() {
    return {'settings': settings, 'lighting': lighting, 'effects': effects};
  }
}
