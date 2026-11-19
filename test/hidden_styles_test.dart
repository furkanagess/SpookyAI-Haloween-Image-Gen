import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/services/main_navigation_provider.dart';
import 'package:spooky_ai/features/home/data/models/prompt_category.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';
import 'package:spooky_ai/features/home/domain/generation_mode.dart';

PromptItem text(String id) =>
    PromptService.getTextToImagePrompts().firstWhere((p) => p.id == id);
PromptItem photo(String id) =>
    PromptService.getImageToImagePrompts().firstWhere((p) => p.id == id);

void main() {
  group('style selection state', () {
    test(
      'picking a photo style switches to image mode and keeps the prompt hidden',
      () {
        final p = MainNavigationProvider();
        p.setStyle(photo('halloween_vampire'));
        expect(p.activeMode, GenerationMode.image);
        expect(p.style!.id, 'halloween_vampire');
        expect(
          p.prompt,
          isEmpty,
          reason: 'the hidden prompt must not land in the text box',
        );
        expect(p.promptLabel, 'Vampire Noble');
        expect(p.hasPromptInput, isTrue);
      },
    );

    test('picking a text style switches to text mode and drops any photo', () {
      final p = MainNavigationProvider();
      p.switchMode(GenerationMode.image);
      p.setUploadedImage(Uint8List(3));
      p.setStyle(text('pumpkin_king'));
      expect(p.activeMode, GenerationMode.text);
      expect(p.uploadedImage, isNull);
      expect(p.promptLabel, 'Pumpkin King');
    });

    test('switching mode drops a style that belongs to the other mode', () {
      final p = MainNavigationProvider();
      p.setStyle(text('pumpkin_king'));
      p.switchMode(GenerationMode.image);
      expect(p.style, isNull);
    });

    test('the label shows what the user typed when no style is chosen', () {
      final p = MainNavigationProvider();
      expect(p.hasPromptInput, isFalse);
      p.updatePrompt('a friendly ghost');
      expect(p.promptLabel, 'a friendly ghost');
      expect(p.hasPromptInput, isTrue);
    });

    test('extra details are kept separate from the style', () {
      final p = MainNavigationProvider();
      p.setStyle(text('moonlit_witch'));
      p.updatePrompt('with a red scarf');
      expect(p.prompt, 'with a red scarf');
      expect(
        p.promptLabel,
        'Moonlit Witch',
      ); // history/sharing never leaks the prompt
      p.clearStyle();
      expect(p.style, isNull);
      expect(p.promptLabel, 'with a red scarf');
    });

    test('a new style starts with empty details', () {
      final p = MainNavigationProvider();
      p.updatePrompt('leftover');
      p.setStyle(text('pumpkin_king'));
      expect(p.prompt, isEmpty);
    });
  });

  group('engine builds from the hidden style', () {
    test('style prompt is the subject; extra details are appended cleanly', () {
      final king = text('pumpkin_king');
      final built = PromptEngine.textToImage(
        'with a red scarf',
        style: king,
      ).prompt;
      final subject = king.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '');
      expect(built, startsWith('$subject, with a red scarf, '));
      expect(built.contains('..'), isFalse);
      expect(built.contains(',,'), isFalse);
    });

    test('empty extra equals the plain style prompt', () {
      final king = text('pumpkin_king');
      expect(
        PromptEngine.textToImage('', style: king).prompt,
        '${king.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '')}, '
        '${PromptEngine.photoTail}',
      );
    });

    test(
      'scene-owning styles keep owning their scene even with extra details',
      () {
        final bedroom = photo('halloween_retro_bedroom');
        final built = PromptEngine.imageToImage(
          'wearing a red jacket',
          style: bedroom,
        ).prompt;
        expect(built.contains('set in'), isFalse);
        expect(built, contains('wearing a red jacket'));
      },
    );

    test('image styles keep the single face sentence', () {
      final built = PromptEngine.imageToImage(
        '',
        style: photo('halloween_witch'),
      ).prompt;
      expect(built, contains(PromptEngine.faceLock));
      expect(built, endsWith(PromptEngine.fantasyTail));
    });

    test('extra details are still moderated like any user text', () {
      expect(PromptEngine.moderate('a nude figure').allowed, isFalse);
      final issue = PromptValidator.validate(
        'a nude figure',
        mode: GenerationMode.text,
        hasPhoto: false,
        hasStyle: true,
      );
      expect(issue!.kind, PromptIssueKind.blocked);
    });
  });

  group('validator with a style', () {
    test('empty and short extra details are fine when a style is chosen', () {
      for (final extra in ['', '  ', 'red']) {
        expect(
          PromptValidator.validate(
            extra,
            mode: GenerationMode.text,
            hasPhoto: false,
            hasStyle: true,
          ),
          isNull,
          reason: '"$extra"',
        );
      }
    });

    test('without a style the old rules still apply', () {
      expect(
        PromptValidator.validate(
          '',
          mode: GenerationMode.text,
          hasPhoto: false,
        )!.kind,
        PromptIssueKind.empty,
      );
      expect(
        PromptValidator.validate(
          'red',
          mode: GenerationMode.text,
          hasPhoto: false,
        )!.kind,
        PromptIssueKind.tooShort,
      );
    });

    test('a photo is still required for photo styles', () {
      expect(
        PromptValidator.validate(
          '',
          mode: GenerationMode.image,
          hasPhoto: false,
          hasStyle: true,
        )!.kind,
        PromptIssueKind.missingPhoto,
      );
    });
  });

  group('the UI never reveals a style prompt', () {
    const files = [
      'lib/features/home/presentation/pages/prompts_page.dart',
      'lib/features/home/presentation/widgets/prompt_detail_sheet.dart',
      'lib/features/home/presentation/widgets/style_picker_card.dart',
      'lib/features/home/presentation/pages/main_navigation_page_refactored.dart',
      'lib/features/home/presentation/pages/photos_page.dart',
      'lib/features/home/presentation/pages/trend_page.dart',
    ];
    // Word boundaries: `item.promptType` is fine, `item.prompt` is not.
    final forbidden = {
      RegExp(r'\bstyle!?\.prompt\b'): 'style.prompt',
      RegExp(r'\bitem\.prompt\b'): 'item.prompt',
      RegExp(r'SelectableText'): 'SelectableText',
      RegExp(r'Clipboard\.setData'): 'Clipboard.setData',
    };

    test('no screen reads or copies a library prompt text', () {
      for (final f in files) {
        final src = File(f).readAsStringSync();
        forbidden.forEach((pattern, name) {
          expect(pattern.hasMatch(src), isFalse, reason: '$f contains "$name"');
        });
      }
    });

    test('generated results store the label, not the prompt', () {
      final src = File(
        'lib/features/home/presentation/pages/main_navigation_page_refactored.dart',
      ).readAsStringSync();
      expect(src.contains('prompt: provider.prompt,'), isFalse);
      expect(src, contains('prompt: provider.promptLabel,'));
    });
  });
}
