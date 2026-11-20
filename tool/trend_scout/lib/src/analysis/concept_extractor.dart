import '../models.dart';
import '../seasons.dart';

/// Offline concept clustering: frequent 2–3 word phrases across signal
/// titles, weighted by signal score. Used when no LLM is available and as a
/// sanity baseline next to the LLM's clusters.
class ConceptExtractor {
  const ConceptExtractor({this.maxConcepts = 20});

  final int maxConcepts;

  static const _stop = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'of',
    'to',
    'in',
    'on',
    'for',
    'with',
    'my',
    'your',
    'this',
    'that',
    'is',
    'are',
    'it',
    'at',
    'by',
    'from',
    'i',
    'we',
    'you',
    'me',
    'us',
    'our',
    'be',
    'as',
    'made',
    'using',
    'ai',
    'generated',
    'image',
    'images',
    'photo',
    'photos',
    'picture',
    'art',
    'prompt',
    'prompts',
    'oc',
    'new',
    'just',
    'some',
    'how',
    'what',
    'vs',
    'ideas',
    'idea',
    'best',
    'top',
    'video',
    'shorts',
    'tiktok',
    'trend',
    'trending',
    'viral',
    'ile',
    've',
    'bir',
    'için',
    'bu',
  };

  List<TrendConcept> extract(List<TrendSignal> signals, SeasonSpec season) {
    final seasonWords = season.nameWords.map((k) => k.toLowerCase()).toSet();
    final weight = <String, double>{};
    final evidence = <String, List<TrendSignal>>{};

    // Seeds are hand-written concepts already: keep each line whole.
    final seeds = <TrendConcept>[
      for (final s in signals.where((s) => s.source == 'seed'))
        TrendConcept(
          name: s.title.toLowerCase(),
          keywords: _tokens(s.title, seasonWords),
          strength: s.score,
          evidence: [s],
          whyTrending: s.note,
        ),
    ];

    for (final s in signals.where((s) => s.source != 'seed')) {
      final tokens = _tokens(s.title, seasonWords);
      final seen = <String>{};
      for (var n = 2; n <= 3; n++) {
        for (var i = 0; i + n <= tokens.length; i++) {
          final gram = tokens.sublist(i, i + n).join(' ');
          if (!seen.add(gram)) continue;
          weight[gram] = (weight[gram] ?? 0) + s.score + 0.05;
          (evidence[gram] ??= []).add(s);
        }
      }
    }

    // Only phrases seen in ≥2 independent signals count as a trend;
    // sparse data honestly yields fewer concepts. Ties prefer the longer
    // (more specific) phrase so "snow globe portrait" beats "globe portrait".
    final entries =
        weight.entries.where((e) => evidence[e.key]!.length >= 2).toList()
          ..sort((a, b) {
            final byWeight = b.value.compareTo(a.value);
            return byWeight != 0
                ? byWeight
                : b.key.length.compareTo(a.key.length);
          });

    // Drop grams that are substrings of a stronger gram (keep the longest).
    final picked = <String>[];
    for (final e in entries) {
      if (picked.any((p) => p.contains(e.key) || e.key.contains(p))) continue;
      picked.add(e.key);
      if (picked.length >= maxConcepts) break;
    }

    final mined = <TrendConcept>[
      for (final g in picked)
        TrendConcept(
          name: g,
          keywords: g.split(' '),
          strength: weight[g]!,
          evidence: (evidence[g]!..sort((a, b) => b.score.compareTo(a.score))),
        ),
    ];

    // Normalize everything to 0..100 on one scale, strongest first.
    final all = [...seeds, ...mined];
    if (all.isEmpty) return all;
    final maxW = all.map((c) => c.strength).reduce((a, b) => a > b ? a : b);
    for (final c in all) {
      c.strength = maxW == 0 ? 0 : c.strength / maxW * 100;
    }
    all.sort((a, b) => b.strength.compareTo(a.strength));
    return all.take(maxConcepts).toList();
  }

  static List<String> _tokens(String title, Set<String> seasonWords) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s-]'), ' ')
        .split(RegExp(r'\s+'))
        .where(
          (w) => w.length > 2 && !_stop.contains(w) && !seasonWords.contains(w),
        )
        .toList();
  }
}
