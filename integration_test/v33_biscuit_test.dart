// Marketing asset generator for V33 (docs/marketing/V33_BISCUIT_RUYA.md).
// Runs on the iOS simulator through the app's own prompt engine + fal service:
//   flutter test integration_test/v33_biscuit_test.dart \
//     -d <simulator-id> --dart-define-from-file=.env
// The simulator shares the host filesystem, so input/output use host paths.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/services/fal_ai_service.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/features/home/data/services/prompt_service.dart';

const _root = String.fromEnvironment('V33_ROOT');

class _Scene {
  final String id, style, note, motion;
  const _Scene(this.id, this.style, this.note, this.motion);
}

const _scenes = [
  _Scene('s1', 'By the Fireplace',
      'Keep the same dog and red collar; curled up asleep on a rug, eyes closed.',
      "The sleeping dog's paws twitch softly, fire flickers, camera slowly pushes in."),
  _Scene('s2', 'Snow Globe',
      'Keep the same dog and red collar; inside the snow globe, looking around amazed.',
      'Snow swirls around the dog, it tilts its head and looks up, camera circles slowly.'),
  _Scene('s3', 'Flying Sleigh',
      'Keep the same dog; harnessed at the front, pulling the sleigh, ears flying.',
      'The sleigh flies forward over snowy rooftops, ears and scarf flutter in the wind.'),
  _Scene('s4', 'Workshop Elf',
      'Keep the same dog; small green elf hat with a golden bell, holding a tennis ball.',
      'The dog wags its tail, the bell on its hat jingles, sparks float in the workshop.'),
  _Scene('s5', 'Jolly Santa',
      'Keep the same dog and red collar; joyful, tongue out, sitting on the sleigh seat.',
      'The dog laughs with tongue out, snow falls, camera slowly pulls back.'),
  _Scene('s6', 'Christmas Morning',
      'Keep the same dog and red collar; just woke up by the tree, sleepy eyes.',
      'The dog yawns and stretches by the tree, soft morning light, static camera.'),
];

const _closeUpNote =
    'Keep the same dog; close-up, a small golden bell now hangs on its red collar.';
const _closeUpMotion =
    'The small bell on the collar swings and catches the light, slow push in.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('V33 Biscuit dream: images + clips', () async {
    expect(_root, isNotEmpty, reason: 'pass --dart-define=V33_ROOT=<repo>');
    SeasonPalette.current = SeasonRegistry.christmas;
    final out = Directory('$_root/assets/images/characters/biscuit(dog)/v33')
      ..createSync(recursive: true);
    final src = File('$_root/assets/images/characters/biscuit(dog)/biscuit.jpg')
        .readAsBytesSync();

    Future<Uint8List> image(String name, Future<FalAiResult> Function() run) async {
      final f = File('${out.path}/$name.jpg');
      if (f.existsSync()) return f.readAsBytesSync();
      final r = await run();
      final bytes = await FalAiService.fetchImageBytes(r.images.first.url);
      f.writeAsBytesSync(bytes);
      print('V33 image ok: $name');
      return bytes;
    }

    Future<void> clip(String name, Uint8List img, String motion) async {
      final f = File('${out.path}/$name.mp4');
      if (f.existsSync()) return;
      final url = await FalAiService.generateVideo(imageBytes: img, motionPrompt: motion);
      f.writeAsBytesSync(await FalAiService.downloadVideoBytes(url));
      print('V33 clip ok: $name');
    }

    final images = await Future.wait(_scenes.map((s) {
      final lib = PromptService.findByTitle(s.style)!;
      // Biscuit is the hero and is alone in every scene: no invented person.
      final style = lib.copyWith(
          prompt: lib.prompt.replaceAll('the person', 'the golden retriever'));
      final built = PromptEngine.imageToImage(s.note, style: style);
      return image(s.id, () => FalAiService.generateImageFromImage(
            prompt: built.prompt, imageBytes: src));
    }));
    final s7 = await image('s7', () => FalAiService.generateImageFromImage(
          prompt: PromptEngine.editImage(_closeUpNote).prompt,
          imageBytes: images[5]));

    await Future.wait([
      for (var i = 0; i < _scenes.length; i++)
        clip(_scenes[i].id, images[i], _scenes[i].motion),
      clip('s7', s7, _closeUpMotion),
    ]);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
