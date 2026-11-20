import 'package:flutter/material.dart';

import 'season_decor.dart';
import 'season_registry.dart';
import 'season_theme.dart';

/// Static access to the active season's colors, for widgets that do not
/// want to thread a BuildContext. [SeasonProvider] keeps [current] in sync,
/// and the app root is keyed by season id so the whole tree rebuilds on change.
class SeasonPalette {
  SeasonPalette._();

  static SeasonTheme current = SeasonRegistry.halloween;

  /// Kept in sync by [SeasonProvider.isDark] as a side effect, the same way
  /// [current] is kept in sync by [SeasonProvider.current] — widgets that
  /// read colors statically (without a BuildContext) see the right
  /// brightness without having to thread it through everywhere.
  static bool isDark = true;

  static SeasonDecor get decor => current.decor;

  /// Translate a Halloween-authored string (emoji + words) to the active season.
  static String t(String s) => current.decor.apply(s);

  /// True when the active season replaces [baseAsset] with an emoji.
  static bool hasEmojiArt(String baseAsset) =>
      current.decor.art[baseAsset]?.emoji != null;

  static Color get accent => current.accent;
  static Color get secondaryAccent => current.secondaryAccent;
  static Color get highlight => current.highlight;
  static Color get highlightDeep => current.highlightDeep;
  static Color get seed => current.seedColor;
  static Color get scaffold =>
      isDark ? current.scaffoldBackground : current.lightScaffoldBackground;
  static Color get surface => isDark ? current.surface : current.lightSurface;
  static Color get card => isDark ? current.card : current.lightCard;
  static Color get cardGradientStart =>
      isDark ? current.cardGradientStart : current.lightCardGradientStart;
  static Color get cardGradientEnd =>
      isDark ? current.cardGradientEnd : current.lightCardGradientEnd;
  static Color get inputFill =>
      isDark ? current.inputFill : current.lightInputFill;
  static Color get mutedText =>
      isDark ? current.mutedText : current.lightMutedText;

  /// Primary foreground (body text, default icons): white in dark mode,
  /// near-black in light mode. Prefer this over a hardcoded `Colors.white`
  /// for any text or icon that sits on [scaffold], [surface], [card] or
  /// [inputFill] — those are the surfaces that actually flip with the mode.
  /// A `Colors.white` icon or label on a solid accent-colored chip should
  /// stay `Colors.white`; it is not affected by this setting.
  static Color get text => isDark ? Colors.white : const Color(0xFF14121A);

  /// Foreground for text/icons on a solid [accent] fill: white or near-black,
  /// whichever reaches the higher WCAG contrast against the accent.
  static Color get onAccent => onColor(accent);

  /// Low-emphasis icons and placeholders (broken image, empty-state glyphs).
  /// Kept at >= 3:1 against [card] (WCAG non-text contrast), unlike
  /// `Colors.white38`, which falls below that on dark cards.
  static Color get subtleIcon =>
      isDark ? const Color(0xFF9A96A3) : const Color(0xFF6E6A73);

  /// White or near-black, whichever contrasts more with [background].
  static Color onColor(Color background) {
    const dark = Color(0xFF14121A);
    return contrastRatio(Colors.white, background) >=
            contrastRatio(dark, background)
        ? Colors.white
        : dark;
  }

  /// WCAG 2.x contrast ratio between two opaque colors (1.0 – 21.0).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }
}
