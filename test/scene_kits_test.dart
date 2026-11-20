import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/prompt_engine/scene_kits.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/core/theme/seasons/season_theme.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

Map<String, int> histogram(
  SeasonId season,
  Set<String> tags, {
  bool forFace = false,
  int n = 600,
}) {
  final h = <String, int>{};
  for (var i = 0; i < n; i++) {
    final k = SceneKits.pick(season: season, tags: tags, forFace: forFace);
    h[k.id] = (h[k.id] ?? 0) + 1;
  }
  return h;
}

void main() {
  setUp(() {
    SceneKits.random = Random(42);
    SeasonPalette.current = SeasonRegistry.halloween;
  });
  tearDown(() => SeasonPalette.current = SeasonRegistry.halloween);

  group('kit data quality', () {
    final all = [for (final s in SeasonId.values) ...SceneKits.forSeason(s)];

    test('every season has kits; ids are unique', () {
      for (final s in SeasonId.values) {
        expect(
          SceneKits.forSeason(s).length,
          greaterThanOrEqualTo(6),
          reason: s.name,
        );
      }
      expect({for (final k in all) k.id}.length, all.length);
    });

    test('settings read naturally and stay concise', () {
      for (final k in all) {
        expect(RegExp(r'^(a|an) ').hasMatch(k.setting), isTrue, reason: k.id);
        expect(k.setting.length, lessThanOrEqualTo(85), reason: k.id);
        expect(k.lighting.length, lessThanOrEqualTo(65), reason: k.id);
        expect(k.effect.length, lessThanOrEqualTo(60), reason: k.id);
        expect(k.tags, isNotEmpty, reason: k.id);
      }
    });

    test('no kit asks for AI/glitch/digital artifacts', () {
      for (final k in all) {
        final t = '${k.setting} ${k.lighting} ${k.effect}'.toLowerCase();
        for (final bad in [
          'glitch',
          'pixel',
          'digital',
          'neural',
          'generated',
          ' ai ',
        ]) {
          expect(t.contains(bad), isFalse, reason: '${k.id}: $bad');
        }
      }
    });

    test('kits pass the content-safety gate', () {
      for (final k in all) {
        expect(
          PromptEngine.moderate(
            '${k.setting} ${k.lighting} ${k.effect}',
          ).allowed,
          isTrue,
          reason: k.id,
        );
      }
    });

    test('every season keeps face-friendly kits for image-to-image', () {
      for (final s in SeasonId.values) {
        expect(
          SceneKits.forSeason(s).where((k) => k.faceFriendly).length,
          greaterThanOrEqualTo(5),
          reason: s.name,
        );
      }
    });
  });

  group('picker', () {
    test(
      'matches the concept: graveyard prompts land in graveyard-like scenes',
      () {
        final h = histogram(SeasonId.halloween, {
          'graveyard',
          'ghosts',
          'moon',
        });
        final top = h.entries.reduce((a, b) => a.value >= b.value ? a : b);
        expect(top.key, 'graveyard_moon');
        expect(
          h.keys.every(
            (id) => const {
              'graveyard_moon',
              'haunted_forest',
              'candlelit_mansion',
              'foggy_alley',
              'stone_crypt',
            }.contains(id),
          ),
          isTrue,
        );
      },
    );

    test('pumpkin prompts avoid unrelated scenes like crypts', () {
      final h = histogram(SeasonId.halloween, {'pumpkin'});
      expect(h.containsKey('stone_crypt'), isFalse);
      expect(h.containsKey('graveyard_moon'), isFalse);
      expect(h['pumpkin_dusk']! + (h['autumn_path'] ?? 0), 600);
    });

    test('specific matches beat generic ones (library regressions)', () {
      Set<String> libTags(String id) => {
        ...[
          ...PromptService.getTextToImagePrompts(),
          ...PromptService.getImageToImagePrompts(),
        ].firstWhere((p) => p.id == id).tags,
      };
      // Ghost bride: ghosts/gothic -> never a witch cottage, forest or pumpkin field.
      final bride = histogram(SeasonId.halloween, {
        ...libTags('ghost_bride'),
        ...SceneKits.tagsFromText('spectral bride lace veil translucent'),
      }, n: 800);
      expect(bride.containsKey('witch_cottage'), isFalse, reason: '$bride');
      expect(bride.containsKey('pumpkin_dusk'), isFalse, reason: '$bride');
      // Pumpkin King: pumpkin first, never the crypt.
      final king = histogram(SeasonId.halloween, {
        ...libTags('pumpkin_king'),
        ...SceneKits.tagsFromText('pumpkin-headed king throne crown'),
      }, n: 800);
      expect(king.containsKey('stone_crypt'), isFalse, reason: '$king');
      // Mummy (image): the crypt is the favourite.
      final mummy = histogram(
        SeasonId.halloween,
        SceneKits.tagsFromText('ancient mummy linen bandages hieroglyph'),
        forFace: true,
        n: 800,
      );
      final top = mummy.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(top.key, 'stone_crypt', reason: '$mummy');
    });

    test('same prompt always gets the same scene (no random draw)', () {
      final h = histogram(SeasonId.halloween, {'gothic', 'vampire'});
      expect(h.length, 1);
    });

    test('no overlap picks one deterministic scene', () {
      final h = histogram(SeasonId.halloween, {'unrelated-tag'});
      expect(h.length, 1);
    });

    test('image-to-image never picks non-face-friendly light', () {
      final h = histogram(SeasonId.halloween, {
        'party',
        'retro',
        'clown',
      }, forFace: true);
      expect(h.containsKey('neon_carnival'), isFalse);
      // …but text-to-image may.
      final t = histogram(SeasonId.halloween, {'party', 'retro', 'clown'});
      expect(t.containsKey('neon_carnival'), isTrue);
    });

    test('each season only returns its own kits', () {
      final xmas = SceneKits.forSeason(
        SeasonId.christmas,
      ).map((k) => k.id).toSet();
      expect(
        histogram(SeasonId.christmas, {'cozy'}).keys.every(xmas.contains),
        isTrue,
      );
    });

    test('keyword extraction works for free text', () {
      expect(
        SceneKits.tagsFromText('a ghost bride in a graveyard'),
        containsAll(['ghosts', 'graveyard']),
      );
      expect(
        SceneKits.tagsFromText('wearing a cozy knit sweater by the fireplace'),
        contains('cozy'),
      );
      expect(SceneKits.tagsFromText('xyz'), isEmpty);
    });
  });

  group('engine integration', () {
    test('library prompts carry their own place, no kit setting added', () {
      final bride = PromptService.getTextToImagePrompts().firstWhere(
        (p) => p.id == 'ghost_bride',
      );
      final built = PromptEngine.textToImage(bride.prompt).prompt;
      expect(built, contains('graveyard'));
      expect(built.contains(' set in '), isFalse, reason: built);
    });

    test('user-typed prompts are matched by keywords', () {
      for (var i = 0; i < 40; i++) {
        final built = PromptEngine.textToImage(
          'a pumpkin scarecrow guarding a field',
        ).prompt;
        expect(
          built.contains('crypt') || built.contains('graveyard'),
          isFalse,
          reason: built,
        );
      }
    });

    test('Christmas season builds from Christmas kits', () {
      SeasonPalette.current = SeasonRegistry.christmas;
      final christmas = SceneKits.forSeason(
        SeasonId.christmas,
      ).map((k) => k.setting);
      final built = PromptEngine.imageToImage(
        'the person in a cozy knit sweater',
      ).prompt;
      expect(christmas.any(built.contains), isTrue, reason: built);
      expect(built.contains('graveyard'), isFalse);
    });

    test('the subject is never trimmed, for any prompt and any chosen kit', () {
      final prompts = [
        ...PromptService.getImageToImagePrompts(),
        ...PromptService.getTextToImagePrompts(),
      ];
      for (final p in prompts) {
        for (var seed = 0; seed < 150; seed++) {
          SceneKits.random = Random(seed);
          final built = p.promptType.name == 'imageToImage'
              ? PromptEngine.imageToImage(p.prompt).prompt
              : PromptEngine.textToImage(p.prompt).prompt;
          expect(
            built.length,
            lessThanOrEqualTo(PromptEngine.maxPromptLength),
            reason: p.id,
          );
          final subject = p.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '');
          expect(
            built,
            contains(subject),
            reason: '${p.id} seed $seed trimmed',
          );
        }
      }
    });

    test('lighting is phrased as "lit by" and the grammar is clean', () {
      final built = PromptEngine.textToImage(
        'a friendly ghost with a lantern',
      ).prompt;
      expect(built, contains(', lit by '));
      expect(built.contains('..'), isFalse);
      expect(built.contains('  '), isFalse);
    });
  });
}
