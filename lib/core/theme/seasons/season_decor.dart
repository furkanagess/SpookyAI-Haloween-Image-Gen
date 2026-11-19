import 'package:flutter/material.dart';

/// How ambient particles move across the screen.
enum SeasonEffectKind { fall, rise }

/// Ambient full-screen effect of a season (snowfall, rising embers, ...).
/// The UI layout never changes; only this data does.
class SeasonEffect {
  const SeasonEffect({
    required this.kind,
    required this.glyphs,
    this.count = 22,
    this.minSize = 10,
    this.maxSize = 20,
    this.minSpeed = 0.03,
    this.maxSpeed = 0.08,
    this.sway = 14,
    this.opacity = 0.5,
    this.color,
  });

  final SeasonEffectKind kind;

  /// Characters drawn as particles (picked at random per particle).
  final List<String> glyphs;
  final int count;
  final double minSize;
  final double maxSize;

  /// Screen heights travelled per second.
  final double minSpeed;
  final double maxSpeed;

  /// Horizontal wobble in logical pixels.
  final double sway;
  final double opacity;

  /// Tint for text-style glyphs. Null keeps the glyph's own colors (emoji).
  final Color? color;
}

/// A replacement for a bundled image: either another asset or an emoji.
class SeasonArt {
  const SeasonArt.asset(String this.asset) : emoji = null;
  const SeasonArt.emoji(String this.emoji) : asset = null;

  final String? asset;
  final String? emoji;
}

/// Everything about a season that is NOT color: wording, glyphs, art, effects.
///
/// [swaps] is applied to any user-facing string through `SeasonPalette.t`,
/// so screens keep a single copy of their text and icons. The base strings are
/// the Halloween ones, so Halloween uses an empty map.
class SeasonDecor {
  const SeasonDecor({
    this.swaps = const {},
    this.art = const {},
    this.effect,
    this.splashLottie,
  });

  /// Substring replacements (emoji and words), applied in insertion order.
  final Map<String, String> swaps;

  /// Per-image replacements keyed by the base (Halloween) asset path.
  final Map<String, SeasonArt> art;

  final SeasonEffect? effect;

  /// Lottie shown as the splash hero. Null falls back to an animated emoji.
  final String? splashLottie;

  String apply(String input) {
    if (swaps.isEmpty) return input;
    var out = input;
    swaps.forEach((from, to) => out = out.replaceAll(from, to));
    return out;
  }
}
