/// One piece of evidence that something is trending.
class TrendSignal {
  TrendSignal({
    required this.source,
    required this.title,
    required this.url,
    required this.rawEngagement,
    required this.publishedAt,
    this.trusted = false,
    this.note,
  });

  final String source; // reddit:r/sub, youtube, google-trends, seed
  final String title;
  final String url;

  /// Source-native engagement (upvotes, views, approx traffic, …).
  final double rawEngagement;
  final DateTime publishedAt;

  /// Seeds and season-specific communities skip the relevance filter.
  final bool trusted;
  final String? note;

  /// Filled by the scorer: 0..1, comparable across sources.
  double score = 0;

  Map<String, dynamic> toJson() => {
    'source': source,
    'title': title,
    'url': url,
    'raw_engagement': rawEngagement,
    'published_at': publishedAt.toIso8601String(),
    'score': double.parse(score.toStringAsFixed(3)),
    if (note != null) 'note': note,
  };
}

/// A cluster of signals that describe one visual idea.
class TrendConcept {
  TrendConcept({
    required this.name,
    required this.keywords,
    required this.strength,
    required this.evidence,
    this.whyTrending,
  });

  final String name;
  final List<String> keywords;

  /// Sum of evidence scores, normalized later to 0..100.
  double strength;
  final List<TrendSignal> evidence;
  final String? whyTrending;

  Set<String> get sources => evidence.map((e) => e.source).toSet();

  Map<String, dynamic> toJson() => {
    'name': name,
    'keywords': keywords,
    'strength': double.parse(strength.toStringAsFixed(1)),
    if (whyTrending != null) 'why_trending': whyTrending,
    'sources': sources.toList(),
    'evidence': evidence.take(5).map((e) => e.toJson()).toList(),
  };
}

enum PromptMode { text, image }

/// A ready-to-review prompt for the app's library.
class PromptCandidate {
  PromptCandidate({
    required this.id,
    required this.title,
    required this.mode,
    required this.prompt,
    required this.tags,
    required this.concept,
    required this.trendScore,
    required this.origin, // 'llm' | 'template'
    List<String>? warnings,
  }) : warnings = warnings ?? [];

  final String id;
  final String title;
  final PromptMode mode;
  final String prompt;
  final List<String> tags;
  final String concept;
  final double trendScore;
  final String origin;
  final List<String> warnings;
  String? blockedReason;

  bool get blocked => blockedReason != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mode': mode.name,
    'prompt': prompt,
    'tags': tags,
    'concept': concept,
    'trend_score': double.parse(trendScore.toStringAsFixed(1)),
    'origin': origin,
    if (warnings.isNotEmpty) 'warnings': warnings,
    if (blockedReason != null) 'blocked_reason': blockedReason,
  };
}

class ScoutReport {
  ScoutReport({
    required this.season,
    required this.generatedAt,
    required this.windowDays,
    required this.sourcesUsed,
    required this.sourceErrors,
    required this.signals,
    required this.concepts,
    required this.candidates,
    required this.llmUsed,
    required this.llmModel,
  });

  final String season;
  final DateTime generatedAt;
  final int windowDays;
  final List<String> sourcesUsed;
  final Map<String, String> sourceErrors;
  final List<TrendSignal> signals;
  final List<TrendConcept> concepts;
  final List<PromptCandidate> candidates;
  final bool llmUsed;
  final String? llmModel;

  List<PromptCandidate> get approved =>
      candidates.where((c) => !c.blocked).toList();
  List<PromptCandidate> get blocked =>
      candidates.where((c) => c.blocked).toList();

  Map<String, dynamic> toJson() => {
    'season': season,
    'generated_at': generatedAt.toIso8601String(),
    'window_days': windowDays,
    'sources_used': sourcesUsed,
    'source_errors': sourceErrors,
    'llm_used': llmUsed,
    if (llmModel != null) 'llm_model': llmModel,
    'stats': {
      'signals': signals.length,
      'concepts': concepts.length,
      'candidates_total': candidates.length,
      'candidates_text': approved
          .where((c) => c.mode == PromptMode.text)
          .length,
      'candidates_image': approved
          .where((c) => c.mode == PromptMode.image)
          .length,
      'candidates_blocked': blocked.length,
    },
    'concepts': concepts.map((c) => c.toJson()).toList(),
    'candidates': candidates.map((c) => c.toJson()).toList(),
    'signals_top': signals.take(60).map((s) => s.toJson()).toList(),
  };
}
