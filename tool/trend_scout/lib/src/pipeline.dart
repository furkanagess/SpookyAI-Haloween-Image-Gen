import 'analysis/concept_extractor.dart';
import 'analysis/signal_scorer.dart';
import 'generation/candidate_writer.dart';
import 'models.dart';
import 'safety/candidate_filter.dart';
import 'seasons.dart';
import 'sources/trend_source.dart';

/// collect → score → cluster → write prompts → safety → report.
class ScoutPipeline {
  ScoutPipeline({
    required this.sources,
    required this.writer,
    this.scorer = const SignalScorer(),
    this.extractor = const ConceptExtractor(),
    this.filter = const CandidateFilter(),
    this.maxConcepts = 20,
    this.log,
  });

  final List<TrendSource> sources;
  final CandidateWriter writer;
  final SignalScorer scorer;
  final ConceptExtractor extractor;
  final CandidateFilter filter;
  final int maxConcepts;
  final void Function(String)? log;

  Future<ScoutReport> run(SeasonSpec season, {required int windowDays}) async {
    final signals = <TrendSignal>[];
    final used = <String>[];
    final errors = <String, String>{};

    // 1. collect (sources run concurrently; one failing never aborts the run)
    final results = await Future.wait(
      sources.map((s) async {
        try {
          final got = await s.fetch(season, windowDays: windowDays);
          log?.call('  ${s.name}: ${got.length} signals');
          return (s.name, got, null);
        } catch (e) {
          log?.call('  ${s.name}: FAILED ($e)');
          return (s.name, <TrendSignal>[], '$e');
        }
      }),
    );
    for (final (name, got, err) in results) {
      if (err != null) errors[name] = err;
      if (got.isNotEmpty) used.add(name);
      signals.addAll(got);
    }

    // 2. score + relevance filter + dedupe
    final scored = scorer.score(signals, season, windowDays: windowDays);
    log?.call('  relevant after filtering: ${scored.length}');

    // 3. heuristic concepts (always computed: offline result + LLM hint)
    final heuristic = extractor
        .extract(scored, season)
        .take(maxConcepts)
        .toList();

    // 4. prompts (Claude or templates)
    final (concepts, raw) = await writer.write(
      season: season,
      signals: scored,
      heuristic: heuristic,
      maxConcepts: maxConcepts,
    );

    // 5. safety
    final candidates = filter.apply(raw);

    return ScoutReport(
      season: season.id,
      generatedAt: DateTime.now(),
      windowDays: windowDays,
      sourcesUsed: used,
      sourceErrors: errors,
      signals: scored,
      concepts: concepts,
      candidates: candidates,
      llmUsed: writer.usesLlm,
      llmModel: writer.claude?.model,
    );
  }
}
