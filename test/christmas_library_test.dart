import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/config/prompt_preview_assets.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/features/home/data/models/prompt_category.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

void main() {
  tearDown(() => SeasonPalette.current = SeasonRegistry.halloween);

  List<PromptItem> text() => PromptService.getTextToImagePrompts();
  List<PromptItem> image() => PromptService.getImageToImagePrompts();

  test('every season splits photo styles 10 realistic / 10 fantasy', () {
    for (final season in SeasonRegistry.all) {
      SeasonPalette.current = season;
      final image = PromptService.getImageToImagePrompts();
      final fantasy = image.where((p) => p.kind == StyleKind.fantasy);
      expect(image.length, 20, reason: season.displayName);
      expect(fantasy.length, 10, reason: season.displayName);
      for (final p in image) {
        final built = PromptEngine.imageToImage('', style: p).prompt;
        expect(
          built,
          endsWith(
            p.kind == StyleKind.fantasy
                ? PromptEngine.fantasyTail
                : 'Realistic photo.',
          ),
          reason: p.id,
        );
      }
    }
  });

  test('each season has its own library', () {
    SeasonPalette.current = SeasonRegistry.halloween;
    final h = {for (final p in text()) p.id};
    SeasonPalette.current = SeasonRegistry.christmas;
    final c = {for (final p in text()) p.id};
    expect(h.intersection(c), isEmpty);
    expect(c, contains('santa_workshop'));
  });

  group('Christmas library shape and rules', () {
    setUp(() => SeasonPalette.current = SeasonRegistry.christmas);

    test('10 text + 20 image, unique, enough free and popular', () {
      expect(text().length, 10);
      expect(image().length, 20);
      final all = [...text(), ...image()];
      expect({for (final p in all) p.id}.length, all.length);
      expect({for (final p in all) p.title}.length, all.length);
      expect(text().where((p) => !p.isPremium).length, 3);
      for (final k in StyleKind.values) {
        expect(
          image().where((p) => p.kind == k && !p.isPremium).length,
          3,
          reason: k.name,
        );
      }
      expect(text().where((p) => p.isPopular).length, inInclusiveRange(3, 5));
      expect(image().where((p) => p.isPopular).length, inInclusiveRange(3, 6));
      for (final p in all) {
        expect(p.tags, isNotEmpty, reason: p.id);
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(p.id), isTrue, reason: p.id);
        expect(p.tagline, isNotEmpty, reason: p.id);
        expect(p.description, isNotEmpty, reason: p.id);
      }
    });

    test('safe, correctly sized, person-based and engine-compatible', () {
      for (final p in [...text(), ...image()]) {
        expect(
          PromptEngine.moderate('${p.title} ${p.prompt}').allowed,
          isTrue,
          reason: p.id,
        );
        expect(p.prompt.length, greaterThanOrEqualTo(120), reason: p.id);
        final isImage = p.promptType == PromptType.imageToImage;
        final limit = (isImage && !p.ownsScene) ? 235 : 340;
        expect(p.prompt.length, lessThanOrEqualTo(limit), reason: p.id);
        if (isImage) {
          expect(p.prompt.toLowerCase().startsWith('the person'), isTrue);
          final built = PromptEngine.imageToImage(p.prompt).prompt;
          expect(built.length, lessThanOrEqualTo(PromptEngine.maxPromptLength));
          expect(built, contains(p.prompt));
        } else {
          final built = PromptEngine.textToImage(p.prompt).prompt;
          expect(
            built,
            startsWith(p.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '')),
          );
        }
      }
    });

    test('library prompts are recognised in any season', () {
      final santa = text().firstWhere((p) => p.id == 'santa_workshop');
      SeasonPalette.current = SeasonRegistry.halloween;
      expect(PromptService.findByPrompt(santa.prompt)?.id, santa.id);
    });
  });

  test('the Generate screen copy differs per season', () {
    expect(
      SeasonRegistry.christmas.copy.textHint,
      isNot(SeasonRegistry.halloween.copy.textHint),
    );
    expect(
      SeasonRegistry.christmas.copy.imageTitle,
      isNot(SeasonRegistry.halloween.copy.imageTitle),
    );
  });

  test('every Christmas text prompt has an existing preview picture', () {
    SeasonPalette.current = SeasonRegistry.christmas;
    for (final p in PromptService.getTextToImagePrompts()) {
      final path = PromptPreviewAssets.forPrompt(p.id);
      expect(path, isNotNull, reason: '${p.id} has no preview mapped');
      expect(File(path!).existsSync(), isTrue, reason: '${p.id}: $path');
    }
  });
}
