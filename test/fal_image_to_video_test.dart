import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spooky_ai/core/services/fal_ai_service.dart';
import 'package:spooky_ai/core/services/token_costs.dart';

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'FAL_AI_API_KEY=test-key'));

  test('prices: 1 / 2 / 10 tokens', () {
    expect(TokenCosts.textToImage, 1.0);
    expect(TokenCosts.imageToImage, 2.0);
    expect(TokenCosts.imageToVideo, 10.0);
  });

  test('video body is fixed length/resolution with safety on', () {
    final b = FalAiService.buildImageToVideoBody(
      imageDataUri: 'data:image/png;base64,AA==',
      prompt: 'p',
    );
    expect(b['duration'], FalAiService.videoSeconds);
    expect(b['resolution'], FalAiService.videoResolution);
    expect(b['enable_safety_checker'], true);
    expect(b['image_url'], 'data:image/png;base64,AA==');
  });

  test('generateVideo submits, polls and returns the video url', () async {
    FalAiService.pollInterval = Duration.zero;
    final old = FalAiService.httpClient;
    addTearDown(() => FalAiService.httpClient = old);
    FalAiService.httpClient = MockClient((req) async {
      if (req.method == 'POST') {
        expect(req.url.path, contains('minimax/h3-max/image-to-video'));
        return http.Response(
          jsonEncode({
            'request_id': 'abcd1234-0000',
            'status_url': 'https://q/status',
            'response_url': 'https://q/result',
          }),
          200,
        );
      }
      if (req.url.path.endsWith('status')) {
        return http.Response(jsonEncode({'status': 'COMPLETED'}), 200);
      }
      return http.Response(
        jsonEncode({
          'video': {'url': 'https://cdn/v.mp4'},
        }),
        200,
      );
    });
    final url = await FalAiService.generateVideo(
      imageBytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]),
    );
    expect(url, 'https://cdn/v.mp4');
  });

  test('video prompt is short and uses quality prompt expansion', () {
    expect(
      FalAiService.buildVideoPrompt('she turns and smiles.'),
      'Action: she turns and smiles. Keep the same face, natural and true to the photo, '
      'and keep the scene, lighting and setting from the image. '
      'No speech, voiceover or narration; ambient sound only.',
    );
    expect(FalAiService.buildVideoPrompt(''), contains('No speech'));
    expect(
      FalAiService.buildVideoPrompt(''),
      startsWith('Subtle, natural motion.'),
    );
    final b = FalAiService.buildImageToVideoBody(
      imageDataUri: 'x',
      prompt: 'p',
    );
    expect(b['prompt_expansion_mode'], 'quality');
  });
}
