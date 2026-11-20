import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/models/halloween_prompt_data.dart';
import 'package:spooky_ai/core/prompt_engine/scene_kits.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/core/theme/seasons/season_theme.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

/// Guards the "adding a season" checklist in docs/SEASONS.md: a season that
/// is registered but half-finished would silently fall back to Halloween
/// content, so every registered season must bring its own.
void main() {
  tearDown(() => SeasonPalette.current = SeasonRegistry.halloween);

  test('every SeasonId is registered exactly once', () {
    final ids = SeasonRegistry.all.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), SeasonId.values.toSet());
  });

  group('each season ships its own content', () {
    for (final season in SeasonRegistry.all) {
      group(season.displayName, () {
        setUp(() => SeasonPalette.current = season);

        test('identity and ambient effect', () {
          expect(season.appTitle, isNotEmpty);
          expect(season.emoji, isNotEmpty);
          expect(season.decor.effect, isNotNull);
          expect(season.decor.effect!.glyphs, isNotEmpty);
        });

        test('scene kits for the prompt engine', () {
          expect(
            SceneKits.forSeason(season.id).length,
            greaterThanOrEqualTo(5),
          );
          expect(
            SceneKits.forSeason(season.id).any((k) => k.faceFriendly),
            isTrue,
            reason: 'image-to-image only uses face-friendly kits',
          );
        });

        test('prompt library: 10 text, at least 10 image', () {
          expect(PromptService.getTextToImagePrompts().length, 10);
          expect(
            PromptService.getImageToImagePrompts().length,
            greaterThanOrEqualTo(10),
          );
        });

        test('legacy option lists exist', () {
          expect(HalloweenPromptData.settings, isNotEmpty);
          expect(HalloweenPromptData.lighting, isNotEmpty);
          expect(HalloweenPromptData.effects, isNotEmpty);
        });

        if (season.id != SeasonId.halloween) {
          test('does not reuse Halloween content', () {
            final h = SeasonRegistry.halloween;
            expect(season.copy.textHint, isNot(h.copy.textHint));
            expect(season.copy.imageTitle, isNot(h.copy.imageTitle));
            expect(season.copy.chooseTextStyle, isNot(h.copy.chooseTextStyle));
            expect(season.accent, isNot(h.accent));
            final own = PromptService.getTextToImagePrompts().map((p) => p.id);
            SeasonPalette.current = h;
            final theirs = PromptService.getTextToImagePrompts().map(
              (p) => p.id,
            );
            expect(own.toSet().intersection(theirs.toSet()), isEmpty);
          });
        }
      });
    }
  });

  test('prompt ids are unique across seasons (favorites are keyed by id)', () {
    final ids = <String>[];
    for (final library in PromptService.allSeasonLibraries) {
      for (final c in library) {
        ids.addAll(c.prompts.map((p) => p.id));
      }
    }
    expect(ids.toSet().length, ids.length);
  });
}
