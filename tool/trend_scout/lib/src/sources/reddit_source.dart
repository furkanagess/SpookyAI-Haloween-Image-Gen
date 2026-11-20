import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import '../seasons.dart';
import 'trend_source.dart';

/// Reddit via the official OAuth API (anonymous `.json` listings now return
/// 403). Needs a free "script" app: REDDIT_CLIENT_ID + REDDIT_CLIENT_SECRET
/// (https://www.reddit.com/prefs/apps). Uses the client-credentials grant,
/// so no user login is involved.
///
/// Two passes:
///  * season communities (r/halloween …) — top posts of the window, trusted;
///  * AI-art communities — search for the season's queries, untrusted (they
///    still have to pass the keyword relevance filter).
class RedditSource implements TrendSource {
  RedditSource({
    required this.clientId,
    required this.clientSecret,
    http.Client? client,
    this.perListing = 40,
  }) : _client = client ?? http.Client();

  final String clientId;
  final String clientSecret;
  final http.Client _client;
  final int perListing;

  static const _ua = 'macos:spookyai-trend-scout:0.1 (developer tooling)';

  @override
  String get name => 'reddit';

  @override
  Future<List<TrendSignal>> fetch(
    SeasonSpec season, {
    required int windowDays,
  }) async {
    final token = await _token();
    final t = windowDays <= 7
        ? 'week'
        : windowDays <= 31
        ? 'month'
        : 'year';
    final out = <TrendSignal>[];
    final failures = <String>[];

    for (final sub in season.communitySubreddits) {
      final uri = Uri.https('oauth.reddit.com', '/r/$sub/top', {
        't': t,
        'limit': '$perListing',
        'raw_json': '1',
      });
      await _collect(
        uri,
        token,
        'reddit:r/$sub',
        trusted: true,
        into: out,
        failures: failures,
      );
    }

    for (final sub in SeasonSpec.aiArtSubreddits) {
      for (final q in season.aiArtQueries) {
        final uri = Uri.https('oauth.reddit.com', '/r/$sub/search', {
          'q': q,
          'restrict_sr': '1',
          'sort': 'top',
          't': t,
          'limit': '$perListing',
          'raw_json': '1',
        });
        await _collect(
          uri,
          token,
          'reddit:r/$sub',
          trusted: false,
          into: out,
          failures: failures,
        );
      }
    }

    if (out.isEmpty && failures.isNotEmpty) {
      throw SourceException(name, 'all listings failed: ${failures.first}');
    }
    return out;
  }

  Future<String> _token() async {
    final res = await _client
        .post(
          Uri.https('www.reddit.com', '/api/v1/access_token'),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
            'User-Agent': _ua,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: 'grant_type=client_credentials',
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw SourceException(
        name,
        'auth ${res.statusCode}: check REDDIT_CLIENT_ID/SECRET',
      );
    }
    final tok = jsonDecode(res.body)['access_token'] as String?;
    if (tok == null) throw SourceException(name, 'auth response had no token');
    return tok;
  }

  Future<void> _collect(
    Uri uri,
    String token,
    String label, {
    required bool trusted,
    required List<TrendSignal> into,
    required List<String> failures,
  }) async {
    try {
      final res = await _client
          .get(
            uri,
            headers: {'Authorization': 'Bearer $token', 'User-Agent': _ua},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        failures.add('${uri.path} → ${res.statusCode}');
        return;
      }
      into.addAll(parseListing(res.body, label, trusted: trusted));
    } catch (e) {
      failures.add('${uri.path} → $e');
    }
  }

  /// Exposed for tests.
  static List<TrendSignal> parseListing(
    String body,
    String label, {
    required bool trusted,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final children = (json['data']?['children'] as List?) ?? const [];
    final out = <TrendSignal>[];
    for (final c in children) {
      final d = (c as Map)['data'] as Map<String, dynamic>;
      if (d['over_18'] == true) continue; // never ingest NSFW listings
      final title = (d['title'] as String?)?.trim();
      if (title == null || title.isEmpty) continue;
      final ups = (d['ups'] as num?)?.toDouble() ?? 0;
      final comments = (d['num_comments'] as num?)?.toDouble() ?? 0;
      final created = (d['created_utc'] as num?)?.toDouble();
      out.add(
        TrendSignal(
          source: label,
          title: title,
          url: 'https://www.reddit.com${d['permalink'] ?? ''}',
          rawEngagement: ups + comments * 2,
          publishedAt: created == null
              ? DateTime.now()
              : DateTime.fromMillisecondsSinceEpoch(
                  (created * 1000).round(),
                  isUtc: true,
                ),
          trusted: trusted,
        ),
      );
    }
    return out;
  }
}
