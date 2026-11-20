import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/prompt_engine/scene_kits.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/features/home/data/models/prompt_category.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

/// Generates docs/PROMPT_LIBRARY.md from the live library and engine, and
/// fails when the committed file is out of date.
///
/// Regenerate after changing prompts, scene kits or templates:
///   UPDATE_PROMPT_DOCS=1 flutter test test/prompt_docs_test.dart
/// (the first run, when the file does not exist yet, also writes it).
const _path = 'docs/PROMPT_LIBRARY.md';

String _generate() {
  SeasonPalette.current = SeasonRegistry.halloween;
  final text = PromptService.getTextToImagePrompts();
  final image = PromptService.getImageToImagePrompts();

  String badges(PromptItem p) => [
    p.isPremium ? 'Premium' : 'Free',
    if (p.isPopular) 'Popular',
    if (p.ownsScene) 'own scene',
  ].join(' · ');

  String sceneLine(SceneKit k) => '`${k.id}` — ${k.setting}';

  String appliedRules(PromptItem p) => p.promptType == PromptType.imageToImage
      ? 'One face sentence: "${PromptEngine.faceLock}"'
      : 'Short tail only: ", ${PromptEngine.photoTail}".';

  final b = StringBuffer()
    ..writeln('# Halloween prompt library — ready to use')
    ..writeln()
    ..writeln(
      '> Generated from the live code by `test/prompt_docs_test.dart`; do not edit by hand.',
    )
    ..writeln(
      '> Regenerate: `UPDATE_PROMPT_DOCS=1 flutter test test/prompt_docs_test.dart`.',
    )
    ..writeln()
    ..writeln('Each entry has:')
    ..writeln()
    ..writeln(
      '- **Raw prompt** — what is stored in the library and shown in the app.',
    )
    ..writeln(
      '- **Applied generation guidance** — the few words the app adds to each prompt (image prompts: one face sentence; text prompts: "realistic photo").',
    )
    ..writeln(
      '- **Ready-to-use prompt** — exactly what the app sends to the model: the raw prompt wrapped by the prompt architecture (`PromptEngine`) with the scene that fits it best. Paste this into a playground to test.',
    )
    ..writeln(
      '- **Other scenes** — alternatives the app may pick for the same prompt (it always uses the best-fitting scene; library prompts carry their own place).',
    )
    ..writeln()
    ..writeln(
      'Prompts marked *own scene* describe their own place and light, so no scene is added.',
    )
    ..writeln()
    ..writeln('## Settings to use with the ready-to-use prompts')
    ..writeln()
    ..writeln('| | Text to Image | Image to Image |')
    ..writeln('|---|---|---|')
    ..writeln(
      '| Model (current) | `openai/gpt-image-2` | `openai/gpt-image-2/edit` |',
    )
    ..writeln(
      '| Settings | `aspect_ratio` 1:1, `resolution` 1K, `output_format` jpeg, `safety_tolerance` 3, web search off | `image_size` portrait_4_3, `quality` high, jpeg, safety checker on |',
    )
    ..writeln(
      '| Negative prompt | not supported (the prompt words its limits positively) | not supported |',
    )
    ..writeln('| Input | – | a clear, front-facing photo |')
    ..writeln()
    ..writeln(
      'Neither model takes a negative prompt or a strength value. Prompts are kept short on purpose, so paste the ready-to-use text as is.',
    )
    ..writeln()
    ..writeln('---')
    ..writeln()
    ..writeln('## Text to Image (${text.length})')
    ..writeln();

  for (final p in text) {
    final scenes = PromptEngine.rankedScenes(p.prompt, forFace: false);
    final built = PromptEngine.textToImage(p.prompt, scene: scenes.first);
    b
      ..writeln('### ${p.title}  `${p.id}`')
      ..writeln('*${badges(p)}* · tags: ${p.tags.join(', ')}')
      ..writeln()
      ..writeln('**In-app copy:** *${p.tagline}* — ${p.description}')
      ..writeln()
      ..writeln('**Raw prompt**')
      ..writeln()
      ..writeln('```')
      ..writeln(p.prompt)
      ..writeln('```')
      ..writeln()
      ..writeln('**Applied generation guidance:** ${appliedRules(p)}')
      ..writeln()
      ..writeln('**Ready-to-use prompt** (${built.prompt.length} chars)')
      ..writeln()
      ..writeln('```')
      ..writeln(built.prompt)
      ..writeln('```');
    if (!p.ownsScene && scenes.length > 1) {
      b
        ..writeln()
        ..writeln('**Other scenes the app may pick:**');
      for (final k in scenes.skip(1).take(4)) {
        b.writeln('- ${sceneLine(k)}');
      }
    }
    b.writeln();
  }

  b
    ..writeln('---')
    ..writeln()
    ..writeln('## Image to Image (${image.length})')
    ..writeln()
    ..writeln(
      'Use with a photo of a person. The identity-lock and natural-blending instructions are already inside the ready-to-use prompt.',
    )
    ..writeln();

  for (final p in image) {
    final scenes = PromptEngine.rankedScenes(p.prompt, forFace: true);
    final built = PromptEngine.imageToImage(p.prompt, scene: scenes.first);
    b
      ..writeln('### ${p.title}  `${p.id}`')
      ..writeln('*${badges(p)}* · tags: ${p.tags.join(', ')}')
      ..writeln()
      ..writeln('**In-app copy:** *${p.tagline}* — ${p.description}')
      ..writeln()
      ..writeln('**Raw prompt**')
      ..writeln()
      ..writeln('```')
      ..writeln(p.prompt)
      ..writeln('```')
      ..writeln()
      ..writeln('**Applied generation guidance:** ${appliedRules(p)}')
      ..writeln()
      ..writeln('**Ready-to-use prompt** (${built.prompt.length} chars)')
      ..writeln()
      ..writeln('```')
      ..writeln(built.prompt)
      ..writeln('```');
    if (!p.ownsScene && scenes.length > 1) {
      b
        ..writeln()
        ..writeln('**Other scenes the app may pick:**');
      for (final k in scenes.skip(1).take(4)) {
        b.writeln('- ${sceneLine(k)}');
      }
    }
    b.writeln();
  }
  return b.toString();
}

void main() {
  test('docs/PROMPT_LIBRARY.md is up to date', () {
    final generated = _generate();
    final file = File(_path);
    final update = Platform.environment['UPDATE_PROMPT_DOCS'] == '1';

    if (update || !file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(generated);
      return;
    }
    expect(
      file.readAsStringSync(),
      generated,
      reason:
          'Prompt library docs are stale. Regenerate with '
          'UPDATE_PROMPT_DOCS=1 flutter test test/prompt_docs_test.dart',
    );
  });

  test('every library prompt appears in the docs with a ready-to-use form', () {
    final doc = _generate();
    for (final p in [
      ...PromptService.getTextToImagePrompts(),
      ...PromptService.getImageToImagePrompts(),
    ]) {
      expect(doc, contains('`${p.id}`'), reason: p.id);
      expect(
        doc,
        contains(p.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '')),
        reason: p.id,
      );
    }
    expect(doc, contains('Moonlit Witch'));
  });
}
