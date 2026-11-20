import 'dart:io';

import '../models.dart';
import '../seasons.dart';
import 'trend_source.dart';

/// Hand-curated concepts you noticed on platforms without a public API
/// (TikTok, Pinterest, Instagram). File: `seeds/<season>.txt`, one per line:
///
///   concept text | optional note | optional source URL
///
/// Lines starting with # are comments. Seeds are trusted and score high, so
/// they always reach the concept stage.
class SeedFileSource implements TrendSource {
  SeedFileSource({this.directory = 'seeds'});

  final String directory;

  @override
  String get name => 'seed';

  @override
  Future<List<TrendSignal>> fetch(
    SeasonSpec season, {
    required int windowDays,
  }) async {
    final f = File('$directory/${season.id}.txt');
    if (!f.existsSync()) return const [];
    return parse(f.readAsStringSync());
  }

  /// Exposed for tests.
  static List<TrendSignal> parse(String content) {
    final out = <TrendSignal>[];
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('|').map((p) => p.trim()).toList();
      out.add(
        TrendSignal(
          source: 'seed',
          title: parts[0],
          url: parts.length > 2 ? parts[2] : '',
          rawEngagement: 1,
          publishedAt: DateTime.now(),
          trusted: true,
          note: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        ),
      );
    }
    return out;
  }
}
