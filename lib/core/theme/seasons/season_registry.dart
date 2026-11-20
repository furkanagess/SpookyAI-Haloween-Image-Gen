import 'package:flutter/material.dart';

import 'season_decor.dart';
import 'season_theme.dart';

/// All season definitions plus the date-based auto selection rules.
class SeasonRegistry {
  SeasonRegistry._();

  static const halloween = SeasonTheme(
    id: SeasonId.halloween,
    displayName: 'Halloween',
    appTitle: 'SpookyAI',
    emoji: '🎃',
    seedColor: Color(0xFFE46ADF),
    accent: Color(0xFFFF6A00),
    secondaryAccent: Color(0xFFFF8A00),
    highlight: Color(0xFFB25AFF),
    highlightDeep: Color(0xFF9C27B0),
    scaffoldBackground: Color(0xFF0F0B1A),
    surface: Color(0xFF1A132B),
    card: Color(0xFF2A1F3D),
    cardGradientStart: Color(0xFF352046),
    cardGradientEnd: Color(0xFF120B25),
    inputFill: Color(0xFF1D162B),
    mutedText: Color(0xFF9F8FB8),
    // Light mode: warm parchment with the same faint purple undertone as
    // the dark card gradient, so it still reads as "Halloween" in daylight.
    lightScaffoldBackground: Color(0xFFFAF6F3),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFFFFFFF),
    lightCardGradientStart: Color(0xFFFFFFFF),
    lightCardGradientEnd: Color(0xFFF3ECF7),
    lightInputFill: Color(0xFFF2ECF5),
    lightMutedText: Color(0xFF7A6E82),
    promptAssetPath: 'assets/prompts/halloween.json',
    decor: SeasonDecor(
      splashLottie: 'assets/lottie/splash_lottie.json',
      effect: SeasonEffect(
        kind: SeasonEffectKind.rise,
        glyphs: ['✦', '•'],
        count: 18,
        minSize: 8,
        maxSize: 16,
        minSpeed: 0.02,
        maxSpeed: 0.06,
        sway: 10,
        opacity: 0.35,
        color: Color(0xFFFF6A00),
      ),
    ),
  );

  static const christmas = SeasonTheme(
    id: SeasonId.christmas,
    displayName: 'Christmas',
    appTitle: 'SpookyAI Christmas',
    emoji: '🎄',
    seedColor: Color(0xFFC62828),
    accent: Color(0xFFE53935),
    secondaryAccent: Color(0xFFFFC107),
    highlight: Color(0xFF43A047),
    highlightDeep: Color(0xFF2E7D32),
    scaffoldBackground: Color(0xFF07140F),
    surface: Color(0xFF0F2219),
    card: Color(0xFF173226),
    cardGradientStart: Color(0xFF1F4533),
    cardGradientEnd: Color(0xFF08160F),
    inputFill: Color(0xFF10261C),
    mutedText: Color(0xFF8FB5A0),
    // Light mode: snowy white with a faint mint undertone, echoing the dark
    // card gradient's green so it still reads as "Christmas" in daylight.
    lightScaffoldBackground: Color(0xFFF6FAF7),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFFFFFFF),
    lightCardGradientStart: Color(0xFFFFFFFF),
    lightCardGradientEnd: Color(0xFFEAF3EC),
    lightInputFill: Color(0xFFEEF6EF),
    lightMutedText: Color(0xFF5F7A68),
    promptAssetPath: 'assets/prompts/christmas.json',
    copy: SeasonCopy(
      textTitle: 'Describe your Christmas scene',
      textHint: 'A cozy cabin in the snow, a tree glowing in the window...',
      imageTitle: 'Which Christmas look?',
      imageHint: 'e.g. turn me into Santa in a cozy red coat',
      styleDetailsHint: 'e.g. add a red scarf, a fireplace, falling snow',
      chooseTextStyle: 'Pick a Christmas idea',
      choosePhotoStyle: 'Pick a festive look',
    ),
    decor: SeasonDecor(
      swaps: {
        '🎃': '🎄',
        '👻': '🎅',
        '💀': '⛄',
        '🧙‍♀️': '🧝‍♀️',
        '🧙': '🧝',
        '🕸️': '❄️',
        '🕷️': '⭐',
        '🦇': '🔔',
        'Halloween': 'Christmas',
        'spooky': 'festive',
      },
      art: {
        'assets/images/ghost-face.png': SeasonArt.emoji('🎅'),
        'assets/images/pumpkin.png': SeasonArt.emoji('🎄'),
        'assets/images/haunted-house.png': SeasonArt.emoji('🏡'),
        'assets/images/witch-hat.png': SeasonArt.emoji('🎁'),
        'assets/images/spider.png': SeasonArt.emoji('⭐'),
      },
      effect: SeasonEffect(
        kind: SeasonEffectKind.fall,
        glyphs: ['❄', '❅', '❆'],
        count: 26,
        minSize: 9,
        maxSize: 20,
        minSpeed: 0.04,
        maxSpeed: 0.1,
        sway: 18,
        opacity: 0.55,
        color: Colors.white,
      ),
    ),
  );

  static const all = <SeasonTheme>[halloween, christmas];

  static SeasonTheme byId(SeasonId id) =>
      all.firstWhere((s) => s.id == id, orElse: () => halloween);

  /// Default date windows (start inclusive, as month/day). Later this table
  /// can be overridden by remote config.
  /// Christmas: Nov 25 – Jan 15. Everything else falls back to Halloween.
  static SeasonId forDate(DateTime d) {
    final md = d.month * 100 + d.day;
    if (md >= 1125 || md <= 115) return SeasonId.christmas;
    return SeasonId.halloween;
  }
}
