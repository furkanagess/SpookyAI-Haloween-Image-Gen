import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';

/// WCAG AA: 4.5:1 for body text, 3:1 for large text, icons and UI parts.
void main() {
  tearDown(() {
    SeasonPalette.current = SeasonRegistry.halloween;
    SeasonPalette.isDark = true;
  });

  for (final season in SeasonRegistry.all) {
    for (final dark in [true, false]) {
      final mode = dark ? 'dark' : 'light';
      group('${season.displayName} ($mode)', () {
        setUp(() {
          SeasonPalette.current = season;
          SeasonPalette.isDark = dark;
        });

        test('body text on scaffold, surface and card is >= 4.5:1', () {
          for (final bg in [
            SeasonPalette.scaffold,
            SeasonPalette.surface,
            SeasonPalette.card,
          ]) {
            expect(
              SeasonPalette.contrastRatio(SeasonPalette.text, bg),
              greaterThanOrEqualTo(4.5),
            );
          }
        });

        test('muted text on card is >= 4.5:1', () {
          expect(
            SeasonPalette.contrastRatio(
              SeasonPalette.mutedText,
              SeasonPalette.card,
            ),
            greaterThanOrEqualTo(4.5),
          );
        });

        test('subtle icons on card are >= 3:1', () {
          expect(
            SeasonPalette.contrastRatio(
              SeasonPalette.subtleIcon,
              SeasonPalette.card,
            ),
            greaterThanOrEqualTo(3),
          );
        });

        test('onAccent on accent is >= 3:1 (bold labels, icons)', () {
          expect(
            SeasonPalette.contrastRatio(
              SeasonPalette.onAccent,
              SeasonPalette.accent,
            ),
            greaterThanOrEqualTo(3),
          );
        });
      });
    }
  }
}
