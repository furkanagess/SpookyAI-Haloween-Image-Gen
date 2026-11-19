import 'dart:math' as math;

import '../models.dart';
import '../seasons.dart';

/// Turns heterogeneous engagement numbers into one comparable 0..1 score.
///
/// score = engagement (log-scaled, normalized per source)
///       × recency (linear decay over the window, floor 0.35)
///       × relevance boost (keyword hits; trusted sources skip the filter)
class SignalScorer {
  const SignalScorer({this.now});

  final DateTime? now;

  List<TrendSignal> score(
    List<TrendSignal> signals,
    SeasonSpec season, {
    required int windowDays,
  }) {
    final t0 = now ?? DateTime.now();

    // Relevance filter.
    final kept = signals
        .where(
          (s) => s.trusted || season.isRelevant('${s.title} ${s.note ?? ''}'),
        )
        .toList();

    // Per-source log-normalization so 2M YouTube views and 900 upvotes
    // can live on one scale.
    final maxBySource = <String, double>{};
    for (final s in kept) {
      final key = s.source.split(':').first;
      final v = math.log(1 + s.rawEngagement);
      if (v > (maxBySource[key] ?? 0)) maxBySource[key] = v;
    }

    for (final s in kept) {
      final key = s.source.split(':').first;
      final max = maxBySource[key] ?? 1;
      final engagement = key == 'seed'
          ? 0.9
          : max == 0
          ? 0.5
          : math.log(1 + s.rawEngagement) / max;

      final ageDays = t0.difference(s.publishedAt).inHours / 24;
      final recency = ageDays <= 0
          ? 1.0
          : math.max(0.35, 1 - ageDays / math.max(1, windowDays));

      final hits = season.keywords
          .where((k) => s.title.toLowerCase().contains(k.toLowerCase()))
          .length;
      final relevance = 1 + math.min(hits, 3) * 0.15;

      s.score = (engagement * recency * relevance).clamp(0.0, 1.0);
    }

    // Dedupe by normalized title, keep the best.
    final best = <String, TrendSignal>{};
    for (final s in kept) {
      final k = _norm(s.title);
      if (!best.containsKey(k) || best[k]!.score < s.score) best[k] = s;
    }
    final out = best.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
