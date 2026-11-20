import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin raw-HTTP client for the Claude Messages API (Dart has no official
/// Anthropic SDK). One structured-output call per scout run.
class ClaudeClient {
  ClaudeClient(
    this.apiKey, {
    http.Client? client,
    this.model = 'claude-opus-5-5',
    this.effort = 'medium',
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final String model;
  final String effort;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  /// Sends [system] + [user] and returns the JSON object Claude produced
  /// under [schema] (structured outputs, `output_config.format`).
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    int maxTokens = 16000,
  }) async {
    final body = {
      'model': model,
      'max_tokens': maxTokens,
      // Opus 5.5: thinking is always on; depth is controlled by effort.
      'output_config': {
        'effort': effort,
        'format': {'type': 'json_schema', 'schema': schema},
      },
      // Route refusals to a fallback model server-side instead of failing.
      'fallbacks': 'default',
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
    };

    final res = await _client
        .post(
          _endpoint,
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2026-10-21',
            'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 5));

    if (res.statusCode != 200) {
      throw ClaudeException('HTTP ${res.statusCode}: ${_short(res.body)}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['stop_reason'] == 'refusal') {
      throw ClaudeException(
        'request refused (${json['stop_details']?['category'] ?? 'unknown'})',
      );
    }
    if (json['stop_reason'] == 'max_tokens') {
      throw ClaudeException('output truncated at max_tokens=$maxTokens');
    }
    final text = (json['content'] as List)
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      throw ClaudeException('response was not valid JSON: ${_short(text)}');
    }
  }

  static String _short(String s) =>
      s.length > 300 ? '${s.substring(0, 300)}…' : s;
}

class ClaudeException implements Exception {
  ClaudeException(this.message);
  final String message;
  @override
  String toString() => 'ClaudeException: $message';
}
