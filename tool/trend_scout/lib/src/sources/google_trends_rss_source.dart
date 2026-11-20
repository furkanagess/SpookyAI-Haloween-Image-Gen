import 'package:http/http.dart' as http;

import '../models.dart';
import '../seasons.dart';
import 'trend_source.dart';

/// Google Trends "trending now" public RSS feed (no key). Mostly news, so
/// almost everything is dropped by the seasonal relevance filter — but when
/// a seasonal query spikes it shows up here first.
class GoogleTrendsRssSource implements TrendSource {
  GoogleTrendsRssSource({http.Client? client, this.geos = const ['US', 'TR']})
    : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> geos;

  @override
  String get name => 'google-trends';

  @override
  Future<List<TrendSignal>> fetch(
    SeasonSpec season, {
    required int windowDays,
  }) async {
    final out = <TrendSignal>[];
    var failures = 0;
    for (final geo in geos) {
      try {
        final res = await _client
            .get(Uri.https('trends.google.com', '/trending/rss', {'geo': geo}))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) {
          failures++;
          continue;
        }
        out.addAll(parseRss(res.body, geo));
      } catch (_) {
        failures++;
      }
    }
    if (out.isEmpty && failures == geos.length) {
      throw SourceException(name, 'feed unavailable');
    }
    return out;
  }

  static final _item = RegExp(r'<item>(.*?)</item>', dotAll: true);
  static final _title = RegExp(
    r'<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>',
    dotAll: true,
  );
  static final _traffic = RegExp(
    r'<ht:approx_traffic>(.*?)</ht:approx_traffic>',
  );
  static final _link = RegExp(r'<link>(.*?)</link>');
  static final _date = RegExp(r'<pubDate>(.*?)</pubDate>');

  /// Exposed for tests.
  static List<TrendSignal> parseRss(String xml, String geo) {
    final out = <TrendSignal>[];
    for (final m in _item.allMatches(xml)) {
      final block = m.group(1)!;
      final title = _title.firstMatch(block)?.group(1)?.trim();
      if (title == null || title.isEmpty) continue;
      final trafficText = _traffic
          .firstMatch(block)
          ?.group(1)
          ?.replaceAll(RegExp(r'[^0-9]'), '');
      out.add(
        TrendSignal(
          source: 'google-trends:$geo',
          title: title,
          url: _link.firstMatch(block)?.group(1)?.trim() ?? '',
          rawEngagement: double.tryParse(trafficText ?? '') ?? 0,
          publishedAt:
              _parseRfc822(_date.firstMatch(block)?.group(1)) ?? DateTime.now(),
        ),
      );
    }
    return out;
  }

  static DateTime? _parseRfc822(String? s) {
    if (s == null) return null;
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4})').firstMatch(s);
    if (m == null) return null;
    final mo = months[m.group(2)];
    if (mo == null) return null;
    return DateTime.utc(int.parse(m.group(3)!), mo, int.parse(m.group(1)!));
  }
}
