import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spooky_ai/core/config/environment_config.dart';
import 'package:spooky_ai/core/services/fal_ai_service.dart';

void main() {
  tearDown(() {
    dotenv.testLoad(fileInput: '');
    FalAiService.httpClient = http.Client();
    FalAiService.pollInterval = const Duration(milliseconds: 1500);
  });

  group('no secret in the repository', () {
    test('no fal key pattern anywhere in lib/, test/ or tool/', () {
      final keyPattern = RegExp(
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:[0-9a-f]{32}',
      );
      final hits = <String>[];
      for (final root in ['lib', 'test', 'tool']) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;
        for (final f in dir.listSync(recursive: true).whereType<File>()) {
          final p = f.path;
          if (p.contains('.dart_tool') || p.contains('/output/')) continue;
          if (!(p.endsWith('.dart') ||
              p.endsWith('.js') ||
              p.endsWith('.md') ||
              p.endsWith('.json') ||
              p.endsWith('.toml') ||
              p.endsWith('.yaml'))) {
            continue;
          }
          if (keyPattern.hasMatch(f.readAsStringSync())) hits.add(p);
        }
      }
      expect(hits, isEmpty, reason: 'hard-coded key found in $hits');
    });

    test('.env is no longer bundled as an asset', () {
      expect(
        File('pubspec.yaml').readAsStringSync().contains(
          RegExp(r'^\s*-\s*\.env\s*$', multiLine: true),
        ),
        isFalse,
      );
    });
  });

  group('configuration resolution', () {
    test('nothing configured → unavailable, with an actionable error', () {
      dotenv.testLoad(fileInput: '');
      expect(EnvironmentConfig.isFalAiKeyAvailable, isFalse);
      expect(EnvironmentConfig.falAiApiKey, isNull);
      expect(EnvironmentConfig.getMissingApiKeys(), isNotEmpty);
      expect(() => EnvironmentConfig.falAuthHeaders(), throwsStateError);
    });

    test('direct key (dev): Authorization header and queue.fal.run', () {
      dotenv.testLoad(fileInput: 'FAL_AI_API_KEY=dev-key');
      expect(EnvironmentConfig.usesFalProxy, isFalse);
      expect(EnvironmentConfig.falQueueBase, 'https://queue.fal.run');
      expect(EnvironmentConfig.falAuthHeaders(), {
        'Authorization': 'Key dev-key',
      });
    });

    test('proxy mode: no fal key is sent, base is the proxy', () {
      dotenv.testLoad(
        fileInput:
            'FAL_PROXY_URL=https://proxy.example.com/\nFAL_PROXY_TOKEN=tok\nFAL_AI_API_KEY=ignored',
      );
      expect(EnvironmentConfig.usesFalProxy, isTrue);
      expect(EnvironmentConfig.falQueueBase, 'https://proxy.example.com');
      expect(EnvironmentConfig.falAuthHeaders(), {'X-App-Token': 'tok'});
      expect(
        EnvironmentConfig.falAuthHeaders().containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('service uses the active mode', () {
    test('requests go to the proxy and never carry a fal key', () async {
      dotenv.testLoad(
        fileInput:
            'FAL_PROXY_URL=https://proxy.example.com\nFAL_PROXY_TOKEN=tok',
      );
      FalAiService.pollInterval = Duration.zero;
      final seen = <http.Request>[];
      FalAiService.httpClient = MockClient((req) async {
        seen.add(req);
        if (req.method == 'POST') {
          return http.Response(jsonEncode({'request_id': 'r1'}), 200);
        }
        if (req.url.path.endsWith('/status')) {
          return http.Response(jsonEncode({'status': 'COMPLETED'}), 200);
        }
        return http.Response(
          jsonEncode({
            'images': [
              {'url': 'https://v3b.fal.media/x.jpg'},
            ],
          }),
          200,
        );
      });
      final r = await FalAiService.generateImage(prompt: 'a friendly ghost');
      expect(r.images, isNotEmpty);
      for (final req in seen) {
        expect(req.url.host, 'proxy.example.com');
        expect(req.headers['X-App-Token'], 'tok');
        expect(req.headers.containsKey('Authorization'), isFalse);
      }
    });

    test(
      'without configuration the user sees "service unavailable" copy',
      () async {
        dotenv.testLoad(fileInput: '');
        await expectLater(
          FalAiService.generateImage(prompt: 'a friendly ghost'),
          throwsA(
            isA<FalAiException>().having(
              (e) => e.message,
              'message',
              contains('FAL_AI_API_KEY'),
            ),
          ),
        );
      },
    );
  });
}
