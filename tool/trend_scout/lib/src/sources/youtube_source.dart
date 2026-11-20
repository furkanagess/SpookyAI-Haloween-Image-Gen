import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import '../seasons.dart';
import 'trend_source.dart';

/// YouTube Data API v3 (official; needs YOUTUBE_API_KEY, free quota).
/// Searches recent videos per season query, then reads view counts.
class YouTubeSource implements TrendSource {
  YouTubeSource(this.apiKey, {http.Client? client, this.perQuery = 25})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final int perQuery;

  @override
  String get name => 'youtube';

  @override
  Future<List<TrendSignal>> fetch(
    SeasonSpec season, {
    required int windowDays,
  }) async {
    final since = DateTime.now().toUtc().subtract(Duration(days: windowDays));
    final out = <TrendSignal>[];
    for (final q in season.youtubeQueries) {
      final search = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': q,
        'type': 'video',
        'order': 'viewCount',
        'publishedAfter': since.toIso8601String(),
        'maxResults': '$perQuery',
        'key': apiKey,
      });
      final res = await _client
          .get(search)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw SourceException(
          name,
          'search ${res.statusCode}: ${_short(res.body)}',
        );
      }
      final items = (jsonDecode(res.body)['items'] as List?) ?? const [];
      final ids = <String, Map<String, dynamic>>{};
      for (final it in items) {
        final id = it['id']?['videoId'] as String?;
        if (id != null) ids[id] = it['snippet'] as Map<String, dynamic>;
      }
      if (ids.isEmpty) continue;

      final stats = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
        'part': 'statistics',
        'id': ids.keys.join(','),
        'key': apiKey,
      });
      final sres = await _client
          .get(stats)
          .timeout(const Duration(seconds: 20));
      final views = <String, double>{};
      if (sres.statusCode == 200) {
        for (final v in (jsonDecode(sres.body)['items'] as List?) ?? const []) {
          views[v['id'] as String] =
              double.tryParse('${v['statistics']?['viewCount'] ?? 0}') ?? 0;
        }
      }
      ids.forEach((id, sn) {
        out.add(
          TrendSignal(
            source: 'youtube',
            title: (sn['title'] as String).trim(),
            url: 'https://www.youtube.com/watch?v=$id',
            rawEngagement: views[id] ?? 0,
            publishedAt:
                DateTime.tryParse(sn['publishedAt'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      });
    }
    return out;
  }

  static String _short(String s) =>
      s.length > 160 ? '${s.substring(0, 160)}…' : s;
}
