import 'package:flutter/material.dart';

import 'season_decor.dart';
import 'season_palette.dart';

/// Identifier of every supported season. Add new seasons here.
enum SeasonId { halloween, christmas }

/// Season-specific wording for the Generate screen.
class SeasonCopy {
  const SeasonCopy({
    this.textTitle = 'Describe your vision',
    this.textHint = 'Describe your Halloween scene...',
    this.imageTitle = 'How should we transform it?',
    this.imageHint = 'e.g. turn me into a spooky Halloween character',
    this.styleDetailsHint = 'e.g. add a red scarf, make it snowy',
    this.chooseTextStyle = 'Choose a ready-made idea',
    this.choosePhotoStyle = 'Choose a photo style',
  });

  final String textTitle;
  final String textHint;
  final String imageTitle;
  final String imageHint;
  final String styleDetailsHint;
  final String chooseTextStyle;
  final String choosePhotoStyle;
}

/// Pure data describing how the whole app looks during a season.
class SeasonTheme {
  const SeasonTheme({
    required this.id,
    required this.displayName,
    required this.appTitle,
    required this.emoji,
    required this.seedColor,
    required this.accent,
    required this.secondaryAccent,
    required this.highlight,
    required this.highlightDeep,
    required this.scaffoldBackground,
    required this.surface,
    required this.card,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.inputFill,
    required this.mutedText,
    required this.promptAssetPath,
    this.decor = const SeasonDecor(),
    this.copy = const SeasonCopy(),
    // Light-mode counterparts of the structural (non-brand) surfaces above.
    // Accent/secondary/highlight stay the same in both brightnesses — those
    // saturated brand colors read fine on a light canvas too; only the
    // backgrounds, cards and muted text need their own light values.
    Color? lightScaffoldBackground,
    Color? lightSurface,
    Color? lightCard,
    Color? lightCardGradientStart,
    Color? lightCardGradientEnd,
    Color? lightInputFill,
    Color? lightMutedText,
  }) : lightScaffoldBackground =
           lightScaffoldBackground ?? const Color(0xFFFBF7F2),
       lightSurface = lightSurface ?? const Color(0xFFFFFFFF),
       lightCard = lightCard ?? const Color(0xFFFFFFFF),
       lightCardGradientStart =
           lightCardGradientStart ?? const Color(0xFFFFFFFF),
       lightCardGradientEnd = lightCardGradientEnd ?? const Color(0xFFF2ECE3),
       lightInputFill = lightInputFill ?? const Color(0xFFF1ECE4),
       lightMutedText = lightMutedText ?? const Color(0xFF75706A);

  final SeasonId id;
  final String displayName;
  final String appTitle;
  final String emoji;

  final Color seedColor;
  final Color accent; // primary call-to-action color (was 0xFFFF6A00)
  final Color secondaryAccent;
  final Color highlight; // secondary brand tone (Halloween purple)
  final Color highlightDeep; // deeper variant of highlight
  final Color scaffoldBackground;
  final Color surface;
  final Color card;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color inputFill;
  final Color mutedText;

  // Light-mode counterparts, resolved to a default in the constructor body
  // above when a season does not override them.
  final Color lightScaffoldBackground;
  final Color lightSurface;
  final Color lightCard;
  final Color lightCardGradientStart;
  final Color lightCardGradientEnd;
  final Color lightInputFill;
  final Color lightMutedText;

  /// Asset holding this season's prompts (loaded later by prompt providers).
  final String promptAssetPath;

  /// Wording, glyph swaps, art overrides and ambient effect.
  final SeasonDecor decor;

  /// Texts on the Generate screen that differ per season.
  final SeasonCopy copy;

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardGradientStart, cardGradientEnd],
  );

  LinearGradient get accentGradient =>
      LinearGradient(colors: [accent, secondaryAccent]);

  /// [isDark] picks which set of structural colors to use. Accent colors
  /// are shared between the two; only backgrounds, cards and muted text
  /// switch (see the `light*` fields above).
  ThemeData toThemeData({bool isDark = true}) {
    final bg = isDark ? scaffoldBackground : lightScaffoldBackground;
    final surf = isDark ? surface : lightSurface;
    final fill = isDark ? inputFill : lightInputFill;
    final muted = isDark ? mutedText : lightMutedText;
    final fg = isDark ? Colors.white : const Color(0xFF14121A);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        surface: surf,
      ).copyWith(primary: accent, secondary: secondaryAccent),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        // No tint or blur when content scrolls under the bar.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      extensions: [SeasonColors.from(this, isDark: isDark)],
    );
  }
}

/// ThemeExtension so widgets can read season colors via
/// `Theme.of(context).extension<SeasonColors>()` or `context.season`.
@immutable
class SeasonColors extends ThemeExtension<SeasonColors> {
  const SeasonColors({
    required this.accent,
    required this.secondaryAccent,
    required this.card,
    required this.scaffoldBackground,
    required this.inputFill,
    required this.mutedText,
    required this.cardGradient,
    required this.accentGradient,
    required this.emoji,
    required this.appTitle,
  });

  factory SeasonColors.from(SeasonTheme t, {bool isDark = true}) =>
      SeasonColors(
        accent: t.accent,
        secondaryAccent: t.secondaryAccent,
        card: isDark ? t.card : t.lightCard,
        scaffoldBackground: isDark
            ? t.scaffoldBackground
            : t.lightScaffoldBackground,
        inputFill: isDark ? t.inputFill : t.lightInputFill,
        mutedText: isDark ? t.mutedText : t.lightMutedText,
        cardGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [t.cardGradientStart, t.cardGradientEnd]
              : [t.lightCardGradientStart, t.lightCardGradientEnd],
        ),
        accentGradient: t.accentGradient,
        emoji: t.emoji,
        appTitle: t.appTitle,
      );

  final Color accent;
  final Color secondaryAccent;
  final Color card;
  final Color scaffoldBackground;
  final Color inputFill;
  final Color mutedText;
  final LinearGradient cardGradient;
  final LinearGradient accentGradient;
  final String emoji;
  final String appTitle;

  @override
  SeasonColors copyWith({
    Color? accent,
    Color? secondaryAccent,
    Color? card,
    Color? scaffoldBackground,
    Color? inputFill,
    Color? mutedText,
    LinearGradient? cardGradient,
    LinearGradient? accentGradient,
    String? emoji,
    String? appTitle,
  }) => SeasonColors(
    accent: accent ?? this.accent,
    secondaryAccent: secondaryAccent ?? this.secondaryAccent,
    card: card ?? this.card,
    scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
    inputFill: inputFill ?? this.inputFill,
    mutedText: mutedText ?? this.mutedText,
    cardGradient: cardGradient ?? this.cardGradient,
    accentGradient: accentGradient ?? this.accentGradient,
    emoji: emoji ?? this.emoji,
    appTitle: appTitle ?? this.appTitle,
  );

  @override
  SeasonColors lerp(ThemeExtension<SeasonColors>? other, double t) {
    if (other is! SeasonColors) return this;
    return SeasonColors(
      accent: Color.lerp(accent, other.accent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      card: Color.lerp(card, other.card, t)!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
      emoji: t < 0.5 ? emoji : other.emoji,
      appTitle: t < 0.5 ? appTitle : other.appTitle,
    );
  }
}

extension SeasonContext on BuildContext {
  /// Current season colors. Falls back to the active palette if absent.
  SeasonColors get season =>
      Theme.of(this).extension<SeasonColors>() ??
      SeasonColors.from(SeasonPalette.current);
}
