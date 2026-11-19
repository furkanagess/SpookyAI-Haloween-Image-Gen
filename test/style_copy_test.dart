import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

void main() {
  final all = [
    ...PromptService.getTextToImagePrompts(),
    ...PromptService.getImageToImagePrompts(),
  ];

  group('every style has attention-grabbing copy', () {
    test('tagline and description exist and are concise', () {
      for (final p in all) {
        expect(p.tagline, isNotEmpty, reason: p.id);
        expect(p.description, isNotEmpty, reason: p.id);
        expect(
          p.tagline.length,
          lessThanOrEqualTo(55),
          reason: '${p.id} tagline too long',
        );
        expect(
          p.description.length,
          inInclusiveRange(60, 180),
          reason: '${p.id} description length',
        );
      }
    });

    test('taglines are unique (no two cards read the same)', () {
      expect({for (final p in all) p.tagline}.length, all.length);
    });

    test('copy never leaks prompt language or the architecture', () {
      const leaks = [
        'transform this photo',
        'face shape',
        'jawline',
        'film grain',
        'no watermark',
        'exact same person',
        'photograph',
        'cinematic',
        'avoid:',
        'sharp focus',
        'prompt',
      ];
      for (final p in all) {
        final copy = '${p.tagline} ${p.description}'.toLowerCase();
        for (final l in leaks) {
          expect(copy.contains(l), isFalse, reason: '${p.id} contains "$l"');
        }
      }
    });

    test('no generic filler words', () {
      const filler = [
        'unique',
        'stunning',
        'amazing',
        'perfect',
        'unleash',
        'discover',
        'experience',
        'transform your',
        'elevate',
        'magical',
        'ultimate',
      ];
      for (final p in all) {
        final copy = '${p.tagline} ${p.description}'.toLowerCase();
        for (final w in filler) {
          expect(copy.contains(w), isFalse, reason: '${p.id} contains "$w"');
        }
      }
    });

    test('photo styles speak to the user, text styles describe the image', () {
      for (final p in PromptService.getImageToImagePrompts()) {
        final copy = '${p.tagline} ${p.description}'.toLowerCase();
        expect(
          copy.contains('you'),
          isTrue,
          reason: '${p.id} should address the user',
        );
      }
    });

    test('descriptions do not repeat the tagline', () {
      for (final p in all) {
        expect(
          p.description.toLowerCase().contains(p.tagline.toLowerCase()),
          isFalse,
          reason: p.id,
        );
      }
    });
  });
}
