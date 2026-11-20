/// Trend Scout: seasonal trend → prompt-candidate robot for SpookyAI.
library;

export 'src/analysis/concept_extractor.dart';
export 'src/analysis/signal_scorer.dart';
export 'src/env.dart';
export 'src/generation/candidate_writer.dart';
export 'src/generation/claude_client.dart';
export 'src/models.dart';
export 'src/output/report_writer.dart';
export 'src/pipeline.dart';
export 'src/safety/candidate_filter.dart';
export 'src/seasons.dart';
export 'src/sources/google_trends_rss_source.dart';
export 'src/sources/reddit_source.dart';
export 'src/sources/seed_file_source.dart';
export 'src/sources/trend_source.dart';
export 'src/sources/youtube_source.dart';
