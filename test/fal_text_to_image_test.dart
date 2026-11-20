import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/core/services/fal_ai_service.dart';

void main() {
  setUpAll(() {
    // A placeholder key is enough: every request goes to the mock client.
    dotenv.testLoad(fileInput: 'FAL_AI_API_KEY=test-key');
  });

  tearDown(() {
    FalAiService.httpClient = http.Client();
    FalAiService.pollInterval = const Duration(milliseconds: 1500);
  });

  group('request body', () {
    test('uses the GPT Image 2 contract: medium, 512x512, one image', () {
      final b = FalAiService.buildTextToImageBody(
        prompt: 'a ghost with a lantern',
      );
      expect(b['prompt'], 'a ghost with a lantern');
      expect(b['image_size'], 'square'); // fal preset: 512x512
      expect(b['quality'], 'medium');
      expect(b['num_images'], 1);
      expect(b['output_format'], 'jpeg');
      expect(b['output_compression'], 90);
      expect(b['background'], 'opaque');
      expect(b['enable_safety_checker'], true);
      // Nano Banana Pro fields must be gone.
      for (final k in [
        'aspect_ratio',
        'resolution',
        'safety_tolerance',
        'enable_web_search',
        'limit_generations',
      ]) {
        expect(b.containsKey(k), isFalse, reason: k);
      }
    });

    test('image to image uses the same size and quality', () {
      expect(FalAiService.imageSize, 'square');
      expect(FalAiService.imageQuality, 'medium');
    });

    test('invalid output format falls back to jpeg', () {
      expect(
        FalAiService.buildTextToImageBody(
          prompt: 'abc',
          outputFormat: 'gif',
        )['output_format'],
        'jpeg',
      );
    });
  });

  group('queue flow', () {
    String url(String tail) => 'https://queue.fal.run/openai/gpt-image-2$tail';

    test('submit → poll → fetch result → image', () async {
      FalAiService.pollInterval = Duration.zero;
      final calls = <String>[];
      var statusCalls = 0;
      FalAiService.httpClient = MockClient((req) async {
        calls.add('${req.method} ${req.url}');
        if (req.method == 'POST') {
          expect(req.headers['Authorization'], startsWith('Key '));
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['prompt'], contains('pumpkin'));
          return http.Response(
            jsonEncode({
              'request_id': 'r1',
              'status_url': url('/requests/r1/status'),
              'response_url': url('/requests/r1'),
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/status')) {
          statusCalls++;
          return http.Response(
            jsonEncode({
              'status': statusCalls < 3 ? 'IN_PROGRESS' : 'COMPLETED',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'images': [
              {
                'url': 'https://v3b.fal.media/files/x.jpg',
                'content_type': 'image/jpeg',
              },
            ],
            'description': 'thoughts',
          }),
          200,
        );
      });

      final r = await FalAiService.generateImage(
        prompt: 'a pumpkin king on a throne',
      );
      expect(r.images.single.url, 'https://v3b.fal.media/files/x.jpg');
      expect(statusCalls, 3);
      expect(calls.first, startsWith('POST'));
      expect(calls.last, 'GET ${url('/requests/r1')}');
    });

    test('empty image list means the safety system declined', () async {
      FalAiService.pollInterval = Duration.zero;
      FalAiService.httpClient = MockClient((req) async {
        if (req.method == 'POST') {
          return http.Response(jsonEncode({'request_id': 'r2'}), 200);
        }
        if (req.url.path.endsWith('/status')) {
          return http.Response(jsonEncode({'status': 'COMPLETED'}), 200);
        }
        return http.Response(
          jsonEncode({'images': [], 'description': 'blocked'}),
          200,
        );
      });
      await expectLater(
        FalAiService.generateImage(prompt: 'something spooky'),
        throwsA(
          isA<FalAiException>().having(
            (e) => e.message,
            'message',
            contains('safety system'),
          ),
        ),
      );
      // …and the user sees the "didn't pass our safety check" sheet, not a crash.
      final issue = GenerationFailure.classify(
        'FalAiException: Generation returned no image (filtered by the safety system)',
      );
      expect(issue!.kind, PromptIssueKind.serverFiltered);
    });

    test('HTTP errors surface their status code for classification', () async {
      FalAiService.httpClient = MockClient(
        (_) async => http.Response('{"detail":"rate limit"}', 429),
      );
      await expectLater(
        FalAiService.generateImage(prompt: 'a witch'),
        throwsA(
          isA<FalAiException>().having(
            (e) => e.message,
            'message',
            contains('429'),
          ),
        ),
      );
      expect(
        GenerationFailure.classify(
          'Failed to submit generation: 429 - rate limit',
        )!.kind,
        PromptIssueKind.busy,
      );
    });

    test('FAILED status is reported', () async {
      FalAiService.pollInterval = Duration.zero;
      FalAiService.httpClient = MockClient((req) async {
        if (req.method == 'POST')
          return http.Response(jsonEncode({'request_id': 'r3'}), 200);
        return http.Response(
          jsonEncode({'status': 'FAILED', 'error': 'boom'}),
          200,
        );
      });
      await expectLater(
        FalAiService.generateImage(prompt: 'a witch'),
        throwsA(
          isA<FalAiException>().having(
            (e) => e.message,
            'message',
            contains('failed'),
          ),
        ),
      );
    });

    test('cancellation stops polling', () async {
      FalAiService.pollInterval = Duration.zero;
      FalAiService.httpClient = MockClient((req) async {
        if (req.method == 'POST')
          return http.Response(jsonEncode({'request_id': 'r4'}), 200);
        return http.Response(jsonEncode({'status': 'IN_PROGRESS'}), 200);
      });
      var n = 0;
      await expectLater(
        FalAiService.generateImage(
          prompt: 'a witch',
          isCancelled: () => ++n > 2,
        ),
        throwsA(
          isA<FalAiException>().having(
            (e) => e.message,
            'message',
            contains('cancelled'),
          ),
        ),
      );
    });

    test('too short prompt is rejected before any request', () async {
      FalAiService.httpClient = MockClient(
        (_) async => fail('no request expected'),
      );
      await expectLater(
        FalAiService.generateImage(prompt: 'a'),
        throwsA(isA<FalAiException>()),
      );
    });
  });

  group('image to image (GPT Image 2 edit)', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4, 5]);

    test('request body follows the contract and the cost guards', () {
      final b = FalAiService.buildImageToImageBody(
        prompt: 'the person as a witch',
        imageDataUri: 'data:image/jpeg;base64,AAAA',
      );
      expect(b['image_urls'], ['data:image/jpeg;base64,AAAA']);
      expect(b['image_size'], 'square');
      expect(b['quality'], 'medium');
      expect(b['num_images'], 1);
      expect(b['output_format'], 'jpeg');
      expect(b['output_compression'], 90);
      expect(b['background'], 'opaque');
      expect(b['enable_safety_checker'], true);
      // Old scene-composition fields are gone.
      for (final k in [
        'image_url',
        'strength',
        'num_inference_steps',
        'guidance_scale',
        'negative_prompt',
      ]) {
        expect(b.containsKey(k), isFalse, reason: k);
      }
    });

    test('invalid size or quality fall back to safe defaults', () {
      final b = FalAiService.buildImageToImageBody(
        prompt: 'x',
        imageDataUri: 'd',
        imageSize: 'custom_9000',
        quality: 'ultra',
        outputFormat: 'png',
      );
      expect(b['image_size'], 'square');
      expect(b['quality'], 'medium');
      expect(b.containsKey('output_compression'), isFalse); // png
      expect(
        FalAiService.buildImageToImageBody(
          prompt: 'x',
          imageDataUri: 'd',
          quality: 'low',
        )['quality'],
        'low',
      );
    });

    test(
      'sends the photo as a data URI to the right endpoint and returns the image',
      () async {
        FalAiService.pollInterval = Duration.zero;
        Map<String, dynamic>? sent;
        final urls = <String>[];
        FalAiService.httpClient = MockClient((req) async {
          urls.add('${req.method} ${req.url.path}');
          if (req.method == 'POST') {
            sent = jsonDecode(req.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({'request_id': 'i1'}), 200);
          }
          if (req.url.path.endsWith('/status')) {
            return http.Response(jsonEncode({'status': 'COMPLETED'}), 200);
          }
          return http.Response(
            jsonEncode({
              'images': [
                {
                  'url': 'https://v3b.fal.media/files/o.jpg',
                  'width': 768,
                  'height': 1024,
                },
              ],
            }),
            200,
          );
        });
        final r = await FalAiService.generateImageFromImage(
          prompt: 'Transform this photo: the person as a vampire',
          imageBytes: jpeg,
        );
        expect(r.images.single.url, 'https://v3b.fal.media/files/o.jpg');
        expect(urls.first, 'POST /openai/gpt-image-2/edit');
        expect(urls.last, 'GET /openai/gpt-image-2/edit/requests/i1');
        final uri = (sent!['image_urls'] as List).single as String;
        expect(uri, startsWith('data:image/jpeg;base64,'));
        expect(sent!['prompt'], contains('vampire'));
      },
    );

    test('a declined edit surfaces as a safety filter, not a crash', () async {
      FalAiService.pollInterval = Duration.zero;
      FalAiService.httpClient = MockClient((req) async {
        if (req.method == 'POST')
          return http.Response(jsonEncode({'request_id': 'i2'}), 200);
        if (req.url.path.endsWith('/status'))
          return http.Response(jsonEncode({'status': 'COMPLETED'}), 200);
        return http.Response(jsonEncode({'images': []}), 200);
      });
      await expectLater(
        FalAiService.generateImageFromImage(prompt: 'x y z', imageBytes: jpeg),
        throwsA(
          isA<FalAiException>().having(
            (e) => e.message,
            'message',
            contains('safety system'),
          ),
        ),
      );
      expect(
        GenerationFailure.classify('submit: 400 - moderation_blocked')!.kind,
        PromptIssueKind.serverFiltered,
      );
    });
  });
}
