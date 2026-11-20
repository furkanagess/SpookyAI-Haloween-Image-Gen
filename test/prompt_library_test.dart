import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/features/home/data/models/prompt_category.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

void main() {
  setUp(() => SeasonPalette.current = SeasonRegistry.halloween);

  final all = [for (final c in PromptService.getAllCategories()) ...c.prompts];
  final text = PromptService.getTextToImagePrompts();
  final image = PromptService.getImageToImagePrompts();

  group('Halloween library shape', () {
    test('10 text and 20 image prompts', () {
      expect(text.length, 10);
      expect(image.length, 20);
      expect(text.every((p) => p.promptType == PromptType.textToImage), isTrue);
      expect(
        image.every((p) => p.promptType == PromptType.imageToImage),
        isTrue,
      );
    });

    test('ids and titles are unique', () {
      expect({for (final p in all) p.id}.length, all.length);
      expect({for (final p in all) p.title}.length, all.length);
    });

    test(
      'free split: 3 text, 3 realistic and 3 fantasy photo styles unlocked',
      () {
        expect(text.where((p) => !p.isPremium).length, 3);
        for (final k in StyleKind.values) {
          expect(
            image.where((p) => p.kind == k && !p.isPremium).length,
            3,
            reason: k.name,
          );
        }
      },
    );

    test('about a quarter are popular in each mode', () {
      expect(text.where((p) => p.isPopular).length, inInclusiveRange(3, 5));
      expect(image.where((p) => p.isPopular).length, inInclusiveRange(3, 6));
    });

    test('every prompt has tags and a preview-friendly id', () {
      for (final p in all) {
        expect(p.tags, isNotEmpty, reason: p.id);
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(p.id), isTrue, reason: p.id);
      }
    });
  });

  group('every prompt satisfies the architecture rules', () {
    test('passes the content-safety gate', () {
      for (final p in all) {
        expect(
          PromptEngine.moderate('${p.title} ${p.prompt}').allowed,
          isTrue,
          reason: p.id,
        );
      }
    });

    test(
      'length: concise, and short enough that the engine never trims them',
      () {
        for (final p in all) {
          expect(p.prompt.length, greaterThanOrEqualTo(120), reason: p.id);
          // Costume-only image prompts share the budget with a scene line.
          final limit =
              (p.promptType == PromptType.imageToImage && !p.ownsScene)
              ? 235
              : 340;
          expect(p.prompt.length, lessThanOrEqualTo(limit), reason: p.id);
        }
      },
    );

    test(
      'text prompts are subject-only (no quality tags, no transform wording)',
      () {
        const banned = [
          '4k',
          '8k',
          'masterpiece',
          'trending on',
          'transform',
          'negative prompt',
        ];
        for (final p in text) {
          final lower = p.prompt.toLowerCase();
          for (final b in banned) {
            expect(lower.contains(b), isFalse, reason: '${p.id} contains "$b"');
          }
        }
      },
    );

    test(
      'image prompts never replace or hide the face, and avoid artificial wording',
      () {
        const hidesFace = [
          'pumpkin head',
          'as a head',
          'wearing a mask',
          'wearing an ornate mask',
          'covering the face',
          'covers the face',
          'full face',
          'replace',
          'instead of',
          'hood up',
          'hooded face',
        ];
        const artificial = [
          'flawless',
          'perfect',
          'airbrush',
          'porcelain',
          'glowing skin',
          'poreless',
          'hyper',
          'ultra',
          'masterpiece',
          'glamour',
        ];
        for (final p in image) {
          final lower = p.prompt.toLowerCase();
          for (final w in [...hidesFace, ...artificial]) {
            expect(lower.contains(w), isFalse, reason: '${p.id} contains "$w"');
          }
        }
      },
    );

    test('image prompts are person-based and carry no identity wording', () {
      const identity = [
        'same person',
        'identical face',
        'exact same',
        'preserve',
        'facial features',
        'face identity',
      ];
      for (final p in image) {
        final lower = p.prompt.toLowerCase();
        expect(lower.startsWith('the person'), isTrue, reason: p.id);
        for (final w in identity) {
          expect(lower.contains(w), isFalse, reason: '${p.id} contains "$w"');
        }
      }
    });
  });

  group('prompts survive the engine intact', () {
    test('image prompts: library text intact, then the face sentence', () {
      for (final p in image) {
        final built = PromptEngine.imageToImage(p.prompt).prompt;
        expect(built, startsWith('Edit this photo: ${p.prompt}'), reason: p.id);
        expect(built, contains(PromptEngine.faceLock), reason: p.id);
        expect(
          built,
          endsWith(
            p.kind == StyleKind.fantasy
                ? PromptEngine.fantasyTail
                : 'Realistic photo.',
          ),
          reason: p.id,
        );
        // Short: library text plus a few words, no rule blocks.
        expect(built.length, lessThan(p.prompt.length + 130), reason: p.id);
      }
    });

    test('text prompts: library text first, short tail', () {
      for (final p in text) {
        final subject = p.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '');
        final built = PromptEngine.textToImage(p.prompt).prompt;
        expect(built, startsWith(subject), reason: p.id);
        expect(built, endsWith(PromptEngine.photoTail), reason: p.id);
        expect(built.length, lessThan(p.prompt.length + 30), reason: p.id);
      }
    });

    test('scene-owning prompts skip the random setting; others get one', () {
      final owning = [...text, ...image].where((p) => p.ownsScene);
      expect(owning, isNotEmpty);
      for (final p in owning) {
        final built = p.promptType == PromptType.imageToImage
            ? PromptEngine.imageToImage(p.prompt).prompt
            : PromptEngine.textToImage(p.prompt).prompt;
        expect(built.contains('set in '), isFalse, reason: p.id);
      }
      // Every library prompt now writes its own fitting place.
      expect(owning.length, [...text, ...image].length);
    });

    test(
      'user-edited library prompts keep their own place, no second scene',
      () {
        final owning = image.firstWhere((p) => p.ownsScene);
        final edited = '${owning.prompt} with a red umbrella';
        final built = PromptEngine.imageToImage(edited).prompt;
        expect(built, isNot(contains('set in ')));
        expect(built, contains('with a red umbrella'));
      },
    );

    test('an oversized subject is trimmed, never the face sentence', () {
      final huge = 'the person as a ${'very mysterious ' * 60}vampire';
      final built = PromptEngine.imageToImage(huge).prompt;
      expect(built.length, lessThanOrEqualTo(PromptEngine.maxPromptLength));
      expect(built, contains(PromptEngine.faceLock));
      expect(built, endsWith('Realistic photo.'));
    });
  });
}
